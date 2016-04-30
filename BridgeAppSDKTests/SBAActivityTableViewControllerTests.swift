//
//  SBAActivityTableViewControllerTests.swift
//  BridgeAppSDK
//
//  Created by Shannon Young on 4/29/16.
//  Copyright © 2016 Sage Bionetworks. All rights reserved.
//

import XCTest
import BridgeAppSDK
import BridgeSDK

class SBAActivityTableViewControllerTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testUpdateSchedules() {

        let vc = TestActivityTableViewController()
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

class TestActivityTableViewController: SBAActivityTableViewController {
    
    var updatedScheduledActivities:[SBBScheduledActivity]?
    
    override func sendUpdatedScheduledActivities(scheduledActivities: [SBBScheduledActivity]) {
        updatedScheduledActivities = scheduledActivities
    }
    
}
