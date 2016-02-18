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

public protocol SBASurveyItem: class {
    var identifier: String { get }
    var surveyItemType: SBASurveyItemType { get }
    var optional: Bool { get }
    var stepTitle: String? { get }
    var detailText: String? { get }
    var prompt: String? { get }
    var image: UIImage? { get }
    var items: [AnyObject]? { get }
    var imageName: String? { get }
    var skipIdentifier: String? { get }
    var skipIfPassed: Bool { get }
    var nextIdentifier: String? { get }
    var rulePredicate: NSPredicate? { get }
    func createCustomStep() -> ORKStep
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
        case SingleChoiceText       // ORKTextChoiceAnswerFormat of style SingleChoiceTextQuestion
        case MultipleChoiceText     // ORKTextChoiceAnswerFormat of style MultipleChoiceTextQuestion
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
        case "singleChoiceText"      : self = .Form(.SingleChoiceText)
        case "multipleChoiceText"    : self = .Form(.MultipleChoiceText)
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
}

extension NSDictionary: SBASurveyItem {
    
    public var identifier: String {
        return (self["identifier"] as? String) ?? "\(self.hash)"
    }
    
    public var surveyItemType: SBASurveyItemType {
        let type = self["type"] as? String
        return SBASurveyItemType(rawValue: type)
    }
    
    public var stepTitle: String? {
        return self["title"] as? String
    }
    
    public var prompt: String? {
        return self["prompt"] as? String ?? self["text"] as? String
    }
    
    public var detailText: String? {
        return self["detailText"] as? String
    }
    
    public var image: UIImage? {
        guard let imageNamed = self["image"] as? String else { return nil }
        return SBAResourceFinder().imageNamed(imageNamed)
    }
    
    public var items: [AnyObject]? {
        return self["items"] as? [AnyObject]
    }
    
    public var imageName: String? {
        return self["image"] as? String
    }
    
    public var optional: Bool {
        let optional = self["optional"] as? Bool
        return optional ?? false
    }
    
    public var expectedAnswer: AnyObject? {
        return self["expectedAnswer"]
    }
    
    public var rulePredicate: NSPredicate? {
        if let rulePredicate = self["rulePredicate"] as? NSPredicate {
            return rulePredicate
        }
        else if let subtype = self.surveyItemType.formSubtype() {
            if case .Boolean = subtype,
                let expectedAnswer = self.expectedAnswer as? Bool
            {
                return NSPredicate(format: "answer = %@", expectedAnswer)
            }
            else if case .SingleChoiceText = subtype,
                let expectedAnswer = self.expectedAnswer
            {
                let answerArray = [expectedAnswer]
                return NSPredicate(format: "answer = %@", answerArray)
            }
        }
        return nil;
    }
    
    public var skipIdentifier: String? {
        return self["skipIdentifier"] as? String
    }
    
    public var skipIfPassed: Bool {
        let skipIfPassed = self["skipIfPassed"] as? Bool
        return skipIfPassed ?? false
    }
    
    public var nextIdentifier: String? {
        return self["nextIdentifier"] as? String
    }
    
    public func createCustomStep() -> ORKStep {
        return self.createInstructionStep()
    }
}