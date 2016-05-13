//
//  SBAActiveTaskTests.swift
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
import ResearchKit
import BridgeAppSDK

class SBAActiveTaskTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testTappingTask() {
        
        let inputTask: NSDictionary = [
            "taskIdentifier"            : "1-Tapping-ABCD-1234",
            "schemaIdentifier"          : "Tapping Activity",
            "taskType"                  : "tapping",
            "intendedUseDescription"    : "intended Use Description Text",
            "taskOptions"               : [
                "duration"      : 10.0,
                "handOptions"   : "right"
            ],
            "localizedSteps"               : [[
                "identifier" : "conclusion",
                "title"      : "Title 123",
                "text"       : "Text 123",
                "detailText" : "Detail Text 123"
                ]
            ]
        ]
        
        let result = inputTask.createORKTask()
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.identifier, "Tapping Activity")
        
        guard let task = result as? ORKOrderedTask else {
            XCTAssert(false, "\(result) not of expect class")
            return
        }
        
        let expectedCount = 4
        XCTAssertEqual(task.steps.count, expectedCount, "\(task.steps)")
        guard task.steps.count == expectedCount else { return }

        // Step 1 - Overview
        guard let instructionStep = task.steps.first as? ORKInstructionStep else {
            XCTAssert(false, "\(task.steps.first) not of expect class")
            return
        }
        XCTAssertEqual(instructionStep.identifier, "instruction")
        XCTAssertEqual(instructionStep.text, "intended Use Description Text")
        
        // Step 2 - Right Hand Tapping Instruction
        guard let rightInstructionStep = task.steps[1] as? ORKInstructionStep else {
            XCTAssert(false, "\(task.steps[1]) not of expect class")
            return
        }
        XCTAssertEqual(rightInstructionStep.identifier, "instruction1.right")
        
        // Step 3 - Right Hand Tapping
        guard let rightTappingStep = task.steps[2] as? ORKTappingIntervalStep else {
            XCTAssert(false, "\(task.steps[2]) not of expect class")
            return
        }
        XCTAssertEqual(rightTappingStep.identifier, "tapping.right")
        
        // Step 4 - Completion
        guard let completionStep = task.steps.last as? ORKCompletionStep else {
            XCTAssert(false, "\(task.steps.last) not of expect class")
            return
        }
        XCTAssertEqual(completionStep.identifier, "conclusion")
        XCTAssertEqual(completionStep.title, "Title 123")
        XCTAssertEqual(completionStep.text, "Text 123")
        XCTAssertEqual(completionStep.detailText, "Detail Text 123")
    }
    
    func testMemoryTask() {
        
        let inputTask: NSDictionary = [
            "taskIdentifier"            : "1-Memory-ABCD-1234",
            "schemaIdentifier"          : "Memory Activity",
            "taskType"                  : "memory",
            "intendedUseDescription"    : "intended Use Description Text",
            "taskOptions"               : [
                "initialSpan"               : 5,
                "minimumSpan"               : 3,
                "maximumSpan"               : 10,
                "playSpeed"                 : 1.5,
                "maxTests"                  : 6,
                "maxConsecutiveFailures"    : 4
            ],
        ]
        
        let result = inputTask.createORKTask()
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.identifier, "Memory Activity")
        
        guard let task = result as? ORKOrderedTask else {
            XCTAssert(false, "\(result) not of expect class")
            return
        }
        
        let expectedCount = 4
        XCTAssertEqual(task.steps.count, expectedCount, "\(task.steps)")
        guard task.steps.count == expectedCount else { return }
        
        // First - Overview
        guard let instructionStep = task.steps.first as? ORKInstructionStep else {
            XCTAssert(false, "\(task.steps.first) not of expect class")
            return
        }
        XCTAssertEqual(instructionStep.identifier, "instruction")
        XCTAssertEqual(instructionStep.text, "intended Use Description Text")
        
        // Third - Memory
        guard let activeStep = task.steps[2] as? ORKSpatialSpanMemoryStep else {
            XCTAssert(false, "\(task.steps[2]) not of expect class")
            return
        }
        XCTAssertEqual(activeStep.identifier, "cognitive.memory.spatialspan")
        XCTAssertEqual(activeStep.initialSpan, 5)
        XCTAssertEqual(activeStep.minimumSpan, 3)
        XCTAssertEqual(activeStep.maximumSpan, 10)
        XCTAssertEqual(activeStep.playSpeed, 1.5)
        XCTAssertEqual(activeStep.maxTests, 6)
        XCTAssertEqual(activeStep.maxConsecutiveFailures, 4)
        
        // Last - Completion
        guard let completionStep = task.steps.last as? ORKCompletionStep else {
            XCTAssert(false, "\(task.steps.last) not of expect class")
            return
        }
        XCTAssertEqual(completionStep.identifier, "conclusion")
    }
    
    func testVoiceTask() {
        
        let inputTask: NSDictionary = [
            "taskIdentifier"            : "1-Voice-ABCD-1234",
            "schemaIdentifier"          : "Voice Activity",
            "taskType"                  : "voice",
            "intendedUseDescription"    : "intended Use Description Text",
            "taskOptions"               : [
                "duration"              : 10.0,
                "speechInstruction"     : "Speech Instruction",
                "shortSpeechInstruction": "Short Speech Instruction"
            ],
        ]
        
        let result = inputTask.createORKTask()
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.identifier, "Voice Activity")
        
        guard let task = result as? ORKNavigableOrderedTask else {
            XCTAssert(false, "\(result) not of expect class")
            return
        }
        
        let expectedCount = 6
        XCTAssertEqual(task.steps.count, expectedCount, "\(task.steps)")
        guard task.steps.count == expectedCount else { return }
        
        // Step 1 - Overview
        guard let instructionStep = task.steps.first as? ORKInstructionStep else {
            XCTAssert(false, "\(task.steps.first) not of expect class")
            return
        }
        XCTAssertEqual(instructionStep.identifier, "instruction")
        XCTAssertEqual(instructionStep.text, "intended Use Description Text")
        
        // Step 2 - Detail Instruction
        guard let instructionDetailStep = task.steps[1] as? ORKInstructionStep else {
            XCTAssert(false, "\(task.steps[1]) not of expect class")
            return
        }
        XCTAssertEqual(instructionDetailStep.identifier, "instruction1")
        XCTAssertEqual(instructionDetailStep.text, "Speech Instruction")
        
        // Step 3 - Count down
        guard let countStep = task.steps[2] as? ORKCountdownStep else {
            XCTAssert(false, "\(task.steps[2]) not of expect class")
            return
        }
        XCTAssertEqual(countStep.identifier, "countdown")
        let audioRule = task.navigationRuleForTriggerStepIdentifier(countStep.identifier)
        XCTAssertNotNil(audioRule)
        
        // Step 4 - audio too loud
        guard let tooLoudStep = task.steps[3] as? ORKInstructionStep else {
            XCTAssert(false, "\(task.steps[3]) not of expect class")
            return
        }
        XCTAssertEqual(tooLoudStep.identifier, "audio.tooloud")
        if let navTooLoudRule = task.navigationRuleForTriggerStepIdentifier(tooLoudStep.identifier) as? ORKDirectStepNavigationRule {
            XCTAssertEqual(navTooLoudRule.destinationStepIdentifier, countStep.identifier)
        }
        else {
            XCTAssert(false, "\(tooLoudStep.identifier) navigation rule missing or not expected type")
        }
        
        // Step 5 - Audio
        guard let audioStep = task.steps[4] as? ORKAudioStep else {
            XCTAssert(false, "\(task.steps[4]) not of expect class")
            return
        }
        XCTAssertEqual(audioStep.identifier, "audio")
        XCTAssertEqual(audioStep.title, "Short Speech Instruction")
        
        // Last - Completion
        guard let completionStep = task.steps.last as? ORKCompletionStep else {
            XCTAssert(false, "\(task.steps.last) not of expect class")
            return
        }
        XCTAssertEqual(completionStep.identifier, "conclusion")
    }
    
    func testWalkingTask() {
        
        let inputTask: NSDictionary = [
            "taskIdentifier"            : "1-Walking-ABCD-1234",
            "schemaIdentifier"          : "Walking Activity",
            "taskType"                  : "walking",
            "intendedUseDescription"    : "intended Use Description Text",
            "taskOptions"               : [
                "walkDuration"          : 45.0,
                "restDuration"          : 20.0,
            ],
            ]
        
        let result = inputTask.createORKTask()
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.identifier, "Walking Activity")
        
        guard let task = result as? ORKOrderedTask else {
            XCTAssert(false, "\(result) not of expect class")
            return
        }
        
        let expectedCount = 6
        XCTAssertEqual(task.steps.count, expectedCount, "\(task.steps)")
        guard task.steps.count == expectedCount else { return }
        
        // Step 1 - Overview
        guard let instructionStep = task.steps.first as? ORKInstructionStep else {
            XCTAssert(false, "\(task.steps.first) not of expect class")
            return
        }
        XCTAssertEqual(instructionStep.identifier, "instruction")
        XCTAssertEqual(instructionStep.text, "intended Use Description Text")
        
        // Step 2 - Detail Instruction
        guard let instructionDetailStep = task.steps[1] as? ORKInstructionStep else {
            XCTAssert(false, "\(task.steps[1]) not of expect class")
            return
        }
        XCTAssertEqual(instructionDetailStep.identifier, "instruction1")
        
        // Step 3 - Count down
        guard let countStep = task.steps[2] as? ORKCountdownStep else {
            XCTAssert(false, "\(task.steps[2]) not of expect class")
            return
        }
        XCTAssertEqual(countStep.identifier, "countdown")
        
        // Step 4 - Walking
        guard let walkingStep = task.steps[3] as? ORKWalkingTaskStep else {
            XCTAssert(false, "\(task.steps[3]) not of expect class")
            return
        }
        XCTAssertEqual(walkingStep.identifier, "walking.outbound")
        XCTAssertEqual(walkingStep.stepDuration, 45.0)
        
        // Step 5 - Rest
        guard let restStep = task.steps[4] as? ORKFitnessStep else {
            XCTAssert(false, "\(task.steps[4]) not of expect class")
            return
        }
        XCTAssertEqual(restStep.identifier, "walking.rest")
        XCTAssertEqual(restStep.stepDuration, 20.0)
        
        // Last - Completion
        guard let completionStep = task.steps.last as? ORKCompletionStep else {
            XCTAssert(false, "\(task.steps.last) not of expect class")
            return
        }
        XCTAssertEqual(completionStep.identifier, "conclusion")
    }
    
    func testTremorTask() {
        
        let inputTask: NSDictionary = [
            "taskIdentifier"            : "1-Tremor-ABCD-1234",
            "schemaIdentifier"          : "Tremor Activity",
            "taskType"                  : "tremor",
            "intendedUseDescription"    : "intended Use Description Text",
            "taskOptions"               : [
                "duration"      : 10.0,
                "handOptions"   : "right",
            ],
        ]
        
        let result = inputTask.createORKTask()
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.identifier, "Tremor Activity")
        
        guard let task = result as? ORKOrderedTask else {
            XCTAssert(false, "\(result) not of expect class")
            return
        }
        
        let expectedCount = 18
        XCTAssertEqual(task.steps.count, expectedCount, "\(task.steps)")
        guard task.steps.count == expectedCount else { return }
        
        // Step 1 - Overview
        guard let instructionStep = task.steps.first as? ORKInstructionStep else {
            XCTAssert(false, "\(task.steps.first) not of expect class")
            return
        }
        XCTAssertEqual(instructionStep.identifier, "instruction")
        XCTAssertEqual(instructionStep.text, "intended Use Description Text")
        
        // Step 2 - Additional Instruction
        guard let additionalInstructionStep = task.steps[1] as? ORKInstructionStep else {
            XCTAssert(false, "\(task.steps[1]) not of expect class")
            return
        }
        XCTAssertEqual(additionalInstructionStep.identifier, "instruction1")
        
        // Step 3 - Right Hand Tremor Instruction
        guard let rightInstructionStep = task.steps[2] as? ORKInstructionStep else {
            XCTAssert(false, "\(task.steps[2]) not of expect class")
            return
        }
        XCTAssertEqual(rightInstructionStep.identifier, "instruction2.right")
        
        // Step 4 - Count down
        guard let countStep = task.steps[3] as? ORKCountdownStep else {
            XCTAssert(false, "\(task.steps[3]) not of expect class")
            return
        }
        XCTAssertEqual(countStep.identifier, "countdown1.right")
        
        // Step 5 - Hand In Lap
        guard let handInLapStep = task.steps[4] as? ORKActiveStep else {
            XCTAssert(false, "\(task.steps[4]) not of expect class")
            return
        }
        XCTAssertEqual(handInLapStep.identifier, "tremor.handInLap.right")

        // Last - Completion
        guard let completionStep = task.steps.last as? ORKCompletionStep else {
            XCTAssert(false, "\(task.steps.last) not of expect class")
            return
        }
        XCTAssertEqual(completionStep.identifier, "conclusion")
    }
    
    func testGroupedActiveTask() {
        
        let tappingTask: NSDictionary = [
            "taskIdentifier"            : "1-Tapping-ABCD-1234",
            "schemaIdentifier"          : "Tapping Activity",
            "surveyItemType"            : "activeTask",
            "taskType"                  : "tapping",
        ]
        
        let voiceTask: NSDictionary = [
            "taskIdentifier"            : "1-Voice-ABCD-1234",
            "schemaIdentifier"          : "Voice Activity",
            "taskType"                  : "voice",
            "intendedUseDescription"    : "intended Use Description Text",
            "predefinedExclusions"      : 0,
            ]
        
        let walkingTask: NSDictionary = [
            "taskIdentifier"            : "1-Walking-ABCD-1234",
            "schemaIdentifier"          : "Walking Activity",
            "surveyItemType"            : "activeTask",
            "taskType"                  : "walking",
            ]
        
        let inputTask: NSDictionary = [
            "taskIdentifier"            : "1-Combo-ABCD-1234",
            "taskSteps"                 :[
                [
                    "identifier" : "introduction",
                    "text" : "This is a combo task",
                    "detailText": "Tap the button below to begin",
                    "type"  : "instruction",
                ],
                tappingTask,
                voiceTask,
                walkingTask
            ],
            "insertSteps"               :[
                [
                    "resourceName"      : "MedicationTracking",
                    "resourceBundle"    : NSBundle(forClass: self.classForCoder).bundleIdentifier ?? "",
                    "classType"         : "TrackedDataObjectCollection"
                    ]
                ]
        ]
        
        let result = inputTask.createORKTask()
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.identifier, "1-Combo-ABCD-1234")
        
        guard let task = result as? SBANavigableOrderedTask else {
            XCTAssert(false, "\(result) not of expect class")
            return
        }
        
        let expectedCount = 7
        XCTAssertEqual(task.steps.count, expectedCount, "\(task.steps)")
        guard task.steps.count == expectedCount else { return }
        
        // Step 1 - Overview
        guard let instructionStep = task.steps.first as? ORKInstructionStep else {
            XCTAssert(false, "\(task.steps.first) not of expect class")
            return
        }
        XCTAssertEqual(instructionStep.identifier, "introduction")
        XCTAssertEqual(instructionStep.text, "This is a combo task")
        XCTAssertEqual(instructionStep.detailText, "Tap the button below to begin")
        
        // Step 2 - Medication tracking
        let medStep = task.steps[1]
        XCTAssertEqual(medStep.identifier, "Medication Tracker")
        
        // Step 3 - Tapping Subtask
        guard let tappingStep = task.steps[2] as? SBASubtaskStep,
            let tapTask = tappingStep.subtask as? ORKOrderedTask,
            let lastTapStep = tapTask.steps.last else {
            XCTAssert(false, "\(task.steps[2]) not of expect class")
            return
        }
        XCTAssertEqual(tappingStep.identifier, "Tapping Activity")
        XCTAssertNotEqual(lastTapStep.identifier, "conclusion")
        
        // Progress Step
        guard let progressStep1 = task.steps[3] as? SBAProgressStep else {
            XCTAssert(false, "\(task.steps[3]) not of expect class")
            return
        }
        XCTAssertEqual(progressStep1.index, 0)
        let expectedTitles = ["Tapping Speed", "Voice", "Gait and Balance"]
        XCTAssertEqual(progressStep1.stepTitles, expectedTitles)
        
        
        // Step 4 - Voice Subtask
        guard let voiceStep = task.steps[4] as? SBASubtaskStep,
            let vTask = voiceStep.subtask as? ORKOrderedTask,
            let lastVoiceStep = vTask.steps.last else {
            XCTAssert(false, "\(task.steps[4]) not of expect class")
            return
        }
        XCTAssertEqual(voiceStep.identifier, "Voice Activity")
        XCTAssertEqual(lastVoiceStep.identifier, "conclusion")
        
        // Progress Step
        guard let progressStep2 = task.steps[5] as? SBAProgressStep else {
            XCTAssert(false, "\(task.steps[5]) not of expect class")
            return
        }
        XCTAssertEqual(progressStep2.index, 1)
        
        // Step 5 - Walking Subtask
        guard let memoryStep = task.steps[6] as? SBASubtaskStep,
            let mTask = memoryStep.subtask as? ORKOrderedTask,
            let lastMemoryStep = mTask.steps.last else {
            XCTAssert(false, "\(task.steps[6]) not of expect class")
            return
        }
        XCTAssertEqual(memoryStep.identifier, "Walking Activity")
        XCTAssertEqual(lastMemoryStep.identifier, "conclusion")
        
    }

}
