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

public final class SBASurveyFactory : NSObject {
       
    public func createSurveyStep(inputItem: SBASurveyItem) -> ORKStep {
        return self.createSurveyStep(inputItem, checkForNavigationRule: true)
    }
    
    func createSurveyStep(obj: AnyObject, checkForNavigationRule: Bool) -> ORKStep {
        
        guard let inputItem = obj as? SBASurveyItem else {
            assertionFailure("Passing object \(obj) does not match expected protocol SBASurveyItem")
            return ORKStep(identifier: "null")
        }
        
        switch (inputItem.type) {
        case .Instruction:
            return self.createInstructionStep(inputItem)
        case .Default:
            return self.createDefaultStep(inputItem)
        case .Subtask:
            return self.createSubtaskStep(inputItem)
        default:
            return self.createFormStep(inputItem, checkForNavigationRule: checkForNavigationRule)
        }
    }
    
    func createSubtaskStep(inputItem: SBASurveyItem) -> SBASubtaskStep {
        assert(inputItem.items?.count > 0, "A subtask step requires items")
        let steps = inputItem.items?.map({ self.createSurveyStep($0, checkForNavigationRule: false) })
        var step: SBASubtaskStep!
        if inputItem.usesNavigation() {
            let navStep = SBASurveySubtaskStep(identifier: inputItem.identifier, steps: steps)
            if let skipIdentifier = inputItem.skipIdentifier {
                navStep.skipNextStepIdentifier = skipIdentifier
            }
            navStep.rulePredicate = inputItem.rulePredicate
            navStep.skipIfPassed = inputItem.skipIfPassed
            step = navStep
        }
        else {
            step = SBASubtaskStep(identifier: inputItem.identifier, steps: steps)
        }
        return step
    }
    
    func createFormStep(inputItem: SBASurveyItem, checkForNavigationRule: Bool) -> ORKFormStep {
        var step: ORKFormStep!
        if (checkForNavigationRule && inputItem.usesNavigation()) {
            let navStep = SBASurveyFormStep(identifier: inputItem.identifier)
            if let skipIdentifier = inputItem.skipIdentifier {
                navStep.skipNextStepIdentifier = skipIdentifier
            }
            navStep.skipIfPassed = inputItem.skipIfPassed
            navStep.rulePredicate = inputItem.rulePredicate
            step = navStep
        }
        else {
            step = ORKFormStep(identifier: inputItem.identifier)
        }
        step.formItems = self.createFormItems(inputItem)
        step.title = inputItem.title
        step.text = inputItem.prompt
        step.optional = inputItem.optional
        return step
    }
    
    func createFormItems(inputItem: SBASurveyItem) -> [ORKFormItem]? {
        if (inputItem.type == .CompoundQuestion) {
            return inputItem.items?.map({ self.createFormItem($0, text: $0.prompt) })
        }
        else {
            return [self.createFormItem(inputItem, text: nil)]
        }
    }
    
    func createInstructionStep(inputItem: SBASurveyItem) -> ORKInstructionStep {
        var instructionStep: ORKInstructionStep!
        if let nextIdentifier = inputItem.nextIdentifier {
            instructionStep = SBADirectNavigationStep(identifier: inputItem.identifier, nextStepIdentifier: nextIdentifier)
        }
        else {
            instructionStep = ORKInstructionStep(identifier: inputItem.identifier)
        }
        instructionStep.title = inputItem.title
        instructionStep.text = inputItem.prompt
        return instructionStep
    }
    
    func createDefaultStep(inputItem: SBASurveyItem) -> ORKStep {
        return self.createInstructionStep(inputItem)
    }
    
    func createFormItem(obj: AnyObject, text: String?) -> ORKFormItem {
        
        guard let inputItem = obj as? SBASurveyItem else {
            assertionFailure("Passing object \(obj) does not match expected protocol SBASurveyItem")
            return ORKFormItem(identifier: "null", text: nil, answerFormat: nil, optional: true)
        }
        
        let answerFormat = self.createAnswerFormat(inputItem)
        
        if let rulePredicate = inputItem.formItemRulePredicate() {
            // If there is a rule predicate then return a survey form item
            let formItem = SBASurveyFormItem(identifier: inputItem.identifier, text: text, answerFormat: answerFormat, optional: inputItem.optional)
            formItem.rulePredicate = rulePredicate
            return formItem
        }
        else {
            // Otherwise, return a form item
            return ORKFormItem(identifier: inputItem.identifier, text: text, answerFormat: answerFormat, optional: inputItem.optional)
        }
    }
    
    func createTextChoice(obj: AnyObject) -> ORKTextChoice {
        guard let textChoice = obj as? SBATextChoice else {
            assertionFailure("Passing object \(obj) does not match expected protocol SBATextChoice")
            return ORKTextChoice(text: "", detailText: nil, value: NSNull(), exclusive: false)
        }
        let text = textChoice.prompt ?? "\(textChoice.value)"
        return ORKTextChoice(text: text, detailText: textChoice.detailText, value: textChoice.value, exclusive: textChoice.exclusive)
    }
    
    func createAnswerFormat(inputItem: SBASurveyItem) -> ORKAnswerFormat? {
        let type = inputItem.type
        
        // Create the answer format that maps to the question type
        if (type == .BoolQuestion) {
            return ORKBooleanAnswerFormat()
        }
        else if (type == .SingleChoiceTextQuestion || type == .MultipleChoiceTextQuestion) {
            let textChoices = inputItem.items!.map({createTextChoice($0)})
            let style: ORKChoiceAnswerStyle = (type == .SingleChoiceTextQuestion) ? .SingleChoice : .MultipleChoice
            return ORKTextChoiceAnswerFormat(style: style, textChoices: textChoices)
        }
        
        assertionFailure("Form item question type \(type) not implemented")
        return nil
    }
}

public enum SBASurveyItemType: UInt8 {
    case Default = 0x00
    case Instruction = 0x10
    case Subtask = 0x20
    case Question = 0xF0
    case BoolQuestion = 0xF1
    case SingleChoiceTextQuestion = 0xF2
    case MultipleChoiceTextQuestion = 0xF3
    case CompoundQuestion = 0xFF
}

public protocol SBASurveyItem: SBASurveyPredicateRule {
    var identifier: String { get }
    var type: SBASurveyItemType { get }
    var optional: Bool { get }
    var title: String? { get }
    var prompt: String? { get }
    var items: [AnyObject]? { get }
    var skipIdentifier: String? { get }
    var skipIfPassed: Bool { get }
    var nextIdentifier: String? { get }
    func formItemRulePredicate() -> NSPredicate?
}

extension SBASurveyItem {
    
    func usesNavigation() -> Bool {
        if (self.skipIdentifier != nil) ||
            (self.rulePredicate != nil) {
                return true
        }
        guard let items = self.items else { return false }
        for item in items {
            if let item = item as? SBASurveyItem,
                let _ = item.formItemRulePredicate() {
                    return true
            }
        }
        return false
    }
}

extension NSDictionary: SBASurveyItem {
    
    public var identifier: String {
        return (self["identifier"] as? String) ?? "\(self.hash)"
    }
    
    public var type: SBASurveyItemType {
        if let type = self["type"] as? String {
            if type == "boolean" {
                return .BoolQuestion
            }
            else if type == "singleChoiceText" {
                return .SingleChoiceTextQuestion
            }
            else if type == "multipleChoiceText" {
                return .MultipleChoiceTextQuestion
            }
            else if type == "instruction" {
                return .Instruction
            }
            else if type == "subtask" {
                return .Subtask
            }
            else {
                assertionFailure("unrecognized type: \(type)")
            }
        }
        else if let items = self.items where items.count > 0 {
            return .CompoundQuestion
        }
        return .Default
    }

    public var title: String? {
        return self["title"] as? String
    }

    public var prompt: String? {
        return self["prompt"] as? String
    }
    
    public var optional: Bool {
        let optional = self["optional"] as? Bool
        return optional ?? false
    }
    
    public var items: [AnyObject]? {
        return self["items"] as? [AnyObject]
    }
    
    public var expectedAnswer: AnyObject? {
        return self["expectedAnswer"]
    }
    
    public var rulePredicate: NSPredicate? {
        return self["rulePredicate"] as? NSPredicate
    }
    
    public func formItemRulePredicate() -> NSPredicate? {
        if let expectedAnswer = self.expectedAnswer as? Bool
            where self.type == .BoolQuestion {
            return NSPredicate(format: "answer = %@", expectedAnswer)
        }
        else if let expectedAnswer = self.expectedAnswer as? String
            where self.type == .SingleChoiceTextQuestion {
            return NSPredicate(format: "answer = %@", [expectedAnswer])
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
}

public protocol SBATextChoice  {
    var prompt: String? { get }
    var value: protocol<NSCoding, NSCopying, NSObjectProtocol> { get }
    var detailText: String? { get }
    var exclusive: Bool { get }
}

extension NSDictionary: SBATextChoice {
    
    public var value: protocol<NSCoding, NSCopying, NSObjectProtocol> {
        return (self["value"] as? protocol<NSCoding, NSCopying, NSObjectProtocol>) ?? self.prompt ?? self.identifier
    }
    
    public var detailText: String? {
        return self["detailText"] as? String
    }
    
    public var exclusive: Bool {
        let exclusive = self["exclusive"] as? Bool
        return exclusive ?? false
    }
}

extension ORKTextChoice: SBATextChoice {
    public var prompt: String? { return self.text }
}

extension NSString: SBATextChoice {
    public var prompt: String? { return self as String }
    public var value: protocol<NSCoding, NSCopying, NSObjectProtocol> { return self }
    public var detailText: String? { return nil }
    public var exclusive: Bool { return false }
}