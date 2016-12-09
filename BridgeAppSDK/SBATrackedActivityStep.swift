//
//  SBATrackedActivityStep.swift
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

import ResearchKit

public protocol SBATrackedActivitySurveyItem: SBAFormStepSurveyItem, SBATrackedStep {
    var trackEach: Bool { get }
    var textFormat: String? { get }
}

extension SBATrackedActivitySurveyItem {
    
    public func createTrackedActivityStep(_ items:[SBATrackedDataObject], factory: SBASurveyFactory) -> ORKStep {
        
        // Create a base form step
        let baseStep = SBATrackedActivityFormStep(identifier: self.identifier)
        baseStep.textFormat = self.textFormat
        self.mapStepValues(with: baseStep)
        self.buildFormItems(with: baseStep, isSubtaskStep: false, factory: factory)
        
        if (self.trackEach) {
            // If tracking each then need to create a step for each item that is tracked
            let steps = items.mapAndFilter({ (item) -> SBATrackedActivityFormStep? in
                guard item.tracking else { return nil }
                return baseStep.copy(withIdentifier: item.identifier)
            })
            return SBATrackedActivityPageStep(identifier: self.identifier, steps: steps)
            
        }
        else {
            // If using a consolidated form step, then just return the one step
            return baseStep
        }
    }
}

open class SBATrackedActivityFormStep: ORKFormStep, SBATrackedNavigationStep {
    
    var textFormat: String?
    
    public override init(identifier: String) {
        super.init(identifier: identifier)
    }
    
    override public func defaultStepResult() -> ORKStepResult {
        guard let formItem = self.formItems?.first else { return ORKStepResult(identifier: self.identifier) }
        let questionResult = ORKChoiceQuestionResult(identifier: formItem.identifier)
        questionResult.questionType = ORKQuestionType.multipleChoice
        questionResult.choiceAnswers = ["No Tracked Data"]
        return ORKStepResult(stepIdentifier: self.identifier, results: [questionResult])
    }
    
    // MARK: SBATrackedNavigationStep
    
    open var trackingType: SBATrackingStepType? {
        return .activity
    }
    
    open var shouldSkipStep: Bool {
        return _shouldSkipStep
    }
    var _shouldSkipStep: Bool = false
    
    open func update(selectedItems:[SBATrackedDataObject]) {
        // filter out selected items that are not tracked
        let trackedItems = selectedItems.filter({ $0.tracking })
        _shouldSkipStep = (trackedItems.count == 0)
        if let textFormat = self.textFormat , (trackedItems.count > 0) {
            let shortText = Localization.localizedJoin(textList: trackedItems.map({ $0.shortText}))
            self.text = String.localizedStringWithFormat(textFormat, shortText)
        }
    }
    
    // MARK: NSCoding
    
    required public init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.textFormat = aDecoder.decodeObject(forKey: "textFormat") as? String
    }
    
    override open func encode(with aCoder: NSCoder){
        super.encode(with: aCoder)
        aCoder.encode(self.textFormat, forKey: "textFormat")
    }
    
    // MARK: NSCopying
    
    override open func copy(with zone: NSZone? = nil) -> Any {
        let copy = super.copy(with: zone) as! SBATrackedActivityFormStep
        copy.textFormat = self.textFormat
        return copy
    }
    
    // MARK: Equality

    override open func isEqual(_ object: Any?) -> Bool {
        guard let object = object as? SBATrackedActivityFormStep else { return false }
        return super.isEqual(object) &&
            SBAObjectEquality(object.textFormat, self.textFormat)
    }
    
    override open var hash: Int {
        return super.hash ^
            SBAObjectHash(self.textFormat)
    }
    
}

open class SBATrackedActivityPageStep: ORKPageStep, SBATrackedNavigationStep {
    
    @objc
    fileprivate var selectedItemIdentifiers: [String] = []
    
    override init(identifier: String, steps: [ORKStep]?) {
        super.init(identifier: identifier, steps: steps)
    }
    
    override open func stepViewControllerClass() -> AnyClass {
        return SBATrackedActivityPageStepViewController.classForCoder()
    }
    
    override public func defaultStepResult() -> ORKStepResult {
        let questionResult = ORKChoiceQuestionResult(identifier: self.identifier)
        questionResult.questionType = ORKQuestionType.multipleChoice
        questionResult.choiceAnswers = []
        return ORKStepResult(stepIdentifier: self.identifier, results: [questionResult])
    }
    
    // MARK: Navigation override
    
    override open func stepAfterStep(withIdentifier identifier: String?, with result: ORKTaskResult) -> ORKStep? {
        // If this step should be skipped then there are no valid steps to display
        if shouldSkipStep { return nil }
        
        // Look for the next match
        guard let nextIdentifier = selectedItemIdentifiers.nextMatch(identifier) else { return nil }
        return step(withIdentifier: nextIdentifier)
    }
    
    override open func stepBeforeStep(withIdentifier identifier: String, with result: ORKTaskResult) -> ORKStep? {
        // If this step should be skipped then there are no valid steps to display
        if shouldSkipStep { return nil }
        
        // Look in reverse order through the selected identifiers
        guard let nextIdentifier = selectedItemIdentifiers.reversed().nextMatch(identifier) else { return nil }
        return step(withIdentifier: nextIdentifier)
    }
    
    // MARK: SBATrackedNavigationStep
    
    open var trackingType: SBATrackingStepType? {
        return .activity
    }
    
    open var shouldSkipStep: Bool {
        return selectedItemIdentifiers.count == 0
    }
    
    open func update(selectedItems:[SBATrackedDataObject]) {
    
        // filter out selected items that are not tracked
        let trackedItems = selectedItems.filter({ $0.tracking })
        
        // update the selectedIdentifiers
        selectedItemIdentifiers = trackedItems.map({ $0.identifier })
        
        // update the underlying form steps
        for item in trackedItems {
            if let step = self.step(withIdentifier: item.identifier) as? SBATrackedActivityFormStep {
                step.update(selectedItems: [item])
            }
        }
    }
    
    // MARK: NSCoding
    
    required public init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.selectedItemIdentifiers = aDecoder.decodeObject(forKey: #keyPath(selectedItemIdentifiers)) as? [String] ?? []
    }
    
    override open func encode(with aCoder: NSCoder){
        super.encode(with: aCoder)
        aCoder.encode(self.selectedItemIdentifiers, forKey: #keyPath(selectedItemIdentifiers))
    }
    
    // MARK: NSCopying
    
    public init(identifier: String) {
        // Copying requires defining the base class ORKStep init
        super.init(identifier: identifier, steps: nil)
    }
    
    override open func copy(with zone: NSZone? = nil) -> Any {
        let copy = super.copy(with: zone) as! SBATrackedActivityPageStep
        copy.selectedItemIdentifiers = self.selectedItemIdentifiers
        return copy
    }
    
    // MARK: Equality
    
    // syoung 07/20/2016 Equality does not depend upon the selectedItemIdentifiers being the same
    // This is a tracking value that is necessary in order to be able to setup which items to include in
    // the questions asked when tracking each, but it is only included in copying and coding so that this 
    // step does not need a reverse weak link to the data store.
}

open class SBATrackedActivityPageStepViewController: ORKPageStepViewController {
    
    override open var result: ORKStepResult? {
        guard let stepResult = super.result else { return nil }
        
        // Get the choice answers
        var formIdentifier = self.step!.identifier
        let choiceAnswers = self.pageStep?.steps.mapAndFilter({ (step) -> AnyObject? in
            
            guard let formStep = step as? ORKFormStep,
                let formItem = formStep.formItems?.first,
                let formResult = stepResult.result(forIdentifier: "\(step.identifier).\(formItem.identifier)") as? ORKQuestionResultAnswerJSON,
                let answer = formResult.jsonSerializedAnswer()
                else {
                    return nil
            }
            
            // keep track of the identifier for the form item and use this for the identifier for the 
            // consolidated result
            formIdentifier = formItem.identifier
            
            // create and return a mapping of identifier to value
            var value = answer.value
            if let array = value as? NSArray, array.count == 1 {
                value = array.firstObject! as! NSSecureCoding
            }
            return ["identifier" : step.identifier, "answer" : value] as NSDictionary
        })
        
        // Create and return a result for the consolidated steps
        let questionResult = ORKChoiceQuestionResult(identifier: formIdentifier)
        questionResult.startDate = stepResult.startDate
        questionResult.endDate = stepResult.endDate
        questionResult.questionType = ORKQuestionType.multipleChoice
        questionResult.choiceAnswers = choiceAnswers ?? []
        stepResult.addResult(questionResult)

        return stepResult
    }
}
