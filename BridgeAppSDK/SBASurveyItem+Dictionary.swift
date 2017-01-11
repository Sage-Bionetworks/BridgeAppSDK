//
//  SBASurveyItem+Dictionary.swift
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


extension NSDictionary: SBAStepTransformer {
    
    // Because an NSDictionary could be used to create both an SBASurveyItem *and* an SBAActiveTask
    // need to look to see which is the more likely form to result in a valid result.
    public func transformToStep(with factory: SBASurveyFactory, isLastStep: Bool) -> ORKStep? {
        if (self.surveyItemType.isNilType()) {
            guard let subtask = self.transformToTask(with: factory, isLastStep: isLastStep) else {
                return nil
            }
            let step = SBASubtaskStep(subtask: subtask)
            step.taskIdentifier = self.taskIdentifier
            step.schemaIdentifier = self.schemaIdentifier
            return step
        }
        else {
            return factory.createSurveyStep(self)
        }
    }
}

extension NSDictionary: SBASurveyItem {
    
    public var identifier: String! {
        return (self["identifier"] as? String) ?? self.schemaIdentifier
    }
    
    public var surveyItemType: SBASurveyItemType {
        if let type = self["type"] as? String {
            return SBASurveyItemType(rawValue: type)
        }
        return .custom(nil)
    }
    
    public var stepTitle: String? {
        return self["title"] as? String
    }
    
    public var stepText: String? {
        return (self["text"] as? String) ?? (self["prompt"] as? String)
    }
    
    public var stepDetail: String? {
        return self["detailText"] as? String
    }
    
    public var stepFootnote: String? {
        return self["footnote"] as? String
    }
    
    public var options: [String : AnyObject]? {
        return self["options"] as? [String : AnyObject]
    }
}

extension NSDictionary: SBAActiveStepSurveyItem {
    
    public var stepSpokenInstruction: String? {
        return self["spokenInstruction"] as? String
    }
    
    public var stepFinishedSpokenInstruction: String? {
        return self["finishedSpokenInstruction"] as? String
    }
}

extension NSDictionary: SBAInstructionStepSurveyItem {
    
    public var stepImage: UIImage? {
        guard let imageNamed = self["image"] as? String else { return nil }
        return SBAResourceFinder.shared.image(forResource: imageNamed)
    }
    
    public var iconImage: UIImage? {
        guard let imageNamed = self["iconImage"] as? String else { return nil }
        return SBAResourceFinder.shared.image(forResource: imageNamed)
    }
    
    public func learnMoreAction() -> SBALearnMoreAction? {
        // Keep reverse-compatibility to previous dictionary key
        if let html = self["learnMoreHTMLContentURL"] as? String {
            return SBAURLLearnMoreAction(identifier: html)
        }
        // Look for a dictionary that matches the learnMoreActionKey
        if let learnMoreAction = self["learnMoreAction"] as? [AnyHashable: Any] {
            return SBAClassTypeMap.shared.object(with: learnMoreAction) as? SBALearnMoreAction
        }
        return nil
    }
}

extension NSDictionary: SBAFormStepSurveyItem, SBASurveyRule {
    
    public var placeholderText: String? {
        return self["placeholder"] as? String
    }
    
    public var optional: Bool {
        let optional = self["optional"] as? Bool
        return optional ?? false
    }
    
    public var items: [Any]? {
        return self["items"] as? [Any]
    }
    
    public var range: AnyObject? {
        return nil 
    }
    
    public var rules: [SBASurveyRule]? {
        guard self.rulePredicate != nil || self.skipIdentifier != nil else { return nil }
        return [self]
    }
    
    public var skipIdentifier: String? {
        return self["skipIdentifier"] as? String
    }
    
    public var skipIfPassed: Bool {
        let skipIfPassed = self["skipIfPassed"] as? Bool
        return skipIfPassed ?? false
    }
    
    public var rulePredicate: NSPredicate? {
        if let subtype = self.surveyItemType.formSubtype() {
            if case .boolean = subtype,
                let expectedAnswer = self.expectedAnswer as? Bool
            {
                return NSPredicate(format: "answer = %@", expectedAnswer as CVarArg)
            }
            else if case .singleChoice = subtype,
                let expectedAnswer = self.expectedAnswer
            {
                let answerArray = [expectedAnswer]
                return NSPredicate(format: "answer = %@", answerArray)
            }
            else if case .multipleChoice = subtype,
                let expectedAnswer = self.expectedAnswer as? [AnyObject]
            {
                return NSPredicate(format: "answer = %@", expectedAnswer)
            }
        }
        return nil;
    }
    
    public var expectedAnswer: Any? {
        return self["expectedAnswer"]
    }
    
    public var questionStyle: Bool {
        return self["questionStyle"] as? Bool ?? false
    }
}

extension NSDictionary: SBANumberRange {
    
    public var minNumber: NSNumber? {
        return self["min"] as? NSNumber
    }
    
    public var maxNumber: NSNumber? {
        return self["max"] as? NSNumber
    }

    public var unitLabel: String? {
        return self["unit"] as? String
    }

    public var stepInterval: Int {
        return self["stepInterval"] as? Int ?? 1
    }
}
