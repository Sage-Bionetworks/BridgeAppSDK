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
 The purpose of the Survey Factory is to allow subclassing for custom types of steps
 that are not recognized by this factory and to allow usage by Obj-c classes that
 do not recognize protocol extensions.
 */
open class SBASurveyFactory : NSObject, SBASharedInfoController {
    
    open var steps: [ORKStep]?
    
    lazy open var sharedAppDelegate: SBAAppInfoDelegate = {
        return UIApplication.shared.delegate as! SBAAppInfoDelegate
    }()
    
    public override init() {
        super.init()
    }
    
    public convenience init?(jsonNamed: String) {
        guard let json = SBAResourceFinder.shared.json(forResource: jsonNamed) else { return nil }
        self.init(dictionary: json as NSDictionary)
    }
    
    public convenience init(dictionary: NSDictionary) {
        self.init()
        self.mapSteps(dictionary)
    }
    
    func mapSteps(_ dictionary: NSDictionary) {
        if let steps = dictionary["steps"] as? [NSDictionary] {
            self.steps = steps.mapAndFilter({ self.createSurveyStepWithDictionary($0) })
        }
    }
    
    /**
     Factory method for creating an SBANavigableOrderedTask from the current steps
     @param identifier  The task identifier
     @return            Task created with the steps initialized with this factory
     */
    open func createTaskWithIdentifier(_ identifier: String) -> SBANavigableOrderedTask {
        return SBANavigableOrderedTask(identifier: identifier, steps: steps)
    }
    
    /**
     Factory method for creating an ORKTask from an SBBSurvey
     @param survey      An `SBBSurvey` bridge model object
     @return            Task created with this survey
     */
    open func createTaskWithSurvey(_ survey: SBBSurvey) -> SBANavigableOrderedTask {
        let lastStepIndex = survey.elements.count - 1
        let steps: [ORKStep] = survey.elements.enumerated().mapAndFilter({ (offset: Int, element: Any) -> ORKStep? in
            guard let surveyItem = element as? SBBSurveyElement else { return nil }
            return createSurveyStepWithSurveyElement(surveyItem, isLastStep: (offset == lastStepIndex))
        })
        return SBANavigableOrderedTask(identifier: survey.identifier, steps: steps)
    }
    
    /**
     Factory method for creating an ORKTask from an SBAActiveTask
     @param activeTask      An `SBAActiveTask` active task
     @param taskOptions     Task options for this task
     @return                An encodable, copyable `ORKTask`
     */
    open func createTaskWithActiveTask(_ activeTask: SBAActiveTask, taskOptions: ORKPredefinedTaskOption) ->
        (ORKTask & NSCopying & NSSecureCoding)? {
        return activeTask.createDefaultORKActiveTask(taskOptions)
    }

    /**
     Factory method for creating a survey step with a dictionary
     @param dictionary      Dictionary defining the step
     @return                An `ORKStep`
     */
    open func createSurveyStepWithDictionary(_ dictionary: NSDictionary) -> ORKStep? {
        return self.createSurveyStep(dictionary)
    }
    
    /**
     Factory method for creating a survey step with an SBBSurveyElement
     @param inputItem       A `SBBSurveyElement` bridge model object
     @return                An `ORKStep`
     */
    open func createSurveyStepWithSurveyElement(_ inputItem: SBBSurveyElement, isLastStep:Bool = false) -> ORKStep? {
        guard let surveyItem = inputItem as? SBASurveyItem else { return nil }
        let step = self.createSurveyStep(surveyItem)
        if isLastStep, let instructionStep = step as? SBAInstructionStep {
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
    }
    
    /**
     Factory method for creating a custom type of survey question that is not
     defined by this class. Note: Only swift can subclass this method directly
     @param inputItem       An input item conforming to the `SBASurveyItem` protocol
     @return                An `ORKStep`
     */
    open func createSurveyStepWithCustomType(_ inputItem: SBASurveyItem) -> ORKStep? {
        switch (inputItem.surveyItemType) {
        case .custom(_):
            return SBAInstructionStep(inputItem: inputItem)
        default:
            return nil
        }
    }
    
    /**
     Factory method for creating a step where the step uses tracked items to build the step.
     Note: only swift can subclass this method directly.
     @param inputItem       An input item conforming to the `SBASurveyItem` protocol
     @param trackingType    The tracking type for the survey item
     @param trackedItems    The list of all tracked data objects used to define this step
     @return                An `ORKStep`
     */
    open func createSurveyStep(_ inputItem: SBASurveyItem, trackingType: SBATrackingStepType, trackedItems: [SBATrackedDataObject]) -> ORKStep? {
        if trackingType == .activity, let activityItem = inputItem as? SBATrackedActivitySurveyItem {
            // Let the activity item return the appropriate instance of the step
            return activityItem.createTrackedActivityStep(trackedItems, factory: self)
        }
        else if trackingType == .selection, let selectionItem = inputItem as? SBAFormStepSurveyItem {
            return SBATrackedSelectionStep(inputItem: selectionItem, trackedItems: trackedItems, factory: self)
        }
        else {
            // Otherwise, return the step from the factory
            return self.createSurveyStep(inputItem)
        }
    }
    
    /**
     Factory method for injecting an override of the functionality supported by the `SBAFormStepSurveyItem`
     protocol extension. Because a protocol extension cannot be overriden, this method allows the injection 
     of customization of the default answer format.
     @param inputItem       An input item conforming to the `SBAFormStepSurveyItem` protocol
     @param subtype         The form subtype to use when creating the answer format
     @return                An answer format.
    */
    open func createAnswerFormat(_ inputItem: SBAFormStepSurveyItem, subtype: SBASurveyItemType.FormSubtype?) -> ORKAnswerFormat? {
        return inputItem.createAnswerFormat(subtype)
    }
    
    /**
     Factory method for injecting an override of the functionality supported by the `SBAFormStepSurveyItem`
     protocol extension. Because a protocol extension cannot be overriden, this method allows the injection
     of customization of the default form item.
     @param inputItem       An input item conforming to the `SBAFormStepSurveyItem` protocol
     @param subtype         The form subtype to use when creating the answer format
     @return                A form item.
    */
    open func createFormItem(_ inputItem:SBAFormStepSurveyItem, subtype: SBASurveyItemType.FormSubtype? = nil) -> ORKFormItem {
        let subtype = inputItem.surveyItemType.formSubtype() ?? subtype
        return inputItem.createFormItem(text: inputItem.stepText, subtype: subtype, factory: self)
    }
    
    /**
     Factory method for injecting an override of the functionality supported by the `SBAFormStepSurveyItem`
     protocol extension. Because a protocol extension cannot be overriden, this method allows the injection
     of customization of the default form item.
     @param inputItem       An input item conforming to the `SBAFormStepSurveyItem` protocol
     @param isSubtaskStep   Whether or not this is a subtask step
     @return                step
     */
    open func createFormStep(_ inputItem:SBAFormStepSurveyItem, isSubtaskStep: Bool = false) -> ORKStep? {
        
        // If this item should use the question style then create accordingly
        if inputItem.questionStyle {
            return SBANavigationQuestionStep(inputItem: inputItem, factory: self)
        }
        
        // Factory method for determining the proper type of form-style step to return
        // the ORKQuestionStep and ORKFormStep have a different UI presentation
        let step: ORKStep =
            // If this is a boolean toggle step then that casting takes priority
            inputItem.isBooleanToggle ? SBAToggleFormStep(inputItem: inputItem) :
            // If this is *not* a subtask step and it uses navigation then return a survey form step
            (!isSubtaskStep && inputItem.usesNavigation()) ? SBANavigationFormStep(inputItem: inputItem) :
            // Otherwise, use a form step
            ORKFormStep(identifier: inputItem.identifier)
        
        inputItem.buildFormItems(with: step as! SBAFormProtocol, isSubtaskStep: isSubtaskStep, factory: self)
        inputItem.mapStepValues(with: step)
        return step
    }
    
    internal final func createSurveyStep(_ inputItem: SBASurveyItem, isSubtaskStep: Bool = false) -> ORKStep? {
        switch (inputItem.surveyItemType) {
            
        case .instruction(_):
            return SBAInstructionStep(inputItem: inputItem)
            
        case .subtask:
            if let form = inputItem as? SBAFormStepSurveyItem {
                return form.createSubtaskStep(with: self)
            } else { break }
            
        case .form(_):
            if let form = inputItem as? SBAFormStepSurveyItem {
                return createFormStep(form, isSubtaskStep: isSubtaskStep)
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
    
    fileprivate func createAccountStep(inputItem: SBASurveyItem, subtype: SBASurveyItemType.AccountSubtype) -> ORKStep? {
        switch (subtype) {
        case .registration:
            return SBARegistrationStep(inputItem: inputItem, factory: self)
        case .login:
            return SBALoginStep(inputItem: inputItem, factory: self)
        case .emailVerification:
            return SBAEmailVerificationStep(inputItem: inputItem, appInfo: self.sharedAppDelegate)
        case .externalID:
            return SBAExternalIDStep(inputItem: inputItem)
        case .permissions:
            return SBAPermissionsStep(inputItem: inputItem)
        case .completion:
            return SBAOnboardingCompleteStep(inputItem: inputItem)
        case .dataGroups:
            return SBADataGroupsStep(inputItem: inputItem)
        case .profile:
            return SBAProfileFormStep(inputItem: inputItem, factory: self)
            
        }
    }
    
}

extension SBASurveyItem {
}

extension SBAInstructionStepSurveyItem {
}

extension SBAFormStepSurveyItem {
    
    var isValidFormItem: Bool {
        return (self.identifier != nil) && (self.surveyItemType.formSubtype() != nil)
    }
    
    var isBooleanToggle: Bool {
        return SBASurveyItemType.form(.toggle) == self.surveyItemType
    }
    
    var isCompoundStep: Bool {
        return isBooleanToggle || (SBASurveyItemType.form(.compound) == self.surveyItemType)
    }
    
    func createSubtaskStep(with factory:SBASurveyFactory) -> SBASubtaskStep {
        assert((self.items?.count ?? 0) > 0, "A subtask step requires items")
        let steps = self.items?.mapAndFilter({ factory.createSurveyStep($0 as! SBASurveyItem, isSubtaskStep: true) })
        let step = self.usesNavigation() ?
            SBANavigationSubtaskStep(inputItem: self, steps: steps) :
            SBASubtaskStep(identifier: self.identifier, steps: steps)
        return step
    }
    
    func mapStepValues(with step: ORKStep) {
        step.title = self.stepTitle?.trim()
        step.text = self.stepText?.trim()
        step.isOptional = self.optional
        if let formStep = step as? ORKFormStep {
            formStep.footnote = self.stepFootnote
        }
    }
    
    func buildFormItems(with step: SBAFormProtocol, isSubtaskStep: Bool, factory: SBASurveyFactory? = nil) {
        
        if self.isCompoundStep {
            let factory = factory ?? SBASurveyFactory()
            step.formItems = self.items?.map({
                return factory.createFormItem($0 as! SBAFormStepSurveyItem)
            })
        }
        else {
            let subtype = self.surveyItemType.formSubtype()
            step.formItems = [self.createFormItem(text: nil, subtype: subtype, factory: factory)]
        }
    }
        
    func createFormItem(text: String?, subtype: SBASurveyItemType.FormSubtype?, factory: SBASurveyFactory? = nil) -> ORKFormItem {
        let answerFormat = factory?.createAnswerFormat(self, subtype: subtype) ?? self.createAnswerFormat(subtype)
        if let rulePredicate = self.rules?.first?.rulePredicate {
            // If there is a rule predicate then return a survey form item
            let formItem = SBANavigationFormItem(identifier: self.identifier, text: text, answerFormat: answerFormat, optional: self.optional)
            formItem.rulePredicate = rulePredicate
            return formItem
        }
        else {
            // Otherwise, return a form item
            return ORKFormItem(identifier: self.identifier, text: text, answerFormat: answerFormat, optional: self.optional)
        }
    }
    
    func createAnswerFormat(_ subtype: SBASurveyItemType.FormSubtype?) -> ORKAnswerFormat? {
        let subtype = subtype ?? SBASurveyItemType.FormSubtype.boolean
        switch(subtype) {
        case .boolean:
            return ORKBooleanAnswerFormat()
        case .text:
            return ORKTextAnswerFormat()
        case .singleChoice, .multipleChoice:
            guard let textChoices = self.items?.map({createTextChoice(from: $0)}) else { return nil }
            let style: ORKChoiceAnswerStyle = (subtype == .singleChoice) ? .singleChoice : .multipleChoice
            return ORKTextChoiceAnswerFormat(style: style, textChoices: textChoices)
        case .date, .dateTime:
            let style: ORKDateAnswerStyle = (subtype == .date) ? .date : .dateAndTime
            let range = self.range as? SBADateRange
            return ORKDateAnswerFormat(style: style, defaultDate: nil, minimumDate: range?.minDate as Date?, maximumDate: range?.maxDate as Date?, calendar: nil)
        case .time:
            return ORKTimeOfDayAnswerFormat()
        case .duration:
            return ORKTimeIntervalAnswerFormat()
        case .integer, .decimal, .scale:
            guard let range = self.range as? SBANumberRange else {
                assertionFailure("\(subtype) requires a valid number range")
                return nil
            }
            return range.createAnswerFormat(with: subtype)
        case .timingRange:
            guard let textChoices = self.items?.mapAndFilter({ (obj) -> ORKTextChoice? in
                guard let item = obj as? SBANumberRange else { return nil }
                return item.createORKTextChoice()
            }) else { return nil }
            let notSure = ORKTextChoice(text: Localization.localizedString("SBA_NOT_SURE_CHOICE"), value: "Not sure" as NSString)
            return ORKTextChoiceAnswerFormat(style: .singleChoice, textChoices: textChoices + [notSure])
        case .compound, .toggle:
            assertionFailure("Form item question type .compound or .toggle is not supported as an answer format")
            return nil
        }
    }
    
    func createTextChoice(from obj: Any) -> ORKTextChoice {
        guard let textChoice = obj as? SBATextChoice else {
            assertionFailure("Passing object \(obj) does not match expected protocol SBATextChoice")
            return ORKTextChoice(text: "", detailText: nil, value: NSNull(), exclusive: false)
        }
        return textChoice.createORKTextChoice()
    }

    func usesNavigation() -> Bool {
        if let count = self.rules?.count, count > 0 {
            return true
        }
        guard let items = self.items else { return false }
        for item in items {
            if let item = item as? SBAFormStepSurveyItem,
                let count = item.rules?.count, count > 0 {
                    return true
            }
        }
        return false
    }
}

extension SBANumberRange {
    
    func createAnswerFormat(with subtype: SBASurveyItemType.FormSubtype) -> ORKAnswerFormat {
        
        if (subtype == .scale) && self.stepInterval >= 1,
            // If this is a scale subtype then check that the max, min and step interval are valid
            let min = self.minNumber?.doubleValue, let max = self.maxNumber?.doubleValue, (max > min)
        {
            // ResearchKit will throw an assertion if the number of steps is greater than 13 so 
            // hardcode a check for whether or not to use a continuous scale based on that number
            let interval = Double(self.stepInterval)
            let numberOfSteps = floor((max - min) / interval)
            if (numberOfSteps > 13) || (numberOfSteps * interval != (max - min)) {
                return ORKContinuousScaleAnswerFormat(maximumValue: max, minimumValue: min, defaultValue: 0.0, maximumFractionDigits: 0)
            }
            else {
                return ORKScaleAnswerFormat(maximumValue: self.maxNumber!.intValue, minimumValue: self.minNumber!.intValue, defaultValue: 0, step: self.stepInterval)
            }
        }
        
        // Fall through for non-scale or invalid scale type
        let style: ORKNumericAnswerStyle = (subtype == .decimal) ? .decimal : .integer
        return ORKNumericAnswerFormat(style: style, unit: self.unitLabel, minimum: self.minNumber, maximum: self.maxNumber)
    }
    
    // Return a timing interval
    func createORKTextChoice() -> ORKTextChoice? {
        
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = timeIntervalUnit
        formatter.unitsStyle = .full
        let unitText = self.unitLabel ?? "seconds"
        let calendarUnit = self.timeIntervalUnit
        
        // Note: in all cases, the value is returned in English so that the localized 
        // values will result in the same answer in any table. It is up to the researcher to translate.
        if let maxNum = self.maxNumber?.intValue,
            let max = dateComponents(value: maxNum, calendarUnit: calendarUnit),
            let maxString = formatter.string(from: max) {
            
            if let minNum = self.minNumber?.intValue {
                let maxText = Localization.localizedStringWithFormatKey("SBA_RANGE_%@_AGO", maxString)
                return ORKTextChoice(text: "\(minNum)-\(maxText)",
                                     value: "\(minNum)-\(maxNum) \(unitText) ago"  as NSString)
            }
            else {
                let text = Localization.localizedStringWithFormatKey("SBA_LESS_THAN_%@_AGO", maxString)
                return ORKTextChoice(text: text, value: "Less than \(maxNum) \(unitText) ago"  as NSString)
            }
        }
        else if let minNum = self.minNumber?.intValue,
            let min = dateComponents(value: minNum, calendarUnit: calendarUnit),
            let minString = formatter.string(from: min) {
            
            let text = Localization.localizedStringWithFormatKey("SBA_MORE_THAN_%@_AGO", minString)
            return ORKTextChoice(text: text, value: "More than \(minNum) \(unitText) ago" as NSString)
        }
        
        assertionFailure("Not a valid range with neither a min or max value defined")
        return nil
    }
    
    var timeIntervalUnit: NSCalendar.Unit {
        guard let unit = self.unitLabel else { return NSCalendar.Unit.second }
        switch unit {
        case "minutes" :
            return NSCalendar.Unit.minute
        case "hours" :
            return NSCalendar.Unit.hour
        case "days" :
            return NSCalendar.Unit.day
        case "weeks" :
            return NSCalendar.Unit.weekOfMonth
        case "months" :
            return NSCalendar.Unit.month
        case "years" :
            return NSCalendar.Unit.year
        default :
            return NSCalendar.Unit.second
        }
    }
    
    func dateComponents(value: Int, calendarUnit: NSCalendar.Unit) -> DateComponents? {
        var components = DateComponents()
        switch(calendarUnit) {
        case NSCalendar.Unit.year:
            components.year = value
        case NSCalendar.Unit.month:
            components.month = value
        case NSCalendar.Unit.weekOfMonth:
            components.weekOfYear = value
        case NSCalendar.Unit.hour:
            components.hour = value
        case NSCalendar.Unit.minute:
            components.minute = value
        default:
            components.second = value
        }
        return components
    }

}



