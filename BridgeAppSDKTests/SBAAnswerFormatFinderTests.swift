//
//  SBAAnswerFormatFinderTests.swift
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
@testable import BridgeAppSDK

class SBAAnswerFormatFinderTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testAnswerFormatFinder_FormStep() {
        let answerFormat = ORKBooleanAnswerFormat()
        let formItemB = ORKFormItem(identifier: "test", text: nil, answerFormat: answerFormat)
        let textFormat = ORKTextAnswerFormat()
        let formItemA = ORKFormItem(identifier: "textAnswer", text: nil, answerFormat: textFormat)
        
        let step = ORKFormStep(identifier: "formStep")
        step.formItems = [formItemA, formItemB]
        
        let found = step.find(for: "test")
        XCTAssertNotNil(found)
        XCTAssertEqual(found, answerFormat)
        
        let notFound = step.find(for: "null")
        XCTAssertNil(notFound)
        
        let resultId = step.resultIdentifier(for: "test")
        XCTAssertNotNil(resultId)
        XCTAssertEqual(resultId?.identifier, "test")
        XCTAssertEqual(resultId?.stepIdentifier, "formStep")
    }
    
    func testAnswerFormatFinder_QuestionStep() {
        let answerFormat = ORKBooleanAnswerFormat()
        
        let step = ORKQuestionStep(identifier: "test", title: nil, answer: answerFormat)
        
        let found = step.find(for: "test")
        XCTAssertNotNil(found)
        XCTAssertEqual(found, answerFormat)
        
        let notFound = step.find(for: "null")
        XCTAssertNil(notFound)
        
        let resultId = step.resultIdentifier(for: "test")
        XCTAssertNotNil(resultId)
        XCTAssertEqual(resultId?.identifier, "test")
        XCTAssertEqual(resultId?.stepIdentifier, "test")
    }
    
    func testAnswerFormatFinder_OrderedTask() {
        
        let preFormStep = ORKFormStep(identifier: "textAnswer_initial")
        preFormStep.formItems = [ORKFormItem(identifier: "boolAnswer", text: nil, answerFormat: ORKBooleanAnswerFormat())]
        
        let questionFormat = ORKBooleanAnswerFormat()
        let questionStep = ORKQuestionStep(identifier: "questionAnswer", title: nil, answer: questionFormat)
        
        let answerFormat = ORKBooleanAnswerFormat()
        let formItemB = ORKFormItem(identifier: "boolAnswer", text: nil, answerFormat: answerFormat)
        let textFormat = ORKTextAnswerFormat()
        let formItemA = ORKFormItem(identifier: "textAnswer", text: nil, answerFormat: textFormat)
        
        let formStep = ORKFormStep(identifier: "formStep")
        formStep.formItems = [formItemA, formItemB]
        
        let task = ORKOrderedTask(identifier: "task", steps: [preFormStep, questionStep, formStep])
        
        let foundQuestion = task.find(for: "questionAnswer")
        XCTAssertNotNil(foundQuestion)
        XCTAssertTrue(foundQuestion === questionFormat)
        
        let foundBool = task.find(for: "boolAnswer")
        XCTAssertNotNil(foundBool)
        XCTAssertTrue(foundBool === answerFormat)
        
        let resultId = task.resultIdentifier(for: "boolAnswer")
        XCTAssertNotNil(resultId)
        XCTAssertEqual(resultId?.identifier, "boolAnswer")
        XCTAssertEqual(resultId?.stepIdentifier, "formStep")
    }
    
    func testAnswerFormatFinder_PageStep() {
        
        let preFormStep = ORKFormStep(identifier: "textAnswer_initial")
        preFormStep.formItems = [ORKFormItem(identifier: "boolAnswer", text: nil, answerFormat: ORKBooleanAnswerFormat())]
        
        let questionFormat = ORKBooleanAnswerFormat()
        let questionStep = ORKQuestionStep(identifier: "questionAnswer", title: nil, answer: questionFormat)
        
        let answerFormat = ORKBooleanAnswerFormat()
        let formItemB = ORKFormItem(identifier: "boolAnswer", text: nil, answerFormat: answerFormat)
        let textFormat = ORKTextAnswerFormat()
        let formItemA = ORKFormItem(identifier: "textAnswer", text: nil, answerFormat: textFormat)
        
        let formStep = ORKFormStep(identifier: "formStep")
        formStep.formItems = [formItemA, formItemB]
        
        let step = ORKPageStep(identifier: "page", steps: [preFormStep, questionStep, formStep])
        
        let foundQuestion = step.find(for: "questionAnswer")
        XCTAssertNotNil(foundQuestion)
        XCTAssertTrue(foundQuestion === questionFormat)
        
        let foundBool = step.find(for: "boolAnswer")
        XCTAssertNotNil(foundBool)
        XCTAssertTrue(foundBool === answerFormat)
        
        let resultId = step.resultIdentifier(for: "boolAnswer")
        XCTAssertNotNil(resultId)
        XCTAssertEqual(resultId?.identifier, "formStep.boolAnswer")
        XCTAssertEqual(resultId?.stepIdentifier, "page")
    }
    
    func testAnswerFormatFinder_SubtaskStep() {
        
        let preFormStep = ORKFormStep(identifier: "textAnswer_initial")
        preFormStep.formItems = [ORKFormItem(identifier: "boolAnswer", text: nil, answerFormat: ORKBooleanAnswerFormat())]
        
        let questionFormat = ORKBooleanAnswerFormat()
        let questionStep = ORKQuestionStep(identifier: "questionAnswer", title: nil, answer: questionFormat)
        
        let answerFormat = ORKBooleanAnswerFormat()
        let formItemB = ORKFormItem(identifier: "boolAnswer", text: nil, answerFormat: answerFormat)
        let textFormat = ORKTextAnswerFormat()
        let formItemA = ORKFormItem(identifier: "textAnswer", text: nil, answerFormat: textFormat)
        
        let formStep = ORKFormStep(identifier: "formStep")
        formStep.formItems = [formItemA, formItemB]
        
        let task = ORKOrderedTask(identifier: "task", steps: [preFormStep, questionStep, formStep])
        let step = SBASubtaskStep(subtask: task)
        
        let foundQuestion = step.find(for: "questionAnswer")
        XCTAssertNotNil(foundQuestion)
        XCTAssertTrue(foundQuestion === questionFormat)
        
        let foundBool = step.find(for: "boolAnswer")
        XCTAssertNotNil(foundBool)
        XCTAssertTrue(foundBool === answerFormat)
        
        let resultId = step.resultIdentifier(for: "boolAnswer")
        XCTAssertNotNil(resultId)
        XCTAssertEqual(resultId?.identifier, "boolAnswer")
        XCTAssertEqual(resultId?.stepIdentifier, "task.formStep")
    }
}
