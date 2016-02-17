//
//  SBASurveyFactoryTests.swift
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

import XCTest
import BridgeAppSDK
import ResearchKit

class SBASurveyFactoryTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testFactory_CompoundSurveyQuestion_WithRule() {
        
        let inputStep: NSDictionary = [
            "identifier" : "quiz",
            "items" : [
                [   "identifier" : "question1",
                    "type" : "boolean",
                    "prompt" : "Are you older than 18?",
                    "expectedAnswer" : true],
                [   "identifier" : "question2",
                    "type" : "boolean",
                    "prompt" : "Are you a US resident?",
                    "expectedAnswer" : true],
                [   "identifier" : "question3",
                    "type" : "boolean",
                    "prompt" : "Can you read English?",
                    "expectedAnswer" : true],
            ],
            "skipIdentifier" : "consent",
            "skipIfPassed" : true
        ]
        
        let step = SBASurveyFactory().createSurveyStepWithDictionary(inputStep)
        XCTAssertEqual(step.identifier, "quiz")
        
        guard let surveyStep = step as? SBASurveyFormStep else {
            XCTAssert(false, "\(step) is not of expected class type")
            return
        }
        
        XCTAssertEqual(surveyStep.skipNextStepIdentifier, "consent")
        XCTAssertTrue(surveyStep.skipIfPassed)
        
        guard let formItems = surveyStep.formItems where formItems.count == 3 else {
            XCTAssert(false, "\(surveyStep.formItems) are not of expected count")
            return
        }
    }
    
    func testFactory_CompoundSurveyQuestion_NoRule() {
        
        let inputStep: NSDictionary = [
            "identifier" : "quiz",
            "items" : [
                [   "identifier" : "question1",
                    "type" : "boolean",
                    "prompt" : "Are you older than 18?"],
                [   "identifier" : "question2",
                    "type" : "boolean",
                    "prompt" : "Are you a US resident?"],
                [   "identifier" : "question3",
                    "type" : "boolean",
                    "prompt" : "Can you read English?"],
            ],
        ]
        
        let step = SBASurveyFactory().createSurveyStepWithDictionary(inputStep)
        XCTAssertEqual(step.identifier, "quiz")
        
        guard let surveyStep = step as? ORKFormStep else {
            XCTAssert(false, "\(step) is not of expected class type")
            return
        }
        
        XCTAssertEqual(surveyStep.formItems?.count, 3)
    }
    
    func testFactory_SubtaskSurveyQuestion_WithRule() {
        
        let inputStep: NSDictionary = [
            "identifier" : "quiz",
            "type" : "subtask",
            "items" : [
                [   "identifier" : "question1",
                    "type" : "boolean",
                    "prompt" : "Are you older than 18?",
                    "expectedAnswer" : true],
                [   "identifier" : "question2",
                    "type" : "boolean",
                    "prompt" : "Are you a US resident?",
                    "expectedAnswer" : true],
                [   "identifier" : "question3",
                    "type" : "boolean",
                    "prompt" : "Can you read English?",
                    "expectedAnswer" : true],
            ],
            "skipIdentifier" : "consent",
            "skipIfPassed" : true
        ]
        
        let step = SBASurveyFactory().createSurveyStepWithDictionary(inputStep)
        XCTAssertEqual(step.identifier, "quiz")
        
        guard let surveyStep = step as? SBASurveySubtaskStep else {
            XCTAssert(false, "\(step) is not of expected class type")
            return
        }
        
        XCTAssertEqual(surveyStep.skipNextStepIdentifier, "consent")
        XCTAssertTrue(surveyStep.skipIfPassed)
        
        guard let subtask = surveyStep.subtask as? ORKOrderedTask else {
            XCTAssert(false, "\(surveyStep.subtask) is not of expected class")
            return
        }
        XCTAssertEqual(subtask.steps.count, 3)
    }
    
    func testFactory_DirectNavigationRule() {
        
        let inputStep: NSDictionary = [
            "identifier" : "ineligible",
            "prompt" : "You can't get there from here",
            "nextIdentifier" : "exit"
        ]
        
        let step = SBASurveyFactory().createSurveyStepWithDictionary(inputStep)
        XCTAssertEqual(step.identifier, "ineligible")
        XCTAssertEqual(step.text, "You can't get there from here")
        
        guard let surveyStep = step as? SBADirectNavigationStep else {
            XCTAssert(false, "\(step) is not of expected class type")
            return
        }
        
        XCTAssertEqual(surveyStep.nextStepIdentifier, "exit")
    }
    
    func testFactory_BooleanQuestion() {
        let inputStep: NSDictionary = [
            "identifier" : "question1",
            "type" : "boolean",
            "prompt" : "Are you older than 18?",
            "expectedAnswer" : true
        ]
        
        let step = SBASurveyFactory().createSurveyStepWithDictionary(inputStep)
        XCTAssertEqual(step.identifier, "question1")
        
        guard let surveyStep = step as? ORKFormStep else {
            XCTAssert(false, "\(step) is not of expected class type")
            return
        }
        
        XCTAssertEqual(surveyStep.formItems?.count, 1)
        
        guard let formItem = surveyStep.formItems?.first as? SBASurveyFormItem,
            let _ = formItem.answerFormat as? ORKBooleanAnswerFormat else {
                XCTAssert(false, "\(surveyStep.formItems) is not of expected class type")
                return
        }
        
        XCTAssertNil(formItem.text)
        XCTAssertEqual(step.text, "Are you older than 18?")
        XCTAssertNotNil(formItem.rulePredicate)
        
        guard let navigationRule = formItem.rulePredicate else {
            return
        }
        
        let questionResult = ORKBooleanQuestionResult(identifier:formItem.identifier)
        questionResult.booleanAnswer = true
        XCTAssertTrue(navigationRule.evaluateWithObject(questionResult))
        
        questionResult.booleanAnswer = false
        XCTAssertFalse(navigationRule.evaluateWithObject(questionResult))
    }
    
    func testFactory_SingleChoiceQuestion() {
        let inputStep: NSDictionary = [
            "identifier" : "question1",
            "type" : "singleChoiceText",
            "prompt" : "Question 1?",
            "items" : ["a", "b", "c"],
            "expectedAnswer" : "b"
        ]
        
        let step = SBASurveyFactory().createSurveyStepWithDictionary(inputStep)
        XCTAssertEqual(step.identifier, "question1")
        
        guard let surveyStep = step as? ORKFormStep else {
            XCTAssert(false, "\(step) is not of expected class type")
            return
        }
        
        XCTAssertEqual(surveyStep.formItems?.count, 1)
        
        guard let formItem = surveyStep.formItems?.first as? SBASurveyFormItem,
            let answerFormat = formItem.answerFormat as? ORKTextChoiceAnswerFormat else {
                XCTAssert(false, "\(surveyStep.formItems) is not of expected class type")
                return
        }
        
        XCTAssertNil(formItem.text)
        XCTAssertEqual(step.text, "Question 1?")
        XCTAssertNotNil(formItem.rulePredicate)
        XCTAssertEqual(answerFormat.style, ORKChoiceAnswerStyle.SingleChoice)
        XCTAssertEqual(answerFormat.textChoices.count, 3)
        
        XCTAssertEqual(answerFormat.textChoices.first!.text, "a")
        let firstValue = answerFormat.textChoices.first!.value as? String
        XCTAssertEqual(firstValue, "a")
        
        guard let navigationRule = formItem.rulePredicate else {
            return
        }
        
        let questionResult = ORKChoiceQuestionResult(identifier:formItem.identifier)
        questionResult.choiceAnswers = ["b"]
        XCTAssertTrue(navigationRule.evaluateWithObject(questionResult))
        
        questionResult.choiceAnswers = ["c"]
        XCTAssertFalse(navigationRule.evaluateWithObject(questionResult))
    }
    
    func testFactory_MultipleChoiceQuestion() {
        let inputStep: NSDictionary = [
            "identifier" : "question1",
            "type" : "multipleChoiceText",
            "prompt" : "Question 1?",
            "items" : [
                ["prompt" : "a", "value" : 0],
                ["prompt" : "b", "value" : 1, "detailText": "good"],
                ["prompt" : "c", "value" : 2, "exclusive": true]],
        ]
        
        let step = SBASurveyFactory().createSurveyStepWithDictionary(inputStep)
        XCTAssertEqual(step.identifier, "question1")
        
        guard let surveyStep = step as? ORKFormStep else {
            XCTAssert(false, "\(step) is not of expected class type")
            return
        }
        
        XCTAssertEqual(surveyStep.formItems?.count, 1)
        
        guard let formItem = surveyStep.formItems?.first,
            let answerFormat = formItem.answerFormat as? ORKTextChoiceAnswerFormat else {
                XCTAssert(false, "\(surveyStep.formItems) is not of expected class type")
                return
        }
        
        XCTAssertNil(formItem.text)
        XCTAssertEqual(step.text, "Question 1?")
        XCTAssertEqual(answerFormat.style, ORKChoiceAnswerStyle.MultipleChoice)
        XCTAssertEqual(answerFormat.textChoices.count, 3)
        
        let choiceA = answerFormat.textChoices[0]
        XCTAssertEqual(choiceA.text, "a")
        XCTAssertEqual(choiceA.value as? Int, 0)
        XCTAssertFalse(choiceA.exclusive)
        
        let choiceB = answerFormat.textChoices[1]
        XCTAssertEqual(choiceB.text, "b")
        XCTAssertEqual(choiceB.value as? Int, 1)
        XCTAssertEqual(choiceB.detailText, "good")
        XCTAssertFalse(choiceB.exclusive)
        
        let choiceC = answerFormat.textChoices[2]
        XCTAssertEqual(choiceC.text, "c")
        XCTAssertEqual(choiceC.value as? Int, 2)
        XCTAssertTrue(choiceC.exclusive)
    }
    
}
