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

extension NSDictionary: SBATrackedActivitySurveyItem {
    
    public var textFormat: String? {
        return self["textFormat"] as? String
    }
    
    public var trackEach: Bool {
        return self["trackEach"] as? Bool ?? false
    }
}

extension SBATrackedActivitySurveyItem {
    
    public func createTrackedActivityStep(items:[SBATrackedDataObject]) -> ORKStep {
        
        // Create a base form step
        let baseStep = SBATrackedActivityFormStep(identifier: self.identifier)
        baseStep.textFormat = self.textFormat
        self.mapStepValues(baseStep)
        self.buildFormItems(baseStep, isSubtaskStep: false)
        
        if (self.trackEach) {
            // If tracking each then need to create a step for each item that is tracked
            let steps = items.mapAndFilter({ (item) -> SBATrackedActivityFormStep? in
                guard item.tracking else { return nil }
                return baseStep.copyWithIdentifier(item.identifier)
            })
            let task = ORKOrderedTask(identifier: self.identifier, steps: steps)
            return SBATrackedActivityPageStep(identifier: self.identifier, pageTask: task)
            
        }
        else {
            // If using a consolidated form step, then just return the one step
            return baseStep
        }
    }
}

public class SBATrackedActivityFormStep: ORKFormStep, SBATrackedNavigationStep {
    
    var textFormat: String?
    
    public override init(identifier: String) {
        super.init(identifier: identifier)
    }
    
    // MARK: SBATrackedNavigationStep
    
    public var trackingType: SBATrackingStepType? {
        return .activity
    }
    
    public var shouldSkipStep: Bool {
        return _shouldSkipStep
    }
    var _shouldSkipStep: Bool = false
    
    public func update(selectedItems selectedItems:[SBATrackedDataObject]) {
        // filter out selected items that are not tracked
        let trackedItems = selectedItems.filter({ $0.tracking })
        _shouldSkipStep = (trackedItems.count == 0)
        if let textFormat = self.textFormat where (trackedItems.count > 0) {
            let shortText = Localization.localizedJoin(trackedItems.map({ $0.shortText}))
            self.text = String.localizedStringWithFormat(textFormat, shortText)
        }
    }
    
    // MARK: NSCoding
    
    required public init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.textFormat = aDecoder.decodeObjectForKey("textFormat") as? String
    }
    
    override public func encodeWithCoder(aCoder: NSCoder) {
        super.encodeWithCoder(aCoder)
        aCoder.encodeObject(self.textFormat, forKey: "textFormat")
    }
    
    // MARK: NSCopying
    
    override public func copyWithZone(zone: NSZone) -> AnyObject {
        let copy = super.copyWithZone(zone) as! SBATrackedActivityFormStep
        copy.textFormat = self.textFormat
        return copy
    }
    
    // MARK: Equality

    override public func isEqual(object: AnyObject?) -> Bool {
        guard let object = object as? SBATrackedActivityFormStep else { return false }
        return super.isEqual(object) &&
            object.textFormat == self.textFormat
    }
    
    override public var hash: Int {
        return super.hash ^
            SBAObjectHash(self.textFormat)
    }
    
}

public class SBATrackedActivityPageStep: ORKPageStep, SBATrackedNavigationStep {
    
    private var selectedItemIdentifiers: [String] = []
    
    override public init(identifier: String, pageTask task: ORKOrderedTask) {
        super.init(identifier: identifier, pageTask: task)
    }
    
    override public func stepViewControllerClass() -> AnyClass {
        return SBATrackedActivityPageStepViewController.classForCoder()
    }
    
    // MARK: Navigation override
    
    override public func stepAfterStepWithIdentifier(identifier: String?, withResult result: ORKTaskResult) -> ORKStep? {
        // If this step should be skipped then there are no valid steps to display
        if shouldSkipStep { return nil }
        
        // Look for the next match
        guard let nextIdentifier = selectedItemIdentifiers.nextMatch(identifier) else { return nil }
        return pageTask.stepWithIdentifier(nextIdentifier)
    }
    
    override public func stepBeforeStepWithIdentifier(identifier: String, withResult result: ORKTaskResult) -> ORKStep? {
        // If this step should be skipped then there are no valid steps to display
        if shouldSkipStep { return nil }
        
        // Look in reverse order through the selected identifiers
        guard let nextIdentifier = selectedItemIdentifiers.reverse().nextMatch(identifier) else { return nil }
        return pageTask.stepWithIdentifier(nextIdentifier)
    }
    
    // MARK: SBATrackedNavigationStep
    
    public var trackingType: SBATrackingStepType? {
        return .activity
    }
    
    public var shouldSkipStep: Bool {
        return selectedItemIdentifiers.count == 0
    }
    
    public func update(selectedItems selectedItems:[SBATrackedDataObject]) {
    
        // filter out selected items that are not tracked
        let trackedItems = selectedItems.filter({ $0.tracking })
        
        // update the selectedIdentifiers
        selectedItemIdentifiers = trackedItems.map({ $0.identifier })
        
        // update the underlying form steps
        for item in trackedItems {
            if let step = self.stepWithIdentifier(item.identifier) as? SBATrackedActivityFormStep {
                step.update(selectedItems: [item])
            }
        }
    }
    
    // MARK: NSCoding
    
    required public init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.selectedItemIdentifiers = aDecoder.decodeObjectForKey("selectedItemIdentifiers") as? [String] ?? []
    }
    
    override public func encodeWithCoder(aCoder: NSCoder) {
        super.encodeWithCoder(aCoder)
        aCoder.encodeObject(self.selectedItemIdentifiers, forKey: "selectedItemIdentifiers")
    }
    
    // MARK: NSCopying
    
    public init(identifier: String) {
        // Copying requires defining the base class ORKStep init
        super.init(identifier: identifier, pageTask: ORKOrderedTask(identifier: identifier, steps: nil))
    }
    
    override public func copyWithZone(zone: NSZone) -> AnyObject {
        let copy = super.copyWithZone(zone) as! SBATrackedActivityPageStep
        copy.selectedItemIdentifiers = self.selectedItemIdentifiers
        return copy
    }
    
    // MARK: Equality
    
    // syoung 07/20/2016 Equality does not depend upon the selectedItemIdentifiers being the same
    // This is a tracking value that is necessary in order to be able to setup which items to include in
    // the questions asked when tracking each, but it is only included in copying and coding so that this 
    // step does not need a reverse weak link to the data store.
}

public class SBATrackedActivityPageStepViewController: ORKPageStepViewController {
    
    override public var result: ORKStepResult? {
        guard let stepResult = super.result else { return nil }
        
        // Get the choice answers
        var formIdentifier = self.step!.identifier
        let choiceAnswers = self.pageStep?.pageTask.steps.mapAndFilter({ (step) -> AnyObject? in
            
            guard let formStep = step as? ORKFormStep,
                let formItem = formStep.formItems?.first,
                let formResult = stepResult.resultForIdentifier("\(step.identifier).\(formItem.identifier)") as? ORKQuestionResultAnswerJSON,
                let answer = formResult.jsonSerializedAnswer()
                else {
                    return nil
            }
            
            // keep track of the identifier for the form item and use this for the identifier for the 
            // consolidated result
            formIdentifier = formItem.identifier
            
            // create and return a mapping of identifier to value
            var value = answer.value
            if let array = value as? NSArray where array.count == 1 {
                value = array.firstObject!
            }
            return ["identifier" : step.identifier, "answer" : value] as NSDictionary
        })
        
        // Create and return a result for the consolidated steps
        let questionResult = ORKChoiceQuestionResult(identifier: formIdentifier)
        questionResult.startDate = stepResult.startDate
        questionResult.endDate = stepResult.endDate
        questionResult.questionType = ORKQuestionType.MultipleChoice
        questionResult.choiceAnswers = choiceAnswers ?? []
        stepResult.addResult(questionResult)

        return stepResult
    }
}
