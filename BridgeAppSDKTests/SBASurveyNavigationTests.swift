//
//  SBASurveyNavigationTests.swift
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

class SBASurveyNavigationTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testQuizStep_Boolean_YES_Passed() {
        
        // Create the form step question
        let formStep = self.createBooleanQuizStep([true])
        let result = self.createBooleanTaskResult([true])
        
        // If the question should skip failed passed then the next step identifier is nil
        // which results in a navigation drop through
        formStep.skipIfPassed = false
        let nextStepIdentifier1 = formStep.nextStepIdentifier(with: result, and: nil)
        XCTAssertNil(nextStepIdentifier1)
        
        // If the question should skip if it passes then the next step identifier should
        // be for the step to skip to
        formStep.skipIfPassed = true
        let nextStepIdentifier2 = formStep.nextStepIdentifier(with: result, and: nil)
        XCTAssertNotNil(nextStepIdentifier2)
        XCTAssertEqual(nextStepIdentifier2, "skip")
    }
    
    func testQuizStep_Boolean_YES_Failed() {
        
        // Create the form step question
        let formStep = self.createBooleanQuizStep([true])
        let result = self.createBooleanTaskResult([false])
        
        // If the question should skip if it passes then a FAILED result should drop through
        formStep.skipIfPassed = true
        let nextStepIdentifier1 = formStep.nextStepIdentifier(with: result, and: nil)
        XCTAssertNil(nextStepIdentifier1)
        
        // If the question should NOT skip if it passes then a FAILED result should return the
        // skip step identifier
        formStep.skipIfPassed = false
        let nextStepIdentifier2 = formStep.nextStepIdentifier(with: result, and: nil)
        XCTAssertNotNil(nextStepIdentifier2)
        XCTAssertEqual(nextStepIdentifier2, "skip")
    }
    
    func testQuizStep_Boolean_NO_Passed() {
        
        // Create the form step question
        let formStep = self.createBooleanQuizStep([false])
        let result = self.createBooleanTaskResult([false])
        
        // If the question should skip failed passed then the next step identifier is nil
        // which results in a navigation drop through
        formStep.skipIfPassed = false
        let nextStepIdentifier1 = formStep.nextStepIdentifier(with: result, and: nil)
        XCTAssertNil(nextStepIdentifier1)
        
        // If the question should skip if it passes then the next step identifier should
        // be for the step to skip to
        formStep.skipIfPassed = true
        let nextStepIdentifier2 = formStep.nextStepIdentifier(with: result, and: nil)
        XCTAssertNotNil(nextStepIdentifier2)
        XCTAssertEqual(nextStepIdentifier2, "skip")
    }
    
    func testQuizStep_Boolean_NO_Failed() {
        
        // Create the form step question
        let formStep = self.createBooleanQuizStep([false])
        let result = self.createBooleanTaskResult([true])
        
        // If the question should skip if it passes then a FAILED result should drop through
        formStep.skipIfPassed = true
        let nextStepIdentifier1 = formStep.nextStepIdentifier(with: result, and: nil)
        XCTAssertNil(nextStepIdentifier1)
        
        // If the question should NOT skip if it passes then a FAILED result should return the
        // skip step identifier
        formStep.skipIfPassed = false
        let nextStepIdentifier2 = formStep.nextStepIdentifier(with: result, and: nil)
        XCTAssertNotNil(nextStepIdentifier2)
        XCTAssertEqual(nextStepIdentifier2, "skip")
    }
    
    func testMultipleFormItemQuizStep_Passed() {
        // Create the form step question
        let formStep = self.createBooleanQuizStep([true, false, true])
        let result = self.createBooleanTaskResult([true, false, true])
        
        // If the question should skip failed passed then the next step identifier is nil
        // which results in a navigation drop through
        formStep.skipIfPassed = false
        let nextStepIdentifier1 = formStep.nextStepIdentifier(with: result, and: nil)
        XCTAssertNil(nextStepIdentifier1)
        
        // If the question should skip if it passes then the next step identifier should
        // be for the step to skip to
        formStep.skipIfPassed = true
        let nextStepIdentifier2 = formStep.nextStepIdentifier(with: result, and: nil)
        XCTAssertNotNil(nextStepIdentifier2)
        XCTAssertEqual(nextStepIdentifier2, "skip")
    }
    
    func testMultipleFormItemQuizStep_Failed() {
        // Create the form step question
        let formStep = self.self.createBooleanQuizStep([true, false, true])
        let result = self.createBooleanTaskResult([true, true, true])
        
        // If the question should skip if it passes then a FAILED result should drop through
        formStep.skipIfPassed = true
        let nextStepIdentifier1 = formStep.nextStepIdentifier(with: result, and: nil)
        XCTAssertNil(nextStepIdentifier1)
        
        // If the question should NOT skip if it passes then a FAILED result should return the
        // skip step identifier
        formStep.skipIfPassed = false
        let nextStepIdentifier2 = formStep.nextStepIdentifier(with: result, and: nil)
        XCTAssertNotNil(nextStepIdentifier2)
        XCTAssertEqual(nextStepIdentifier2, "skip")
    }
    
    func testTextChoiceQuizStep_Passed() {
        // Create the form step question
        let formStep = self.createTextChoiceQuizStep()
        let result = self.createTextChoiceTaskResult(true)
        
        // If the question should skip failed passed then the next step identifier is nil
        // which results in a navigation drop through
        formStep.skipIfPassed = false
        let nextStepIdentifier1 = formStep.nextStepIdentifier(with: result, and: nil)
        XCTAssertNil(nextStepIdentifier1)
        
        // If the question should skip if it passes then the next step identifier should
        // be for the step to skip to
        formStep.skipIfPassed = true
        let nextStepIdentifier2 = formStep.nextStepIdentifier(with: result, and: nil)
        XCTAssertNotNil(nextStepIdentifier2)
        XCTAssertEqual(nextStepIdentifier2, "skip")
    }
    
    func testTextChoiceQuizStep_Failed() {
        // Create the form step question
        let formStep = self.createTextChoiceQuizStep()
        let result = self.createTextChoiceTaskResult(false)
        
        // If the question should skip failed passed then the next step identifier is nil
        // which results in a navigation drop through
        formStep.skipIfPassed = true
        let nextStepIdentifier1 = formStep.nextStepIdentifier(with: result, and: nil)
        XCTAssertNil(nextStepIdentifier1)
        
        // If the question should skip if it passes then the next step identifier should
        // be for the step to skip to
        formStep.skipIfPassed = false
        let nextStepIdentifier2 = formStep.nextStepIdentifier(with: result, and: nil)
        XCTAssertNotNil(nextStepIdentifier2)
        XCTAssertEqual(nextStepIdentifier2, "skip")
    }
    
    func testTextChoiceQuizStep_Skipped() {
        // Create the form step question
        let formStep = self.createTextChoiceQuizStep()
        let result = self.createTaskResult("quiz", questionResults: nil)
        
        // If the question should skip failed passed then the next step identifier is nil
        // which results in a navigation drop through
        formStep.skipIfPassed = true
        let nextStepIdentifier1 = formStep.nextStepIdentifier(with: result, and: nil)
        XCTAssertNil(nextStepIdentifier1)
        
        // If the question should skip if it passes then the next step identifier should
        // be for the step to skip to
        formStep.skipIfPassed = false
        let nextStepIdentifier2 = formStep.nextStepIdentifier(with: result, and: nil)
        XCTAssertNotNil(nextStepIdentifier2)
        XCTAssertEqual(nextStepIdentifier2, "skip")
    }

    func testSubtaskQuizStep_Passed() {
        let subtaskStep = self.createSubtaskQuizStep([true as AnyObject, false as AnyObject, "b" as AnyObject])
        let result = self.createSubtaskTaskResult([true as AnyObject, false as AnyObject, "b" as AnyObject])
        
        // If the question should skip failed passed then the next step identifier is nil
        // which results in a navigation drop through
        subtaskStep.skipIfPassed = false
        let nextStepIdentifier1 = subtaskStep.nextStepIdentifier(with: result, and: nil)
        XCTAssertNil(nextStepIdentifier1)
        
        // If the question should skip if it passes then the next step identifier should
        // be for the step to skip to
        subtaskStep.skipIfPassed = true
        let nextStepIdentifier2 = subtaskStep.nextStepIdentifier(with: result, and: nil)
        XCTAssertNotNil(nextStepIdentifier2)
        XCTAssertEqual(nextStepIdentifier2, "skip")
    }
    
    func testSubtaskQuizStep_Failed() {
        let subtaskStep = self.createSubtaskQuizStep([true as AnyObject, false as AnyObject, "b" as AnyObject])
        let result = self.createSubtaskTaskResult([true as AnyObject, true as AnyObject, "b" as AnyObject])
        
        // If the question should skip failed passed then the next step identifier is nil
        // which results in a navigation drop through
        subtaskStep.skipIfPassed = true
        let nextStepIdentifier1 = subtaskStep.nextStepIdentifier(with: result, and: nil)
        XCTAssertNil(nextStepIdentifier1)
        
        // If the question should skip if it passes then the next step identifier should
        // be for the step to skip to
        subtaskStep.skipIfPassed = false
        let nextStepIdentifier2 = subtaskStep.nextStepIdentifier(with: result, and: nil)
        XCTAssertNotNil(nextStepIdentifier2)
        XCTAssertEqual(nextStepIdentifier2, "skip")
    }
    
    func testSubtaskQuizStep_Loop() {
        let subtaskStep = self.createSubtaskQuizStep([true as AnyObject, false as AnyObject, "b" as AnyObject])
        let result = self.createSubtaskTaskResult(loopResults:[
            [true as AnyObject, true as AnyObject, "b" as AnyObject],       // failed results
            [true as AnyObject, false as AnyObject, "b" as AnyObject]])     // passed results
        
        // If the question should skip failed passed then the next step identifier is nil
        // which results in a navigation drop through
        subtaskStep.skipIfPassed = false
        let nextStepIdentifier1 = subtaskStep.nextStepIdentifier(with: result, and: nil)
        XCTAssertNil(nextStepIdentifier1)
        
        // If the question should skip if it passes then the next step identifier should
        // be for the step to skip to
        subtaskStep.skipIfPassed = true
        let nextStepIdentifier2 = subtaskStep.nextStepIdentifier(with: result, and: nil)
        XCTAssertNotNil(nextStepIdentifier2)
        XCTAssertEqual(nextStepIdentifier2, "skip")
    }
    
    func testSubtaskQuizStep_Skipped() {
        let subtaskStep = self.createSubtaskQuizStep([true as AnyObject, false as AnyObject, "b" as AnyObject])
        let result = self.createSubtaskTaskResult([true as AnyObject, false as AnyObject, NSNull()])
        
        // If the question should skip failed passed then the next step identifier is nil
        // which results in a navigation drop through
        subtaskStep.skipIfPassed = true
        let nextStepIdentifier1 = subtaskStep.nextStepIdentifier(with: result, and: nil)
        XCTAssertNil(nextStepIdentifier1)
        
        // If the question should skip if it passes then the next step identifier should
        // be for the step to skip to
        subtaskStep.skipIfPassed = false
        let nextStepIdentifier2 = subtaskStep.nextStepIdentifier(with: result, and: nil)
        XCTAssertNotNil(nextStepIdentifier2)
        XCTAssertEqual(nextStepIdentifier2, "skip")
    }
    
    // MARK: helper methods
    
    func createSubtaskQuizStep(_ expectedAnswers: [AnyObject]) -> SBANavigationSubtaskStep {
        var steps: [ORKStep] = [ORKInstructionStep(identifier: "introduction")]
        for (index, expectedAnswer) in expectedAnswers.enumerated() {
            let identifier = "question\(index+1)"
            let formStep = ORKFormStep(identifier: identifier, title: "Question \(index+1)", text: nil)
            if let expectedAnswer = expectedAnswer as? Bool {
                let formItem = self.createBooleanSurveyFormItem(identifier, text: nil, expectedAnswer: expectedAnswer, optional: true)
                formStep.formItems = [formItem]
            }
            else if let expectedAnswer = expectedAnswer as? String {
                let formItem = self.createSingleTextChoiceSurveyFormItem(identifier, text: nil, choices: ["a","b","c"], values: nil, expectedAnswer: expectedAnswer as NSCoding & NSCopying & NSObjectProtocol, optional: true)
                formStep.formItems = [formItem]
            }
            steps += [formStep]
        }
        let subtaskStep = SBANavigationSubtaskStep(identifier: "quiz", steps: steps)
        subtaskStep.skipToStepIdentifier = "skip"
        return subtaskStep
    }
    
    func createBooleanQuizStep(_ expectedAnswers: [Bool]) -> SBANavigationFormStep {
        // Create the form step question
        let formStep = self.createQuizStep()
        var formItems: [ORKFormItem] = []
        for (index, expectedAnswer) in expectedAnswers.enumerated() {
            let identifier = "question\(index+1)"
            let formItem = self.createBooleanSurveyFormItem(identifier, text: nil, expectedAnswer: expectedAnswer, optional: true)
            formItems += [formItem]
        }
        formStep.formItems = formItems
        return formStep;
    }
    
    func createBooleanSurveyFormItem(_ identifier:String, text:String?, expectedAnswer: Bool, optional:Bool) -> SBANavigationFormItem {
        let answerFormat = ORKBooleanAnswerFormat()
        let formItem = SBANavigationFormItem(identifier: identifier, text: text, answerFormat: answerFormat, optional: optional)
        formItem.rulePredicate = NSPredicate(format: "answer = %@", expectedAnswer as CVarArg)
        return formItem
    }
    
    func createSingleTextChoiceSurveyFormItem(_ identifier:String, text:String?, choices:[String], values:[NSCoding & NSCopying & NSObjectProtocol]?, expectedAnswer: NSCoding & NSCopying & NSObjectProtocol, optional:Bool) -> SBANavigationFormItem {
        let answerFormat = self.createSingleTextChoiceAnswerFormat(choices, values: values)
        let formItem = SBANavigationFormItem(identifier: identifier, text: text, answerFormat: answerFormat, optional: optional)
        formItem.rulePredicate = NSPredicate(format: "answer = %@", [expectedAnswer])
        return formItem
    }
    
    func createSingleTextChoiceAnswerFormat(_ choices:[String], values:[NSCoding & NSCopying & NSObjectProtocol]?) -> ORKTextChoiceAnswerFormat {
        // Create the text choices object from the choices and associated values
        var textChoices: [ORKTextChoice] = []
        for (index, choice) in choices.enumerated() {
            let value = values?[index] ?? choice as NSCoding & NSCopying & NSObjectProtocol
            textChoices += [ORKTextChoice(text: choice, value: value)]
        }
        // Return a survey item of the appropriate type
        return ORKTextChoiceAnswerFormat(style: .singleChoice, textChoices: textChoices)
    }
    
    func createBooleanTaskResult(_ answers: [Bool]) -> ORKTaskResult {
        var questionResults: [ORKQuestionResult] = []
        for (index, answer) in answers.enumerated() {
            let identifier = "question\(index+1)"
            let questionResult = ORKBooleanQuestionResult(identifier:identifier)
            questionResult.booleanAnswer = answer as NSNumber?
            questionResults += [questionResult]
        }
        return self.createTaskResult("quiz", questionResults: questionResults)
    }
    
    func createTextChoiceQuizStep() -> SBANavigationFormStep {
        // Create the form step question
        let formStep = self.createQuizStep()
        let formItem = self.createSingleTextChoiceSurveyFormItem("question1", text: nil, choices: ["a","b","c"], values: nil, expectedAnswer: "b" as NSCoding & NSCopying & NSObjectProtocol, optional: true)
        formStep.formItems = [formItem]
        return formStep;
    }
    
    func createTextChoiceTaskResult(_ passed: Bool) -> ORKTaskResult {
        let questionResult = ORKChoiceQuestionResult(identifier: "question1")
        questionResult.choiceAnswers = passed ? ["b"] : ["a"]
        return self.createTaskResult("quiz", questionResults: [questionResult])
    }
    
    func createQuizStep() -> SBANavigationFormStep {
        let step = SBANavigationFormStep(identifier: "quiz")
        step.skipToStepIdentifier = "skip"
        return step
    }
    
    func createTaskResult(_ quizIdentifier: String, questionResults: [ORKQuestionResult]?) -> ORKTaskResult {
        let introStepResult = ORKStepResult(identifier: "introduction")
        let quizStepResult = ORKStepResult(stepIdentifier: quizIdentifier, results:questionResults)
        let taskResult = ORKTaskResult(identifier: "test");
        taskResult.results = [introStepResult, quizStepResult]
        return taskResult
    }
    
    func createSubtaskTaskResult(_ questionResults: [AnyObject]) -> ORKTaskResult {
        return createSubtaskTaskResult(loopResults: [questionResults])
    }
    
    func createSubtaskTaskResult(loopResults: [[AnyObject]]) -> ORKTaskResult {
        var results: [ORKStepResult] = [ORKStepResult(identifier: "introduction"),
            ORKStepResult(identifier: "quiz.introduction")]
        
        for questionResults in loopResults {
            for (index, answer) in questionResults.enumerated() {
                let identifier = "question\(index+1)"
                var itemResults: [ORKResult]?
                if let answer = answer as? Bool {
                    let questionResult = ORKBooleanQuestionResult(identifier: identifier)
                    questionResult.booleanAnswer = answer as NSNumber?
                    itemResults = [questionResult]
                }
                else if let answer = answer as? String {
                    let questionResult = ORKChoiceQuestionResult(identifier: identifier)
                    questionResult.choiceAnswers = [answer]
                    itemResults = [questionResult]
                }
                let stepResult = ORKStepResult(stepIdentifier: "quiz.\(identifier)", results: itemResults)
                results.append(stepResult)
            }
        }
        
        let taskResult = ORKTaskResult(identifier: "test")
        taskResult.results = results
        return taskResult
    }
}
