//
//  SBASurveyItem.swift
//  BridgeAppSDK
//
//  Created by Shannon Young on 2/17/16.
//  Copyright © 2016 Sage Bionetworks. All rights reserved.
//

import ResearchKit

public enum SBASurveyItemType: UInt8 {
    case Custom = 0x00
    case Instruction = 0x10
    case Subtask = 0x20
    case BoolQuestion = 0xF1
    case SingleChoiceTextQuestion = 0xF2
    case MultipleChoiceTextQuestion = 0xF3
    case CompoundQuestion = 0xFF
}

public protocol SBASurveyItem: class, NSObjectProtocol {
    var identifier: String { get }
    var type: SBASurveyItemType { get }
    var optional: Bool { get }
    var title: String? { get }
    var prompt: String? { get }
    var items: [AnyObject]? { get }
    var skipIdentifier: String? { get }
    var skipIfPassed: Bool { get }
    var nextIdentifier: String? { get }
    var rulePredicate: NSPredicate? { get }
    func createCustomStep() -> ORKStep
}

/**
* Dictionary type name to map to an ORKInstructionStep
*/
public let SBAInstructionTypeKey                   = "instruction"

/**
* Dictionary type name to map to an SBASubtaskStep
*/
public let SBASubtaskTypeKey                       = "subtask"

/**
* Dictionary type name to map to an ORKFormStep with multiple ORKFormItems
*/
public let SBACompoundQuestionTypeKey              = "compound"

/**
* Dictionary type name to map to an ORKQuestionStep or ORKFormItem with an
* ORKBooleanAnswerFormat
*/
public let SBABoolQuestionTypeKey                  = "boolean"

/**
* Dictionary type name to map to an ORKQuestionStep or ORKFormItem with an
* ORKTextChoiceAnswerFormat of style SingleChoiceTextQuestion
*/
public let SBASingleChoiceTextQuestionTypeKey      = "singleChoiceText"

/**
* Dictionary type name to map to an ORKQuestionStep or ORKFormItem with an
* ORKTextChoiceAnswerFormat of style MultipleChoiceTextQuestion
*/
public let SBAMultipleChoiceTextQuestionTypeKey    = "multipleChoiceText"

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
            else if type == "compound" {
                return .CompoundQuestion
            }
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
        if let rulePredicate = self["rulePredicate"] as? NSPredicate {
            return rulePredicate
        }
        else if let expectedAnswer = self.expectedAnswer as? Bool
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