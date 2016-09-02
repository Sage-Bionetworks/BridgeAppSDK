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
import BridgeSDK

class SBASurveyFactoryTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    // -------------------------------------------------
    // MARK: NSDictionary
    // -------------------------------------------------
    
    func testCustomType() {
        let inputStep: NSDictionary = [
            "identifier"    : "customStep",
            "type"          : "customStepType",
            "title"         : "Title",
            "text"          : "Text for this step",
        ]
        
        let step = SBASurveyFactory().createSurveyStepWithDictionary(inputStep)
        XCTAssertNotNil(step)
        
        guard let surveyStep = step as? SBAInstructionStep else {
            XCTAssert(false, "\(step) is not of expected class type")
            return
        }
        XCTAssertEqual(surveyStep.identifier, "customStep")
        XCTAssertEqual(surveyStep.customTypeIdentifier, "customStepType")
        XCTAssertEqual(surveyStep.title, "Title")
        XCTAssertEqual(surveyStep.text, "Text for this step")
    }
    
    func testFactory_CompoundSurveyQuestion_WithRule() {
        
        let inputStep: NSDictionary = [
            "identifier" : "quiz",
            "type" : "compound",
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
        XCTAssertNotNil(step)
        
        guard let surveyStep = step as? SBASurveyFormStep else {
            XCTAssert(false, "\(step) is not of expected class type")
            return
        }
        XCTAssertEqual(surveyStep.identifier, "quiz")
        XCTAssertEqual(surveyStep.skipToStepIdentifier, "consent")
        XCTAssertTrue(surveyStep.skipIfPassed)
        
        guard let formItems = surveyStep.formItems where formItems.count == 3 else {
            XCTAssert(false, "\(surveyStep.formItems) are not of expected count")
            return
        }
    }
    
    func testFactory_CompoundSurveyQuestion_NoRule() {
        
        let inputStep: NSDictionary = [
            "identifier" : "quiz",
            "type" : "compound",
            "items" : [
                [   "identifier" : "question1",
                    "type" : "boolean",
                    "prompt" : "Are you older than 18?"],
                [   "identifier" : "question2",
                    "type" : "boolean",
                    "text" : "Are you a US resident?"],
                [   "identifier" : "question3",
                    "type" : "boolean",
                    "prompt" : "Can you read English?"],
            ],
        ]
        
        let step = SBASurveyFactory().createSurveyStepWithDictionary(inputStep)
        XCTAssertNotNil(step)
        
        guard let surveyStep = step as? ORKFormStep else {
            XCTAssert(false, "\(step) is not of expected class type")
            return
        }
        
        XCTAssertEqual(surveyStep.identifier, "quiz")
        XCTAssertEqual(surveyStep.formItems?.count, 3)
        
        guard let formItems = surveyStep.formItems where formItems.count == 3 else { return }
        
        XCTAssertEqual(formItems[0].text, "Are you older than 18?")
        XCTAssertEqual(formItems[1].text, "Are you a US resident?")
        XCTAssertEqual(formItems[2].text, "Can you read English?")
        
    }
    
    func testFactory_SubtaskSurveyQuestion_WithRule() {
        
        let inputStep: NSDictionary = [
            "identifier" : "quiz",
            "type" : "subtask",
            "items" : [
                [   "identifier" : "question1",
                    "type" : "boolean",
                    "prompt" : "I can share my data broadly or only with Sage?",
                    "expectedAnswer" : true],
                [   "identifier" : "question2",
                    "type" : "boolean",
                    "prompt" : "My name is stored with my results?",
                    "expectedAnswer" : false],
                [   "identifier" : "question3",
                    "type" : "boolean",
                    "prompt" : "I can leave the study at any time?",
                    "expectedAnswer" : true],
            ],
            "skipIdentifier" : "consent",
            "skipIfPassed" : true
        ]
        
        let step = SBASurveyFactory().createSurveyStepWithDictionary(inputStep)
        XCTAssertNotNil(step)
        
        guard let surveyStep = step as? SBASurveySubtaskStep else {
            XCTAssert(false, "\(step) is not of expected class type")
            return
        }
        
        XCTAssertEqual(surveyStep.identifier, "quiz")
        XCTAssertEqual(surveyStep.skipToStepIdentifier, "consent")
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
            "detailText": "Tap the button below to begin the consent process",
            "type"  : "instruction",
            "nextIdentifier" : "exit"
        ]
        
        
        let step = SBASurveyFactory().createSurveyStepWithDictionary(inputStep)
        XCTAssertNotNil(step)
        
        guard let surveyStep = step as? SBAInstructionStep else {
            XCTAssert(false, "\(step) is not of expected class type")
            return
        }
        
        XCTAssertEqual(surveyStep.identifier, "ineligible")
        XCTAssertEqual(surveyStep.text, "You can't get there from here")
        XCTAssertEqual(surveyStep.detailText, "Tap the button below to begin the consent process")
        XCTAssertEqual(surveyStep.nextStepIdentifier, "exit")
    }
    
    func testFactory_CompletionStep() {
        
        let inputStep: NSDictionary = [
            "identifier" : "quizComplete",
            "title" : "Great Job!",
            "text" : "You answered correctly",
            "detailText": "Tap the button below to begin the consent process",
            "type"  : "completion",
        ]
        
        
        let step = SBASurveyFactory().createSurveyStepWithDictionary(inputStep)
        XCTAssertNotNil(step)
        
        guard let surveyStep = step as? ORKInstructionStep else {
            XCTAssert(false, "\(step) is not of expected class type")
            return
        }
        
        XCTAssertEqual(surveyStep.identifier, "quizComplete")
        XCTAssertEqual(surveyStep.title, "Great Job!")
        XCTAssertEqual(surveyStep.text, "You answered correctly")
        XCTAssertEqual(surveyStep.detailText, "Tap the button below to begin the consent process")
    }
    
    func testFactory_BooleanQuestion() {
        
        let inputStep: NSDictionary = [
            "identifier" : "question1",
            "type" : "boolean",
            "prompt" : "Are you older than 18?",
            "expectedAnswer" : true
        ]
        
        let step = SBASurveyFactory().createSurveyStepWithDictionary(inputStep)
        XCTAssertNotNil(step)
        
        guard let surveyStep = step as? ORKFormStep else {
            XCTAssert(false, "\(step) is not of expected class type")
            return
        }
        
        XCTAssertEqual(surveyStep.identifier, "question1")
        XCTAssertEqual(surveyStep.formItems?.count, 1)
        
        guard let formItem = surveyStep.formItems?.first as? SBASurveyFormItem,
            let _ = formItem.answerFormat as? ORKBooleanAnswerFormat else {
                XCTAssert(false, "\(surveyStep.formItems) is not of expected class type")
                return
        }
        
        XCTAssertNil(formItem.text)
        XCTAssertEqual(surveyStep.text, "Are you older than 18?")
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
        XCTAssertNotNil(step)
        
        guard let surveyStep = step as? ORKFormStep else {
            XCTAssert(false, "\(step) is not of expected class type")
            return
        }
        
        XCTAssertEqual(surveyStep.identifier, "question1")
        XCTAssertEqual(surveyStep.formItems?.count, 1)
        
        guard let formItem = surveyStep.formItems?.first as? SBASurveyFormItem,
            let answerFormat = formItem.answerFormat as? ORKTextChoiceAnswerFormat else {
                XCTAssert(false, "\(surveyStep.formItems) is not of expected class type")
                return
        }
        
        XCTAssertNil(formItem.text)
        XCTAssertEqual(surveyStep.text, "Question 1?")
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
        XCTAssertNotNil(step)
        
        guard let surveyStep = step as? ORKFormStep else {
            XCTAssert(false, "\(step) is not of expected class type")
            return
        }
        
        XCTAssertEqual(surveyStep.identifier, "question1")
        XCTAssertEqual(surveyStep.formItems?.count, 1)
        
        guard let formItem = surveyStep.formItems?.first,
            let answerFormat = formItem.answerFormat as? ORKTextChoiceAnswerFormat else {
                XCTAssert(false, "\(surveyStep.formItems) is not of expected class type")
                return
        }
        
        XCTAssertNil(formItem.text)
        XCTAssertEqual(surveyStep.text, "Question 1?")
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
    
    func testFactory_TextChoice() {
        
        let inputStep: NSDictionary = [
            "identifier": "purpose",
            "title": "What is the purpose of this study?",
            "type": "singleChoiceText",
            "items":[
                ["text" :"Understand the fluctuations of Parkinson disease symptoms", "value" : true],
                ["text" :"Treating Parkinson disease", "value": false],
            ],
            "expectedAnswer": true,
        ]
        
        let step = SBASurveyFactory().createSurveyStepWithDictionary(inputStep)
        XCTAssertNotNil(step)
        
        guard let surveyStep = step as? ORKFormStep else {
            XCTAssert(false, "\(step) is not of expected class type")
            return
        }
        
        XCTAssertEqual(surveyStep.identifier, "purpose")
        XCTAssertEqual(surveyStep.formItems?.count, 1)
        
        guard let formItem = surveyStep.formItems?.first as? SBASurveyFormItem,
            let answerFormat = formItem.answerFormat as? ORKTextChoiceAnswerFormat else {
                XCTAssert(false, "\(surveyStep.formItems) is not of expected class type")
                return
        }
        
        XCTAssertNil(formItem.text)
        
        XCTAssertEqual(answerFormat.style, ORKChoiceAnswerStyle.SingleChoice)
        XCTAssertEqual(answerFormat.textChoices.count, 2)
        if (answerFormat.textChoices.count != 2) {
            return
        }
        
        XCTAssertEqual(answerFormat.textChoices.first!.text, "Understand the fluctuations of Parkinson disease symptoms")
        let firstValue = answerFormat.textChoices.first!.value as? Bool
        XCTAssertEqual(firstValue, true)
        
        XCTAssertEqual(answerFormat.textChoices.last!.text, "Treating Parkinson disease")
        let lastValue = answerFormat.textChoices.last!.value as? Bool
        XCTAssertEqual(lastValue, false)
        
        XCTAssertNotNil(formItem.rulePredicate)
        guard let navigationRule = formItem.rulePredicate else {
            return
        }
        
        let questionResult = ORKChoiceQuestionResult(identifier:formItem.identifier)
        questionResult.choiceAnswers = [true]
        XCTAssertTrue(navigationRule.evaluateWithObject(questionResult))
        
        questionResult.choiceAnswers = [false]
        XCTAssertFalse(navigationRule.evaluateWithObject(questionResult))
        
    }
    
    // -------------------------------------------------
    // MARK: SBBSurvey
    // -------------------------------------------------
    
    func testFactory_SBBSurveyInfoScreen() {
        let inputStep = SBBSurveyInfoScreen()
        inputStep.identifier = "abc123"
        inputStep.title = "Title"
        inputStep.prompt = "Text"
        inputStep.promptDetail = "Detail"
        
        let step = SBASurveyFactory().createSurveyStepWithSurveyElement(inputStep)
        XCTAssertNotNil(step)
        
        guard let surveyStep = step as? ORKInstructionStep else {
            XCTAssert(false, "\(step) is not of expected class type")
            return
        }
        
        XCTAssertEqual(surveyStep.identifier, "abc123")
        XCTAssertEqual(surveyStep.title, "Title")
        XCTAssertEqual(surveyStep.text, "Text")
        XCTAssertEqual(surveyStep.detailText, "Detail")
    }
    
    // MARK: BooleanConstraints
    
    func testFactory_BooleanConstraints() {

        let inputStep = SBBSurveyQuestion()
        inputStep.identifier = "living-alone-status"
        inputStep.guid = "216a6a73-86dc-432a-bb6a-71a8b7cf4be1"
        inputStep.uiHint = "checkbox"
        inputStep.prompt = "Do you live alone?"
        inputStep.constraints = SBBBooleanConstraints();
    
        let ruleNotEqual = SBBSurveyRule(dictionaryRepresentation:         [
            "value" : NSNumber(bool: true),
            "operator" : "ne",
            "skipTo" : "video-usage",
            "type" : "SurveyRule"
        ])
        let ruleSkip = SBBSurveyRule(dictionaryRepresentation:         [
            "value" : "true",
            "operator" : "de",
            "skipTo" : "video-usage",
            "type" : "SurveyRule"
            ])
        
        inputStep.constraints.addRulesObject(ruleNotEqual)
        inputStep.constraints.addRulesObject(ruleSkip)
        
        let step = SBASurveyFactory().createSurveyStepWithSurveyElement(inputStep)
        XCTAssertNotNil(step)
        
        guard let surveyStep = step as? SBASurveyQuestionStep else {
            XCTAssert(false, "\(step) is not of expected class type")
            return
        }
        
        XCTAssertEqual(surveyStep.identifier, "living-alone-status")
        XCTAssertEqual(surveyStep.text, "Do you live alone?")
        XCTAssertEqual(surveyStep.formItems?.count, 1)
        XCTAssertTrue(surveyStep.skipIfPassed)
        XCTAssertEqual(surveyStep.skipToStepIdentifier, "video-usage")
        
        guard let formItem = surveyStep.formItems?.first as? SBASurveyFormItem,
            let _ = formItem.answerFormat as? ORKBooleanAnswerFormat else {
                XCTAssert(false, "\(surveyStep.formItems) is not of expected class type")
                return
        }
        
        XCTAssertNil(formItem.text)
        XCTAssertNotNil(formItem.rulePredicate)
        
        guard let navigationRule = formItem.rulePredicate else {
            return
        }
        
        let questionResult = ORKBooleanQuestionResult(identifier:formItem.identifier)
        XCTAssertTrue(navigationRule.evaluateWithObject(questionResult))
        
        questionResult.booleanAnswer = false
        XCTAssertTrue(navigationRule.evaluateWithObject(questionResult))
        
        questionResult.booleanAnswer = true
        XCTAssertFalse(navigationRule.evaluateWithObject(questionResult))
    }
    
    func testFactory_BooleanConstraints_NoRules() {
        
        let inputStep = SBBSurveyQuestion()
        inputStep.identifier = "living-alone-status"
        inputStep.guid = "216a6a73-86dc-432a-bb6a-71a8b7cf4be1"
        inputStep.uiHint = "checkbox"
        inputStep.prompt = "Do you live alone?"
        inputStep.constraints = SBBBooleanConstraints();
        
        let step = SBASurveyFactory().createSurveyStepWithSurveyElement(inputStep)
        XCTAssertNotNil(step)
        
        guard let surveyStep = step as? SBASurveyQuestionStep else {
            XCTAssert(false, "\(step) is not of expected class type")
            return
        }
        
        XCTAssertEqual(surveyStep.identifier, "living-alone-status")
        
        // In every case, the next step identifier should be nil
        
        let questionResult = ORKBooleanQuestionResult(identifier:surveyStep.identifier)
        let stepResult = ORKStepResult(stepIdentifier: surveyStep.identifier, results: [questionResult])
        let taskResult = ORKTaskResult(identifier: "task")
        taskResult.results = [stepResult]
        
        XCTAssertNil(surveyStep.nextStepIdentifier(taskResult, additionalTaskResults: nil))
        
        questionResult.booleanAnswer = false
        XCTAssertNil(surveyStep.nextStepIdentifier(taskResult, additionalTaskResults: nil))
        
        questionResult.booleanAnswer = true
        XCTAssertNil(surveyStep.nextStepIdentifier(taskResult, additionalTaskResults: nil))
    }
    
    // MARK: MultiValueConstraints

    func testFactory_MultiValueConstraints() {

        let inputStep:SBBSurveyQuestion = createMultipleChoiceQuestion(allowMultiple: false)
        
        inputStep.constraints.addRulesObject(
            SBBSurveyRule(dictionaryRepresentation:[
                                                    "value" : "false",
                                                    "operator" : "eq",
                                                    "skipTo" : "video-usage",
                                                    "type" : "SurveyRule"
                                                    ]))
        inputStep.constraints.addRulesObject(
            SBBSurveyRule(dictionaryRepresentation:[
                                                    "value" : "true",
                                                    "operator" : "de",
                                                    "skipTo" : "video-usage",
                                                    "type" : "SurveyRule"
                                                    ]))

        let step = SBASurveyFactory().createSurveyStepWithSurveyElement(inputStep)
        XCTAssertNotNil(step)
        
        guard let surveyStep = step as? SBASurveyQuestionStep else {
            XCTAssert(false, "\(step) is not of expected class type")
            return
        }
        
        XCTAssertEqual(surveyStep.identifier, "medical-usage")
        XCTAssertEqual(surveyStep.text, "Do you ever use your smartphone to look for health or medical information online?")
        XCTAssertEqual(surveyStep.formItems?.count, 1)
        XCTAssertTrue(surveyStep.skipIfPassed)
        XCTAssertEqual(surveyStep.skipToStepIdentifier, "video-usage")
        
        guard let formItem = surveyStep.formItems?.first as? SBASurveyFormItem,
            let answerFormat = formItem.answerFormat as? ORKTextChoiceAnswerFormat else {
                XCTAssert(false, "\(surveyStep.formItems) is not of expected class type")
                return
        }
        
        XCTAssertNil(formItem.text)

        XCTAssertEqual(answerFormat.style, ORKChoiceAnswerStyle.SingleChoice)
        XCTAssertEqual(answerFormat.textChoices.count, 3)
        
        guard let textChoice = answerFormat.textChoices.first else {
            return
        }
        
        XCTAssertEqual(textChoice.text, "Yes, I have done this")
        guard let value = textChoice.value as? String else {
            XCTAssert(false, "\(textChoice.value) is not of expected class type")
            return
        }
        XCTAssertEqual(value, "true")
        
        XCTAssertNotNil(formItem.rulePredicate)
        guard let navigationRule = formItem.rulePredicate else {
            return
        }
        
        let questionResult = ORKChoiceQuestionResult(identifier:formItem.identifier)
        XCTAssertTrue(navigationRule.evaluateWithObject(questionResult))
        
        questionResult.choiceAnswers = ["false"]
        XCTAssertTrue(navigationRule.evaluateWithObject(questionResult))
        
        questionResult.choiceAnswers = ["true"]
        XCTAssertFalse(navigationRule.evaluateWithObject(questionResult))
    }

    func testFactory_MultiValueConstraints_NotEqual() {
        
        let inputStep:SBBSurveyQuestion = createMultipleChoiceQuestion(allowMultiple: false)
        inputStep.constraints.addRulesObject(
            SBBSurveyRule(dictionaryRepresentation:[
                "value" : "true",
                "operator" : "ne",
                "skipTo" : "video-usage",
                "type" : "SurveyRule"
                ]))
        
        let step = SBASurveyFactory().createSurveyStepWithSurveyElement(inputStep)
        XCTAssertNotNil(step)
        
        guard let surveyStep = step as? SBASurveyQuestionStep,
            let formItem = surveyStep.formItems?.first as? SBASurveyFormItem,
            let navigationRule = formItem.rulePredicate else {
                XCTAssert(false, "\(step) does not meet expected format")
                return
        }
        
        let questionResult = ORKChoiceQuestionResult(identifier:formItem.identifier)
        XCTAssertTrue(navigationRule.evaluateWithObject(questionResult))
        
        questionResult.choiceAnswers = ["false"]
        XCTAssertTrue(navigationRule.evaluateWithObject(questionResult))
        
        questionResult.choiceAnswers = ["maybe"]
        XCTAssertTrue(navigationRule.evaluateWithObject(questionResult))
        
        questionResult.choiceAnswers = ["true"]
        XCTAssertFalse(navigationRule.evaluateWithObject(questionResult))
    }
    
    func testFactory_MultiValueConstraints_OtherThan() {
        
        let inputStep:SBBSurveyQuestion = createMultipleChoiceQuestion(allowMultiple: false)
        inputStep.constraints.addRulesObject(
            SBBSurveyRule(dictionaryRepresentation:[
                "value" : "true",
                "operator" : "ot",
                "skipTo" : "video-usage",
                "type" : "SurveyRule"
                ]))
        
        let step = SBASurveyFactory().createSurveyStepWithSurveyElement(inputStep)
        XCTAssertNotNil(step)
        
        guard let surveyStep = step as? SBASurveyQuestionStep,
            let formItem = surveyStep.formItems?.first as? SBASurveyFormItem,
            let navigationRule = formItem.rulePredicate else {
                XCTAssert(false, "\(step) does not meet expected format")
                return
        }
        
        let questionResult = ORKChoiceQuestionResult(identifier:formItem.identifier)
        XCTAssertTrue(navigationRule.evaluateWithObject(questionResult))
        
        questionResult.choiceAnswers = ["false"]
        XCTAssertTrue(navigationRule.evaluateWithObject(questionResult))
        
        questionResult.choiceAnswers = ["maybe"]
        XCTAssertTrue(navigationRule.evaluateWithObject(questionResult))
        
        questionResult.choiceAnswers = ["true"]
        XCTAssertFalse(navigationRule.evaluateWithObject(questionResult))
    }
    
    func testFactory_MultiValueConstraints_AllowMultiple() {
        
        let inputStep:SBBSurveyQuestion = createMultipleChoiceQuestion(allowMultiple: true)
        let step = SBASurveyFactory().createSurveyStepWithSurveyElement(inputStep)
        XCTAssertNotNil(step)
        
        guard let surveyStep = step as? SBASurveyQuestionStep,
            let formItem = surveyStep.formItems?.first,
            let answerFormat = formItem.answerFormat as? ORKTextChoiceAnswerFormat else {
                XCTAssert(false, "\(step) is not of expected format")
                return
        }
        
        XCTAssertEqual(answerFormat.style, ORKChoiceAnswerStyle.MultipleChoice)
    }
    
    func testFactory_MultiValueConstraints_AllowOther_Uppercase() {
        
        let inputStep:SBBSurveyQuestion = createMultipleChoiceQuestion(allowMultiple: false)
        guard let constraints = inputStep.constraints as? SBBMultiValueConstraints else { return }
        
        constraints.allowOtherValue = true
        
        let step = SBASurveyFactory().createSurveyStepWithSurveyElement(inputStep)
        XCTAssertNotNil(step)
        
        guard let surveyStep = step as? SBASurveyQuestionStep,
            let formItem = surveyStep.formItems?.first,
            let answerFormat = formItem.answerFormat as? ORKTextChoiceAnswerFormat else {
                XCTAssert(false, "\(step) is not of expected format")
                return
        }
        
        XCTAssertEqual(answerFormat.style, ORKChoiceAnswerStyle.SingleChoice)
        XCTAssertEqual(answerFormat.textChoices.count, 4)
       
        guard let lastChoice = answerFormat.textChoices.last else { return }
        XCTAssertEqual(lastChoice.text, "Other")
    }
    
    func testFactory_MultiValueConstraints_AllowOther_Lowercase() {
        
        let inputStep:SBBSurveyQuestion = createMultipleChoiceQuestion(allowMultiple: false)
        guard let constraints = inputStep.constraints as? SBBMultiValueConstraints else { return }
        
        constraints.allowOtherValue = true
        for textChoice in constraints.enumeration {
            if let choice = textChoice as? SBBSurveyQuestionOption {
                choice.label = choice.label.lowercaseString
            }
        }
        
        let step = SBASurveyFactory().createSurveyStepWithSurveyElement(inputStep)
        XCTAssertNotNil(step)
        
        guard let surveyStep = step as? SBASurveyQuestionStep,
            let formItem = surveyStep.formItems?.first,
            let answerFormat = formItem.answerFormat as? ORKTextChoiceAnswerFormat else {
                XCTAssert(false, "\(step) is not of expected format")
                return
        }
        
        XCTAssertEqual(answerFormat.style, ORKChoiceAnswerStyle.SingleChoice)
        XCTAssertEqual(answerFormat.textChoices.count, 4)
        
        guard let lastChoice = answerFormat.textChoices.last else { return }
        XCTAssertEqual(lastChoice.text, "other")
    }
    
    // MARK: StringConstraints
    
    func testFactory_TextAnswer() {
        
        let inputStep:SBBSurveyQuestion = SBBSurveyQuestion()
        inputStep.uiHint = "textfield"
        inputStep.identifier = "feelings"
        inputStep.guid = "c096d808-2b5b-4151-9e09-0c4ada6028e9"
        inputStep.prompt = "How do you feel?"
        // pattern, maxLength and minLength are currently unsupported
        inputStep.constraints = SBBStringConstraints()
        
        let step = SBASurveyFactory().createSurveyStepWithSurveyElement(inputStep)
        XCTAssertNotNil(step)
        
        guard let surveyStep = step as? SBASurveyQuestionStep else {
            XCTAssert(false, "\(step) is not of expected class type")
            return
        }
        
        XCTAssertEqual(surveyStep.identifier, "feelings")
        XCTAssertEqual(surveyStep.text, "How do you feel?")
        XCTAssertEqual(surveyStep.formItems?.count, 1)
        
        guard let formItem = surveyStep.formItems?.first else {
            XCTAssert(false, "\(surveyStep.formItems) is not of expected class type")
            return
        }
        guard let _ = formItem.answerFormat as? ORKTextAnswerFormat else {
            XCTAssert(false, "\(formItem.answerFormat) is not of expected class type")
            return
        }
        
        XCTAssertNil(formItem.text)
    }
    
    // MARK: DateTimeConstraints
    
    func testFactory_DateTimeConstraints() {

        let inputStep:SBBSurveyQuestion = SBBSurveyQuestion()
        inputStep.identifier = "last-smoked"
        inputStep.guid = "2d4b697c-368e-4cda-a30d-0c7dfc38342e"
        inputStep.prompt = "When is the last time you smoked (put todays date if you are still smoking)?"
        inputStep.uiHint = "datetimepicker"
        
        let constraints = SBBDateTimeConstraints()
        constraints.dataType = "datetime"
        constraints.allowFutureValue = false
        inputStep.constraints = constraints
        
        let step = SBASurveyFactory().createSurveyStepWithSurveyElement(inputStep)
        XCTAssertNotNil(step)
        
        guard let surveyStep = step as? SBASurveyQuestionStep else {
            XCTAssert(false, "\(step) is not of expected class type")
            return
        }
        
        XCTAssertEqual(surveyStep.identifier, "last-smoked")
        XCTAssertEqual(surveyStep.text, "When is the last time you smoked (put todays date if you are still smoking)?")
        XCTAssertEqual(surveyStep.formItems?.count, 1)
        
        guard let formItem = surveyStep.formItems?.first else {
            XCTAssert(false, "\(surveyStep.formItems) is not of expected class type")
            return
        }
        
        XCTAssertNil(formItem.text)
        
        guard let answerFormat = formItem.answerFormat as? ORKDateAnswerFormat else {
            XCTAssert(false, "\(formItem.answerFormat) is not of expected class type")
            return
        }
        
        XCTAssertEqual(answerFormat.style, ORKDateAnswerStyle.DateAndTime)
        
        XCTAssertNil(answerFormat.minimumDate)
        XCTAssertNil(answerFormat.defaultDate)
        XCTAssertNotNil(answerFormat.maximumDate)
        guard let maximumDate = answerFormat.maximumDate else {
            return
        }
        XCTAssertEqualWithAccuracy(maximumDate.timeIntervalSinceNow, NSTimeInterval(0), accuracy: 5)
        
    }
    
    func testFactory_DateConstraints() {
        
        let inputStep:SBBSurveyQuestion = SBBSurveyQuestion()
        inputStep.identifier = "last-smoked"
        inputStep.guid = "2d4b697c-368e-4cda-a30d-0c7dfc38342e"
        inputStep.prompt = "When is the last time you smoked (put todays date if you are still smoking)?"
        inputStep.uiHint = "datetimepicker"
        
        let constraints = SBBDateConstraints()
        constraints.dataType = "date"
        constraints.allowFutureValue = false
        inputStep.constraints = constraints
        
        let step = SBASurveyFactory().createSurveyStepWithSurveyElement(inputStep)
        XCTAssertNotNil(step)
        
        guard let surveyStep = step as? SBASurveyQuestionStep else {
            XCTAssert(false, "\(step) is not of expected class type")
            return
        }
        
        XCTAssertEqual(surveyStep.identifier, "last-smoked")
        XCTAssertEqual(surveyStep.text, "When is the last time you smoked (put todays date if you are still smoking)?")
        XCTAssertEqual(surveyStep.formItems?.count, 1)
        
        guard let formItem = surveyStep.formItems?.first else {
            XCTAssert(false, "\(surveyStep.formItems) is not of expected class type")
            return
        }
        
        XCTAssertNil(formItem.text)
        
        guard let answerFormat = formItem.answerFormat as? ORKDateAnswerFormat else {
            XCTAssert(false, "\(formItem.answerFormat) is not of expected class type")
            return
        }
        
        XCTAssertEqual(answerFormat.style, ORKDateAnswerStyle.Date)
        
        XCTAssertNil(answerFormat.minimumDate)
        XCTAssertNil(answerFormat.defaultDate)
        XCTAssertNotNil(answerFormat.maximumDate)
        guard let maximumDate = answerFormat.maximumDate else {
            return
        }
        XCTAssertEqualWithAccuracy(maximumDate.timeIntervalSinceNow, NSTimeInterval(0), accuracy: 5)
        
    }
    
    func testFactory_TimeConstraints() {
        
        let inputStep:SBBSurveyQuestion = SBBSurveyQuestion()
        inputStep.identifier = "last-smoked"
        inputStep.guid = "2d4b697c-368e-4cda-a30d-0c7dfc38342e"
        inputStep.prompt = "When is the last time you smoked (put todays date if you are still smoking)?"
        inputStep.uiHint = "datetimepicker"
        inputStep.constraints = SBBTimeConstraints()
        
        let step = SBASurveyFactory().createSurveyStepWithSurveyElement(inputStep)
        XCTAssertNotNil(step)
        
        guard let surveyStep = step as? SBASurveyQuestionStep else {
            XCTAssert(false, "\(step) is not of expected class type")
            return
        }
    
        XCTAssertEqual(surveyStep.identifier, "last-smoked")
        XCTAssertEqual(surveyStep.text, "When is the last time you smoked (put todays date if you are still smoking)?")
        XCTAssertEqual(surveyStep.formItems?.count, 1)
        
        guard let formItem = surveyStep.formItems?.first else {
            XCTAssert(false, "\(surveyStep.formItems) is not of expected class type")
            return
        }
        
        XCTAssertNil(formItem.text)
        
        guard let _ = formItem.answerFormat as? ORKTimeOfDayAnswerFormat else {
            XCTAssert(false, "\(formItem.answerFormat) is not of expected class type")
            return
        }
    }
    
    func testFactory_DurationConstraints() {
        
        let inputStep:SBBSurveyQuestion = SBBSurveyQuestion()
        inputStep.identifier = "last-smoked"
        inputStep.guid = "2d4b697c-368e-4cda-a30d-0c7dfc38342e"
        inputStep.prompt = "When is the last time you smoked (put todays date if you are still smoking)?"
        inputStep.uiHint = "datetimepicker"
        inputStep.constraints = SBBDurationConstraints()
        
        let step = SBASurveyFactory().createSurveyStepWithSurveyElement(inputStep)
        XCTAssertNotNil(step)
        
        guard let surveyStep = step as? SBASurveyQuestionStep else {
            XCTAssert(false, "\(step) is not of expected class type")
            return
        }
        
        XCTAssertEqual(surveyStep.identifier, "last-smoked")
        XCTAssertEqual(surveyStep.text, "When is the last time you smoked (put todays date if you are still smoking)?")
        XCTAssertEqual(surveyStep.formItems?.count, 1)
        
        guard let formItem = surveyStep.formItems?.first else {
            XCTAssert(false, "\(surveyStep.formItems) is not of expected class type")
            return
        }
        
        XCTAssertNil(formItem.text)
        
        guard let _ = formItem.answerFormat as? ORKTimeIntervalAnswerFormat else {
            XCTAssert(false, "\(formItem.answerFormat) is not of expected class type")
            return
        }
    }
    
    func testFactory_DurationConstraints_Weeks() {
        
        let inputStep:SBBSurveyQuestion = SBBSurveyQuestion()
        inputStep.identifier = "last-smoked"
        inputStep.guid = "2d4b697c-368e-4cda-a30d-0c7dfc38342e"
        inputStep.prompt = "When is the last time you smoked (put todays date if you are still smoking)?"
        inputStep.uiHint = "datetimepicker"
        
        let constraints = SBBDurationConstraints()
        inputStep.constraints = constraints
        constraints.unit = "weeks"
        
        let step = SBASurveyFactory().createSurveyStepWithSurveyElement(inputStep)
        XCTAssertNotNil(step)
        
        guard let surveyStep = step as? SBASurveyQuestionStep else {
            XCTAssert(false, "\(step) or answer format is not of expected class type")
            return
        }
        
        guard let answerFormat = surveyStep.answerFormat as? ORKNumericAnswerFormat else {
                XCTAssert(false, "\(surveyStep.answerFormat) not of expected class type")
                return
        }
        
        XCTAssertEqual(answerFormat.minimum, 0)
        XCTAssertEqual(answerFormat.maximum, NSIntegerMax)
        XCTAssertEqual(answerFormat.style, ORKNumericAnswerStyle.Integer)
        XCTAssertEqual(answerFormat.unit, "weeks")
    }
    
    // MARK: IntegerConstraints
    
    func testFactory_IntegerConstraints() {
        
        let inputStep:SBBSurveyQuestion = createIntegerQuestion()
        inputStep.constraints.addRulesObject(
            SBBSurveyRule(dictionaryRepresentation:         [
                "value" : NSNumber(int: 50),
                "operator" : "lt",
                "skipTo" : "video-usage",
                "type" : "SurveyRule"
                ]))
        inputStep.constraints.addRulesObject(
            SBBSurveyRule(dictionaryRepresentation:         [
                "value" : "true",
                "operator" : "de",
                "skipTo" : "video-usage",
                "type" : "SurveyRule"
                ]))
        
        let step = SBASurveyFactory().createSurveyStepWithSurveyElement(inputStep)
        XCTAssertNotNil(step)
    
        guard let surveyStep = step as? SBASurveyQuestionStep else {
            XCTAssert(false, "\(step) is not of expected class type")
            return
        }
        
        XCTAssertEqual(surveyStep.identifier, "age")
        XCTAssertEqual(surveyStep.text, "How old are you?")
        XCTAssertEqual(surveyStep.formItems?.count, 1)
        XCTAssertTrue(surveyStep.skipIfPassed)
        XCTAssertEqual(surveyStep.skipToStepIdentifier, "video-usage")
        
        guard let formItem = surveyStep.formItems?.first as? SBASurveyFormItem,
            let answerFormat = formItem.answerFormat as? ORKNumericAnswerFormat else {
                XCTAssert(false, "\(surveyStep.formItems) is not of expected class type")
                return
        }
        
        XCTAssertNil(formItem.text)
        XCTAssertNotNil(formItem.rulePredicate)
        
        XCTAssertEqual(answerFormat.unit, "years")
        XCTAssertEqual(answerFormat.minimum, NSNumber(int: 18))
        XCTAssertEqual(answerFormat.maximum, NSNumber(int: 100))
        XCTAssertEqual(answerFormat.style, ORKNumericAnswerStyle.Integer)
        
        guard let navigationRule = formItem.rulePredicate else {
            return
        }
        
        let questionResult = ORKNumericQuestionResult(identifier:formItem.identifier)
        XCTAssertTrue(navigationRule.evaluateWithObject(questionResult))
        
        questionResult.numericAnswer = NSNumber(int: 49)
        XCTAssertTrue(navigationRule.evaluateWithObject(questionResult))
        
        questionResult.numericAnswer = NSNumber(int: 50)
        XCTAssertFalse(navigationRule.evaluateWithObject(questionResult))
        
        questionResult.numericAnswer = NSNumber(int: 51)
        XCTAssertFalse(navigationRule.evaluateWithObject(questionResult))
        
    }
    
    func testFactory_IntegerConstraints_Equal() {
        
        let inputStep:SBBSurveyQuestion = createIntegerQuestion()
        inputStep.constraints.addRulesObject(
            SBBSurveyRule(dictionaryRepresentation:         [
                "value" : NSNumber(int: 50),
                "operator" : "eq",
                "skipTo" : "video-usage",
                "type" : "SurveyRule"
                ]))
        
        let step = SBASurveyFactory().createSurveyStepWithSurveyElement(inputStep)
        
        guard let surveyStep = step as? SBASurveyQuestionStep,
            let formItem = surveyStep.formItems?.first as? SBASurveyFormItem,
            let navigationRule = formItem.rulePredicate else {
            XCTAssert(false, "\(step) does not match expected")
            return
        }
        
        let questionResult = ORKNumericQuestionResult(identifier:formItem.identifier)
        
        questionResult.numericAnswer = NSNumber(int: 49)
        XCTAssertFalse(navigationRule.evaluateWithObject(questionResult))
        
        questionResult.numericAnswer = NSNumber(int: 50)
        XCTAssertTrue(navigationRule.evaluateWithObject(questionResult))
        
        questionResult.numericAnswer = NSNumber(int: 51)
        XCTAssertFalse(navigationRule.evaluateWithObject(questionResult))
    }
    
    func testFactory_IntegerConstraints_NotEqual() {
        
        let inputStep:SBBSurveyQuestion = createIntegerQuestion()
        inputStep.constraints.addRulesObject(
            SBBSurveyRule(dictionaryRepresentation:         [
                "value" : NSNumber(int: 50),
                "operator" : "ne",
                "skipTo" : "video-usage",
                "type" : "SurveyRule"
                ]))
        
        let step = SBASurveyFactory().createSurveyStepWithSurveyElement(inputStep)
        
        guard let surveyStep = step as? SBASurveyQuestionStep,
            let formItem = surveyStep.formItems?.first as? SBASurveyFormItem,
            let navigationRule = formItem.rulePredicate else {
                XCTAssert(false, "\(step) does not match expected")
                return
        }
        
        let questionResult = ORKNumericQuestionResult(identifier:formItem.identifier)
        
        questionResult.numericAnswer = NSNumber(int: 49)
        XCTAssertTrue(navigationRule.evaluateWithObject(questionResult))
        
        questionResult.numericAnswer = NSNumber(int: 50)
        XCTAssertFalse(navigationRule.evaluateWithObject(questionResult))
        
        questionResult.numericAnswer = NSNumber(int: 51)
        XCTAssertTrue(navigationRule.evaluateWithObject(questionResult))
    }
    
    func testFactory_IntegerConstraints_GreaterThan() {
        
        let inputStep:SBBSurveyQuestion = createIntegerQuestion()
        inputStep.constraints.addRulesObject(
            SBBSurveyRule(dictionaryRepresentation:         [
                "value" : NSNumber(int: 50),
                "operator" : "gt",
                "skipTo" : "video-usage",
                "type" : "SurveyRule"
                ]))
        
        let step = SBASurveyFactory().createSurveyStepWithSurveyElement(inputStep)
        
        guard let surveyStep = step as? SBASurveyQuestionStep,
            let formItem = surveyStep.formItems?.first as? SBASurveyFormItem,
            let navigationRule = formItem.rulePredicate else {
                XCTAssert(false, "\(step) does not match expected")
                return
        }
        
        let questionResult = ORKNumericQuestionResult(identifier:formItem.identifier)
        
        questionResult.numericAnswer = NSNumber(int: 49)
        XCTAssertFalse(navigationRule.evaluateWithObject(questionResult))
        
        questionResult.numericAnswer = NSNumber(int: 50)
        XCTAssertFalse(navigationRule.evaluateWithObject(questionResult))
        
        questionResult.numericAnswer = NSNumber(int: 51)
        XCTAssertTrue(navigationRule.evaluateWithObject(questionResult))
    }
    
    func testFactory_IntegerConstraints_GreaterThanOrEqual() {
        
        let inputStep:SBBSurveyQuestion = createIntegerQuestion()
        inputStep.constraints.addRulesObject(
            SBBSurveyRule(dictionaryRepresentation:         [
                "value" : NSNumber(int: 50),
                "operator" : "ge",
                "skipTo" : "video-usage",
                "type" : "SurveyRule"
                ]))
        
        let step = SBASurveyFactory().createSurveyStepWithSurveyElement(inputStep)
        
        guard let surveyStep = step as? SBASurveyQuestionStep,
            let formItem = surveyStep.formItems?.first as? SBASurveyFormItem,
            let navigationRule = formItem.rulePredicate else {
                XCTAssert(false, "\(step) does not match expected")
                return
        }
        
        let questionResult = ORKNumericQuestionResult(identifier:formItem.identifier)
        
        questionResult.numericAnswer = NSNumber(int: 49)
        XCTAssertFalse(navigationRule.evaluateWithObject(questionResult))
        
        questionResult.numericAnswer = NSNumber(int: 50)
        XCTAssertTrue(navigationRule.evaluateWithObject(questionResult))
        
        questionResult.numericAnswer = NSNumber(int: 51)
        XCTAssertTrue(navigationRule.evaluateWithObject(questionResult))
    }
    
    func testFactory_IntegerConstraints_LessThanOrEqual() {
        
        let inputStep:SBBSurveyQuestion = createIntegerQuestion()
        inputStep.constraints.addRulesObject(
            SBBSurveyRule(dictionaryRepresentation:         [
                "value" : NSNumber(int: 50),
                "operator" : "le",
                "skipTo" : "video-usage",
                "type" : "SurveyRule"
                ]))
        
        let step = SBASurveyFactory().createSurveyStepWithSurveyElement(inputStep)
        
        guard let surveyStep = step as? SBASurveyQuestionStep,
            let formItem = surveyStep.formItems?.first as? SBASurveyFormItem,
            let navigationRule = formItem.rulePredicate else {
                XCTAssert(false, "\(step) does not match expected")
                return
        }
        
        let questionResult = ORKNumericQuestionResult(identifier:formItem.identifier)
        
        questionResult.numericAnswer = NSNumber(int: 49)
        XCTAssertTrue(navigationRule.evaluateWithObject(questionResult))
        
        questionResult.numericAnswer = NSNumber(int: 50)
        XCTAssertTrue(navigationRule.evaluateWithObject(questionResult))
        
        questionResult.numericAnswer = NSNumber(int: 51)
        XCTAssertFalse(navigationRule.evaluateWithObject(questionResult))
    }
    
    func testFactory_IntegerConstraints_OtherThan() {
        
        let inputStep:SBBSurveyQuestion = createIntegerQuestion()
        inputStep.constraints.addRulesObject(
            SBBSurveyRule(dictionaryRepresentation:         [
                "value" : NSNumber(int: 50),
                "operator" : "ot",
                "skipTo" : "video-usage",
                "type" : "SurveyRule"
                ]))
        
        let step = SBASurveyFactory().createSurveyStepWithSurveyElement(inputStep)
        
        guard let surveyStep = step as? SBASurveyQuestionStep,
            let formItem = surveyStep.formItems?.first as? SBASurveyFormItem,
            let navigationRule = formItem.rulePredicate else {
                XCTAssert(false, "\(step) does not match expected")
                return
        }
        
        let questionResult = ORKNumericQuestionResult(identifier:formItem.identifier)
        
        questionResult.numericAnswer = NSNumber(int: 49)
        XCTAssertTrue(navigationRule.evaluateWithObject(questionResult))
        
        questionResult.numericAnswer = NSNumber(int: 50)
        XCTAssertFalse(navigationRule.evaluateWithObject(questionResult))
        
        questionResult.numericAnswer = NSNumber(int: 51)
        XCTAssertTrue(navigationRule.evaluateWithObject(questionResult))
    }

    func testFactory_DecimalConstraints() {
        
        let inputStep:SBBSurveyQuestion = SBBSurveyQuestion()
        inputStep.uiHint = "numberfield"
        inputStep.identifier = "age"
        inputStep.guid = "c096d808-2b5b-4151-9e09-0c4ada6028e9"
        inputStep.prompt = "How old are you?"
        
        let constraints = SBBDecimalConstraints()
        inputStep.constraints = constraints
        constraints.minValue = NSNumber(double: 18.3)
        constraints.maxValue = NSNumber(double: 100.2)
        constraints.unit = "years"
        
        inputStep.constraints.addRulesObject(
            SBBSurveyRule(dictionaryRepresentation:         [
                "value" : NSNumber(double: 50.0),
                "operator" : "lt",
                "skipTo" : "video-usage",
                "type" : "SurveyRule"
                ]))
        inputStep.constraints.addRulesObject(
            SBBSurveyRule(dictionaryRepresentation:         [
                "value" : "true",
                "operator" : "de",
                "skipTo" : "video-usage",
                "type" : "SurveyRule"
                ]))
        
        let step = SBASurveyFactory().createSurveyStepWithSurveyElement(inputStep)
        XCTAssertNotNil(step)
        
        guard let surveyStep = step as? SBASurveyQuestionStep,
              let formItems = surveyStep.formItems
        else {
            XCTAssert(false, "\(step) is not of expected class type")
            return
        }
        
        XCTAssertEqual(surveyStep.identifier, "age")
        XCTAssertEqual(surveyStep.text, "How old are you?")
        XCTAssertEqual(formItems.count, 1)
        XCTAssertTrue(surveyStep.skipIfPassed)
        XCTAssertEqual(surveyStep.skipToStepIdentifier, "video-usage")
        
        guard let formItem = formItems.first as? SBASurveyFormItem,
            let answerFormat = formItem.answerFormat as? ORKNumericAnswerFormat else {
                XCTAssert(false, "\(surveyStep.formItems) is not of expected class type")
                return
        }
        
        XCTAssertNil(formItem.text)
        XCTAssertNotNil(formItem.rulePredicate)
        
        XCTAssertEqual(answerFormat.unit, "years")
        XCTAssertEqual(answerFormat.minimum, NSNumber(double: 18.3))
        XCTAssertEqual(answerFormat.maximum, NSNumber(double: 100.2))
        XCTAssertEqual(answerFormat.style, ORKNumericAnswerStyle.Decimal)
        
        guard let navigationRule = formItem.rulePredicate else {
            return
        }
        
        let questionResult = ORKNumericQuestionResult(identifier:formItem.identifier)
        XCTAssertTrue(navigationRule.evaluateWithObject(questionResult))
        
        questionResult.numericAnswer = NSNumber(double: 49.0)
        XCTAssertTrue(navigationRule.evaluateWithObject(questionResult))
        
        questionResult.numericAnswer = NSNumber(double: 50.0)
        XCTAssertFalse(navigationRule.evaluateWithObject(questionResult))
        
        questionResult.numericAnswer = NSNumber(double: 51.0)
        XCTAssertFalse(navigationRule.evaluateWithObject(questionResult))
        
    }
    
    // MARK: IntegerConstraint with uiHint == slider
    
    func testFactory_IntegerSlider_step100() {
        
        let inputStep:SBBSurveyQuestion = createSliderQuestion(100)
        
        let step = SBASurveyFactory().createSurveyStepWithSurveyElement(inputStep)
        XCTAssertNotNil(step)
        
        guard let surveyStep = step as? SBASurveyQuestionStep,
            let formItem = surveyStep.formItems?.first,
            let scaleFormat = formItem.answerFormat as? ORKScaleAnswerFormat else {
                XCTAssert(false, "\(step) Not of expected class")
                return
        }
        
        XCTAssertEqual(scaleFormat.step, 100)
    }
    
    func testFactory_IntegerSlider_step5() {
        
        let inputStep:SBBSurveyQuestion = createSliderQuestion(5)
        
        let step = SBASurveyFactory().createSurveyStepWithSurveyElement(inputStep)
        XCTAssertNotNil(step)
        
        // ResearchKit requires that number of steps between min and max value are >= 1 and <= 13
        // so if there would be more than 13 steps (100/5 == 20) then use continuous scale
        guard let surveyStep = step as? SBASurveyQuestionStep,
            let formItem = surveyStep.formItems?.first,
            let scaleFormat = formItem.answerFormat as? ORKContinuousScaleAnswerFormat else {
                XCTAssert(false, "\(step) is not of expected format")
                return
        }

        XCTAssertEqual(scaleFormat.maximumFractionDigits, 0)
        XCTAssertEqual(scaleFormat.minimum, 0.0)
        XCTAssertEqual(scaleFormat.maximum, 100.0)
    }
    
    func testFactory_IntegerSlider_step25() {
        
        let inputStep:SBBSurveyQuestion = createSliderQuestion(25)
        
        let step = SBASurveyFactory().createSurveyStepWithSurveyElement(inputStep)
        XCTAssertNotNil(step)
        
        guard let surveyStep = step as? SBASurveyQuestionStep,
            let formItem = surveyStep.formItems?.first,
            let scaleFormat = formItem.answerFormat as? ORKScaleAnswerFormat else {
                XCTAssert(false, "\(step) is not of expected format")
                return
        }
        
        XCTAssertEqual(scaleFormat.step, 25)
        XCTAssertEqual(scaleFormat.minimum, 0)
        XCTAssertEqual(scaleFormat.maximum, 100)
    }

    func testFactory_IntegerSlider_stepNil() {
        
        let inputStep:SBBSurveyQuestion = createSliderQuestion(nil)
        
        let step = SBASurveyFactory().createSurveyStepWithSurveyElement(inputStep)
        XCTAssertNotNil(step)
        
        // If the step size is not defined, but the slider uiHint is set,
        // then should be step size == 1. This will result in more than 13 step intervals
        // so the returned class should be continuous scale
        guard let surveyStep = step as? SBASurveyQuestionStep,
            let formItem = surveyStep.formItems?.first,
            let scaleFormat = formItem.answerFormat as? ORKContinuousScaleAnswerFormat else {
                XCTAssert(false, "\(step) is not of expected format")
                return
        }
        
        XCTAssertEqual(scaleFormat.maximumFractionDigits, 0)
        XCTAssertEqual(scaleFormat.minimum, 0.0)
        XCTAssertEqual(scaleFormat.maximum, 100.0)
    }
    
    func testFactory_IntegerSlider_stepInvalid() {
        
        let inputStep:SBBSurveyQuestion = createSliderQuestion(37)
        
        let step = SBASurveyFactory().createSurveyStepWithSurveyElement(inputStep)
        XCTAssertNotNil(step)
        
        // a step size of 37 is not divisible by 100 so is invalid
        guard let surveyStep = step as? SBASurveyQuestionStep,
            let formItem = surveyStep.formItems?.first,
            let _ = formItem.answerFormat as? ORKNumericAnswerFormat else {
            XCTAssert(false, "\(step) Not of expected class")
            return
        }
    }
    

    
    
    // MARK: Helper methods

    func createMultipleChoiceQuestion(allowMultiple allowMultiple: Bool) -> SBBSurveyQuestion {
        let inputStep:SBBSurveyQuestion = SBBSurveyQuestion()
        inputStep.uiHint = "radiobutton"
        inputStep.identifier = "medical-usage"
        inputStep.guid = "c564984a-0951-48b5-a490-43d07aa04886"
        inputStep.prompt = "Do you ever use your smartphone to look for health or medical information online?"
        
        let constraints = SBBMultiValueConstraints()
        constraints.allowMultiple = NSNumber(bool: allowMultiple)
        constraints.dataType = "string"
        constraints.addEnumerationObject(
            SBBSurveyQuestionOption(dictionaryRepresentation:[
                "label" : "Yes, I have done this",
                "value" : "true",
                "type" : "SurveyQuestionOption"
                ]))
        constraints.addEnumerationObject(
            SBBSurveyQuestionOption(dictionaryRepresentation:[
                "label" : "No, I have never done this",
                "value" : "false",
                "type" : "SurveyQuestionOption"
                ]))
        constraints.addEnumerationObject(
            SBBSurveyQuestionOption(dictionaryRepresentation:[
                "label" : "Maybe",
                "value" : "maybe",
                "type" : "SurveyQuestionOption"
                ]))
        inputStep.constraints = constraints
        
        return inputStep
    }
    
    func createIntegerQuestion() -> SBBSurveyQuestion {
    
        let inputStep:SBBSurveyQuestion = SBBSurveyQuestion()
        inputStep.uiHint = "numberfield"
        inputStep.identifier = "age"
        inputStep.guid = "c096d808-2b5b-4151-9e09-0c4ada6028e9"
        inputStep.prompt = "How old are you?"
        
        let constraints = SBBIntegerConstraints()
        inputStep.constraints = constraints
        constraints.minValue = NSNumber(int: 18)
        constraints.maxValue = NSNumber(int: 100)
        constraints.unit = "years"
        
        return inputStep;
    }
    
    func createSliderQuestion(step: Int32?) -> SBBSurveyQuestion {
        
        let inputStep:SBBSurveyQuestion = SBBSurveyQuestion()
        inputStep.uiHint = "numberfield"
        inputStep.identifier = "age"
        inputStep.guid = "c096d808-2b5b-4151-9e09-0c4ada6028e9"
        inputStep.prompt = "How old are you?"
        inputStep.uiHint = "slider"
        
        let constraints = SBBIntegerConstraints()
        inputStep.constraints = constraints
        constraints.minValue = NSNumber(int: 0)
        constraints.maxValue = NSNumber(int: 100)
        constraints.unit = "years"
        if let step = step {
            constraints.step = NSNumber(int: step)
        }
        
        return inputStep;
    }


}
