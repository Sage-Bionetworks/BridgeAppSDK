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

/**
 * The purpose of the Survey Factory is to allow subclassing for custom types of steps
 * that are not recognized by this factory and to allow usage by Obj-c classes that 
 * do not recognize protocol extensions.
 */
public class SBASurveyFactory : NSObject {
       
    public func createSurveyStepWithDictionary(dictionary: NSDictionary) -> ORKStep {
        return self.createSurveyStep(dictionary, isSubtaskStep: false)
    }
    
    public func createSurveyStepWithCustomType(inputItem: AnyObject) -> ORKStep {
        guard let inputItem = inputItem as? SBASurveyItem else {
            assertionFailure("Unrecognized class for the base class implementation")
            return ORKStep(identifier: "NULL")
        }
        return inputItem.createCustomStep()
    }
    
    func createSurveyStep(inputItem: SBASurveyItem, isSubtaskStep: Bool) -> ORKStep {
        switch (inputItem.type) {
        case .Instruction:
            return inputItem.createInstructionStep()
        case .Custom:
            return self.createSurveyStepWithCustomType(inputItem)
        case .Subtask:
            return inputItem.createSubtaskStep(self)
        default:
            return inputItem.createFormStep(isSubtaskStep)
        }
    }
}

public enum SBASurveyItemType: UInt8 {
    case Custom = 0x00
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
    func createCustomStep() -> ORKStep
}

extension SBASurveyItem {
    
    func createInstructionStep() -> ORKInstructionStep {
        var instructionStep: ORKInstructionStep!
        if let nextIdentifier = self.nextIdentifier {
            instructionStep = SBADirectNavigationStep(identifier: self.identifier, nextStepIdentifier: nextIdentifier)
        }
        else {
            instructionStep = ORKInstructionStep(identifier: self.identifier)
        }
        instructionStep.title = self.title
        instructionStep.text = self.prompt
        return instructionStep
    }
    
    func createSubtaskStep(factory:SBASurveyFactory) -> SBASubtaskStep {
        assert(self.items?.count > 0, "A subtask step requires items")
        let steps = self.items?.map({ factory.createSurveyStep($0 as! SBASurveyItem, isSubtaskStep: true) })
        let step = self.usesNavigation() ?
            SBASurveySubtaskStep(surveyItem: self, steps: steps) :
            SBASubtaskStep(identifier: self.identifier, steps: steps)
        return step
    }
    
    func createFormStep(isSubtaskStep: Bool) -> ORKFormStep {
        let step = (!isSubtaskStep && self.usesNavigation()) ?
            SBASurveyFormStep(surveyItem: self) :
            ORKFormStep(identifier: self.identifier)
        if (self.type == .CompoundQuestion) {
            step.formItems = self.items?.map({ ($0 as! SBASurveyItem).createFormItem($0.prompt) })
        }
        else {
            step.formItems = [self.createFormItem(nil)]
        }
        step.title = self.title
        step.text = self.prompt
        step.optional = self.optional
        return step
    }
    
    func createFormItem(text: String?) -> ORKFormItem {
        
        let answerFormat = self.createAnswerFormat()
        
        if let rulePredicate = self.formItemRulePredicate() {
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
        let type = self.type
        
        // Create the answer format that maps to the question type
        if (type == .BoolQuestion) {
            return ORKBooleanAnswerFormat()
        }
        else if (type == .SingleChoiceTextQuestion || type == .MultipleChoiceTextQuestion) {
            let textChoices = self.items!.map({createTextChoice($0)})
            let style: ORKChoiceAnswerStyle = (type == .SingleChoiceTextQuestion) ? .SingleChoice : .MultipleChoice
            return ORKTextChoiceAnswerFormat(style: style, textChoices: textChoices)
        }
        
        assertionFailure("Form item question type \(type) not implemented")
        return nil
    }
    
    func createTextChoice(obj: AnyObject) -> ORKTextChoice {
        guard let textChoice = obj as? SBATextChoice else {
            assertionFailure("Passing object \(obj) does not match expected protocol SBATextChoice")
            return ORKTextChoice(text: "", detailText: nil, value: NSNull(), exclusive: false)
        }
        let text = textChoice.prompt ?? "\(textChoice.value)"
        return ORKTextChoice(text: text, detailText: textChoice.detailText, value: textChoice.value, exclusive: textChoice.exclusive)
    }

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
        }
        else if let items = self.items where items.count > 0 {
            return .CompoundQuestion
        }
        return .Custom
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
    
    public func createCustomStep() -> ORKStep {
        return self.createInstructionStep()
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