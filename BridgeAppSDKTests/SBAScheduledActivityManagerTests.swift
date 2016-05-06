//
//  SBAActivityTableViewControllerTests.swift
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
import BridgeSDK

class SBAScheduledActivityManagerTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testUpdateSchedules() {

        let vc = TestScheduledActivityManager()
        vc.activities = createScheduledActivities()
        
        let step1 = ORKInstructionStep(identifier: "instruction")
        let subtask = ORKOrderedTask(identifier: "Subtask", steps: [ORKInstructionStep(identifier: "instruction")])
        let step2 = SBASubtaskStep(subtask: subtask)
        step2.taskIdentifier = "Med Task"
        let step3 = ORKCompletionStep(identifier: "conclusion")
        let task = SBANavigableOrderedTask(identifier: "Main Task", steps: [step1, step2, step3])
        
        let taskVC = SBATaskViewController(task: task, taskRunUUID: nil)
        taskVC.scheduledActivityGUID = vc.activities[1].guid
        
        vc.updateScheduledActivity(vc.activities[1], taskViewController: taskVC)
        
        XCTAssertNotNil(vc.updatedScheduledActivities)
        XCTAssertEqual(vc.updatedScheduledActivities!.count, 2)
        
    }
    
    // MARK: helper methods
    
    func createScheduledActivities() -> [SBBScheduledActivity] {
        
        var ret: [SBBScheduledActivity] = []
        
        for taskId in ["Med Task", "Combo Task", "Combo Task"] {
    
            let schedule = SBBScheduledActivity()
            schedule.guid = NSUUID().UUIDString
            schedule.activity = SBBActivity()
            schedule.activity.guid = NSUUID().UUIDString
            schedule.activity.task = SBBTaskReference()
            schedule.activity.task.identifier = taskId
            ret += [schedule]
        }
        
        return ret
    }

}

class TestScheduledActivityManager: SBAScheduledActivityManager {
    
    var updatedScheduledActivities:[SBBScheduledActivity]?
    
    override func sendUpdatedScheduledActivities(scheduledActivities: [SBBScheduledActivity]) {
        updatedScheduledActivities = scheduledActivities
    }
    
}
