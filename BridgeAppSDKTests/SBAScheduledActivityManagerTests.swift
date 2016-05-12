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
import ResearchKit

let medicationTrackingTaskId = "Medication Task"
let comboTaskId = "Combo Task"
let tappingTaskId = "Tapping Task"
let memoryTaskId = "Memory Task"

class SBAScheduledActivityManagerTests: XCTestCase {

    override func setUp() {
        super.setUp()
        
        // flush the defaults
        SBATrackedDataStore.defaultStore().reset()
        SBATrackedDataStore.defaultStore().storedDefaults.flushUserDefaults()
    }
    
    override func tearDown() {
        
        SBATrackedDataStore.defaultStore().reset()
        SBATrackedDataStore.defaultStore().storedDefaults.flushUserDefaults()
        
        super.tearDown()
    }
    
    func testCreateTask_MedicationTask() {
        let manager = TestScheduledActivityManager()
        let schedule = createScheduledActivity(medicationTrackingTaskId)
        let (task, taskRef) = manager.createTask(schedule)
        XCTAssertNotNil(task)
        XCTAssertNotNil(taskRef)
    }
    
    func testCreateTask_ComboTask() {
        let manager = TestScheduledActivityManager()
        let schedule = createScheduledActivity(comboTaskId)
        let (task, taskRef) = manager.createTask(schedule)
        XCTAssertNotNil(task)
        XCTAssertNotNil(taskRef)
    }

    func testCreateTask_TappingTaskWithMeds() {
        let manager = TestScheduledActivityManager()
        let schedule = createScheduledActivity(tappingTaskId)
        let (task, taskRef) = manager.createTask(schedule)
        XCTAssertNotNil(task)
        XCTAssertNotNil(taskRef)
    }
    
    func testCreateTask_SingleTask() {
        let manager = TestScheduledActivityManager()
        let schedule = createScheduledActivity(memoryTaskId)
        let (task, taskRef) = manager.createTask(schedule)
        XCTAssertNotNil(task)
        XCTAssertNotNil(taskRef)
        
        guard let orderedTask = task as? ORKOrderedTask else {
            XCTAssert(false, "\(task) not of expected type")
            return
        }
        XCTAssert(orderedTask.dynamicType === ORKOrderedTask.self)
    }
    
    func testUpdateSchedules() {

        let manager = TestScheduledActivityManager()
        manager.activities = createScheduledActivities([medicationTrackingTaskId, comboTaskId, comboTaskId])
        
        let schedule = manager.activities[1]
        guard let taskVC = manager.createTaskViewControllerForSchedule(schedule) as? TestTaskViewController,
            let task = taskVC.task
            else {
                XCTAssert(false, "Failed to create a task view controller of expected type")
                return
        }
        taskVC.taskResult = buildTaskResult(task)
        
        manager.updateScheduledActivity(manager.activities[1], taskViewController: taskVC)
        
        XCTAssertNotNil(manager.updatedScheduledActivities)
        XCTAssertEqual(manager.updatedScheduledActivities!.count, 2)
        
    }
    
    func testActivityResultsForSchedule_MedTrackingOnly() {
        
        let manager = TestScheduledActivityManager()
        manager.activities = createScheduledActivities([medicationTrackingTaskId, comboTaskId, comboTaskId])
        
        let schedule = manager.activities[0]
        guard let taskVC = manager.createTaskViewControllerForSchedule(schedule) as? TestTaskViewController,
            let task = taskVC.task
            else {
                XCTAssert(false, "Failed to create a task view controller of expected type")
                return
        }
        taskVC.taskResult = buildTaskResult(task)
        
        let splitResults = manager.activityResultsForSchedule(schedule, taskViewController: taskVC)
        XCTAssertEqual(splitResults.count, 1)
        guard let results = splitResults.first?.results, taskResults = taskVC.result.results else {
            XCTAssert(false, "\(splitResults) or \(taskVC.result.results) does not match expected")
            return
        }
        XCTAssertEqual(results, taskResults)
        XCTAssertEqual(splitResults[0].schedule, schedule)
    }
    
    func testActivityResultsForSchedule_ComboWithNoMedsSelected() {
        
        let manager = TestScheduledActivityManager()
        manager.activities = createScheduledActivities([medicationTrackingTaskId, comboTaskId, comboTaskId])
        
        let schedule = manager.activities[1]
        guard let taskVC = manager.createTaskViewControllerForSchedule(schedule) as? TestTaskViewController,
            let task = taskVC.task
            else {
                XCTAssert(false, "Failed to create a task view controller of expected type")
                return
        }
        taskVC.taskResult = buildTaskResult(task)
        
        let splitResults = manager.activityResultsForSchedule(schedule, taskViewController: taskVC)
        XCTAssertEqual(splitResults.count, 5)
        
        // check that the data store results were added to the other tasks
        for result in splitResults {
            let momentInDay = result.stepResultForStepIdentifier("momentInDay")
            XCTAssertNotNil(momentInDay)
        }
    }
    
    func testActivityResultsForSchedule_ComboWithMedsSelected() {
        
        let manager = TestScheduledActivityManager()
        manager.activities = createScheduledActivities([medicationTrackingTaskId, comboTaskId, comboTaskId])
        
        let schedule = manager.activities[1]
        guard let taskVC = manager.createTaskViewControllerForSchedule(schedule) as? TestTaskViewController,
            let task = taskVC.task
            else {
                XCTAssert(false, "Failed to create a task view controller of expected type")
                return
        }
        taskVC.taskResult = buildTaskResult(task, selectedMeds: ["Levodopa":3])
        
        let splitResults = manager.activityResultsForSchedule(schedule, taskViewController: taskVC)
        XCTAssertEqual(splitResults.count, 5)
        
        // check that the data store results were added to the other tasks
        for result in splitResults {
            let momentInDay = result.stepResultForStepIdentifier("momentInDay")
            XCTAssertNotNil(momentInDay)
        }
    }
    
    func testActivityResultsForSchedule_ComboWithMedsSelectedPreviously() {
        
        let manager = TestScheduledActivityManager()
        manager.activities = createScheduledActivities([medicationTrackingTaskId, comboTaskId, comboTaskId])
        
        let schedule = manager.activities[1]
        
        // run through the task steps to setup the data store with previous values
        let (previousTask, _) = manager.createTask(schedule)
        buildTaskResult(previousTask!, selectedMeds: ["Levodopa":3])
        
        // run again with updated steps
        guard let taskVC = manager.createTaskViewControllerForSchedule(schedule) as? TestTaskViewController,
            let task = taskVC.task
        else {
            XCTAssert(false, "Failed to create a task view controller of expected type")
            return
        }
        taskVC.taskResult = buildTaskResult(task)
        
        let splitResults = manager.activityResultsForSchedule(schedule, taskViewController: taskVC)
        XCTAssertEqual(splitResults.count, 4)
        
        // check that the data store results were added to the other tasks
        let expectedSchema = [["Tapping Activity", 5],
                              ["Voice Activity", 1],
                              ["Memory Activity", 3],
                              ["Walking Activity", 7]]
        for (idx,result) in splitResults.enumerate() {
            let momentInDay = result.stepResultForStepIdentifier("momentInDay")
            XCTAssertNotNil(momentInDay)
            let expectedSchemaId = expectedSchema[idx].first
            XCTAssertEqual(result.schemaIdentifier, expectedSchemaId)
            let expectedSchemaRev = expectedSchema[idx].last
            XCTAssertEqual(result.schemaRevision, expectedSchemaRev)
        }
    }
    
    func testActivityResultsForSchedule_SingleTaskWithNoMeds() {
        let manager = TestScheduledActivityManager()
        manager.activities = createScheduledActivities([medicationTrackingTaskId, tappingTaskId])
        
        let schedule = manager.activities[1]
        guard let taskVC = manager.createTaskViewControllerForSchedule(schedule) as? TestTaskViewController,
            let task = taskVC.task
            else {
                XCTAssert(false, "Failed to create a task view controller of expected type")
                return
        }
        taskVC.taskResult = buildTaskResult(task)
        
        let splitResults = manager.activityResultsForSchedule(schedule, taskViewController: taskVC)
        XCTAssertEqual(splitResults.count, 2)
        
        // check that the data store results were added to the other tasks
        for result in splitResults {
            let momentInDay = result.stepResultForStepIdentifier("momentInDay")
            XCTAssertNotNil(momentInDay)
        }
    }
    
    func testActivityResultsForSchedule_SingleTaskWithMedsSelected() {
        let manager = TestScheduledActivityManager()
        manager.activities = createScheduledActivities([medicationTrackingTaskId, tappingTaskId])
        
        let schedule = manager.activities[1]
        guard let taskVC = manager.createTaskViewControllerForSchedule(schedule) as? TestTaskViewController,
            let task = taskVC.task
            else {
                XCTAssert(false, "Failed to create a task view controller of expected type")
                return
        }
        taskVC.taskResult = buildTaskResult(task, selectedMeds: ["Levodopa":3])
        
        let splitResults = manager.activityResultsForSchedule(schedule, taskViewController: taskVC)
        XCTAssertEqual(splitResults.count, 2)
        
        // check that the data store results were added to the other tasks
        for result in splitResults {
            let momentInDay = result.stepResultForStepIdentifier("momentInDay")
            XCTAssertNotNil(momentInDay)
        }
        
        guard let tappingResult = splitResults.last else { return }

        // check the schema
        XCTAssertEqual(tappingResult.schemaIdentifier, "Tapping Activity")
        XCTAssertEqual(tappingResult.schemaRevision, 5)
    }
    
    func testActivityResultsForSchedule_SingleTaskWithMedsPreviouslySelected() {
        let manager = TestScheduledActivityManager()
        manager.activities = createScheduledActivities([medicationTrackingTaskId, tappingTaskId])
        
        let schedule = manager.activities[1]
        
        // run through the task steps to setup the data store with previous values
        let (previousTask, _) = manager.createTask(schedule)
        buildTaskResult(previousTask!, selectedMeds: ["Levodopa":3])
        
        guard let taskVC = manager.createTaskViewControllerForSchedule(schedule) as? TestTaskViewController,
            let task = taskVC.task
            else {
                XCTAssert(false, "Failed to create a task view controller of expected type")
                return
        }
        taskVC.taskResult = buildTaskResult(task, selectedMeds: ["Levodopa":3])
        
        let splitResults = manager.activityResultsForSchedule(schedule, taskViewController: taskVC)
        XCTAssertEqual(splitResults.count, 1)
        
        guard let tappingResult = splitResults.first else { return }
        
        // check that the data store results was added to the other tasks
        let momentInDay = tappingResult.stepResultForStepIdentifier("momentInDay")
        XCTAssertNotNil(momentInDay)
        
        // check the schema
        XCTAssertEqual(tappingResult.schemaIdentifier, "Tapping Activity")
        XCTAssertEqual(tappingResult.schemaRevision, 5)
        
    }
    
    func testActivityResultsForSchedule_SingleTask() {
        
        let manager = TestScheduledActivityManager()
        manager.activities = createScheduledActivities([memoryTaskId])
        
        let schedule = manager.activities[0]
        guard let taskVC = manager.createTaskViewControllerForSchedule(schedule) as? TestTaskViewController,
            let task = taskVC.task
            else {
                XCTAssert(false, "Failed to create a task view controller of expected type")
                return
        }
        taskVC.taskResult = buildTaskResult(task)
        
        let splitResults = manager.activityResultsForSchedule(schedule, taskViewController: taskVC)
        XCTAssertEqual(splitResults.count, 1)
    
        guard let result = splitResults.first else { return }
        
        XCTAssertEqual(result.schemaIdentifier, "Memory Activity")
        XCTAssertEqual(result.schemaRevision, 3)
        
    }
    
    // MARK: helper methods
    
    func createScheduledActivities(taskIds:[String]) -> [SBBScheduledActivity] {
        
        var ret: [SBBScheduledActivity] = []
        
        for taskId in taskIds {
            let schedule = createScheduledActivity(taskId)
            ret += [schedule]
        }
        
        return ret
    }
    
    func createScheduledActivity(taskId: String, scheduledOn:NSDate = NSDate(), expiresOn:NSDate? = nil, finishedOn:NSDate? = nil, optional:Bool = false) -> SBBScheduledActivity {
        
        let schedule = SBBScheduledActivity()
        schedule.guid = NSUUID().UUIDString
        schedule.activity = SBBActivity()
        schedule.activity.guid = NSUUID().UUIDString
        schedule.activity.task = SBBTaskReference()
        schedule.activity.task.identifier = taskId
        schedule.scheduledOn = scheduledOn
        schedule.expiresOn = expiresOn
        schedule.finishedOn = finishedOn
        schedule.persistentValue = optional
        return schedule
    }

    func buildTaskResult(task: ORKTask,
                         selectedMeds: [String : NSNumber]? = nil,
                         outputDirectory: NSURL? = nil) -> ORKTaskResult {
        
        let taskResult = ORKTaskResult(taskIdentifier: task.identifier, taskRunUUID: NSUUID(), outputDirectory: outputDirectory)
        taskResult.results = []
        
        var step: ORKStep?
        repeat {
            step = task.stepAfterStep(step, withResult: taskResult)
            if let activeStep = step as? ORKActiveStep {
                let stepResult = ORKStepResult(identifier: activeStep.identifier)
                taskResult.results! += [stepResult]
            }
            else if let formStep = step as? SBATrackedFormStep, let formItems = formStep.formItems {
                
                switch formStep.trackingType! {
                case .Selection:
                    // Add a question answer to the selection step
                    let questionResult = ORKChoiceQuestionResult(identifier: formItems[0].identifier)
                    if let meds = selectedMeds {
                        questionResult.choiceAnswers = Array(meds.keys)
                    }
                    else {
                        questionResult.choiceAnswers = ["None"]
                    }
                    let stepResult = ORKStepResult(stepIdentifier: formStep.identifier, results: [questionResult])
                    taskResult.results! += [stepResult]
                    
                case .Frequency:
                    let formItemResults = formItems.map({ (formItem) -> ORKResult in
                        let questionResult = ORKScaleQuestionResult(identifier: formItem.identifier)
                        questionResult.scaleAnswer = selectedMeds?[formItem.identifier]
                        return questionResult
                    })
                    let stepResult = ORKStepResult(stepIdentifier: formStep.identifier, results: formItemResults)
                    taskResult.results! += [stepResult]
                    
                case .Activity:
                    let formItemResults = formItems.map({ (formItem) -> ORKResult in
                        let questionResult = ORKChoiceQuestionResult(identifier: formItem.identifier)
                        if let answerFormat = formItem.answerFormat as? ORKTextChoiceAnswerFormat,
                            let answer = answerFormat.textChoices.first {
                            questionResult.choiceAnswers = [answer]
                        }
                        return questionResult
                    })
                    let stepResult = ORKStepResult(stepIdentifier: formStep.identifier, results: formItemResults)
                    taskResult.results! += [stepResult]
                    
                default:
                    break
                }
            }
        } while (step != nil)
        
        return taskResult
    }
}

class TestTaskViewController: SBATaskViewController {
    
    var taskResult: ORKTaskResult!
    
    override var result: ORKTaskResult {
        return taskResult
    }
    
}

class TestScheduledActivityManager: SBAScheduledActivityManager, SBABridgeInfo {
    
    // MARK: bridge info
    override var bridgeInfo: SBABridgeInfo {
        return self
    }
    
    var studyIdentifier: String!
    var useCache: Bool = false
    var environment: SBBEnvironment!
    var appStoreLinkURLString: String?
    var emailForLoginViaExternalId: String?
    var passwordFormatForLoginViaExternalId: String?
    var testUserDataGroup: String?
    var schemaMap: [NSDictionary]? {
        return [memorySchemaRef, walkingSchemaRef, tappingSchemaRef]
    }
    var taskMap: [NSDictionary]? {
        return [medTaskRef, comboTaskRef, tappingTaskRef, memoryTaskRef]
    }
    
    var medTaskRef = [
        "taskIdentifier"    : medicationTrackingTaskId,
        "resourceName"      : "MedicationTracking",
        "resourceBundle"    : NSBundle(forClass: SBAScheduledActivityManagerTests.classForCoder()).bundleIdentifier ?? "",
        "classType"         : "TrackedDataObjectCollection"]
    var comboTaskRef = [
        "taskIdentifier"    : comboTaskId,
        "resourceName"      : "CombinedTask",
        "resourceBundle"    : NSBundle(forClass: SBAScheduledActivityManagerTests.classForCoder()).bundleIdentifier ?? ""]
    var tappingTaskRef = [
        "taskIdentifier"    : tappingTaskId,
        "resourceName"      : "TappingTask",
        "resourceBundle"    : NSBundle(forClass: SBAScheduledActivityManagerTests.classForCoder()).bundleIdentifier ?? ""]
    var memoryTaskRef = [
        "taskIdentifier"    : memoryTaskId,
        "schemaIdentifier"  : "Memory Activity",
        "taskType"          : "memory"]
    
    var walkingSchemaRef = [
        "schemaIdentifier"  : "Walking Activity",
        "schemaRevision"    : 7,
    ]
    var memorySchemaRef = [
        "schemaIdentifier"  : "Memory Activity",
        "schemaRevision"    : 3,
        ]
    var tappingSchemaRef = [
        "schemaIdentifier"  : "Tapping Activity",
        "schemaRevision"    : 5,
        ]
    
    // MARK: test function overrrides
    var updatedScheduledActivities:[SBBScheduledActivity]?
    
    override func sendUpdatedScheduledActivities(scheduledActivities: [SBBScheduledActivity]) {
        updatedScheduledActivities = scheduledActivities
    }
    
    override func instantiateTaskViewController(schedule: SBBScheduledActivity, task: ORKTask, taskRef: SBATaskReference) -> SBATaskViewController {
        return TestTaskViewController(task: task, taskRunUUID: nil)
    }
    
}
