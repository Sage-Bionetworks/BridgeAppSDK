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
    
    lazy public var sharedAppDelegate: SBAAppInfoDelegate = {
        return UIApplication.sharedApplication().delegate as! SBAAppInfoDelegate
    }()
    
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
     * Factory method for creating an SBANavigableOrderedTask from the current steps
     */
    public func createTaskWithIdentifier(identifier: String) -> SBANavigableOrderedTask {
        return SBANavigableOrderedTask(identifier: identifier, steps: steps)
    }
    
    /**
     * Factory method for creating an ORKTask from an SBBSurvey
     */
    public func createTaskWithSurvey(survey: SBBSurvey) -> SBANavigableOrderedTask {
        let lastStepIndex = survey.elements.count - 1
        let steps: [ORKStep] = survey.elements.enumerate().mapAndFilter({ (index: Int, element: AnyObject) -> ORKStep? in
            guard let surveyItem = element as? SBASurveyItem else { return nil }
            let step = createSurveyStep(surveyItem)
            if (index == lastStepIndex), let instructionStep = step as? SBAInstructionStep {
                instructionStep.isCompletionStep = true
                // For the last step of a survey, put the detail text in a popup and assume that it 
                // is copyright information
                if let detailText = instructionStep.detailText {
                    let popAction = SBAPopUpLearnMoreAction(identifier: "learnMore")
                    popAction.learnMoreText = detailText
                    popAction.learnMoreButtonText = Localization.localizedString("SBA_COPYRIGHT")
                    instructionStep.detailText = nil
                    instructionStep.learnMoreAction = popAction
                }
            }
            return step
        })
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
        return self.createSurveyStep(dictionary)
    }
    
    /**
     * Factory method for creating a survey step with an SBBSurveyElement
     */
    public func createSurveyStepWithSurveyElement(inputItem: SBBSurveyElement) -> ORKStep? {
        guard let surveyItem = inputItem as? SBASurveyItem else { return nil }
        return self.createSurveyStep(surveyItem)
    }
    
    /**
     * Factory method for creating a custom type of survey question that is not
     * defined by this class. Note: Only swift can subclass this method directly
     */
    public func createSurveyStepWithCustomType(inputItem: SBASurveyItem) -> ORKStep? {
        switch (inputItem.surveyItemType) {
        case .custom(_):
            return SBAInstructionStep(inputItem: inputItem)
        default:
            return nil
        }
    }
    
    /**
     * Factory method for creating a step where the step uses tracked items to build the step.
     * Note: only swift can subclass this method directly.
     */
    public func createSurveyStep(inputItem: SBASurveyItem, trackingType:SBATrackingStepType, trackedItems:[SBATrackedDataObject]) -> ORKStep? {
        if trackingType == .activity, let activityItem = inputItem as? SBATrackedActivitySurveyItem {
            // Let the activity item return the appropriate instance of the step
            return activityItem.createTrackedActivityStep(trackedItems)
        }
        else if trackingType == .selection, let selectionItem = inputItem as? SBAFormStepSurveyItem {
            return SBATrackedSelectionStep(inputItem: selectionItem, trackedItems: trackedItems, factory: self)
        }
        else {
            // Otherwise, return the step from the factory
            return self.createSurveyStep(inputItem)
        }
    }
    
    final func createSurveyStep(inputItem: SBASurveyItem, isSubtaskStep: Bool = false) -> ORKStep? {
        switch (inputItem.surveyItemType) {
            
        case .instruction(_):
            return SBAInstructionStep(inputItem: inputItem)
            
        case .subtask:
            if let form = inputItem as? SBAFormStepSurveyItem {
                return form.createSubtaskStep(self)
            } else { break }
            
        case .form(_):
            if let form = inputItem as? SBAFormStepSurveyItem {
                return form.createFormStep(isSubtaskStep ?? false)
            } else { break }
            
        case .account(let subtype):
            return createAccountStep(inputItem: inputItem, subtype: subtype)
            
        case .passcode(let passcodeType):
            let step = ORKPasscodeStep(identifier: inputItem.identifier)
            step.title = inputItem.stepTitle
            step.text = inputItem.stepText
            step.passcodeType = passcodeType
            return step
            
        default:
            break
        }
        return createSurveyStepWithCustomType(inputItem)
    }
    
    func createAccountStep(inputItem inputItem: SBASurveyItem, subtype: SBASurveyItemType.AccountSubtype) -> ORKStep? {
        switch (subtype) {
        case .registration:
            return SBARegistrationStep(inputItem: inputItem)
        case .login:
            return SBALoginStep(inputItem: inputItem)
        case .emailVerification:
            return SBAEmailVerificationStep(inputItem: inputItem, appInfo: self.sharedAppDelegate)
        case .externalID:
            return SBAExternalIDStep(inputItem: inputItem)
        case .permissions:
            return SBAPermissionsStep(inputItem: inputItem)
        case .completion:
            return SBAOnboardingCompleteStep(inputItem: inputItem)
        }
    }
    
}

extension SBASurveyItem {
}

extension SBAInstructionStepSurveyItem {
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
    
    func createFormStep(isSubtaskStep: Bool) -> ORKStep {
        
        // Factory method for determining the proper type of form-style step to return
        // the ORKQuestionStep and ORKFormStep have a different UI presentation
        let step: ORKStep =
            // If this is a question style then use the SBA subclass
            self.questionStyle ? SBASurveyQuestionStep(surveyItem: self) :
            // If this is *not* a subtask step and it uses navigation then return a survey form step
            (!isSubtaskStep && self.usesNavigation()) ? SBASurveyFormStep(surveyItem: self) :
            // Otherwise, use a form step
            ORKFormStep(identifier: self.identifier)
        
        buildFormItems(step as! SBAFormProtocol, isSubtaskStep: isSubtaskStep)
        mapStepValues(step)
        return step
    }
    
    func mapStepValues(step: ORKStep) {
        step.title = self.stepTitle?.trim()
        step.text = self.stepText?.trim()
        step.optional = self.optional
    }
    
    func buildFormItems(step: SBAFormProtocol, isSubtaskStep: Bool) {
        if case SBASurveyItemType.form(.compound) = self.surveyItemType {
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
        case .boolean:
            return ORKBooleanAnswerFormat()
        case .text:
            return ORKTextAnswerFormat()
        case .singleChoice, .multipleChoice:
            guard let textChoices = self.items?.map({createTextChoice($0)}) else { return nil }
            let style: ORKChoiceAnswerStyle = (subtype == .singleChoice) ? .SingleChoice : .MultipleChoice
            return ORKTextChoiceAnswerFormat(style: style, textChoices: textChoices)
        case .date, .dateTime:
            let style: ORKDateAnswerStyle = (subtype == .date) ? .Date : .DateAndTime
            let range = self.range as? SBADateRange
            return ORKDateAnswerFormat(style: style, defaultDate: nil, minimumDate: range?.minDate, maximumDate: range?.maxDate, calendar: nil)
        case .time:
            return ORKTimeOfDayAnswerFormat()
        case .duration:
            return ORKTimeIntervalAnswerFormat()
        case .integer, .decimal, .scale:
            guard let range = self.range as? SBANumberRange else {
                assertionFailure("\(subtype) requires a valid number range")
                return nil
            }
            return range.createAnswerFormat(subtype)
        case .timingRange:
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
        
        if (subtype == .scale) && self.stepInterval >= 1,
            // If this is a scale subtype then check that the max, min and step interval are valid
            let min = self.minNumber?.doubleValue, let max = self.maxNumber?.doubleValue where (max > min)
        {
            // ResearchKit will throw an assertion if the number of steps is greater than 13 so 
            // hardcode a check for whether or not to use a continuous scale based on that number
            let interval = Double(self.stepInterval)
            let numberOfSteps = floor((max - min) / interval)
            if (numberOfSteps > 13) || (numberOfSteps * interval != (max - min)) {
                return ORKContinuousScaleAnswerFormat(maximumValue: max, minimumValue: min, defaultValue: 0.0, maximumFractionDigits: 0)
            }
            else {
                return ORKScaleAnswerFormat(maximumValue: self.maxNumber!.integerValue, minimumValue: self.minNumber!.integerValue, defaultValue: 0, step: self.stepInterval)
            }
        }
        
        // Fall through for non-scale or invalid scale type
        let style: ORKNumericAnswerStyle = (subtype == .decimal) ? .Decimal : .Integer
        return ORKNumericAnswerFormat(style: style, unit: self.unitLabel, minimum: self.minNumber, maximum: self.maxNumber)
    }
    
    // Return a timing interval
    func createORKTextChoice() -> ORKTextChoice? {
        
        let formatter = NSDateComponentsFormatter()
        formatter.allowedUnits = timeIntervalUnit
        formatter.unitsStyle = .Full
        let unitText = self.unitLabel ?? "seconds"
        let calendarUnit = self.timeIntervalUnit
        
        // Note: in all cases, the value is returned in English so that the localized 
        // values will result in the same answer in any table. It is up to the researcher to translate.
        if let maxNum = self.maxNumber?.integerValue,
            let max = dateComponents(maxNum, calendarUnit: calendarUnit),
            let maxString = formatter.stringFromDateComponents(max) {
            
            if let minNum = self.minNumber?.integerValue {
                let maxText = Localization.localizedStringWithFormatKey("SBA_RANGE_%@_AGO", maxString)
                return ORKTextChoice(text: "\(minNum)-\(maxText)",
                                     value: "\(minNum)-\(maxNum) \(unitText) ago")
            }
            else {
                let text = Localization.localizedStringWithFormatKey("SBA_LESS_THAN_%@_AGO", maxString)
                return ORKTextChoice(text: text, value: "Less than \(maxNum) \(unitText) ago")
            }
        }
        else if let minNum = self.minNumber?.integerValue,
            let min = dateComponents(minNum, calendarUnit: calendarUnit),
            let minString = formatter.stringFromDateComponents(min) {
            
            let text = Localization.localizedStringWithFormatKey("SBA_MORE_THAN_%@_AGO", minString)
            return ORKTextChoice(text: text, value: "More than \(minNum) \(unitText) ago")
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
    
    func dateComponents(value: Int, calendarUnit: NSCalendarUnit) -> NSDateComponents? {
        let components = NSDateComponents()
        switch(calendarUnit) {
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



