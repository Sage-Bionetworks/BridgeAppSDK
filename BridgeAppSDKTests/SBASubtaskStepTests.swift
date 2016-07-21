//
//  SBASubtaskStepTests.swift
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

class SBASubtaskStepTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testMutatedResultSet() {

        // If a subtask mutates the result set, these mutated results need to be carried back
        let inputIntro: NSDictionary = [
            "identifier" : "intruction",
            "prompt" : "This is a test",
            "type"  : "instruction"]
        
        let inputQ1: NSDictionary = [
            "identifier" : "question1",
            "type" : "singleChoiceText",
            "prompt" : "Question 1?",
            "items" : ["a", "b", "c"],
        ]
        
        let inputQ2: NSDictionary = [
            "identifier" : "question2",
            "type" : "boolean",
            "prompt" : "Are you older than 18?",
        ]
        
        let conclusion: NSDictionary = [
            "identifier" : "completion",
            "prompt" : "You are done.",
            "type"  : "completion"]
        
        let factory = SBASurveyFactory()
        let items = [inputIntro, inputQ1, inputQ2, conclusion]
        let steps = items.mapAndFilter({ factory.createSurveyStepWithDictionary($0) })
        let task = MutatedResultTask(identifier: "Mutating Task", steps: steps)
        let subtaskStep = SBASubtaskStep(subtask: task)
        
        let firstStep = steps.first!.copy() as! ORKStep
        let lastStep = steps.last!.copy() as! ORKStep
        let navTask = SBANavigableOrderedTask(identifier: "Parent Task", steps: [firstStep, subtaskStep, lastStep])
        
        let taskResult = ORKTaskResult(identifier: "Parent Task")
        
        let step1 = navTask.stepAfterStep(nil, withResult: taskResult)
        XCTAssertNotNil(step1)
        XCTAssertEqual(step1!.identifier, "intruction")
        taskResult.results = [ORKStepResult(identifier: "instruction")]
        
        let step2 = navTask.stepAfterStep(step1, withResult: taskResult)
        XCTAssertNotNil(step2)
        XCTAssertEqual(step2!.identifier, "Mutating Task.intruction")
        taskResult.results! += [ORKStepResult(identifier: "Mutating Task.instruction")]
        
        let step3 = navTask.stepAfterStep(step2, withResult: taskResult)
        XCTAssertNotNil(step3)
        XCTAssertEqual(step3!.identifier, "Mutating Task.question1")
        guard let formStep3 = step3 as? ORKFormStep else {
            XCTAssert(false, "\(step3) not of expected type")
            return
        }
        taskResult.results! += [formStep3.instantiateDefaultStepResult()]
        
        let step4 = navTask.stepAfterStep(step3, withResult: taskResult)
        XCTAssertNotNil(step4)
        XCTAssertEqual(step4!.identifier, "Mutating Task.question2")

        // Check that mutated task result is returned
        let stepResult = taskResult.stepResultForStepIdentifier("Mutating Task.question1")
        XCTAssertNotNil(stepResult)
        XCTAssertEqual(stepResult!.results!.count, 2)
        
    }
    
}

class MutatedResultTask: ORKOrderedTask {
    
    override func stepAfterStep(step: ORKStep?, withResult result: ORKTaskResult) -> ORKStep? {
        
        if let previousStep = step as? ORKFormStep,
            let stepResult = result.stepResultForStepIdentifier(previousStep.identifier),
            let stepResults = stepResult.results {
            let addedResult = ORKResult(identifier: previousStep.identifier + "addedResult")
            stepResult.results = stepResults + [addedResult]
        }
        
        let nextStep = super.stepAfterStep(step, withResult: result)
        
        return nextStep
    }
    
}