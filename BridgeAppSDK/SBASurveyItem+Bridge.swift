//
//  SBBSurveyElement+SBASurveyItemExtentions.swift
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

import BridgeSDK
import ResearchKit

// NOTE: syoung 03/17/2016 The Objective-C definitions for the SBBBridgeObjects are defined with a
// forced unwrap whereas they should be defined as optionals. Therefore, I am wrapping the properties
// in optionals and always check that the object is not nil before using it.

// NOTE: syoung 08/26/2016 Newline characters are not displayed in the Bridge Web UI so the person 
// copy/pasting the text into the question cannot proofread them. Strip any newlines out of the text.

extension SBBSurveyInfoScreen : SBAInstructionStepSurveyItem {
    
    public var surveyItemType: SBASurveyItemType {
        return .instruction(.instruction)
    }
    
    public var stepTitle: String? {
        if (self.title == nil) { return nil }
        return self.title.removingNewlineCharacters()
    }
    
    public var stepText: String? {
        if (self.prompt == nil) { return nil }
        return self.prompt.removingNewlineCharacters()
    }
    
    public var stepDetail: String? {
        if (self.promptDetail == nil) { return nil }
        return self.promptDetail.removingNewlineCharacters()
    }
    
    public var stepFootnote: String? {
        return nil
    }

    public var stepImage: UIImage? {
        // NOTE: syoung 03/15/2015 SBBImage translation not implemented. Requires caching design and currently not used
        // by any supported apps.
        return nil
    }
    
    public var iconImage: UIImage? {
        return nil
    }
    
    public var options: [String : AnyObject]? {
        return nil
    }
    
    public func learnMoreAction() -> SBALearnMoreAction? {
        return nil
    }
    
    public func transformToStep(with factory: SBABaseSurveyFactory, isLastStep: Bool) -> ORKStep? {
        return factory.createSurveyStep(self)
    }
}

extension SBBSurveyQuestion : SBAFormStepSurveyItem, SBASurveyRuleGroup {
    
    public var shouldUseQuestionStyle: Bool {
        return true
    }
    
    public var surveyItemType: SBASurveyItemType {
        if let _ = self.constraints as? SBBBooleanConstraints {
            return .form(.boolean)
        }
        else if let _ = self.constraints as? SBBStringConstraints {
            if (self.uiHint == "textfield") {
                return .form(.text)
            }
            else {
                return .form(.multipleLineText)
            }
        }
        else if let multiConstraints = self.constraints as? SBBMultiValueConstraints {
            if (multiConstraints.allowMultipleValue) {
                return .form(.multipleChoice)
            }
            else {
                return .form(.singleChoice)
            }
        }
        else if let _ = self.constraints as? SBBDateTimeConstraints {
            return .form(.dateTime)
        }
        else if let _ = self.constraints as? SBBDateConstraints {
            return .form(.date)
        }
        else if let _ = self.constraints as? SBBTimeConstraints {
            return .form(.time)
        }
        else if let durationConstraints = self.constraints as? SBBDurationConstraints {
            if durationConstraints.unit == nil {
                return .form(.duration)
            }
            else {
                return .form(.integer)
            }
        }
        else if let _ = self.constraints as? SBBIntegerConstraints {
            if (self.uiHint == "slider") {
                return .form(.scale)
            }
            else {
                return .form(.integer)
            }
        }
        else if let _ = self.constraints as? SBBDecimalConstraints {
            if (self.uiHint == "slider") {
                return .form(.continuousScale)
            }
            else {
                return .form(.decimal)
            }
        }
        return SBASurveyItemType.custom(nil)
    }
    
    // The Bridge Study Manager UI includes a `prompt` and a `prompt detail` whereas ResearchKit
    // describes a `title` and `text` properties. The `title` is bold large size text that is 
    // not appropriate for a question sentence. 
    //
    // Therefore, if there is no prompt detail (or if this is a textfield WITHOUT a `patternPlaceholder`) 
    // then assign the `SBBSurveyQuestion.prompt` to `ORKQuestionStep.text`. If there is a non-nil value 
    // for `SBBSurveyQuestion.promptDetail` (and the `patternPlaceholder` is non-nil) then assign that 
    // to `ORKQuestionStep.text` and `SBBSurveyQuestion.prompt` to `ORKQuestionStep.title`. If there is a
    // nil placeholder value for the `patternPlaceholder` (which is only valid if there is a pattern)
    // but this is a String constraint then use the `promptDetail` as the placeholder text.
    
    
    var detailPlaceholder: String? {
        guard let constraint = self.constraints as? SBBStringConstraints,
            (constraint.patternPlaceholder == nil) &&
            (self.promptDetail != nil) &&
            (self.promptDetail!.characters.count <= 12)
        else {
            return nil
        }
        return self.promptDetail.removingNewlineCharacters()
    }
    
    var regexPlaceholder: String? {
        guard let constraint = self.constraints as? SBBStringConstraints else { return nil }
        return constraint.patternPlaceholder
    }
    
    public var stepTitle: String? {
        // If either the prompt or the promptDetail is nil then the title is not used
        guard (self.promptDetail != nil) && (self.prompt != nil) && (self.detailPlaceholder == nil) else { return nil }
        return self.prompt.removingNewlineCharacters()
    }
    
    public var stepText: String? {
        if (self.stepTitle != nil) {
            if (self.promptDetail == nil) { return nil }
            return self.promptDetail.removingNewlineCharacters()
        }
        else {
            if (self.prompt == nil) { return nil }
            return self.prompt.removingNewlineCharacters()
        }
    }

    public var placeholderText: String? {
        return self.regexPlaceholder ?? self.detailPlaceholder
    }
    
    public var stepFootnote: String? {
        return nil
    }
    
    public var optional: Bool {
        return true // default implementation.
    }
    
    public var items: [Any]? {
        
        // NOTE: Only supported use of items is for a multiple choice constraint. SBBBridgeObjects
        // do not (currently) have a constraint type that allows for compound steps (although the
        // use of use of the word "constraints" would suggest that. syoung 03/17/2016
        guard let multiConstraints = self.constraints as? SBBMultiValueConstraints, let items = multiConstraints.enumeration
        else {
            return nil
        }

        // If this multiple choice should have an "other" option then include the string as a choice
        if (multiConstraints.allowOtherValue) {
            var other = Localization.localizedString("SBA_OTHER")
            if (items.filter({ ($0 as! SBBSurveyQuestionOption).hasUppercaseLetters }).count == 0) {
                other = other.lowercased()
            }
            return (items as NSArray).adding(NSString(string: other)) as [Any]
        }
        
        return items
    }
    
    public var options: [String : AnyObject]? {
        return nil
    }
    
    public var range: AnyObject? {
        return self.constraints
    }
    
    public var skipIdentifier: String? {
        return nil
    }
    
    public var skipIfPassed: Bool {
        return true
    }
    
    public var rules: [SBASurveyRuleItem]? {
        return (self.constraints.rules as? [SBASurveyRuleItem])?.filter({ $0.ruleOperator != nil })
    }
    
    public func hasNavigationRules() -> Bool {
        guard (self.rules?.count ?? 0) > 0 else { return false }
        return true
    }
    
    public func transformToStep(with factory: SBABaseSurveyFactory, isLastStep: Bool) -> ORKStep? {
        return factory.createSurveyStep(self)
    }
}

extension SBBSurveyRule: SBASurveyRuleItem {
    
    public var formSubtype:SBASurveyItemType.FormSubtype? {
        return nil
    }
    
    public var resultIdentifier: String? {
        return nil
    }
    
    public var skipIdentifier: String? {
        return self.skipTo ?? ORKNullStepIdentifier
    }
    
    public var expectedAnswer: Any? {
        return self.value
    }
    
    public var ruleOperator: SBASurveyRuleOperator? {
        return SBASurveyRuleOperator(rawValue: self.`operator`)
    }
}

extension SBBSurveyQuestionOption: SBATextChoice {
    
    public var choiceDataGroups: [String] {
        return [String(describing: self.value)]
    }

    public var choiceText: String {
        return self.label
    }
    
    public var choiceDetail: String? {
        return self.detail;
    }
    
    public var choiceValue: NSCoding & NSCopying & NSObjectProtocol {
        return self.value
    }
    
    public var exclusive: Bool {
        return false
    }
    
    public var hasUppercaseLetters: Bool {
        return self.label.lowercased() != self.label
    }
}

public protocol sbb_DateRange : SBADateRange {
    var allowFutureValue: Bool { get }
    var earliestValue: Date! { get }
    var latestValue: Date! { get }
}

extension SBBDateConstraints : sbb_DateRange {
}

extension SBBDateTimeConstraints : sbb_DateRange {
}

extension sbb_DateRange  {
    public var minDate: Date? {
        return self.earliestValue
    }
    public var maxDate: Date? {
        if ((!self.allowFutureValue) && (self.latestValue == nil)) {
            return Date() // Return NOW if future dates are not allowed
        }
        else {
            return self.latestValue
        }
    }
}

public protocol sbb_NumberRange: SBANumberRange {
    var maxValue: NSNumber! { get }
    var minValue: NSNumber! { get }
    var step: NSNumber! { get }
    var unit: String! { get }
}

extension SBBIntegerConstraints: sbb_NumberRange {
}

extension SBBDecimalConstraints: sbb_NumberRange {
}

// Note: syoung 08/10/2016 On the server you are required to define a min/max and step
// but the `SBBDurationConstraints` model object does not include these values. 
extension SBBDurationConstraints: sbb_NumberRange {
    
    public var minValue: NSNumber! {
        return NSNumber(value: 0 as Int)
    }
    
    public var maxValue: NSNumber!  {
        return NSNumber(value: NSIntegerMax as Int)
    }
    
    public var step: NSNumber! {
        return nil
    }
}

extension sbb_NumberRange {
    
    public var minNumber: NSNumber? {
        guard ((self.minValue != nil) && (self.maxValue != nil)) else { return nil }
        return minValue
    }

    public var maxNumber: NSNumber? {
        guard ((self.minValue != nil) && (self.maxValue != nil)) else { return nil }
        return maxValue
    }
    
    public var stepInterval: Double {
        guard (self.step != nil) else { return 1 }
        return self.step.doubleValue
    }
    
    public var unitLabel: String? {
        guard (self.unit != "") else { return nil }
        return self.unit
    }
}

extension SBBStringConstraints: SBATextFieldRange {
    
    public var autocapitalizationType: UITextAutocapitalizationType {
        return .none
    }

    public var keyboardType: UIKeyboardType {
        return .default
    }
    
    public var validationRegex: String? {
        if self.pattern != nil {
            return self.pattern
        }
        else if self.minLengthValue > 0 {
            assert(self.pattern == nil, "Factory does not currently support items with both a min length and a regex pattern.")
            return "^.{\(self.minLengthValue),}$"
        }
        else {
            return nil
        }
    }
    
    public var invalidMessage: String? {
        return self.patternErrorMessage
    }
    
    public var maximumLength: Int {
        return Int(self.maxLengthValue)
    }
}


