//
//  UtilityExtensionTests.swift
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

class UtilityExtensionTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testString_removingNewlineCharacters() {
        let input = "This is a line of text.<br/><br /> This is a second line.<br /> This is a third line.<br/><br/> This is a fourth line.<br/>"
        let expected = "This is a line of text.\n\nThis is a second line.\nThis is a third line.\n\nThis is a fourth line."
        let actual = input.replacingBreaklineHtmlTags()
        XCTAssertEqual(actual, expected)
    }
    
    func testORKTaskResult_consolidatedResults() {
        
        // Create a result set
        var stepResults: [ORKStepResult] = []
        for ii in 0..<5 {
            if (ii != 3) {
                let boolResult = ORKBooleanQuestionResult(identifier: "bool")
                boolResult.booleanAnswer = NSNumber(value: ii < 5)
                let choiceResult = ORKChoiceQuestionResult(identifier: "choice")
                choiceResult.choiceAnswers = [NSNumber(value: 0)]
                stepResults.append(ORKStepResult(stepIdentifier: "step\(ii)", results: [boolResult, choiceResult]))
            }
            else {
                for jj in 0..<3 {
                    let numResult = ORKNumericQuestionResult(identifier: "number")
                    numResult.numericAnswer = NSNumber(value: jj)
                    stepResults.append(ORKStepResult(stepIdentifier: "loopQuestion", results: [numResult]))
                    if jj < 2 {
                        stepResults.append(ORKStepResult(stepIdentifier: "loopInstruction", results: nil))
                    }
                }
            }
        }
        
        // Create the task with a copy of the original set
        let taskResult = ORKTaskResult(identifier: "test")
        taskResult.results = stepResults.map({  $0.copy() as! ORKResult })
        
        // -- method under test
        let consolidatedResults = taskResult.consolidatedResults()
        
        // The consolidated results should be copies
        for stepResult in consolidatedResults {
            let isIdentical = stepResults.contains(where: { (sResult) -> Bool in
                return stepResult === sResult
            })
            XCTAssertFalse(isIdentical, "\(stepResult)")
        }
        
        // The task results should be unmutated
        XCTAssertEqual(stepResults, taskResult.results!)
        
        // There should only be one loopInstruction and loopQuestion
        let loopInstruction = consolidatedResults.filter({ $0.identifier == "loopInstruction" })
        XCTAssertEqual(loopInstruction.count, 1)
        
        let loopQuestions = consolidatedResults.filter({ $0.identifier == "loopQuestion" })
        XCTAssertEqual(loopQuestions.count, 1)
        
        guard let loopQuestion = loopQuestions.first, let results = loopQuestion.results else {
            XCTAssert(false, "\(loopQuestions) did not match expected")
            return
        }
        XCTAssertEqual(results.count, 3)
        let lastResult = results.find(withIdentifier: "number")
        XCTAssertNotNil(lastResult)
        XCTAssertNotNil(results.find(withIdentifier: "number_dup1"))
        XCTAssertNotNil(results.find(withIdentifier: "number_dup2"))
        
        guard let numResult = lastResult as? ORKNumericQuestionResult, let numAnswer = numResult.numericAnswer else {
            XCTAssert(false, "\(lastResult) did not match expected")
            return
        }
        
        XCTAssertEqual(numAnswer.intValue, 2)
    }
}
