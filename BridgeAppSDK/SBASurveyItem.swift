//
//  SBASurveyItem.swift
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

public protocol SBAStepTransformer: class {
    func transformToStep(factory: SBASurveyFactory, isLastStep: Bool) -> ORKStep?
}

public protocol SBASurveyItem: SBAStepTransformer {
    var identifier: String! { get }
    var surveyItemType: SBASurveyItemType { get }
    var stepTitle: String? { get }
    var stepText: String? { get }
    var stepDetail: String? { get }
}

public protocol SBAActiveStepSurveyItem: SBASurveyItem {
    var stepSpokenInstruction: String? { get }
    var stepFinishedSpokenInstruction: String? { get }
}

public protocol SBAFormStepSurveyItem: SBASurveyItem {
    var optional: Bool { get }
    var items: [AnyObject]? { get }
    var range: AnyObject? { get }
    var skipIdentifier: String? { get }
    var skipIfPassed: Bool { get }
    var rulePredicate: NSPredicate? { get }
}

public protocol SBAInstructionStepSurveyItem: SBASurveyItem {
    var stepImage: UIImage? { get }
    func learnMoreAction() -> SBALearnMoreAction?
}

public protocol SBADateRange: class {
    var minDate: NSDate? { get }
    var maxDate: NSDate? { get }
}

public protocol SBANumberRange: class {
    var minNumber: NSNumber? { get }
    var maxNumber: NSNumber? { get }
    var unitLabel: String? { get }
    var stepInterval: Int { get }
}

extension ORKPasscodeType {
    init?(key: String) {
        guard let passcodeSuffix = key.parseSuffix(SBASurveyItemType.PasscodeKey) else { return nil }
        self = (passcodeSuffix == SBASurveyItemType.PasscodeType6Digit) ? .Type6Digit : .Type4Digit
    }
}

public enum SBASurveyItemType {
    
    case Custom(String?)
    
    case Subtask                                        // SBASubtaskStep
    public static let SubtaskKey = "subtask"
    
    case Instruction(InstructionSubtype)
    public enum InstructionSubtype: String {
        case Instruction        = "instruction"         // ORKInstructionStep
        case Completion         = "completion"          // ORKCompletionStep
    }

    case Form(FormSubtype)                              // ORKFormStep
    public enum FormSubtype: String {
        case Compound           = "compound"            // ORKFormItems > 1
        case Boolean            = "boolean"             // ORKBooleanAnswerFormat
        case SingleChoice       = "singleChoiceText"    // ORKTextChoiceAnswerFormat of style SingleChoiceTextQuestion
        case MultipleChoice     = "multipleChoiceText"  // ORKTextChoiceAnswerFormat of style MultipleChoiceTextQuestion
        case Text               = "textfield"           // ORKTextAnswerFormat
        case Date               = "datePicker"          // ORKDateAnswerFormat of style Date
        case DateTime           = "timeAndDatePicker"   // ORKDateAnswerFormat of style DateTime
        case Time               = "timePicker"          // ORKTimeOfDayAnswerFormat
        case Duration           = "timeInterval"        // ORKTimeIntervalAnswerFormat
        case Integer            = "numericInteger"      // ORKNumericAnswerFormat of style Integer
        case Decimal            = "numericDecimal"      // ORKNumericAnswerFormat of style Decimal
        case Scale              = "scaleInteger"        // ORKScaleAnswerFormat
        case TimingRange        = "timingRange"         // Timing Range: ORKTextChoiceAnswerFormat of style SingleChoiceTextQuestion
    }

    case Consent(ConsentSubtype)
    public enum ConsentSubtype: String {
        case SharingOptions     = "consentSharingOptions"   // ORKConsentSharingStep
        case Review             = "consentReview"           // ORKConsentReviewStep
        case Visual             = "consentVisual"           // ORKVisualConsentStep
    }
    
    case Account(AccountSubtype)
    public enum AccountSubtype: String {
        case Registration       = "registration"            // SBARegistrationStep
        case Login              = "login"                   // SBALoginStep
        case EmailVerification  = "emailVerification"       // SBAEmailVerificationStep
        //TODO: Implement syoung 06/08/2016
        //case DataGroups         = "dataGroups"              // data groups step
    }
    
    case Passcode(ORKPasscodeType)
    public static let PasscodeKey = "passcode"
    public static let PasscodeType6Digit = "Type6Digit"
    public static let PasscodeType4Digit = "Type4Digit"
    
    init(rawValue: String?) {
        guard let type = rawValue else { self = .Custom(nil); return }
        
        if let subtype = InstructionSubtype(rawValue: type) {
            self = .Instruction(subtype)
        }
        else if let subtype = FormSubtype(rawValue: type) {
            self = .Form(subtype)
        }
        else if let subtype = ConsentSubtype(rawValue: type) {
            self = .Consent(subtype)
        }
        else if let subtype = AccountSubtype(rawValue: type) {
            self = .Account(subtype)
        }
        else if let subtype = ORKPasscodeType(key: type) {
            self = .Passcode(subtype)
        }
        else if type == SBASurveyItemType.SubtaskKey {
            self = .Subtask
        }
        else {
            self = .Custom(type)
        }
    }
        
    func formSubtype() -> FormSubtype? {
        if case .Form(let subtype) = self {
            return subtype
        }
        return nil
    }
    
    func consentSubtype() -> ConsentSubtype? {
        if case .Consent(let subtype) = self {
            return subtype
        }
        return nil
    }
    
    func isNilType() -> Bool {
        if case .Custom(let customType) = self {
            return (customType == nil)
        }
        return false
    }
}

extension SBASurveyItemType: Equatable {
}

public func ==(lhs: SBASurveyItemType, rhs: SBASurveyItemType) -> Bool {
    switch (lhs, rhs) {
    case (.Instruction(let lhsValue), .Instruction(let rhsValue)):
        return lhsValue == rhsValue;
    case (.Form(let lhsValue), .Form(let rhsValue)):
        return lhsValue == rhsValue;
    case (.Consent(let lhsValue), .Consent(let rhsValue)):
        return lhsValue == rhsValue;
    case (.Account(let lhsValue), .Account(let rhsValue)):
        return lhsValue == rhsValue;
    case (.Passcode(let lhsValue), .Passcode(let rhsValue)):
        return lhsValue == rhsValue;
    case (.Subtask, .Subtask):
        return true
    case (.Custom(let lhsValue), .Custom(let rhsValue)):
        return lhsValue == rhsValue;
    default:
        return false
    }
}

public protocol SBACustomTypeStep {
    var customTypeIdentifier: String? { get }
}

extension SBASurveyItemType: SBACustomTypeStep {
    public var customTypeIdentifier: String? {
        if case .Custom(let type) = self {
            return type
        }
        return nil
    }
}

