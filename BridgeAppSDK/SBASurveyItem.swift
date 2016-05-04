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
    var learnMoreHTMLContent: String? { get }
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

public enum SBASurveyItemType {
    
    case Custom(String?)
    case Instruction                // ORKInstructionStep
    case Completion                 // ORKCompletionStep
    case Subtask                    // SBASubtaskStep
    case DataGroups                 // data groups step
    
    case Form(FormSubtype)          // ORKFormStep
    public enum FormSubtype {
        case Compound               // ORKFormItems > 1
        case Boolean                // ORKBooleanAnswerFormat
        case SingleChoice           // ORKTextChoiceAnswerFormat of style SingleChoiceTextQuestion
        case MultipleChoice         // ORKTextChoiceAnswerFormat of style MultipleChoiceTextQuestion
        case Text                   // ORKTextAnswerFormat
        case Date                   // ORKDateAnswerFormat of style Date
        case DateTime               // ORKDateAnswerFormat of style DateTime
        case Time                   // ORKTimeOfDayAnswerFormat
        case Duration               // ORKTimeIntervalAnswerFormat
        case Integer                // ORKNumericAnswerFormat of style Integer
        case Decimal                // ORKNumericAnswerFormat of style Decimal
        case Scale                  // ORKScaleAnswerFormat
        case TimingRange            // Timing Range: ORKTextChoiceAnswerFormat of style SingleChoiceTextQuestion
    }

    case Consent(ConsentSubtype)
    public enum ConsentSubtype {
        case SharingOptions         // ORKConsentSharingStep
        case Review                 // ORKConsentReviewStep
        case Visual                 // ORKVisualConsentStep
    }
    
    init(rawValue: String?) {
        guard let type = rawValue else { self = .Custom(nil); return }
        switch(type) {
        case "instruction"           : self = .Instruction
        case "completion"            : self = .Completion
        case "subtask"               : self = .Subtask
        case "dataGroups"            : self = .DataGroups
        case "compound"              : self = .Form(.Compound)
        case "boolean"               : self = .Form(.Boolean)
        case "singleChoiceText"      : self = .Form(.SingleChoice)
        case "multipleChoiceText"    : self = .Form(.MultipleChoice)
        case "timingRange"           : self = .Form(.TimingRange)
        case "timePicker"            : self = .Form(.Time)
        case "consentSharingOptions" : self = .Consent(.SharingOptions)
        case "consentReview"         : self = .Consent(.Review)
        case "consentVisual"         : self = .Consent(.Visual)
        default                      : self = .Custom(type)
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



