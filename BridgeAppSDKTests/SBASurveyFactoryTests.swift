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
    // MARK: SBBSurvey
    // -------------------------------------------------
    
    func testFactory_SBBSurveyInfoScreen() {
        let inputStep = SBBSurveyInfoScreen()
        inputStep.identifier = "abc123"
        inputStep.title = "Title"
        inputStep.prompt = "Text"
        inputStep.promptDetail = "Detail"
        
        let step = SBASurveyFactory().createSurveyStepWithSurveyElement(inputStep, index:0, count:1)
        XCTAssertNotNil(step)
        
        guard let surveyStep = step as? ORKInstructionStep else {
            XCTAssert(false, "\(String(describing: step)) is not of expected class type")
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
            "value" : NSNumber(value: true as Bool),
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
        
        let step = SBASurveyFactory().createSurveyStepWithSurveyElement(inputStep, index:0, count:1)
        XCTAssertNotNil(step)
        
        guard let surveyStep = step as? SBANavigationQuestionStep else {
            XCTAssert(false, "\(String(describing: step)) is not of expected class type")
            return
        }
        
        XCTAssertEqual(surveyStep.identifier, "living-alone-status")
        XCTAssertEqual(surveyStep.text, "Do you live alone?")
        
        let skipTaskResult = createTaskBooleanResult(nil)
        let skipIdentifierIfSkipped = surveyStep.nextStepIdentifier(with: skipTaskResult, and: nil)
        XCTAssertEqual(skipIdentifierIfSkipped, "video-usage")
        
        let neTaskResult = createTaskBooleanResult(false)
        let skipIdentifierIfFalse = surveyStep.nextStepIdentifier(with: neTaskResult, and: nil)
        XCTAssertEqual(skipIdentifierIfFalse, "video-usage")
        
        let eqTaskResult = createTaskBooleanResult(true)
        let skipIdentifierIfTrue = surveyStep.nextStepIdentifier(with: eqTaskResult, and: nil)
        XCTAssertNil(skipIdentifierIfTrue)
        
        guard let rules = surveyStep.rules, rules.count == 1, let rule = rules.first else {
            XCTAssert(false, "\(String(describing: surveyStep.rules)) is not of expected count")
            return
        }
        
        XCTAssertEqual(rule.resultIdentifier, "living-alone-status")
        XCTAssertEqual(rule.skipIdentifier, "video-usage")
    }
    
    func testFactory_BooleanConstraints_MultipleIdentifiers() {
        
        let inputStep = SBBSurveyQuestion()
        inputStep.identifier = "living-alone-status"
        inputStep.guid = "216a6a73-86dc-432a-bb6a-71a8b7cf4be1"
        inputStep.uiHint = "checkbox"
        inputStep.prompt = "Do you live alone?"
        inputStep.constraints = SBBBooleanConstraints();
        
        let ruleTrue = SBBSurveyRule(dictionaryRepresentation:         [
            "value" : NSNumber(value: true as Bool),
            "operator" : "eq",
            "skipTo" : "video-usage",
            "type" : "SurveyRule"
            ])
        let ruleFalse = SBBSurveyRule(dictionaryRepresentation:         [
            "value" : NSNumber(value: false as Bool),
            "operator" : "eq",
            "skipTo" : "next-section",
            "type" : "SurveyRule"
            ])
        
        inputStep.constraints.addRulesObject(ruleTrue)
        inputStep.constraints.addRulesObject(ruleFalse)
        
        let step = SBASurveyFactory().createSurveyStepWithSurveyElement(inputStep, index:0, count:1)
        XCTAssertNotNil(step)
        
        guard let surveyStep = step as? SBANavigationQuestionStep else {
            XCTAssert(false, "\(String(describing: step)) is not of expected class type")
            return
        }
        
        XCTAssertEqual(surveyStep.identifier, "living-alone-status")
        XCTAssertEqual(surveyStep.text, "Do you live alone?")
        
        let skipIdentifierIfSkipped = surveyStep.nextStepIdentifier(with: createTaskBooleanResult(nil), and: nil)
        XCTAssertNil(skipIdentifierIfSkipped)
        
        let skipIdentifierIfFalse = surveyStep.nextStepIdentifier(with: createTaskBooleanResult(false), and: nil)
        XCTAssertEqual(skipIdentifierIfFalse, "next-section")
        
        let skipIdentifierIfTrue = surveyStep.nextStepIdentifier(with: createTaskBooleanResult(true), and: nil)
        XCTAssertEqual(skipIdentifierIfTrue, "video-usage")
    }
    
    func testFactory_BooleanConstraints_SkipToEnd() {
        
        let inputStep = SBBSurveyQuestion()
        inputStep.identifier = "living-alone-status"
        inputStep.guid = "216a6a73-86dc-432a-bb6a-71a8b7cf4be1"
        inputStep.uiHint = "checkbox"
        inputStep.prompt = "Do you live alone?"
        inputStep.constraints = SBBBooleanConstraints();
        
        let ruleTrue = SBBSurveyRule(dictionaryRepresentation:         [
            "value" : NSNumber(value: true as Bool),
            "operator" : "eq",
            "endSurvey" : NSNumber(value: true as Bool),
            "type" : "SurveyRule"
            ])
        
        inputStep.constraints.addRulesObject(ruleTrue)
        
        let step = SBASurveyFactory().createSurveyStepWithSurveyElement(inputStep, index:0, count:1)
        XCTAssertNotNil(step)
        
        guard let surveyStep = step as? SBANavigationQuestionStep else {
            XCTAssert(false, "\(String(describing: step)) is not of expected class type")
            return
        }
        
        XCTAssertEqual(surveyStep.identifier, "living-alone-status")
        XCTAssertEqual(surveyStep.text, "Do you live alone?")
        
        let skipIdentifierIfSkipped = surveyStep.nextStepIdentifier(with: createTaskBooleanResult(nil), and: nil)
        XCTAssertNil(skipIdentifierIfSkipped)
        
        let skipIdentifierIfFalse = surveyStep.nextStepIdentifier(with: createTaskBooleanResult(false), and: nil)
        XCTAssertNil(skipIdentifierIfFalse)
        
        let skipIdentifierIfTrue = surveyStep.nextStepIdentifier(with: createTaskBooleanResult(true), and: nil)
        XCTAssertEqual(skipIdentifierIfTrue, ORKNullStepIdentifier)
    }
    
    func testFactory_BooleanConstraints_NoRules() {
        
        let inputStep = SBBSurveyQuestion()
        inputStep.identifier = "living-alone-status"
        inputStep.guid = "216a6a73-86dc-432a-bb6a-71a8b7cf4be1"
        inputStep.uiHint = "checkbox"
        inputStep.prompt = "Do you live alone?"
        inputStep.constraints = SBBBooleanConstraints();
        
        let step = SBASurveyFactory().createSurveyStepWithSurveyElement(inputStep, index:0, count:1)
        XCTAssertNotNil(step)
        
        guard let surveyStep = step as? SBANavigationQuestionStep else {
            XCTAssert(false, "\(String(describing: step)) is not of expected class type")
            return
        }
        
        XCTAssertEqual(surveyStep.identifier, "living-alone-status")
        XCTAssertNil(surveyStep.title)
        XCTAssertNotNil(surveyStep.text)
        XCTAssertEqual(surveyStep.text!, "Do you live alone?")
        
        // In every case, the next step identifier should be nil
        let questionResult = ORKBooleanQuestionResult(identifier:"living-alone-status")
        let stepResult = ORKStepResult(stepIdentifier: "living-alone-status", results: [questionResult])
        let taskResult = ORKTaskResult(identifier: "task")
        taskResult.results = [ORKStepResult(identifier: "introduction"), stepResult]
        
        let skipIdentifierIfSkipped = surveyStep.nextStepIdentifier(with: createTaskBooleanResult(nil), and: nil)
        XCTAssertNil(skipIdentifierIfSkipped)
        
        let skipIdentifierIfFalse = surveyStep.nextStepIdentifier(with: createTaskBooleanResult(false), and: nil)
        XCTAssertNil(skipIdentifierIfFalse)
        
        let skipIdentifierIfTrue = surveyStep.nextStepIdentifier(with: createTaskBooleanResult(true), and: nil)
        XCTAssertNil(skipIdentifierIfTrue)
    }
    
    func testFactory_BooleanConstraints_PromptDetail() {
        
        let inputStep = SBBSurveyQuestion()
        inputStep.identifier = "living-alone-status"
        inputStep.guid = "216a6a73-86dc-432a-bb6a-71a8b7cf4be1"
        inputStep.uiHint = "checkbox"
        inputStep.prompt = "Question 1"
        inputStep.promptDetail = "Do you live alone?"
        inputStep.constraints = SBBBooleanConstraints();
        
        let step = SBASurveyFactory().createSurveyStepWithSurveyElement(inputStep, index:0, count:1)
        XCTAssertNotNil(step)
        
        guard let surveyStep = step as? SBANavigationQuestionStep else {
            XCTAssert(false, "\(String(describing: step)) is not of expected class type")
            return
        }
        
        XCTAssertEqual(surveyStep.identifier, "living-alone-status")
        XCTAssertNotNil(surveyStep.title)
        XCTAssertEqual(surveyStep.title!, "Question 1")
        XCTAssertNotNil(surveyStep.text)
        XCTAssertEqual(surveyStep.text!, "Do you live alone?")
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

        let step = SBASurveyFactory().createSurveyStepWithSurveyElement(inputStep, index:0, count:1)
        XCTAssertNotNil(step)
        
        guard let surveyStep = step as? SBANavigationQuestionStep else {
            XCTAssert(false, "\(String(describing: step)) is not of expected class type")
            return
        }
        
        XCTAssertEqual(surveyStep.identifier, "medical-usage")
        XCTAssertEqual(surveyStep.text, "Do you ever use your smartphone to look for health or medical information online?")
        
        let skipIdentifierIfSkipped = surveyStep.nextStepIdentifier(with: createTaskChoiceResult(nil), and: nil)
        XCTAssertEqual(skipIdentifierIfSkipped, "video-usage")
        
        let skipIdentifierIfFalse = surveyStep.nextStepIdentifier(with: createTaskChoiceResult(["false"]), and: nil)
        XCTAssertEqual(skipIdentifierIfFalse, "video-usage")
        
        let skipIdentifierIfTrue = surveyStep.nextStepIdentifier(with: createTaskChoiceResult(["true"]), and: nil)
        XCTAssertNil(skipIdentifierIfTrue)
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
        
        let step = SBASurveyFactory().createSurveyStepWithSurveyElement(inputStep, index:0, count:1)
        XCTAssertNotNil(step)
        
        guard let surveyStep = step as? SBANavigationQuestionStep else {
                XCTAssert(false, "\(String(describing: step)) does not meet expected format")
                return
        }
        
        let questionResult = ORKChoiceQuestionResult(identifier:"medical-usage")
        let stepResult = ORKStepResult(stepIdentifier: "medical-usage", results: [questionResult])
        let taskResult = ORKTaskResult(identifier: "task")
        taskResult.results = [ORKStepResult(identifier: "introduction"), stepResult]
        
        let skipIdentifierIfSkipped = surveyStep.nextStepIdentifier(with: createTaskChoiceResult(nil), and: nil)
        XCTAssertEqual(skipIdentifierIfSkipped, "video-usage")
        
        let skipIdentifierIfFalse = surveyStep.nextStepIdentifier(with: createTaskChoiceResult(["false"]), and: nil)
        XCTAssertEqual(skipIdentifierIfFalse, "video-usage")
        
        let skipIdentifierIfTrue = surveyStep.nextStepIdentifier(with: createTaskChoiceResult(["true"]), and: nil)
        XCTAssertNil(skipIdentifierIfTrue)
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
        
        let step = SBASurveyFactory().createSurveyStepWithSurveyElement(inputStep, index:0, count:1)
        XCTAssertNotNil(step)
        
        guard let surveyStep = step as? SBANavigationQuestionStep else {
                XCTAssert(false, "\(String(describing: step)) does not meet expected format")
                return
        }
        
        let skipIdentifierIfSkipped = surveyStep.nextStepIdentifier(with: createTaskChoiceResult(nil), and: nil)
        XCTAssertEqual(skipIdentifierIfSkipped, "video-usage")
        
        let skipIdentifierIfFalse = surveyStep.nextStepIdentifier(with: createTaskChoiceResult(["false"]), and: nil)
        XCTAssertEqual(skipIdentifierIfFalse, "video-usage")
        
        let skipIdentifierIfTrue = surveyStep.nextStepIdentifier(with: createTaskChoiceResult(["true"]), and: nil)
        XCTAssertNil(skipIdentifierIfTrue)
    }
    
    func testFactory_MultiValueConstraints_AllowMultiple() {
        
        let inputStep:SBBSurveyQuestion = createMultipleChoiceQuestion(allowMultiple: true)
        let step = SBASurveyFactory().createSurveyStepWithSurveyElement(inputStep, index:0, count:1)
        XCTAssertNotNil(step)
        
        guard let surveyStep = step as? SBANavigationQuestionStep,
            let answerFormat = surveyStep.answerFormat as? ORKTextChoiceAnswerFormat else {
                XCTAssert(false, "\(String(describing: step)) is not of expected format")
                return
        }
        
        XCTAssertEqual(answerFormat.style, ORKChoiceAnswerStyle.multipleChoice)
    }
    
    func testFactory_MultiValueConstraints_AllowOther_Uppercase() {
        
        let inputStep:SBBSurveyQuestion = createMultipleChoiceQuestion(allowMultiple: false)
        guard let constraints = inputStep.constraints as? SBBMultiValueConstraints else { return }
        
        constraints.allowOtherValue = true
        
        let step = SBASurveyFactory().createSurveyStepWithSurveyElement(inputStep, index:0, count:1)
        XCTAssertNotNil(step)
        
        guard let surveyStep = step as? SBANavigationQuestionStep,
            let answerFormat = surveyStep.answerFormat as? ORKTextChoiceAnswerFormat else {
                XCTAssert(false, "\(String(describing: step)) is not of expected format")
                return
        }
        
        XCTAssertEqual(answerFormat.style, ORKChoiceAnswerStyle.singleChoice)
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
                choice.label = choice.label.lowercased()
            }
        }
        
        let step = SBASurveyFactory().createSurveyStepWithSurveyElement(inputStep, index:0, count:1)
        XCTAssertNotNil(step)
        
        guard let surveyStep = step as? SBANavigationQuestionStep,
            let answerFormat = surveyStep.answerFormat as? ORKTextChoiceAnswerFormat else {
                XCTAssert(false, "\(String(describing: step)) is not of expected format")
                return
        }
        
        XCTAssertEqual(answerFormat.style, ORKChoiceAnswerStyle.singleChoice)
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
        inputStep.constraints = SBBStringConstraints()
        
        let step = SBASurveyFactory().createSurveyStepWithSurveyElement(inputStep, index:0, count:1)
        XCTAssertNotNil(step)
        
        guard let surveyStep = step as? SBANavigationQuestionStep else {
            XCTAssert(false, "\(String(describing: step)) is not of expected class type")
            return
        }
        
        XCTAssertEqual(surveyStep.identifier, "feelings")
        XCTAssertEqual(surveyStep.text, "How do you feel?")

        guard let _ = surveyStep.answerFormat as? ORKTextAnswerFormat else {
            XCTAssert(false, "\(String(describing: surveyStep.answerFormat)) is not of expected class type")
            return
        }
    }
    
    func testFactory_TextAnswer_ValidationRegEx() {
        
        let inputStep:SBBSurveyQuestion = SBBSurveyQuestion()
        inputStep.uiHint = "textfield"
        inputStep.identifier = "feelings"
        inputStep.guid = "c096d808-2b5b-4151-9e09-0c4ada6028e9"
        inputStep.prompt = "How do you feel?"
        
        // pattern, maxLength and minLength are currently unsupported
        let constraints = SBBStringConstraints()
        constraints.pattern = "^[0-9A-F]+$"
        constraints.patternErrorMessage = "Should be hexidecimal"
        inputStep.constraints = constraints
        
        let step = SBASurveyFactory().createSurveyStepWithSurveyElement(inputStep, index:0, count:1)
        XCTAssertNotNil(step)
        
        guard let surveyStep = step as? SBANavigationQuestionStep else {
            XCTAssert(false, "\(String(describing: step)) is not of expected class type")
            return
        }
        
        XCTAssertEqual(surveyStep.identifier, "feelings")
        XCTAssertEqual(surveyStep.text, "How do you feel?")
        
        guard let answerFormat = surveyStep.answerFormat as? ORKTextAnswerFormat else {
            XCTAssert(false, "\(String(describing: surveyStep.answerFormat)) is not of expected class type")
            return
        }
        
        XCTAssertFalse(answerFormat.multipleLines)
        XCTAssertEqual(answerFormat.validationRegularExpression?.pattern, "^[0-9A-F]+$")
        XCTAssertEqual(answerFormat.invalidMessage, "Should be hexidecimal")
        XCTAssertEqual(answerFormat.maximumLength, 0)
    }
    
    func testFactory_TextAnswer_MinAndMaxLength() {
        
        let inputStep:SBBSurveyQuestion = SBBSurveyQuestion()
        inputStep.uiHint = "textfield"
        inputStep.identifier = "feelings"
        inputStep.guid = "c096d808-2b5b-4151-9e09-0c4ada6028e9"
        inputStep.prompt = "How do you feel?"
        
        // pattern, maxLength and minLength are currently unsupported
        let constraints = SBBStringConstraints()
        constraints.minLength = NSNumber(value: 4)
        constraints.maxLength = NSNumber(value: 8)
        inputStep.constraints = constraints
        
        let step = SBASurveyFactory().createSurveyStepWithSurveyElement(inputStep, index:0, count:1)
        XCTAssertNotNil(step)
        
        guard let surveyStep = step as? SBANavigationQuestionStep else {
            XCTAssert(false, "\(String(describing: step)) is not of expected class type")
            return
        }
        
        XCTAssertEqual(surveyStep.identifier, "feelings")
        XCTAssertEqual(surveyStep.text, "How do you feel?")
        
        guard let answerFormat = surveyStep.answerFormat as? ORKTextAnswerFormat else {
            XCTAssert(false, "\(String(describing: surveyStep.answerFormat)) is not of expected class type")
            return
        }
        
        XCTAssertFalse(answerFormat.multipleLines)
        XCTAssertEqual(answerFormat.validationRegularExpression?.pattern, "^.{4,}$")
        XCTAssertEqual(answerFormat.maximumLength, 8)
    }
    
    func testFactory_TextAnswer_MinLengthOnly() {
        
        let inputStep:SBBSurveyQuestion = SBBSurveyQuestion()
        inputStep.uiHint = "textfield"
        inputStep.identifier = "feelings"
        inputStep.guid = "c096d808-2b5b-4151-9e09-0c4ada6028e9"
        inputStep.prompt = "How do you feel?"
        
        // pattern, maxLength and minLength are currently unsupported
        let constraints = SBBStringConstraints()
        constraints.minLength = NSNumber(value: 4)
        inputStep.constraints = constraints
        
        let step = SBASurveyFactory().createSurveyStepWithSurveyElement(inputStep, index:0, count:1)
        XCTAssertNotNil(step)
        
        guard let surveyStep = step as? SBANavigationQuestionStep else {
            XCTAssert(false, "\(String(describing: step)) is not of expected class type")
            return
        }
        
        XCTAssertEqual(surveyStep.identifier, "feelings")
        XCTAssertEqual(surveyStep.text, "How do you feel?")
        
        guard let answerFormat = surveyStep.answerFormat as? ORKTextAnswerFormat else {
            XCTAssert(false, "\(String(describing: surveyStep.answerFormat)) is not of expected class type")
            return
        }
        
        XCTAssertFalse(answerFormat.multipleLines)
        XCTAssertEqual(answerFormat.validationRegularExpression?.pattern, "^.{4,}$")
        XCTAssertEqual(answerFormat.maximumLength, 0)
    }
    
    func testFactory_TextAnswer_MultipleLine() {
        
        let inputStep:SBBSurveyQuestion = SBBSurveyQuestion()
        inputStep.uiHint = "multilinetext"
        inputStep.identifier = "feelings"
        inputStep.guid = "c096d808-2b5b-4151-9e09-0c4ada6028e9"
        inputStep.prompt = "How do you feel?"
        
        // pattern, maxLength and minLength are currently unsupported
        inputStep.constraints = SBBStringConstraints()
        
        let step = SBASurveyFactory().createSurveyStepWithSurveyElement(inputStep, index:0, count:1)
        XCTAssertNotNil(step)
        
        guard let surveyStep = step as? SBANavigationQuestionStep else {
            XCTAssert(false, "\(String(describing: step)) is not of expected class type")
            return
        }
        
        XCTAssertEqual(surveyStep.identifier, "feelings")
        XCTAssertEqual(surveyStep.text, "How do you feel?")
        
        guard let answerFormat = surveyStep.answerFormat as? ORKTextAnswerFormat else {
            XCTAssert(false, "\(String(describing: surveyStep.answerFormat)) is not of expected class type")
            return
        }
        
        XCTAssertTrue(answerFormat.multipleLines)
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
        
        let step = SBASurveyFactory().createSurveyStepWithSurveyElement(inputStep, index:0, count:1)
        XCTAssertNotNil(step)
        
        guard let surveyStep = step as? SBANavigationQuestionStep else {
            XCTAssert(false, "\(String(describing: step)) is not of expected class type")
            return
        }
        
        XCTAssertEqual(surveyStep.identifier, "last-smoked")
        XCTAssertEqual(surveyStep.text, "When is the last time you smoked (put todays date if you are still smoking)?")
        
        guard let answerFormat = surveyStep.answerFormat as? ORKDateAnswerFormat else {
            XCTAssert(false, "\(String(describing: surveyStep.answerFormat)) is not of expected class type")
            return
        }
        
        XCTAssertEqual(answerFormat.style, ORKDateAnswerStyle.dateAndTime)
        
        XCTAssertNil(answerFormat.minimumDate)
        XCTAssertNil(answerFormat.defaultDate)
        XCTAssertNotNil(answerFormat.maximumDate)
        guard let maximumDate = answerFormat.maximumDate else {
            return
        }
        XCTAssertEqualWithAccuracy(maximumDate.timeIntervalSinceNow, TimeInterval(0), accuracy: 5)
        
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
        
        let step = SBASurveyFactory().createSurveyStepWithSurveyElement(inputStep, index:0, count:1)
        XCTAssertNotNil(step)
        
        guard let surveyStep = step as? SBANavigationQuestionStep else {
            XCTAssert(false, "\(String(describing: step)) is not of expected class type")
            return
        }
        
        XCTAssertEqual(surveyStep.identifier, "last-smoked")
        XCTAssertEqual(surveyStep.text, "When is the last time you smoked (put todays date if you are still smoking)?")
        
        guard let answerFormat = surveyStep.answerFormat as? ORKDateAnswerFormat else {
            XCTAssert(false, "\(String(describing: surveyStep.answerFormat)) is not of expected class type")
            return
        }
        
        XCTAssertEqual(answerFormat.style, ORKDateAnswerStyle.date)
        
        XCTAssertNil(answerFormat.minimumDate)
        XCTAssertNil(answerFormat.defaultDate)
        XCTAssertNotNil(answerFormat.maximumDate)
        guard let maximumDate = answerFormat.maximumDate else {
            return
        }
        XCTAssertEqualWithAccuracy(maximumDate.timeIntervalSinceNow, TimeInterval(0), accuracy: 5)
        
    }
    
    func testFactory_TimeConstraints() {
        
        let inputStep:SBBSurveyQuestion = SBBSurveyQuestion()
        inputStep.identifier = "last-smoked"
        inputStep.guid = "2d4b697c-368e-4cda-a30d-0c7dfc38342e"
        inputStep.prompt = "When is the last time you smoked (put todays date if you are still smoking)?"
        inputStep.uiHint = "datetimepicker"
        inputStep.constraints = SBBTimeConstraints()
        
        let step = SBASurveyFactory().createSurveyStepWithSurveyElement(inputStep, index:0, count:1)
        XCTAssertNotNil(step)
        
        guard let surveyStep = step as? SBANavigationQuestionStep else {
            XCTAssert(false, "\(String(describing: step)) is not of expected class type")
            return
        }
    
        XCTAssertEqual(surveyStep.identifier, "last-smoked")
        XCTAssertEqual(surveyStep.text, "When is the last time you smoked (put todays date if you are still smoking)?")

        guard let _ = surveyStep.answerFormat as? ORKTimeOfDayAnswerFormat else {
            XCTAssert(false, "\(String(describing: surveyStep.answerFormat)) is not of expected class type")
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
        
        let step = SBASurveyFactory().createSurveyStepWithSurveyElement(inputStep, index:0, count:1)
        XCTAssertNotNil(step)
        
        guard let surveyStep = step as? SBANavigationQuestionStep else {
            XCTAssert(false, "\(String(describing: step)) is not of expected class type")
            return
        }
        
        XCTAssertEqual(surveyStep.identifier, "last-smoked")
        XCTAssertEqual(surveyStep.text, "When is the last time you smoked (put todays date if you are still smoking)?")

        guard let _ = surveyStep.answerFormat as? ORKTimeIntervalAnswerFormat else {
            XCTAssert(false, "\(String(describing: surveyStep.answerFormat)) is not of expected class type")
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
        
        let step = SBASurveyFactory().createSurveyStepWithSurveyElement(inputStep, index:0, count:1)
        XCTAssertNotNil(step)
        
        guard let surveyStep = step as? SBANavigationQuestionStep else {
            XCTAssert(false, "\(String(describing: step)) or answer format is not of expected class type")
            return
        }
        
        guard let answerFormat = surveyStep.answerFormat as? ORKNumericAnswerFormat else {
                XCTAssert(false, "\(String(describing: surveyStep.answerFormat)) not of expected class type")
                return
        }
        
        XCTAssertEqual(answerFormat.minimum?.intValue, 0)
        XCTAssertEqual(answerFormat.maximum?.intValue, NSIntegerMax)
        XCTAssertEqual(answerFormat.style, ORKNumericAnswerStyle.integer)
        XCTAssertEqual(answerFormat.unit, "weeks")
    }
    
    // MARK: IntegerConstraints
    
    func testFactory_IntegerConstraints() {
        
        let inputStep:SBBSurveyQuestion = createIntegerQuestion()
        inputStep.constraints.addRulesObject(
            SBBSurveyRule(dictionaryRepresentation:         [
                "value" : NSNumber(value: 50 as Int32),
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
        
        let step = SBASurveyFactory().createSurveyStepWithSurveyElement(inputStep, index:0, count:1)
        XCTAssertNotNil(step)
    
        guard let surveyStep = step as? SBANavigationQuestionStep else {
            XCTAssert(false, "\(String(describing: step)) is not of expected class type")
            return
        }
        
        XCTAssertEqual(surveyStep.identifier, "age")
        XCTAssertEqual(surveyStep.text, "How old are you?")
        
        guard let answerFormat = surveyStep.answerFormat as? ORKNumericAnswerFormat else {
                XCTAssert(false, "\(String(describing: surveyStep.answerFormat)) is not of expected class type")
                return
        }
        
        XCTAssertEqual(answerFormat.unit, "years")
        XCTAssertEqual(answerFormat.minimum, NSNumber(value: 18))
        XCTAssertEqual(answerFormat.maximum, NSNumber(value: 100))
        XCTAssertEqual(answerFormat.style, ORKNumericAnswerStyle.integer)
        
        let skipIdentifierIfSkipped = surveyStep.nextStepIdentifier(with: createTaskNumberResult(nil), and: nil)
        XCTAssertEqual(skipIdentifierIfSkipped, "video-usage")
        
        let skipIdentifierIfLessThan = surveyStep.nextStepIdentifier(with: createTaskNumberResult(49), and: nil)
        XCTAssertEqual(skipIdentifierIfLessThan, "video-usage")
        
        let skipIdentifierIfEqualTo = surveyStep.nextStepIdentifier(with: createTaskNumberResult(50), and: nil)
        XCTAssertNil(skipIdentifierIfEqualTo)
        
        let skipIdentifierIfGreaterThan = surveyStep.nextStepIdentifier(with: createTaskNumberResult(51), and: nil)
        XCTAssertNil(skipIdentifierIfGreaterThan)
    }
    
    func testFactory_IntegerConstraints_Equal() {
        
        let inputStep:SBBSurveyQuestion = createIntegerQuestion()
        inputStep.constraints.addRulesObject(
            SBBSurveyRule(dictionaryRepresentation:         [
                "value" : "50",
                "operator" : "eq",
                "skipTo" : "video-usage",
                "type" : "SurveyRule"
                ]))
        
        let step = SBASurveyFactory().createSurveyStepWithSurveyElement(inputStep, index:0, count:1)
        
        guard let surveyStep = step as? SBANavigationQuestionStep else {
            XCTAssert(false, "\(String(describing: step)) does not match expected")
            return
        }
        
        let skipIdentifierIfSkipped = surveyStep.nextStepIdentifier(with: createTaskNumberResult(nil), and: nil)
        XCTAssertNil(skipIdentifierIfSkipped)
        
        let skipIdentifierIfLessThan = surveyStep.nextStepIdentifier(with: createTaskNumberResult(49), and: nil)
        XCTAssertNil(skipIdentifierIfLessThan)
        
        let skipIdentifierIfEqualTo = surveyStep.nextStepIdentifier(with: createTaskNumberResult(50), and: nil)
        XCTAssertEqual(skipIdentifierIfEqualTo, "video-usage")
        
        let skipIdentifierIfGreaterThan = surveyStep.nextStepIdentifier(with: createTaskNumberResult(51), and: nil)
        XCTAssertNil(skipIdentifierIfGreaterThan)
    }
    
    func testFactory_IntegerConstraints_NotEqual() {
        
        let inputStep:SBBSurveyQuestion = createIntegerQuestion()
        inputStep.constraints.addRulesObject(
            SBBSurveyRule(dictionaryRepresentation:         [
                "value" : NSNumber(value: 50 as Int32),
                "operator" : "ne",
                "skipTo" : "video-usage",
                "type" : "SurveyRule"
                ]))
        
        let step = SBASurveyFactory().createSurveyStepWithSurveyElement(inputStep, index:0, count:1)
        
        guard let surveyStep = step as? SBANavigationQuestionStep else {
            XCTAssert(false, "\(String(describing: step)) does not match expected")
            return
        }
        
        let skipIdentifierIfSkipped = surveyStep.nextStepIdentifier(with: createTaskNumberResult(nil), and: nil)
        XCTAssertEqual(skipIdentifierIfSkipped, "video-usage")
        
        let skipIdentifierIfLessThan = surveyStep.nextStepIdentifier(with: createTaskNumberResult(49), and: nil)
        XCTAssertEqual(skipIdentifierIfLessThan, "video-usage")
        
        let skipIdentifierIfEqualTo = surveyStep.nextStepIdentifier(with: createTaskNumberResult(50), and: nil)
        XCTAssertNil(skipIdentifierIfEqualTo)
        
        let skipIdentifierIfGreaterThan = surveyStep.nextStepIdentifier(with: createTaskNumberResult(51), and: nil)
        XCTAssertEqual(skipIdentifierIfGreaterThan, "video-usage")
    }
    
    func testFactory_IntegerConstraints_GreaterThan() {
        
        let inputStep:SBBSurveyQuestion = createIntegerQuestion()
        inputStep.constraints.addRulesObject(
            SBBSurveyRule(dictionaryRepresentation:         [
                "value" : NSNumber(value: 50 as Int32),
                "operator" : "gt",
                "skipTo" : "video-usage",
                "type" : "SurveyRule"
                ]))
        
        let step = SBASurveyFactory().createSurveyStepWithSurveyElement(inputStep, index:0, count:1)
        
        guard let surveyStep = step as? SBANavigationQuestionStep else {
            XCTAssert(false, "\(String(describing: step)) does not match expected")
            return
        }
        
        let skipIdentifierIfSkipped = surveyStep.nextStepIdentifier(with: createTaskNumberResult(nil), and: nil)
        XCTAssertNil(skipIdentifierIfSkipped)
        
        let skipIdentifierIfLessThan = surveyStep.nextStepIdentifier(with: createTaskNumberResult(49), and: nil)
        XCTAssertNil(skipIdentifierIfLessThan)
        
        let skipIdentifierIfEqualTo = surveyStep.nextStepIdentifier(with: createTaskNumberResult(50), and: nil)
        XCTAssertNil(skipIdentifierIfEqualTo)
        
        let skipIdentifierIfGreaterThan = surveyStep.nextStepIdentifier(with: createTaskNumberResult(51), and: nil)
        XCTAssertEqual(skipIdentifierIfGreaterThan, "video-usage")
    }
    
    func testFactory_IntegerConstraints_GreaterThanOrEqual() {
        
        let inputStep:SBBSurveyQuestion = createIntegerQuestion()
        inputStep.constraints.addRulesObject(
            SBBSurveyRule(dictionaryRepresentation:         [
                "value" : NSNumber(value: 50 as Int32),
                "operator" : "ge",
                "skipTo" : "video-usage",
                "type" : "SurveyRule"
                ]))
        
        let step = SBASurveyFactory().createSurveyStepWithSurveyElement(inputStep, index:0, count:1)
        
        guard let surveyStep = step as? SBANavigationQuestionStep else {
            XCTAssert(false, "\(String(describing: step)) does not match expected")
            return
        }
        
        let skipIdentifierIfSkipped = surveyStep.nextStepIdentifier(with: createTaskNumberResult(nil), and: nil)
        XCTAssertNil(skipIdentifierIfSkipped)
        
        let skipIdentifierIfLessThan = surveyStep.nextStepIdentifier(with: createTaskNumberResult(49), and: nil)
        XCTAssertNil(skipIdentifierIfLessThan)
        
        let skipIdentifierIfEqualTo = surveyStep.nextStepIdentifier(with: createTaskNumberResult(50), and: nil)
        XCTAssertEqual(skipIdentifierIfEqualTo, "video-usage")
        
        let skipIdentifierIfGreaterThan = surveyStep.nextStepIdentifier(with: createTaskNumberResult(51), and: nil)
        XCTAssertEqual(skipIdentifierIfGreaterThan, "video-usage")
    }
    
    func testFactory_IntegerConstraints_LessThanOrEqual() {
        
        let inputStep:SBBSurveyQuestion = createIntegerQuestion()
        inputStep.constraints.addRulesObject(
            SBBSurveyRule(dictionaryRepresentation:         [
                "value" : NSNumber(value: 50 as Int32),
                "operator" : "le",
                "skipTo" : "video-usage",
                "type" : "SurveyRule"
                ]))
        
        let step = SBASurveyFactory().createSurveyStepWithSurveyElement(inputStep, index:0, count:1)
        
        guard let surveyStep = step as? SBANavigationQuestionStep else {
                XCTAssert(false, "\(String(describing: step)) does not match expected")
                return
        }
        
        let skipIdentifierIfSkipped = surveyStep.nextStepIdentifier(with: createTaskNumberResult(nil), and: nil)
        XCTAssertNil(skipIdentifierIfSkipped)
        
        let skipIdentifierIfLessThan = surveyStep.nextStepIdentifier(with: createTaskNumberResult(49), and: nil)
        XCTAssertEqual(skipIdentifierIfLessThan, "video-usage")
        
        let skipIdentifierIfEqualTo = surveyStep.nextStepIdentifier(with: createTaskNumberResult(50), and: nil)
        XCTAssertEqual(skipIdentifierIfEqualTo, "video-usage")
        
        let skipIdentifierIfGreaterThan = surveyStep.nextStepIdentifier(with: createTaskNumberResult(51), and: nil)
        XCTAssertNil(skipIdentifierIfGreaterThan)
    }
    
    func testFactory_IntegerConstraints_OtherThan() {
        
        let inputStep:SBBSurveyQuestion = createIntegerQuestion()
        inputStep.constraints.addRulesObject(
            SBBSurveyRule(dictionaryRepresentation:         [
                "value" : NSNumber(value: 50 as Int32),
                "operator" : "ot",
                "skipTo" : "video-usage",
                "type" : "SurveyRule"
                ]))
        
        let step = SBASurveyFactory().createSurveyStepWithSurveyElement(inputStep, index:0, count:1)
        
        guard let surveyStep = step as? SBANavigationQuestionStep else {
            XCTAssert(false, "\(String(describing: step)) does not match expected")
            return
        }
        
        let skipIdentifierIfSkipped = surveyStep.nextStepIdentifier(with: createTaskNumberResult(nil), and: nil)
        XCTAssertEqual(skipIdentifierIfSkipped, "video-usage")
        
        let skipIdentifierIfLessThan = surveyStep.nextStepIdentifier(with: createTaskNumberResult(49), and: nil)
        XCTAssertEqual(skipIdentifierIfLessThan, "video-usage")
        
        let skipIdentifierIfEqualTo = surveyStep.nextStepIdentifier(with: createTaskNumberResult(50), and: nil)
        XCTAssertNil(skipIdentifierIfEqualTo)
        
        let skipIdentifierIfGreaterThan = surveyStep.nextStepIdentifier(with: createTaskNumberResult(51), and: nil)
        XCTAssertEqual(skipIdentifierIfGreaterThan, "video-usage")
    }

    func testFactory_DecimalConstraints() {
        
        let inputStep:SBBSurveyQuestion = SBBSurveyQuestion()
        inputStep.uiHint = "numberfield"
        inputStep.identifier = "age"
        inputStep.guid = "c096d808-2b5b-4151-9e09-0c4ada6028e9"
        inputStep.prompt = "How old\n\nare you?"
        
        let constraints = SBBDecimalConstraints()
        inputStep.constraints = constraints
        constraints.minValue = NSNumber(value: 18.3 as Double)
        constraints.maxValue = NSNumber(value: 100.2 as Double)
        constraints.unit = "years"
        
        inputStep.constraints.addRulesObject(
            SBBSurveyRule(dictionaryRepresentation:         [
                "value" : NSNumber(value: 50.0 as Double),
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
        
        let step = SBASurveyFactory().createSurveyStepWithSurveyElement(inputStep, index:0, count:1)
        XCTAssertNotNil(step)
        
        guard let surveyStep = step as? SBANavigationQuestionStep else {
            XCTAssert(false, "\(String(describing: step)) is not of expected class type")
            return
        }
        
        XCTAssertEqual(surveyStep.identifier, "age")
        XCTAssertEqual(surveyStep.text, "How old are you?")
        
        guard let answerFormat = surveyStep.answerFormat as? ORKNumericAnswerFormat else {
                XCTAssert(false, "\(String(describing: surveyStep.answerFormat)) is not of expected class type")
                return
        }
        
        XCTAssertEqual(answerFormat.unit, "years")
        XCTAssertEqual(answerFormat.minimum, NSNumber(value: 18.3))
        XCTAssertEqual(answerFormat.maximum, NSNumber(value: 100.2))
        XCTAssertEqual(answerFormat.style, ORKNumericAnswerStyle.decimal)
        
        let skipIdentifierIfSkipped = surveyStep.nextStepIdentifier(with: createTaskNumberResult(nil), and: nil)
        XCTAssertEqual(skipIdentifierIfSkipped, "video-usage")
        
        let skipIdentifierIfLessThan = surveyStep.nextStepIdentifier(with: createTaskNumberResult(49), and: nil)
        XCTAssertEqual(skipIdentifierIfLessThan, "video-usage")
        
        let skipIdentifierIfEqualTo = surveyStep.nextStepIdentifier(with: createTaskNumberResult(50), and: nil)
        XCTAssertNil(skipIdentifierIfEqualTo)
        
        let skipIdentifierIfGreaterThan = surveyStep.nextStepIdentifier(with: createTaskNumberResult(51), and: nil)
        XCTAssertNil(skipIdentifierIfGreaterThan)
        
    }
    
    func testFactory_DecimalConstraints_Slider() {
        
        let inputStep:SBBSurveyQuestion = SBBSurveyQuestion()
        inputStep.uiHint = "slider"
        inputStep.identifier = "age"
        inputStep.guid = "c096d808-2b5b-4151-9e09-0c4ada6028e9"
        inputStep.prompt = "How old\n\nare you?"
        
        let constraints = SBBDecimalConstraints()
        inputStep.constraints = constraints
        constraints.minValue = NSNumber(value: 18.3 as Double)
        constraints.maxValue = NSNumber(value: 100.2 as Double)
        constraints.step = NSNumber(value: 0.1 as Double)
        
        let step = SBASurveyFactory().createSurveyStepWithSurveyElement(inputStep, index:0, count:1)
        XCTAssertNotNil(step)
        
        guard let surveyStep = step as? SBANavigationQuestionStep else {
            XCTAssert(false, "\(String(describing: step)) is not of expected class type")
            return
        }
        
        XCTAssertEqual(surveyStep.identifier, "age")
        XCTAssertEqual(surveyStep.text, "How old are you?")
        
        guard let answerFormat = surveyStep.answerFormat as? ORKContinuousScaleAnswerFormat else {
            XCTAssert(false, "\(String(describing: surveyStep.answerFormat)) is not of expected class type")
            return
        }
        
        XCTAssertEqual(answerFormat.minimum, 18.3)
        XCTAssertEqual(answerFormat.maximum, 100.2)
        XCTAssertEqual(answerFormat.maximumFractionDigits, 1)
    }
    
    // MARK: IntegerConstraint with uiHint == slider
    
    func testFactory_IntegerSlider_step0_10() {
        
        let inputStep:SBBSurveyQuestion = createSliderQuestion(1, min:0, max:10)
        
        let step = SBASurveyFactory().createSurveyStepWithSurveyElement(inputStep, index:0, count:1)
        XCTAssertNotNil(step)
        
        guard let surveyStep = step as? SBANavigationQuestionStep,
            let scaleFormat = surveyStep.answerFormat as? ORKScaleAnswerFormat else {
                XCTAssert(false, "\(String(describing: step)) Not of expected class")
                return
        }
        
        XCTAssertEqual(scaleFormat.step, 1)
        XCTAssertEqual(scaleFormat.minimum, 0)
        XCTAssertEqual(scaleFormat.maximum, 10)
    }
    
    func testFactory_IntegerSlider_step100() {
        
        let inputStep:SBBSurveyQuestion = createSliderQuestion(100)
        
        let step = SBASurveyFactory().createSurveyStepWithSurveyElement(inputStep, index:0, count:1)
        XCTAssertNotNil(step)
        
        guard let surveyStep = step as? SBANavigationQuestionStep,
            let scaleFormat = surveyStep.answerFormat as? ORKScaleAnswerFormat else {
                XCTAssert(false, "\(String(describing: step)) Not of expected class")
                return
        }
        
        XCTAssertEqual(scaleFormat.step, 100)
    }
    
    func testFactory_IntegerSlider_step5() {
        
        let inputStep:SBBSurveyQuestion = createSliderQuestion(5)
        
        let step = SBASurveyFactory().createSurveyStepWithSurveyElement(inputStep, index:0, count:1)
        XCTAssertNotNil(step)
        
        // ResearchKit requires that number of steps between min and max value are >= 1 and <= 13
        // so if there would be more than 13 steps (100/5 == 20) then use continuous scale
        guard let surveyStep = step as? SBANavigationQuestionStep,
            let scaleFormat = surveyStep.answerFormat as? ORKContinuousScaleAnswerFormat else {
                XCTAssert(false, "\(String(describing: step)) is not of expected format")
                return
        }

        XCTAssertEqual(scaleFormat.maximumFractionDigits, 0)
        XCTAssertEqual(scaleFormat.minimum, 0.0)
        XCTAssertEqual(scaleFormat.maximum, 100.0)
    }
    
    func testFactory_IntegerSlider_step25() {
        
        let inputStep:SBBSurveyQuestion = createSliderQuestion(25)
        
        let step = SBASurveyFactory().createSurveyStepWithSurveyElement(inputStep, index:0, count:1)
        XCTAssertNotNil(step)
        
        guard let surveyStep = step as? SBANavigationQuestionStep,
            let scaleFormat = surveyStep.answerFormat as? ORKScaleAnswerFormat else {
                XCTAssert(false, "\(String(describing: step)) is not of expected format")
                return
        }
        
        XCTAssertEqual(scaleFormat.step, 25)
        XCTAssertEqual(scaleFormat.minimum, 0)
        XCTAssertEqual(scaleFormat.maximum, 100)
    }

    func testFactory_IntegerSlider_stepNil() {
        
        let inputStep:SBBSurveyQuestion = createSliderQuestion(nil)
        
        let step = SBASurveyFactory().createSurveyStepWithSurveyElement(inputStep, index:0, count:1)
        XCTAssertNotNil(step)
        
        // If the step size is not defined, but the slider uiHint is set,
        // then should be step size == 1. This will result in more than 13 step intervals
        // so the returned class should be continuous scale
        guard let surveyStep = step as? SBANavigationQuestionStep,
            let scaleFormat = surveyStep.answerFormat as? ORKContinuousScaleAnswerFormat else {
                XCTAssert(false, "\(String(describing: step)) is not of expected format")
                return
        }
        
        XCTAssertEqual(scaleFormat.maximumFractionDigits, 0)
        XCTAssertEqual(scaleFormat.minimum, 0.0)
        XCTAssertEqual(scaleFormat.maximum, 100.0)
    }
    
    func testFactory_IntegerSlider_stepInvalid() {
        
        let inputStep:SBBSurveyQuestion = createSliderQuestion(37)
        
        let step = SBASurveyFactory().createSurveyStepWithSurveyElement(inputStep, index:0, count:1)
        XCTAssertNotNil(step)
        
        // a step size of 37 is not divisible by 100 so is invalid as an integer
        // scale with discrete steps.
        guard let surveyStep = step as? SBANavigationQuestionStep,
            let _ = surveyStep.answerFormat as? ORKContinuousScaleAnswerFormat else {
            XCTAssert(false, "\(String(describing: step)) Not of expected class")
            return
        }
    }
    
    func testFactory_UsesTitleAndText() {
        
        let instructionStep = SBBSurveyInfoScreen()
        instructionStep.identifier = "abc123"
        instructionStep.title = "Title"
        instructionStep.prompt = "Text"
        instructionStep.promptDetail = "Detail"
        
        let inputStep1 = SBBSurveyQuestion()
        inputStep1.identifier = "question1"
        inputStep1.guid = "216a6a73-86dc-432a-bb6a-71a8b7cf4be1"
        inputStep1.uiHint = "checkbox"
        inputStep1.prompt = "Question 1"
        inputStep1.promptDetail = "Do you live alone?"
        inputStep1.constraints = SBBBooleanConstraints();
        
        let inputStep2 = SBBSurveyQuestion()
        inputStep2.identifier = "question2"
        inputStep2.guid = "216a6a73-86dc-432a-bb6a-71a8b7cf4be1"
        inputStep2.uiHint = "checkbox"
        inputStep2.prompt = "Question 2"
        inputStep2.constraints = SBBBooleanConstraints();
        
        let inputStep3 = SBBSurveyQuestion()
        inputStep3.identifier = "question3"
        inputStep3.guid = "216a6a73-86dc-432a-bb6a-71a8b7cf4be1"
        inputStep3.uiHint = "checkbox"
        inputStep3.prompt = "Question 3"
        inputStep3.constraints = SBBBooleanConstraints();
        
        let survey = SBBSurvey()
        survey.createdOn = Date()
        survey.guid = NSUUID().uuidString
        survey.identifier = "test"
        survey.addElementsObject(instructionStep)
        survey.addElementsObject(inputStep1)
        survey.addElementsObject(inputStep2)
        survey.addElementsObject(inputStep3)
        
        let task = SBASurveyFactory().createTaskWithSurvey(survey)
        let steps = task.steps
        
        guard steps.count == 4 else {
            XCTAssert(false, "\(task) does not have expected steps: \(task.steps)")
            return
        }
        
        // If one of the questions has a title, then all the questions should
        XCTAssertEqual(steps[0].title, "Title")
        XCTAssertEqual(steps[1].title, "Question 1")
        XCTAssertEqual(steps[2].title, "Question 2")
        XCTAssertEqual(steps[3].title, "Question 3")
        
        XCTAssertEqual(steps[0].text, "Text")
        XCTAssertEqual(steps[1].text, "Do you live alone?")
        XCTAssertNil(steps[2].text)
        XCTAssertNil(steps[3].text)
    }
    
    func testFactory_UsesTextOnly() {
        
        let instructionStep = SBBSurveyInfoScreen()
        instructionStep.identifier = "abc123"
        instructionStep.title = "Title"
        instructionStep.prompt = "Text"
        instructionStep.promptDetail = "Detail"
        
        let inputStep1 = SBBSurveyQuestion()
        inputStep1.identifier = "question1"
        inputStep1.guid = "216a6a73-86dc-432a-bb6a-71a8b7cf4be1"
        inputStep1.uiHint = "checkbox"
        inputStep1.prompt = "Question 1"
        inputStep1.constraints = SBBBooleanConstraints();
        
        let inputStep2 = SBBSurveyQuestion()
        inputStep2.identifier = "question2"
        inputStep2.guid = "216a6a73-86dc-432a-bb6a-71a8b7cf4be1"
        inputStep2.uiHint = "checkbox"
        inputStep2.prompt = "Question 2"
        inputStep2.constraints = SBBBooleanConstraints();
        
        let inputStep3 = SBBSurveyQuestion()
        inputStep3.identifier = "question3"
        inputStep3.guid = "216a6a73-86dc-432a-bb6a-71a8b7cf4be1"
        inputStep3.uiHint = "checkbox"
        inputStep3.prompt = "Question 3"
        inputStep3.constraints = SBBBooleanConstraints();
        
        let survey = SBBSurvey()
        survey.createdOn = Date()
        survey.guid = NSUUID().uuidString
        survey.identifier = "test"
        survey.addElementsObject(instructionStep)
        survey.addElementsObject(inputStep1)
        survey.addElementsObject(inputStep2)
        survey.addElementsObject(inputStep3)
        
        let task = SBASurveyFactory().createTaskWithSurvey(survey)
        let steps = task.steps
        
        guard steps.count == 4 else {
            XCTAssert(false, "\(task) does not have expected steps: \(task.steps)")
            return
        }
        
        // If one of the questions has a title, then all the questions should
        XCTAssertEqual(steps[0].title, "Title")
        XCTAssertNil(steps[1].title)
        XCTAssertNil(steps[2].title)
        XCTAssertNil(steps[3].title)
        
        XCTAssertEqual(steps[0].text, "Text")
        XCTAssertEqual(steps[1].text, "Question 1")
        XCTAssertEqual(steps[2].text, "Question 2")
        XCTAssertEqual(steps[3].text, "Question 3")
    }
    
    
    // MARK: Helper methods

    func createMultipleChoiceQuestion(allowMultiple: Bool) -> SBBSurveyQuestion {
        let inputStep:SBBSurveyQuestion = SBBSurveyQuestion()
        inputStep.uiHint = "radiobutton"
        inputStep.identifier = "medical-usage"
        inputStep.guid = "c564984a-0951-48b5-a490-43d07aa04886"
        inputStep.prompt = "Do you ever use your smartphone to look for health or medical information online?"
        
        let constraints = SBBMultiValueConstraints()
        constraints.allowMultiple = NSNumber(value: allowMultiple as Bool)
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
        constraints.minValue = NSNumber(value: 18 as Int32)
        constraints.maxValue = NSNumber(value: 100 as Int32)
        constraints.unit = "years"
        
        return inputStep;
    }
    
    func createSliderQuestion(_ step: Int32?, min:Int32 = 0, max: Int32 = 100) -> SBBSurveyQuestion {
        
        let inputStep:SBBSurveyQuestion = SBBSurveyQuestion()
        inputStep.identifier = "age"
        inputStep.guid = "c096d808-2b5b-4151-9e09-0c4ada6028e9"
        inputStep.prompt = "How old are you?"
        inputStep.uiHint = "slider"
        
        let constraints = SBBIntegerConstraints()
        inputStep.constraints = constraints
        constraints.minValue = NSNumber(value: min)
        constraints.maxValue = NSNumber(value: max)
        constraints.unit = "years"
        if let step = step {
            constraints.step = NSNumber(value: step as Int32)
        }
        
        return inputStep;
    }

    func createTaskBooleanResult(_ answer: Bool?) -> ORKTaskResult {
        let questionResult = ORKBooleanQuestionResult(identifier:"living-alone-status")
        if let booleanAnswer = answer {
            questionResult.booleanAnswer = booleanAnswer as NSNumber?
        }
        let stepResult = ORKStepResult(stepIdentifier: "living-alone-status", results: [questionResult])
        let taskResult = ORKTaskResult(identifier: "task")
        taskResult.results = [ORKStepResult(identifier: "introduction"), stepResult]
        return taskResult
    }
    
    func createTaskChoiceResult(_ answer: [Any]?) -> ORKTaskResult {
        let questionResult = ORKChoiceQuestionResult(identifier:"medical-usage")
        questionResult.choiceAnswers = answer
        let stepResult = ORKStepResult(stepIdentifier: "medical-usage", results: [questionResult])
        let taskResult = ORKTaskResult(identifier: "task")
        taskResult.results = [ORKStepResult(identifier: "introduction"), stepResult]
        return taskResult
    }
    
    func createTaskNumberResult(_ answer: Int?) -> ORKTaskResult {
        let questionResult = ORKNumericQuestionResult(identifier: "age")
        if let numericAnswer = answer {
            questionResult.numericAnswer = numericAnswer as NSNumber?
        }
        let stepResult = ORKStepResult(stepIdentifier: "age", results: [questionResult])
        let taskResult = ORKTaskResult(identifier: "task")
        taskResult.results = [ORKStepResult(identifier: "introduction"), stepResult]
        return taskResult
    }
    
}
