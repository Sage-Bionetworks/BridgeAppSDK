//
//  ORKFormStep+Result.swift
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

public enum SBADefaultFormItemAnswer {
    case first, last, defaultValue, skip
}

public extension ORKFormStep {
    
    // Convenience method for adding a default answer or mapped answer for a given step
    public func instantiateStepResult(defaultAnswer: SBADefaultFormItemAnswer, answerMap: [String : AnyObject] = [:], startDate: NSDate = NSDate(), endDate: NSDate = NSDate()) -> ORKStepResult {
        
        let results = self.formItems?.mapAndFilter({ (formItem) -> ORKResult? in
            let answer = answerMap[formItem.identifier]
            return formItem.instantiateQuestionResult(defaultAnswer, answer: answer, startDate: startDate, endDate: endDate)
        })
        
        let stepResult = ORKStepResult(stepIdentifier: self.identifier, results: results)
        stepResult.startDate = startDate
        stepResult.endDate = endDate
        
        return stepResult
    }

}

protocol SBAQuestionResultMapping {
    var questionType: ORKQuestionType { get }
    func instantiateQuestionResult(identifier: String, _ defaultAnswer: SBADefaultFormItemAnswer, _ answer: AnyObject?) -> ORKQuestionResult?
    func isValidAnswer(answer: AnyObject) -> Bool
}

extension ORKFormItem {
    
    // Convenience method for adding a default answer or mapped answer for a given form item
    func instantiateQuestionResult(defaultAnswer: SBADefaultFormItemAnswer, answer: AnyObject?, startDate: NSDate = NSDate(), endDate: NSDate = NSDate()) -> ORKQuestionResult? {
        guard let answerFormat = self.answerFormat as? SBAQuestionResultMapping,
              let questionResult = answerFormat.instantiateQuestionResult(self.identifier, defaultAnswer, answer)
        else {
            return nil
        }
        questionResult.questionType = answerFormat.questionType
        return questionResult
    }
}

extension ORKTextChoiceAnswerFormat: SBAQuestionResultMapping {
    
    func instantiateQuestionResult(identifier: String, _ defaultAnswer: SBADefaultFormItemAnswer, _ answer: AnyObject?) -> ORKQuestionResult? {
        
        // Exit early if there are no choices
        guard self.textChoices.count > 0 else { return nil }
        
        // Check that the answer is formatted as an array
        var choiceAnswers = answer as? [AnyObject]
        if choiceAnswers == nil && answer != nil {
            choiceAnswers = [answer!]
        }
        
        // Check that the choice answers are nil or valid
        guard (choiceAnswers == nil) || isValidAnswer(choiceAnswers!) else {
            assertionFailure("\(answer) is invalid")
            return nil
        }
        
        let result = ORKChoiceQuestionResult(identifier: identifier)
        if choiceAnswers != nil {
            result.choiceAnswers = choiceAnswers
        }
        else {
            switch defaultAnswer {
            case .first:
                result.choiceAnswers = [self.textChoices.first!.value]
            case .last:
                result.choiceAnswers = [self.textChoices.last!.value]
            default:
                result.choiceAnswers = nil
            }
        }
        
        return result
    }
    
    func isValidAnswer(answer: AnyObject) -> Bool {
        guard let choiceAnswers = answer as? [NSObject] else {
            return false
        }
        let filteredChoices = self.textChoices.filter ({ (textChoice) -> Bool in
            guard let value = textChoice.value as? NSObject else { return false }
            return choiceAnswers.contains(value)
        })
        return filteredChoices.count == choiceAnswers.count
    }
}

extension ORKScaleAnswerFormat : SBAQuestionResultMapping {
    
    func instantiateQuestionResult(identifier: String, _ defaultAnswer: SBADefaultFormItemAnswer, _ answer: AnyObject?) -> ORKQuestionResult? {
        
        // Check that the choice answers are nil or valid
        guard (answer == nil) || isValidAnswer(answer!) else {
            assertionFailure("\(answer) is invalid")
            return nil
        }
        
        let result = ORKScaleQuestionResult(identifier: identifier)
        if let num = answer as? NSNumber {
            result.scaleAnswer = num
        }
        else {
            switch defaultAnswer {
            case .defaultValue:
                result.scaleAnswer = self.defaultValue
            case .first:
                result.scaleAnswer = self.minimum
            case .last:
                result.scaleAnswer = self.maximum
            default:
                result.scaleAnswer = nil
            }
        }
        
        return result
    }
    
    func isValidAnswer(answer: AnyObject) -> Bool {
        return NSJSONSerialization.isValidJSONObject(answer) && (answer is NSNumber)
    }
    
}
