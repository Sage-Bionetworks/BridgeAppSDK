//
//  SBATrackedSelectionStep.swift
//  BridgeAppSDK
//
//  Copyright © 2016 Sage Bionetworks. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:
//
// 1.  Redistributions of source code must retain the above copyright notice, this
// list of conditions and the following disclaimer.
//
// 2.  Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimer in the documentation and/or
// other materials provided with the distribution.
//
// 3.  Neither the name of the copyright holder(s) nor the names of any contributors
// may be used to endorse or promote products derived from this software without
// specific prior written permission. No license is granted to the trademarks of
// the copyright holders even if such marks are included in this software.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

open class SBATrackedSelectionStep: ORKPageStep, SBATrackedStep, SBATrackedDataSelectedItemsProtocol {
    
    open var trackingType: SBATrackingStepType? {
        return .selection
    }
    
    open var trackedItems: [SBATrackedDataObject] {
        return _trackedItems
    }
    fileprivate var _trackedItems: [SBATrackedDataObject]
    
    /** 
    Define a non-generic factory-style initializer to hide the implementation details of creating the 
    default selection/frequency steps in the owning class.
    */
    init(inputItem: SBAFormStepSurveyItem, trackedItems: [SBATrackedDataObject], factory: SBASurveyFactory) {
        
        // Set the tracked items pointer
        _trackedItems = trackedItems
        
        // Create the steps with the *first* step as the selection step created from the inputItem
        let firstStep = SBATrackedSelectionFormStep(surveyItem: inputItem, items: trackedItems)
        let additionalSteps:[ORKStep] = inputItem.items?.mapAndFilter({ (element) -> ORKStep? in
            
            // If the item does not conform to survey item then return nil
            guard let surveyItem = element as? SBASurveyItem else { return nil }
            
            // If the item is not a frequency item then no special handling required
            // so fall back to the base level factory for creating the step
            guard let trackedSurveyItem = element as? SBATrackedStep,
                let type = trackedSurveyItem.trackingType , type == .frequency,
                let formSurveyItem = element as? SBAFormStepSurveyItem
                else {
                    return factory.createSurveyStep(surveyItem)
            }
            
            // Otherwise for the case where this is a frequency step, special-case the return to
            // use the frequency subclass
            return SBATrackedFrequencyFormStep(surveyItem: formSurveyItem)
        }) ?? []
        
        let steps = [firstStep] + additionalSteps
        super.init(identifier: inputItem.identifier, steps: steps)
    }
    
    /**
    Generic default initializer defined so that this class can include steps that are not the
    frequency and selection steps. 
    */
    public init(identifier: String, trackedItems: [SBATrackedDataObject], steps:[ORKStep]) {
        _trackedItems = trackedItems
        super.init(identifier: identifier, steps: steps)
    }
    
    override open func stepViewControllerClass() -> AnyClass {
        return SBATrackedSelectionStepViewController.classForCoder()
    }
    
    // MARK: SBATrackedDataSelectedItemsProtocol
    
    @objc(stepResultWithSelectedItems:)
    public func stepResult(selectedItems:[SBATrackedDataObject]?) -> ORKStepResult? {
        guard let items = selectedItems else { return nil }
        
        // Map the steps
        var results:[ORKResult] = self.steps.map { (step) -> [ORKResult] in
            
            let substepResults: [ORKResult] = {
                if let trackingStep = step as? SBATrackedDataSelectedItemsProtocol {
                    // If the substeps implement the selected item result protocol then use that
                    return trackingStep.stepResult(selectedItems: items)?.results ?? []
                }
                else {
                    // TODO: syoung 09/27/2016 Support mapping the results from steps that are not the 
                    // selection and frequency steps
                    return step.defaultStepResult().results ?? []
                }
            }()
            
            for result in substepResults {
                result.identifier = "\(step.identifier).\(result.identifier)"
            }
            return substepResults
            
            }.flatMap({$0})
        
        // Add the tracked result last
        let trackedResult = SBATrackedDataSelectionResult(identifier: self.identifier)
        trackedResult.selectedItems = items
        results.append(trackedResult)
        
        return ORKStepResult(stepIdentifier: self.identifier, results: results)
    }
    
    // MARK: Selection filtering
    
    var trackedResultIdentifier: String? {
        return self.steps.find({ (step) -> Bool in
            if let trackedStep = step as? SBATrackedStep , trackedStep.trackingType == .selection {
                return true
            }
            return false
        })?.identifier
    }
    
    func filterItems(resultSource:ORKTaskResultSource) -> [SBATrackedDataObject]? {
        var items: [SBATrackedDataObject]? = trackedItems
        for step in self.steps {
            if let filterItems = items,
                let filterStep = step as? SBATrackedSelectionFilter,
                let stepResult = resultSource.stepResult(forStepIdentifier: step.identifier) {
                items = filterStep.filter(selectedItems: filterItems, stepResult: stepResult)
            }
        }
        return items
    }
    
    // MARK: Navigation override
    
    override open func stepAfterStep(withIdentifier identifier: String?, with result: ORKTaskResult) -> ORKStep? {
        
        // If the identifier is nil, then this is the first step and there isn't any
        // filtering of the selection that needs to occur
        guard identifier != nil else {
            return super.stepAfterStep(withIdentifier: nil, with: result)
        }
        
        // Check if the current state means that nothing was selected. In this case
        // there is no follow-up steps to further mutate the selection set.
        guard let selectedItems = filterItems(resultSource: result) else { return nil }
        
        // Loop through the next steps to look for the next valid step
        var shouldSkip = false
        var nextStep: ORKStep?
        var previousIdentifier = identifier
        repeat {
            nextStep = super.stepAfterStep(withIdentifier: previousIdentifier, with: result)
            shouldSkip = {
                guard let navStep = nextStep as? SBATrackedNavigationStep else { return false }
                navStep.update(selectedItems: selectedItems)
                return navStep.shouldSkipStep
            }()
            previousIdentifier = nextStep?.identifier
        } while shouldSkip && (nextStep != nil )
        
        return nextStep
    }
    
    override open func stepBeforeStep(withIdentifier identifier: String, with result: ORKTaskResult) -> ORKStep? {
        // Check if the current state means that nothing was selected. In this case
        // return to the first step
        guard let _ = filterItems(resultSource: result) else {
            return self.steps.first
        }
        
        // Loop backward through the steps until one is found that is the first
        var shouldSkip = false
        var previousStep: ORKStep?
        var previousIdentifier: String? = identifier
        repeat {
            previousStep = super.stepBeforeStep(withIdentifier: previousIdentifier!, with: result)
            shouldSkip = {
                guard let navStep = previousStep as? SBATrackedNavigationStep else { return false }
                return navStep.shouldSkipStep
            }()
            previousIdentifier = previousStep?.identifier
        } while shouldSkip && (previousIdentifier != nil )
        
        return previousStep
    }
    
    // MARK: NSCoding
    
    required public init(coder aDecoder: NSCoder) {
        _trackedItems = aDecoder.decodeObject(forKey: "trackedItems") as? [SBATrackedDataObject] ?? []
        super.init(coder: aDecoder)
    }
    
    override open func encode(with aCoder: NSCoder){
        super.encode(with: aCoder)
        aCoder.encode(self.trackedItems, forKey: "trackedItems")
    }
    
    // MARK: NSCopying
    
    convenience init(identifier: String) {
        // Copying requires defining the base class ORKStep init
        self.init(identifier: identifier, trackedItems: [], steps:[])
    }
    
    override open func copy(with zone: NSZone? = nil) -> Any {
        let copy = super.copy(with: zone) as! SBATrackedSelectionStep
        copy._trackedItems = self._trackedItems
        return copy
    }
    
    // MARK: Equality
        
    override open func isEqual(_ object: Any?) -> Bool {
        guard let object = object as? SBATrackedSelectionStep else { return false }
        return super.isEqual(object) &&
            SBAObjectEquality(object.trackedItems, self.trackedItems)
    }
    
    override open var hash: Int {
        return super.hash ^
            SBAObjectHash(self.trackedItems)
    }
}

class SBATrackedSelectionStepViewController: ORKPageStepViewController {
    override var result: ORKStepResult? {
        guard let stepResult = super.result else { return nil }
        guard let selectionStep = self.pageStep as? SBATrackedSelectionStep,
            let trackedResultIdentifier = selectionStep.trackedResultIdentifier
        else {
            return nil
        }
        
        let trackingResult = SBATrackedDataSelectionResult(identifier: trackedResultIdentifier)
        trackingResult.startDate = stepResult.startDate
        trackingResult.endDate = stepResult.endDate
        trackingResult.selectedItems = selectionStep.filterItems(resultSource: self.resultSource())
        stepResult.addResult(trackingResult)
        
        return stepResult
    }
}

class SBATrackedSelectionFormStep: ORKFormStep, SBATrackedSelectionFilter, SBATrackedDataSelectedItemsProtocol {
    
    let skipChoiceValue = "Skipped"
    let noneChoiceValue = "None"
    let choicesFormItemIdentifier = "choices"
    
    // If this is an optional step, then building the form items will add a skip option
    override var isOptional: Bool {
        get {
            return false
        }
        set (newValue) {
            super.isOptional = newValue
        }
    }
    
    init(surveyItem: SBAFormStepSurveyItem, items:[SBATrackedDataObject]) {
        super.init(identifier: surveyItem.identifier)
        surveyItem.mapStepValues(with: self)

        // choices
        var choices = items.map { (item) -> ORKTextChoice in
            return item.createORKTextChoice()
        }
        
        // Add a choice for none of the above
        let noneChoice = ORKTextChoice(text: Localization.localizedString("SBA_NONE_OF_THE_ABOVE"),
                                       detailText: nil,
                                       value: noneChoiceValue as NSString,
                                       exclusive: true)
        choices.append(noneChoice)
        
        // If this is an optional step, then include a choice for skipping
        if (super.isOptional) {
            let skipChoice = ORKTextChoice(text: Localization.localizedString("SBA_SKIP_CHOICE"),
                                           detailText: nil,
                                           value: skipChoiceValue as NSString,
                                           exclusive: true)
            choices.append(skipChoice)
        }
        
        // setup the form items
        let answerFormat = ORKTextChoiceAnswerFormat(style: .multipleChoice, textChoices: choices)
        let formItem = ORKFormItem(identifier: choicesFormItemIdentifier, text: nil, answerFormat: answerFormat)
        self.formItems = [formItem]
    }
    
    override init(identifier: String) {
        super.init(identifier: identifier)
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    // MARK: SBATrackedDataSelectedItemsProtocol
    
    @objc(stepResultWithSelectedItems:)
    public func stepResult(selectedItems:[SBATrackedDataObject]?) -> ORKStepResult? {
        guard let formItem = self.formItems?.first,
            let choices = selectedItems?.map({$0.identifier})
            else {
                return self.defaultStepResult()
        }
        let answer: Any = (choices.count > 0) ? choices : noneChoiceValue
        return stepResult(with: [formItem.identifier : answer] )
    }
    
    // MARK: SBATrackedSelectionFilter
    
    var trackingType: SBATrackingStepType? {
        return .selection
    }
    
    func filter(selectedItems items: [SBATrackedDataObject], stepResult: ORKStepResult) -> [SBATrackedDataObject]? {
        
        // If the step result does not yet include the result of the step then just return all items
        guard let choiceResult = stepResult.result(forIdentifier: choicesFormItemIdentifier) as? ORKChoiceQuestionResult else {
            return items.map({ $0.copy() as! SBATrackedDataObject })
        }
        
        // If the selection was skipped then return nil
        guard let choices = choiceResult.choiceAnswers as? [String] , choices != [skipChoiceValue] else {
            return nil
        }
        
        // filter and map the results
        return items.filter({ choices.contains($0.identifier) }).map({ $0.copy() as! SBATrackedDataObject })
    }
}

class SBATrackedFrequencyFormStep: ORKFormStep, SBATrackedNavigationStep, SBATrackedSelectionFilter, SBATrackedDataSelectedItemsProtocol {
    
    var frequencyAnswerFormat: ORKAnswerFormat?
    
    init(surveyItem: SBAFormStepSurveyItem) {
        super.init(identifier: surveyItem.identifier)
        surveyItem.mapStepValues(with: self)
        if let range = surveyItem as? SBANumberRange {
            self.frequencyAnswerFormat = range.createAnswerFormat(with: .scale)
        }
    }
    
    // MARK: SBATrackedNavigationStep
    
    var trackingType: SBATrackingStepType? {
        return .frequency
    }
    
    var shouldSkipStep: Bool {
        return (self.formItems == nil) || (self.formItems!.count == 0)
    }
    
    func update(selectedItems:[SBATrackedDataObject]) {
        self.formItems = selectedItems.filter({ $0.usesFrequencyRange }).map { (item) -> ORKFormItem in
            return ORKFormItem(identifier: item.identifier, text: item.text, answerFormat: self.frequencyAnswerFormat)
        }
    }
    
    func filter(selectedItems items: [SBATrackedDataObject], stepResult: ORKStepResult) -> [SBATrackedDataObject]? {
        return items.map({ (item) -> SBATrackedDataObject in
            let copy = item.copy() as! SBATrackedDataObject
            if let scaleResult = stepResult.result(forIdentifier: item.identifier) as? ORKScaleQuestionResult,
                let answer = scaleResult.scaleAnswer {
                copy.frequency = answer.uintValue
            }
            return copy
        })
    }
    
    // MARK: SBATrackedDataSelectedItemsProtocol
    
    @objc(stepResultWithSelectedItems:)
    public func stepResult(selectedItems:[SBATrackedDataObject]?) -> ORKStepResult? {
        let results = selectedItems?.mapAndFilter({ (item) -> ORKScaleQuestionResult? in
            guard item.usesFrequencyRange else { return nil }
            let scaleResult = ORKScaleQuestionResult(identifier: item.identifier)
            scaleResult.scaleAnswer = NSNumber(value: item.frequency)
            return scaleResult
        })
        return ORKStepResult(stepIdentifier: self.identifier, results: results)
    }
    
    // MARK: NSCoding
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.frequencyAnswerFormat = aDecoder.decodeObject(forKey: #keyPath(frequencyAnswerFormat)) as? ORKAnswerFormat
    }
    
    override func encode(with aCoder: NSCoder){
        super.encode(with: aCoder)
        aCoder.encode(self.frequencyAnswerFormat, forKey: #keyPath(frequencyAnswerFormat))
    }
    
    // MARK: NSCopying
    
    override init(identifier: String) {
        super.init(identifier: identifier)
    }
    
    override func copy(with zone: NSZone? = nil) -> Any {
        let copy = super.copy(with: zone) as! SBATrackedFrequencyFormStep
        copy.frequencyAnswerFormat = self.frequencyAnswerFormat
        return copy
    }
    
    // MARK: Equality
    
    override func isEqual(_ object: Any?) -> Bool {
        guard let object = object as? SBATrackedFrequencyFormStep else { return false }
        return super.isEqual(object) &&
            SBAObjectEquality(object.frequencyAnswerFormat, self.frequencyAnswerFormat)
    }
    
    override var hash: Int {
        return super.hash ^
            SBAObjectHash(self.frequencyAnswerFormat)
    }
}



