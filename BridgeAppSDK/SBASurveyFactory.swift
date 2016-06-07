//
//  SBASurveyFactory.swift
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
import BridgeSDK

/**
 * The purpose of the Survey Factory is to allow subclassing for custom types of steps
 * that are not recognized by this factory and to allow usage by Obj-c classes that
 * do not recognize protocol extensions.
 */
public class SBASurveyFactory : NSObject, SBASharedInfoController {
    
    public var steps: [ORKStep]?
    
    public var sharedAppDelegate: SBASharedAppDelegate {
        return UIApplication.sharedApplication().delegate as! SBASharedAppDelegate
    }
    
    public override init() {
        super.init()
    }
    
    public convenience init?(jsonNamed: String) {
        guard let json = SBAResourceFinder().jsonNamed(jsonNamed) else { return nil }
        self.init(dictionary: json)
    }
    
    public convenience init(dictionary: NSDictionary) {
        self.init()
        self.mapSteps(dictionary)
    }
    
    func mapSteps(dictionary: NSDictionary) {
        if let steps = dictionary["steps"] as? [NSDictionary] {
            self.steps = steps.mapAndFilter({ self.createSurveyStepWithDictionary($0) })
        }
    }
    
    /**
     * Factory method for creating an ORKTask from an SBBSurvey
     */
    public func createTaskWithSurvey(survey: SBBSurvey) -> SBANavigableOrderedTask {
        let steps: [ORKStep] = survey.elements.mapAndFilter({ self.createSurveyStepWithSurveyElement($0 as! SBBSurveyElement) });
        return SBANavigableOrderedTask(identifier: survey.identifier, steps: steps)
    }
    
    /**
     * Factory method for creating an ORKTask from an SBAActiveTask
     */
    public func createTaskWithActiveTask(activeTask: SBAActiveTask, taskOptions: ORKPredefinedTaskOption) ->
        protocol <ORKTask, NSCopying, NSSecureCoding>? {
        return activeTask.createDefaultORKActiveTask(taskOptions)
    }

    /**
     * Factory method for creating a survey step with a dictionary
     */
    public func createSurveyStepWithDictionary(dictionary: NSDictionary) -> ORKStep? {
        return self.createSurveyStep(dictionary, isSubtaskStep: false)
    }
    
    /**
     * Factory method for creating a survey step with an SBBSurveyElement
     */
    public func createSurveyStepWithSurveyElement(inputItem: SBBSurveyElement) -> ORKStep? {
        guard let surveyItem = inputItem as? SBASurveyItem else { return nil }
        return self.createSurveyStep(surveyItem, isSubtaskStep: false)
    }
    
    /**
     * Factory method for creating a custom type of survey question that is not
     * defined by this class. Note: Only swift can subclass this method directly
     */
    public func createSurveyStepWithCustomType(inputItem: SBASurveyItem) -> ORKStep? {
        switch (inputItem.surveyItemType) {
        case .Custom(let customType):
            if let instruction = inputItem as? SBAInstructionStepSurveyItem {
                return instruction.createInstructionStep(customType)
            }
            else {
                return SBADirectNavigationStep(identifier: inputItem.identifier, customTypeIdentifier: customType)
            }
            
        default:
            return nil
        }
    }
    
    final func createSurveyStep(inputItem: SBASurveyItem) -> ORKStep? {
        return self.createSurveyStep(inputItem, isSubtaskStep: nil, isLastStep: nil)
    }

    final func createSurveyStep(inputItem: SBASurveyItem, isSubtaskStep: Bool?) -> ORKStep? {
        return self.createSurveyStep(inputItem, isSubtaskStep: isSubtaskStep, isLastStep: nil)
    }
    
    final func createSurveyStep(inputItem: SBASurveyItem, isSubtaskStep: Bool?, isLastStep: Bool?) -> ORKStep? {
        switch (inputItem.surveyItemType) {
        case .Instruction, .Completion:
            if let instruction = inputItem as? SBAInstructionStepSurveyItem {
                return instruction.createInstructionStep()
            }
        case .Subtask:
            if let form = inputItem as? SBAFormStepSurveyItem {
                return form.createSubtaskStep(self)
            } else { break }
        case .Form(_):
            if let form = inputItem as? SBAFormStepSurveyItem {
                return form.createFormStep(isSubtaskStep ?? false)
            } else { break }
        case .Registration:
            if let form = inputItem as? SBAFormStepSurveyItem {
                return SBARegistrationStep(inputItem: form)
            } else { break }
        default:
            break
        }
        return createSurveyStepWithCustomType(inputItem)
    }
    
    final func createSurveyStep(inputItem: SBATrackedStepSurveyItem, trackedItems: [SBATrackedDataObject]) -> ORKStep? {
        guard let trackingType = inputItem.trackingType where trackingType.isTrackedFormStepType() else {
            return self.createSurveyStep(inputItem)
        }
        return SBATrackedFormStep(surveyItem: inputItem, items: trackedItems)
    }
    
}

extension SBAInstructionStepSurveyItem {
    
    func createInstructionStep(customType: String? = nil) -> ORKInstructionStep {
        var instructionStep: ORKInstructionStep!
        let learnMore = self.learnMoreAction()
        var nextIdentifier: String? = nil
        if let directStep = self as? SBADirectNavigationRule {
            nextIdentifier = directStep.nextStepIdentifier
        }
        if case .Completion = self.surveyItemType {
            instructionStep = ORKInstructionStep.completionStep().copyWithIdentifier(self.identifier)
        }
        else if (nextIdentifier != nil) || (learnMore != nil) || (customType != nil) {
            let step = SBADirectNavigationStep(identifier: self.identifier, nextStepIdentifier: nextIdentifier)
            step.learnMoreAction = learnMore
            step.customTypeIdentifier = customType
            instructionStep = step
        }
        else {
            instructionStep = ORKInstructionStep(identifier: self.identifier)
        }
        instructionStep.title = self.stepTitle
        instructionStep.text = self.stepText
        instructionStep.detailText = self.stepDetail
        instructionStep.image = self.stepImage;
        return instructionStep
    }
}

extension SBAFormStepSurveyItem {
    
    func createSubtaskStep(factory:SBASurveyFactory) -> SBASubtaskStep {
        assert(self.items?.count > 0, "A subtask step requires items")
        let steps = self.items?.mapAndFilter({ factory.createSurveyStep($0 as! SBASurveyItem, isSubtaskStep: true) })
        let step = self.usesNavigation() ?
            SBASurveySubtaskStep(surveyItem: self, steps: steps) :
            SBASubtaskStep(identifier: self.identifier, steps: steps)
        return step
    }
    
    func createFormStep(isSubtaskStep: Bool) -> ORKFormStep {
        let step = (!isSubtaskStep && self.usesNavigation()) ?
            SBASurveyFormStep(surveyItem: self) :
            ORKFormStep(identifier: self.identifier)
        buildFormItems(step, isSubtaskStep: isSubtaskStep)
        mapStepValues(step)
        return step
    }
    
    func mapStepValues(step:ORKFormStep) {
        step.title = self.stepTitle
        step.text = self.stepText
        step.optional = self.optional
    }
    
    func buildFormItems(step:ORKFormStep, isSubtaskStep: Bool) {
        if case SBASurveyItemType.Form(.Compound) = self.surveyItemType {
            step.formItems = self.items?.map({
                let formItem = $0 as! SBAFormStepSurveyItem
                return formItem.createFormItem(formItem.stepText)
            })
        }
        else {
            step.formItems = [self.createFormItem(nil)]
        }
    }
    
    func createFormItem(text: String?) -> ORKFormItem {
        let answerFormat = self.createAnswerFormat()
        if let rulePredicate = self.rulePredicate {
            // If there is a rule predicate then return a survey form item
            let formItem = SBASurveyFormItem(identifier: self.identifier, text: text, answerFormat: answerFormat, optional: self.optional)
            formItem.rulePredicate = rulePredicate
            return formItem
        }
        else {
            // Otherwise, return a form item
            return ORKFormItem(identifier: self.identifier, text: text, answerFormat: answerFormat, optional: self.optional)
        }
    }
    
    func createAnswerFormat() -> ORKAnswerFormat? {
        guard let subtype = self.surveyItemType.formSubtype() else { return nil }
        switch(subtype) {
        case .Boolean:
            return ORKBooleanAnswerFormat()
        case .Text:
            return ORKTextAnswerFormat()
        case .SingleChoice, .MultipleChoice:
            guard let textChoices = self.items?.map({createTextChoice($0)}) else { return nil }
            let style: ORKChoiceAnswerStyle = (subtype == .SingleChoice) ? .SingleChoice : .MultipleChoice
            return ORKTextChoiceAnswerFormat(style: style, textChoices: textChoices)
        case .Date, .DateTime:
            let style: ORKDateAnswerStyle = (subtype == .Date) ? .Date : .DateAndTime
            let range = self.range as? SBADateRange
            return ORKDateAnswerFormat(style: style, defaultDate: nil, minimumDate: range?.minDate, maximumDate: range?.maxDate, calendar: nil)
        case .Time:
            return ORKTimeOfDayAnswerFormat()
        case .Duration:
            return ORKTimeIntervalAnswerFormat()
        case .Integer, .Decimal, .Scale:
            guard let range = self.range as? SBANumberRange else {
                assertionFailure("\(subtype) requires a valid number range")
                return nil
            }
            return range.createAnswerFormat(subtype)
        case .TimingRange:
            guard let textChoices = self.items?.mapAndFilter({ (obj) -> ORKTextChoice? in
                guard let item = obj as? SBANumberRange else { return nil }
                return item.createORKTextChoice()
            }) else { return nil }
            let notSure = ORKTextChoice(text: Localization.localizedString("SBA_NOT_SURE_CHOICE"), value: "Not sure")
            return ORKTextChoiceAnswerFormat(style: .SingleChoice, textChoices: textChoices + [notSure])
        
        default:
            assertionFailure("Form item question type \(subtype) not implemented")
            return nil
        }
    }
    
    func createTextChoice(obj: AnyObject) -> ORKTextChoice {
        guard let textChoice = obj as? SBATextChoice else {
            assertionFailure("Passing object \(obj) does not match expected protocol SBATextChoice")
            return ORKTextChoice(text: "", detailText: nil, value: NSNull(), exclusive: false)
        }
        return textChoice.createORKTextChoice()
    }

    func usesNavigation() -> Bool {
        if (self.skipIdentifier != nil) || (self.rulePredicate != nil) {
                return true
        }
        guard let items = self.items else { return false }
        for item in items {
            if let item = item as? SBAFormStepSurveyItem,
                let _ = item.rulePredicate {
                    return true
            }
        }
        return false
    }
}

extension SBANumberRange {
    
    func createAnswerFormat(subtype: SBASurveyItemType.FormSubtype) -> ORKAnswerFormat {
        
        if (subtype == .Scale),
            // If this is a scale subtype then check that the max, min and step interval are valid
            let min = self.minNumber?.integerValue, let max = self.maxNumber?.integerValue where
            (max > min) && ((max - min) % self.stepInterval) == 0
        {
            // ResearchKit will throw an assertion if the number of steps is greater than 13 so 
            // hardcode a check for whether or not to use a continuous scale based on that number
            if ((max - min) / self.stepInterval) > 13 {
                return ORKContinuousScaleAnswerFormat(maximumValue: Double(max), minimumValue: Double(min), defaultValue: 0.0, maximumFractionDigits: 0)
            }
            else {
                return ORKScaleAnswerFormat(maximumValue: max, minimumValue: min, defaultValue: 0, step: self.stepInterval)
            }
        }
        
        // Fall through for non-scale or invalid scale type
        let style: ORKNumericAnswerStyle = (subtype == .Decimal) ? .Decimal : .Integer
        return ORKNumericAnswerFormat(style: style, unit: self.unitLabel, minimum: self.minNumber, maximum: self.maxNumber)
    }
    
    // Return a timing interval
    func createORKTextChoice() -> ORKTextChoice? {
        
        let formatter = NSDateComponentsFormatter()
        formatter.allowedUnits = timeIntervalUnit
        formatter.unitsStyle = .Full
        let unit = self.unitLabel ?? "seconds"
        
        // Note: in all cases, the value is returned in English so that the localized 
        // values will result in the same answer in any table. It is up to the researcher to translate.
        if let max = dateComponents(self.maxNumber), let maxString = formatter.stringFromDateComponents(max) {
            let maxNum = self.maxNumber!.integerValue
            if let minNum = self.minNumber?.integerValue {
                let maxText = String(format: Localization.localizedString("SBA_RANGE_%@_AGO"), maxString)
                return ORKTextChoice(text: "\(minNum)-\(maxText)",
                                     value: "\(minNum)-\(maxNum) \(unit) ago")
            }
            else {
                let text = String(format: Localization.localizedString("SBA_LESS_THAN_%@_AGO"), maxString)
                return ORKTextChoice(text: text, value: "Less than \(maxNum) \(unit) ago")
            }
        }
        else if let min = dateComponents(self.minNumber), let minString = formatter.stringFromDateComponents(min) {
            let minNum = self.minNumber!.integerValue
            let text = String(format: Localization.localizedString("SBA_MORE_THAN_%@_AGO"), minString)
            return ORKTextChoice(text: text, value: "More than \(minNum) \(unit) ago")
        }
        
        assertionFailure("Not a valid range with neither a min or max value defined")
        return nil
    }
    
    var timeIntervalUnit: NSCalendarUnit {
        guard let unit = self.unitLabel else { return NSCalendarUnit.Second }
        switch unit {
        case "minutes" :
            return NSCalendarUnit.Minute
        case "hours" :
            return NSCalendarUnit.Hour
        case "days" :
            return NSCalendarUnit.Day
        case "weeks" :
            return NSCalendarUnit.WeekOfMonth
        case "months" :
            return NSCalendarUnit.Month
        case "years" :
            return NSCalendarUnit.Year
        default :
            return NSCalendarUnit.Second
        }
    }
    
    func dateComponents(num: NSNumber?) -> NSDateComponents? {
        guard let value = num?.integerValue else { return nil }
        let components = NSDateComponents()
        switch(timeIntervalUnit) {
        case NSCalendarUnit.Year:
            components.year = value
        case NSCalendarUnit.Month:
            components.month = value
        case NSCalendarUnit.WeekOfMonth:
            components.weekOfYear = value
        case NSCalendarUnit.Hour:
            components.hour = value
        case NSCalendarUnit.Minute:
            components.minute = value
        default:
            components.second = value
        }
        return components
    }

}



