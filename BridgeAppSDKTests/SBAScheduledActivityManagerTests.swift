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
let voiceTaskId = "Voice Task"

class SBAScheduledActivityManagerTests: XCTestCase {

    override func setUp() {
        super.setUp()
        
        // flush the defaults
        SBATrackedDataStore.shared.reset()
        SBATrackedDataStore.shared.storedDefaults.flushUserDefaults()
    }
    
    override func tearDown() {
        
        SBATrackedDataStore.shared.reset()
        SBATrackedDataStore.shared.storedDefaults.flushUserDefaults()
        
        super.tearDown()
    }
    
    // MARK: createTask

    func testCreateTask_MedicationTask() {
        let manager = TestScheduledActivityManager()
        let schedule = createScheduledActivity(medicationTrackingTaskId)
        let (task, taskRef) = manager.createTask(for: schedule)
        XCTAssertNotNil(task)
        XCTAssertNotNil(taskRef)
    }
    
    func testCreateTask_ComboTask() {
        let manager = TestScheduledActivityManager()
        let schedule = createScheduledActivity(comboTaskId)
        let (task, taskRef) = manager.createTask(for: schedule)
        XCTAssertNotNil(task)
        XCTAssertNotNil(taskRef)
    }

    func testCreateTask_TappingTaskWithMeds() {
        let manager = TestScheduledActivityManager()
        let schedule = createScheduledActivity(tappingTaskId)
        let (task, taskRef) = manager.createTask(for: schedule)
        XCTAssertNotNil(task)
        XCTAssertNotNil(taskRef)
    }
    
    func testCreateTask_SingleTask() {
        let manager = TestScheduledActivityManager()
        let schedule = createScheduledActivity(memoryTaskId)
        let (task, taskRef) = manager.createTask(for: schedule)
        XCTAssertNotNil(task)
        XCTAssertNotNil(taskRef)
        
        guard let orderedTask = task as? ORKOrderedTask else {
            XCTAssert(false, "\(task) not of expected type")
            return
        }
        XCTAssert(type(of: orderedTask) === ORKOrderedTask.self)
    }

    // MARK: updateScheduledActivity
    
    func testUpdateSchedules() {

        let manager = TestScheduledActivityManager()
        manager.activities = createScheduledActivities([medicationTrackingTaskId, comboTaskId, comboTaskId])
        
        let schedule = manager.activities[1]
        guard let taskVC = manager.createTaskViewController(for: schedule) as? TestTaskViewController,
            let task = taskVC.task
            else {
                XCTAssert(false, "Failed to create a task view controller of expected type")
                return
        }
        taskVC.taskResult = buildTaskResult(task)
        
        manager.update(schedule: manager.activities[1], taskViewController: taskVC)
        
        XCTAssertNotNil(manager.updatedScheduledActivities)
        XCTAssertEqual(manager.updatedScheduledActivities!.count, 2)
        
    }

    // MARK: activityResultsForSchedule
    
    func testActivityResultsForSchedule_MedTrackingOnly_NoMedsSelected() {
        
        let manager = TestScheduledActivityManager()
        manager.activities = createScheduledActivities([medicationTrackingTaskId, comboTaskId, comboTaskId])
        
        let schedule = manager.activities[0]
        guard let taskVC = manager.createTaskViewController(for: schedule) as? TestTaskViewController,
            let task = taskVC.task
            else {
                XCTAssert(false, "Failed to create a task view controller of expected type")
                return
        }
        taskVC.taskResult = buildTaskResult(task)
        
        let splitResults = manager.activityResults(for: schedule, taskViewController: taskVC)
        
        // check that the data store results were added to the other tasks
        checkSchema(splitResults, expectedSchema:[("Medication Tracker", 1)])
        
        XCTAssertEqual(splitResults.count, 1)
        guard let medResult = splitResults.first else { return }
        
        XCTAssertEqual(medResult.schedule, schedule)
        
        guard let selectionResult = medResult.result(forIdentifier: "medicationSelection") as? ORKStepResult else {
            XCTAssert(false, "\(medResult) does not include 'medicationSelection' of expected type")
            return
        }
        guard let itemsResult = selectionResult.result(forIdentifier: "medicationSelection") as? SBATrackedDataSelectionResult else {
            XCTAssert(false, "\(selectionResult) does not include 'medicationSelection' of expected type")
            return
        }
        
        // Check that the tracked data result is added, non-nil and empty
        XCTAssertNotNil(itemsResult.selectedItems)
        XCTAssertEqual(itemsResult.selectedItems?.count ?? 0, 0)
        
        // Check that the subtask step identifier is stripped
        checkResultIdentifiers(splitResults)
        
        // Check the dates
        checkDates(taskVC.taskResult, splitResults)
        
        // Validate the archive
        checkValidation(splitResults)
        checkDuplicateFilenames(splitResults)
    }
    
    func testActivityResultsForSchedule_MedTrackingOnly_MedsSelected() {
        
        let manager = TestScheduledActivityManager()
        manager.activities = createScheduledActivities([medicationTrackingTaskId, comboTaskId, comboTaskId])
        
        let schedule = manager.activities[0]
        guard let taskVC = manager.createTaskViewController(for: schedule) as? TestTaskViewController,
            let task = taskVC.task
            else {
                XCTAssert(false, "Failed to create a task view controller of expected type")
                return
        }
        taskVC.taskResult = buildTaskResult(task, selectedMeds: ["Levodopa":3])
        
        let splitResults = manager.activityResults(for: schedule, taskViewController: taskVC)
        
        // check that the data store results were added to the other tasks
        checkSchema(splitResults, expectedSchema:[("Medication Tracker", 1 )])

        guard let medResult = splitResults.first else { return }
        
        XCTAssertEqual(medResult.schedule, schedule)
        
        guard let selectionResult = medResult.result(forIdentifier: "medicationSelection") as? ORKStepResult else {
            XCTAssert(false, "\(medResult) does not include 'medicationSelection' of expected type")
            return
        }
        guard let itemsResult = selectionResult.result(forIdentifier: "medicationSelection") as? SBATrackedDataSelectionResult else {
            XCTAssert(false, "\(selectionResult) does not include 'medicationSelection' of expected type")
            return
        }
        
        // Check that the tracked data result is added, non-nil and equal to a count of 1
        XCTAssertNotNil(itemsResult.selectedItems)
        XCTAssertEqual(itemsResult.selectedItems?.count ?? 0, 1)
        
        // Check that the subtask step identifier is stripped
        checkResultIdentifiers(splitResults)
        
        // Check the dates
        checkDates(taskVC.taskResult, splitResults)
        
        // Validate the archive
        checkValidation(splitResults)
        checkDuplicateFilenames(splitResults)
    }
    
    func testActivityResultsForSchedule_ComboWithNoMedsSelected() {
        
        let manager = TestScheduledActivityManager()
        manager.activities = createScheduledActivities([medicationTrackingTaskId, comboTaskId, comboTaskId])
        
        let schedule = manager.activities[1]
        guard let taskVC = manager.createTaskViewController(for: schedule) as? TestTaskViewController,
            let task = taskVC.task
            else {
                XCTAssert(false, "Failed to create a task view controller of expected type")
                return
        }
        taskVC.taskResult = buildTaskResult(task)
        
        let splitResults = manager.activityResults(for: schedule, taskViewController: taskVC)
        
        // check that the data store results were added to the other tasks
        checkSchema(splitResults, expectedSchema:[
            ("Medication Tracker", 1),
            ("Tapping Activity", 5),
            ("Voice Activity", 1),
            ("Memory Activity", 3),
            ("Walking Activity", 7)])
        
        // check that the data store results were added to the other tasks
        checkDataStoreResults(splitResults)
        
        // Check that the subtask step identifier is stripped
        checkResultIdentifiers(splitResults)
        
        // Check the dates
        checkDates(taskVC.taskResult, splitResults)
        
        // Validate the archive
        checkValidation(splitResults)
        checkDuplicateFilenames(splitResults)
    }
    
    func testActivityResultsForSchedule_ComboWithMedsSelected() {
        
        let manager = TestScheduledActivityManager()
        manager.activities = createScheduledActivities([medicationTrackingTaskId, comboTaskId, comboTaskId])
        
        let schedule = manager.activities[1]
        guard let taskVC = manager.createTaskViewController(for: schedule) as? TestTaskViewController,
            let task = taskVC.task
            else {
                XCTAssert(false, "Failed to create a task view controller of expected type")
                return
        }
        taskVC.taskResult = buildTaskResult(task, selectedMeds: ["Levodopa":3])
        
        let splitResults = manager.activityResults(for: schedule, taskViewController: taskVC)

        // check that the data store results were added to the other tasks
        checkSchema(splitResults, expectedSchema:[
            ("Medication Tracker", 1),
            ("Tapping Activity", 5),
            ("Voice Activity", 1),
            ("Memory Activity", 3),
            ("Walking Activity", 7)])
        
        // check that the data store results were added to the other tasks
        checkDataStoreResults(splitResults)
        
        // Check that the subtask step identifier is stripped
        checkResultIdentifiers(splitResults)
        
        // Check the dates
        checkDates(taskVC.taskResult, splitResults)
        
        // Validate the archive
        checkValidation(splitResults)
        checkDuplicateFilenames(splitResults)
    }
    
    func testActivityResultsForSchedule_ComboWithMedsSelectedPreviously() {
        
        let manager = TestScheduledActivityManager()
        manager.activities = createScheduledActivities([medicationTrackingTaskId, comboTaskId, comboTaskId])
        
        let schedule = manager.activities[1]
        
        // run through the task steps to setup the data store with previous values
        let (previousTask, _) = manager.createTask(for: schedule)
        let _ = buildTaskResult(previousTask!, selectedMeds: ["Levodopa":3])
        
        // run again with updated steps
        guard let taskVC = manager.createTaskViewController(for: schedule) as? TestTaskViewController,
            let task = taskVC.task
        else {
            XCTAssert(false, "Failed to create a task view controller of expected type")
            return
        }
        taskVC.taskResult = buildTaskResult(task)
        
        let splitResults = manager.activityResults(for: schedule, taskViewController: taskVC)
        
        // check that the data store results were added to the other tasks
        checkSchema(splitResults, expectedSchema:[
            ("Tapping Activity", 5),
            ("Voice Activity", 1),
            ("Memory Activity", 3),
            ("Walking Activity", 7)])
        
        // check that the data store results were added to the other tasks
        checkDataStoreResults(splitResults)
        
        // Check that the subtask step identifier is stripped
        checkResultIdentifiers(splitResults)
        
        // Check the dates
        checkDates(taskVC.taskResult, splitResults)
        
        // Validate the archive
        checkValidation(splitResults)
        checkDuplicateFilenames(splitResults)
    }
    
    func testActivityResultsForSchedule_SingleTaskWithNoMeds() {
        let manager = TestScheduledActivityManager()
        manager.activities = createScheduledActivities([medicationTrackingTaskId, tappingTaskId])
        
        let schedule = manager.activities[1]
        guard let taskVC = manager.createTaskViewController(for: schedule) as? TestTaskViewController,
            let task = taskVC.task
            else {
                XCTAssert(false, "Failed to create a task view controller of expected type")
                return
        }
        taskVC.taskResult = buildTaskResult(task)
        
        let splitResults = manager.activityResults(for: schedule, taskViewController: taskVC)

        // check that the data store results were added to the other tasks
        checkSchema(splitResults, expectedSchema:[
            ("Medication Tracker", 1),
            ("Tapping Activity", 5)])
        
        // check that the data store results were added to the other tasks
        checkDataStoreResults(splitResults)
        
        // Check that the subtask step identifier is stripped
        checkResultIdentifiers(splitResults)
        
        // Check the dates
        checkDates(taskVC.taskResult, splitResults)
        
        // Validate the archive
        checkValidation(splitResults)
        checkDuplicateFilenames(splitResults)
    }
    
    func testActivityResultsForSchedule_SingleTaskWithMedsSelected() {
        let manager = TestScheduledActivityManager()
        manager.activities = createScheduledActivities([medicationTrackingTaskId, tappingTaskId])
        
        let schedule = manager.activities[1]
        guard let taskVC = manager.createTaskViewController(for: schedule) as? TestTaskViewController,
            let task = taskVC.task
            else {
                XCTAssert(false, "Failed to create a task view controller of expected type")
                return
        }
        taskVC.taskResult = buildTaskResult(task, selectedMeds: ["Levodopa":3])
        
        let splitResults = manager.activityResults(for: schedule, taskViewController: taskVC)
        
        // check that the data store results were added to the other tasks
        checkSchema(splitResults, expectedSchema:[
            ("Medication Tracker", 1),
            ("Tapping Activity", 5)])
        
        // check that the data store results were added to the other tasks
        checkDataStoreResults(splitResults)
        
        // Check that the subtask step identifier is stripped
        checkResultIdentifiers(splitResults)
        
        // Check the dates
        checkDates(taskVC.taskResult, splitResults)
        
        // Validate the archive
        checkValidation(splitResults)
        checkDuplicateFilenames(splitResults)
    }
    
    func testActivityResultsForSchedule_SingleTaskWithMedsPreviouslySelected() {
        let manager = TestScheduledActivityManager()
        manager.activities = createScheduledActivities([medicationTrackingTaskId, tappingTaskId])
        
        let schedule = manager.activities[1]
        
        // run through the task steps to setup the data store with previous values
        let (previousTask, _) = manager.createTask(for: schedule)
        let _ = buildTaskResult(previousTask!, selectedMeds: ["Levodopa":3])
        
        guard let taskVC = manager.createTaskViewController(for: schedule) as? TestTaskViewController,
            let task = taskVC.task
            else {
                XCTAssert(false, "Failed to create a task view controller of expected type")
                return
        }
        taskVC.taskResult = buildTaskResult(task, selectedMeds: ["Levodopa":3])
        
        let splitResults = manager.activityResults(for: schedule, taskViewController: taskVC)
        
        // check the schema
        checkSchema(splitResults, expectedSchema:[("Tapping Activity", 5)])
        
        // check that the data store results were added to the other tasks
        checkDataStoreResults(splitResults)
        
        // Check that the subtask step identifier is stripped
        checkResultIdentifiers(splitResults)
        
        // Check the dates
        checkDates(taskVC.taskResult, splitResults)
        
        // Validate the archive
        checkValidation(splitResults)
        checkDuplicateFilenames(splitResults)
    }
    
    func testActivityResultsForSchedule_SingleTaskWithNoMedsPreviouslySelected() {
        let manager = TestScheduledActivityManager()
        manager.activities = createScheduledActivities([medicationTrackingTaskId, tappingTaskId])
        
        let schedule = manager.activities[1]
        
        // run through the task steps to setup the data store with previous values
        let (previousTask, _) = manager.createTask(for: schedule)
        let _ = buildTaskResult(previousTask!)
        
        guard let taskVC = manager.createTaskViewController(for: schedule) as? TestTaskViewController,
            let task = taskVC.task
            else {
                XCTAssert(false, "Failed to create a task view controller of expected type")
                return
        }
        taskVC.taskResult = buildTaskResult(task)
        
        let splitResults = manager.activityResults(for: schedule, taskViewController: taskVC)

        // check the schema
        checkSchema(splitResults, expectedSchema:[("Tapping Activity", 5)])
        
        // check that the data store results were added to the other tasks
        checkDataStoreResults(splitResults)
        
        // Check that the subtask step identifier is stripped
        checkResultIdentifiers(splitResults)
        
        // Check the dates
        checkDates(taskVC.taskResult, splitResults)
        
        // Validate the archive
        checkValidation(splitResults)
        checkDuplicateFilenames(splitResults)
    }
    
    func testActivityResultsForSchedule_SingleTask() {
        
        let manager = TestScheduledActivityManager()
        manager.activities = createScheduledActivities([memoryTaskId])
        
        let schedule = manager.activities[0]
        guard let taskVC = manager.createTaskViewController(for: schedule) as? TestTaskViewController,
            let task = taskVC.task
            else {
                XCTAssert(false, "Failed to create a task view controller of expected type")
                return
        }
        taskVC.taskResult = buildTaskResult(task)
        
        let splitResults = manager.activityResults(for: schedule, taskViewController: taskVC)
        XCTAssertEqual(splitResults.count, 1)
    
        guard let result = splitResults.first else { return }
        
        XCTAssertEqual(result.schemaIdentifier, "Memory Activity")
        XCTAssertEqual(result.schemaRevision, 3)
        
        // Check that the subtask step identifier is stripped
        checkResultIdentifiers(splitResults)
        
        // Check the dates
        checkDates(taskVC.taskResult, splitResults)
        
        // Validate the archive
        checkValidation(splitResults)
        checkDuplicateFilenames(splitResults)
    }
    
    func testActivityResultsForSchedule_VoiceTask() {
        
        let manager = TestScheduledActivityManager()
        manager.activities = createScheduledActivities([voiceTaskId])
        
        let schedule = manager.activities[0]
        guard let taskVC = manager.createTaskViewController(for: schedule) as? TestTaskViewController,
            let task = taskVC.task
            else {
                XCTAssert(false, "Failed to create a task view controller of expected type")
                return
        }
        taskVC.taskResult = buildTaskResult(task, selectedMeds: nil, outputDirectory: nil, tooLoudCount: 2)
        
        let splitResults = manager.activityResults(for: schedule, taskViewController: taskVC)
        XCTAssertEqual(splitResults.count, 1)
        
        guard let result = splitResults.first else { return }
        
        // Check that the results are singular
        result.validateParameters()
        
        // Validate the archive
        checkValidation(splitResults)
        checkDuplicateFilenames(splitResults)
        
        let countdownResult = result.stepResult(forStepIdentifier: "countdown")
        XCTAssertNotNil(countdownResult)
        XCTAssertNotNil(countdownResult?.results)
        guard let countdownResults = countdownResult?.results else { return }
        XCTAssertEqual(countdownResults.count, 3)
        
        // Additional results should be kept. Only the most recent should *not* have _dup# appended to the identifier
        let resultIdentifiers = countdownResults.map({ $0.identifier })
        let expectedResultIdentifiers = [ "file", "file_dup1", "file_dup2"]
        XCTAssertEqual(resultIdentifiers, expectedResultIdentifiers)
        
        let lastCountdownResult = (taskVC.taskResult.results?.findLast(withIdentifier: "countdown") as? ORKStepResult)?.results?.first
        XCTAssertNotNil(lastCountdownResult)
        XCTAssertEqual(lastCountdownResult?.identifier, "file")
    }
    
    func checkValidation(_ splitResults: [SBAActivityResult]) {
        for activityResult in splitResults {
            
            var stepIdentifiers: [String] = []
            for stepResult in activityResult.results! {
                
                XCTAssertFalse(stepIdentifiers.contains(stepResult.identifier), "\(activityResult.identifier).\(stepResult.identifier)")
                stepIdentifiers.append(stepResult.identifier)
                
                var resultIdentifiers: [String] = []
                if let stepResults = (stepResult as! ORKStepResult).results {
                    for result in stepResults {
                        XCTAssertFalse(resultIdentifiers.contains(result.identifier), "\(activityResult.identifier).\(stepResult.identifier).\(result.identifier)")
                        resultIdentifiers.append(result.identifier)
                    }
                }
            }
            
            activityResult.validateParameters()
        }
    }
    
    func checkDuplicateFilenames(_ splitResults: [SBAActivityResult]) {
        for activityResult in splitResults {
            var filenames: [String] = []
            for stepResult in activityResult.results! {
                if let stepResults = (stepResult as! ORKStepResult).results {
                    for result in stepResults {
                        if let archiveableResult = result.bridgeData(stepResult.identifier) {
                            let filename = archiveableResult.filename
                            XCTAssertFalse(filenames.contains(filename), "\(activityResult.identifier).\(stepResult.identifier).\(result.identifier):\(filename)")
                            filenames.append(filename)
                        }
                    }
                }
            }
        }
    }
    
    func checkSchema(_ splitResults: [SBAActivityResult], expectedSchema:[(schemaId: String, schemaRevision: Int)]) {
        
        XCTAssertEqual(splitResults.count, expectedSchema.count)
        guard splitResults.count <= expectedSchema.count else { return }
        
        for (idx, result) in splitResults.enumerated() {
            let expectedSchemaId = expectedSchema[idx].schemaId
            XCTAssertEqual(result.schemaIdentifier, expectedSchemaId)
            let expectedSchemaRev = expectedSchema[idx].schemaRevision
            XCTAssertEqual(result.schemaRevision.intValue, expectedSchemaRev)
        }
    }
    
    func checkResultIdentifiers(_ splitResults: [SBAActivityResult])
    {
        // Check that the subtask step identifier is stripped
        for activityResult in splitResults {
            for sResult in activityResult.results! {
                guard let stepResult = sResult as? ORKStepResult else {
                    XCTAssert(false, "\(sResult) does not match expected")
                    return
                }
                XCTAssertFalse(stepResult.identifier.hasPrefix(activityResult.schemaIdentifier))
                if let results = stepResult.results {
                    for result in results {
                        XCTAssertFalse(result.identifier.hasPrefix(activityResult.schemaIdentifier))
                    }
                }
            }
        }
    }
    
    func checkDataStoreResults(_ splitResults: [SBAActivityResult]) {
        
        let expectedIdentifiers = ["momentInDay", "medicationActivityTiming", "medicationTrackEach"]
        for result in splitResults {
            if result.identifier == "Medication Tracker" {
                continue
            }
            for stepIdentifier in expectedIdentifiers {
                let stepResult = result.stepResult(forStepIdentifier: stepIdentifier)
                XCTAssertNotNil(stepResult, "\(stepIdentifier)")
                XCTAssertTrue(stepResult?.hasResults ?? false, "\(stepIdentifier)")
                if let results = stepResult?.results {
                    for questionResult in results {
                        let bridgeData = questionResult.bridgeData(stepIdentifier)
                        XCTAssertNotNil(bridgeData, "\(stepIdentifier) \(questionResult.identifier)")
                        let dictionary = bridgeData?.result as? NSDictionary
                        XCTAssertNotNil(dictionary, "\(stepIdentifier) \(questionResult.identifier)")
                        let choiceAnswers = dictionary?["choiceAnswers"]
                        XCTAssertNotNil(choiceAnswers, "\(stepIdentifier) \(questionResult.identifier)")
                    }
                }
            }
        }

    }
    
    func checkDates(_ taskResult: ORKTaskResult, _ splitResults: [SBAActivityResult]) {
        
        for result in splitResults {
            
            func roundDate(_ date: Date) -> Double {
                let ret = date.timeIntervalSinceReferenceDate
                let divisor = pow(10.0, Double(1))
                return round(ret * divisor) / divisor
            }
            
            let resultStart = roundDate(result.startDate)
            let taskStart = roundDate(taskResult.startDate)
            XCTAssertGreaterThanOrEqual(resultStart, taskStart, "\(result.identifier)")
            
            let resultEnd = roundDate(result.endDate)
            let taskEnd = roundDate(taskResult.endDate)
            XCTAssertLessThanOrEqual(resultEnd, taskEnd, "\(result.identifier)")
        }
        
    }
    
    // MARK: schedule filtering
    
    func testDateAddingNumberOfDays_July() {
        
        let calendar = Calendar(identifier: Calendar.Identifier.gregorian)
        var dateComponents = DateComponents()
        dateComponents.month = 7
        dateComponents.day = 28
        dateComponents.year = 2016
        let sept28 = calendar.date(from: dateComponents)!
        
        // For a given date that is known to be *not* Daylight savings change
        // Check that crossing the month threshold is valid
        let days = 5
        let expectedDate = sept28.addingTimeInterval(Double(days * 24 * 60 * 60))
        let actualDate = sept28.addingNumberOfDays(days)
        XCTAssertEqual(actualDate, expectedDate)
    }
    
    func testDateAddingNumberOfDays_December() {
        
        let calendar = Calendar(identifier: Calendar.Identifier.gregorian)
        var dateComponents = DateComponents()
        dateComponents.month = 12
        dateComponents.day = 28
        dateComponents.year = 2016
        let sept28 = calendar.date(from: dateComponents)!
        
        // For a given date that is known to be *not* Daylight savings change
        // Check that crossing the month threshold is valid
        let days = 5
        let expectedDate = sept28.addingTimeInterval(Double(days * 24 * 60 * 60))
        let actualDate = sept28.addingNumberOfDays(days)
        XCTAssertEqual(actualDate, expectedDate)
    }
    
    func testAllDefaultSectionFilters() {
        let manager = TestScheduledActivityManager()
        manager.daysAhead = 7
        let (schedules, sections, expectedTaskIdPerSection) = createFullSchedule()
        manager.sections = sections
        manager.activities = schedules
        
        for (tableSection, expectedTaskIds) in expectedTaskIdPerSection.enumerated() {
            let filteredSchedules = manager.scheduledActivities(for: tableSection)
            let taskIds = filteredSchedules.map({ $0.taskIdentifier }) as! [String]
            XCTAssertEqual(taskIds, expectedTaskIds, "\(tableSection)")
        }
    }
    
    func testExpiredTodaySectionFilter() {
        
        let calendar = Calendar(identifier: Calendar.Identifier.gregorian)
        let hour: TimeInterval = 60 * 60
        let day: TimeInterval = 24 * hour
        
        let now = Date()
        let midnightToday = calendar.startOfDay(for: now)
        let midnightTomorrow = midnightToday.addingTimeInterval(day)

        // Do not attempt to run the test within 5 minutes of midnight.
        // This is a much less complicated (and fairly reliable) than mocking the current date.
        guard (midnightTomorrow.timeIntervalSinceNow < 5 * 60) else {
            return
        }
        
        let past = now.addingTimeInterval(-15*60) // 15 minutes ago
        let expiredPast = now.addingTimeInterval(-10*60) // 10 minutes ago
        
        let manager = TestScheduledActivityManager()
        let expiredTodaySchedule = createScheduledActivity("Expired Today", scheduledOn: past, expiresOn: expiredPast, finishedOn: nil, optional: false)
        
        let (schedules, _, _) = createFullSchedule()
        manager.sections = [.today]
        manager.activities = schedules + [expiredTodaySchedule]
        
        let filteredSchedules = manager.scheduledActivities(for: 0)
        XCTAssertTrue(filteredSchedules.contains(expiredTodaySchedule))
        
    }
    
    // MARK: helper methods
    
    func createScheduledActivities(_ taskIds:[String]) -> [SBBScheduledActivity] {
        
        var ret: [SBBScheduledActivity] = []
        
        for taskId in taskIds {
            let schedule = createScheduledActivity(taskId)
            ret += [schedule]
        }
        
        return ret
    }
    
    func createFullSchedule() -> ([SBBScheduledActivity], [SBAScheduledActivitySection], [[String]]) {
        
        let calendar = Calendar(identifier: Calendar.Identifier.gregorian)
        let hour: TimeInterval = 60 * 60
        //let day: TimeInterval = 24 * hour
        
        let now = Date()
        let twoDaysAgo = now.addingNumberOfDays(-2)
        let yesterday = now.addingNumberOfDays(-1)
        let midnightToday = calendar.startOfDay(for: now)
        let fourAM = midnightToday.addingTimeInterval(4 * hour)
        let tenPM = midnightToday.addingTimeInterval(22 * hour)
        let tomorrow = now.addingNumberOfDays(1)
        let twoDaysFromNow = now.addingNumberOfDays(2)
        let sevenDaysFromNow = now.addingNumberOfDays(7)
        let eightDaysFromNow = now.addingNumberOfDays(8)
        
        var schedules: [SBBScheduledActivity] = []
        var sections: [SBAScheduledActivitySection] = []
        var sectionIdentifiers: [[String]] = []

        // Section - Expired Yesterday
        schedules.append(createScheduledActivity("2 Days Ago - Expired Yesterday",
            scheduledOn: twoDaysAgo, expiresOn: yesterday, finishedOn: nil, optional: false))
        sectionIdentifiers.append(["2 Days Ago - Expired Yesterday"])
        sections.append(.expiredYesterday)
        
        // Section - Today
        schedules.append(createScheduledActivity("2 Days Ago - Incomplete",
            scheduledOn: twoDaysAgo, expiresOn: nil, finishedOn: nil, optional: false))
        schedules.append(createScheduledActivity("2 Days Ago - Completed Today",
            scheduledOn: twoDaysAgo, expiresOn: nil, finishedOn: now, optional: false))
        schedules.append(createScheduledActivity("4AM - Incomplete",
            scheduledOn: fourAM, expiresOn: fourAM.addingTimeInterval(hour), finishedOn: nil, optional: false))
        schedules.append(createScheduledActivity("4AM - Complete",
            scheduledOn: fourAM, expiresOn: fourAM.addingTimeInterval(hour), finishedOn: fourAM.addingTimeInterval(0.5 * hour), optional: false))
        schedules.append(createScheduledActivity("10PM - Incomplete",
            scheduledOn: tenPM, expiresOn: tenPM.addingTimeInterval(hour), finishedOn: nil, optional: false))
        sectionIdentifiers.append(
            ["2 Days Ago - Incomplete",
            "2 Days Ago - Completed Today",
            "4AM - Incomplete",
            "4AM - Complete",
            "10PM - Incomplete",])
        sections.append(.today)

        // Section - Tomorrow
        schedules.append(createScheduledActivity("Tomorrow",
            scheduledOn: tomorrow, expiresOn: nil, finishedOn: nil, optional: false))
        sectionIdentifiers.append(["Tomorrow"])
        sections.append(.tomorrow)
        
        // Section - Keep Going
        schedules.append(createScheduledActivity("2 Days Ago - Incomplete - Optional",
            scheduledOn: twoDaysAgo, expiresOn: nil, finishedOn: nil, optional: true))
        sectionIdentifiers.append(["2 Days Ago - Incomplete - Optional"])
        sections.append(.keepGoing)
        
        // Section - Coming Week
        schedules.append(createScheduledActivity("Two Days From Now",
            scheduledOn: twoDaysFromNow, expiresOn: nil, finishedOn: nil, optional: false))
        schedules.append(createScheduledActivity("Seven Days From Now",
            scheduledOn: sevenDaysFromNow, expiresOn: nil, finishedOn: nil, optional: false))
        sectionIdentifiers.append(["Tomorrow", "Two Days From Now", "Seven Days From Now"])
        sections.append(.comingUp)
        
        // Section - None
        schedules.append(createScheduledActivity("2 Days Ago - Completed Yesterday",
            scheduledOn: twoDaysAgo, expiresOn: nil, finishedOn: yesterday, optional: false))
        schedules.append(createScheduledActivity("2 Days Ago - Completed Today - Optional",
            scheduledOn: twoDaysAgo, expiresOn: nil, finishedOn: now, optional: true))
        schedules.append(createScheduledActivity("8 Days From Now",
            scheduledOn: eightDaysFromNow, expiresOn: nil, finishedOn: nil, optional: false))

        return (schedules, sections, sectionIdentifiers)
    }
    
    func createScheduledActivity(_ taskId: String, scheduledOn:Date = Date(), expiresOn:Date? = nil, finishedOn:Date? = nil, optional:Bool = false) -> SBBScheduledActivity {
        
        let schedule = SBBScheduledActivity()
        schedule.guid = UUID().uuidString
        schedule.activity = SBBActivity()
        schedule.activity.guid = UUID().uuidString
        schedule.activity.task = SBBTaskReference()
        schedule.activity.task.identifier = taskId
        schedule.scheduledOn = scheduledOn
        schedule.expiresOn = expiresOn
        schedule.finishedOn = finishedOn
        schedule.persistentValue = optional
        return schedule
    }

    func buildTaskResult(_ task: ORKTask,
                         selectedMeds: [String : NSNumber]? = nil,
                         outputDirectory: NSURL? = nil,
                         tooLoudCount: Int = 0) -> ORKTaskResult {
        
        let taskResult = ORKTaskResult(taskIdentifier: task.identifier, taskRun: UUID(), outputDirectory: outputDirectory as URL?)
        taskResult.results = []
        
        // setup voice step search
        let voicePrefix = tooLoudCount > 0 && task.identifier != "Voice Activity" ? "Voice Activity." : ""
        let voiceCountdownStepIdentifier = voicePrefix + "countdown"
        let voiceTooLoudStepIdentifier = voicePrefix + "audio.tooloud"
        
        var copyTaskResult: ORKTaskResult = taskResult.copy() as! ORKTaskResult
        var previousStep: ORKStep? = nil
        while let step = task.step(after: previousStep, with: taskResult) {
            
            // Building the task result should not modify the result set
            XCTAssertEqual(taskResult, copyTaskResult)
            
            if let _ = step as? SBATrackedSelectionStep {
                // modify the result to include the selected items if this is the selection step
                let answerMap = NSMutableDictionary()
                if let meds = selectedMeds, let choices = meds.allKeys {
                    answerMap.setValue(choices, forKey: "choices")
                    for (key, value) in meds {
                        answerMap.setValue(value, forKey: key)
                    }
                }
                else {
                    answerMap.setValue("None", forKey: "choices")
                }
                let stepResult = step.instantiateDefaultStepResult(answerMap)
                taskResult.results?.append(stepResult)
            }
            else if tooLoudCount > 0 && step.identifier == voiceCountdownStepIdentifier {
                for ii in 0...tooLoudCount {
                    taskResult.results?.append(step.instantiateDefaultStepResult(nil))
                    if ii < tooLoudCount {
                        taskResult.results?.append(ORKStepResult(identifier: voiceTooLoudStepIdentifier))
                    }
                }
            }
            else {
                // Add the result to the task
                let stepResult = step.instantiateDefaultStepResult(nil)
                taskResult.results?.append(stepResult)
            }
            
            // set the previous step to this step
            previousStep = step
            copyTaskResult = taskResult.copy() as! ORKTaskResult
        }
        
        // Update the start and end dates
        let stepInterval = 5.0
        var date: Date = taskResult.startDate.addingTimeInterval(Double(-1 * taskResult.results!.count) * stepInterval)
        for result in taskResult.results! {
            result.startDate = date
            date = date.addingTimeInterval(stepInterval)
            result.endDate = date
        }
        taskResult.startDate = taskResult.results!.first!.startDate
        taskResult.endDate = taskResult.results!.last!.endDate
        
        // Check assumptions
        XCTAssertGreaterThan(taskResult.results!.count, 0)
        if (tooLoudCount == 0) {
            // Only validate the paramenters if the tooLoudCount is zero
            // because RK Navigiation will add multiple steps with the same result identifier
            taskResult.validateParameters()
        }
        
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
    var cacheDaysAhead: Int = 0
    var cacheDaysBehind: Int = 0
    var environment: SBBEnvironment = .prod
    var appStoreLinkURLString: String?
    var emailForLoginViaExternalId: String?
    var passwordFormatForLoginViaExternalId: String?
    var testUserDataGroup: String?
    var schemaMap: [NSDictionary]? {
        return [memorySchemaRef as NSDictionary, walkingSchemaRef as NSDictionary, tappingSchemaRef as NSDictionary, voiceSchemaRef as NSDictionary]
    }
    var taskMap: [NSDictionary]? {
        return [medTaskRef as NSDictionary, comboTaskRef as NSDictionary, tappingTaskRef as NSDictionary, memoryTaskRef as NSDictionary, voiceTaskRef as NSDictionary]
    }
    var filenameMap: NSDictionary?
    var certificateName: String?
    var newsfeedURLString: String?
    var logoImageName: String?
    var appUpdateURLString: String?
    var disableTestUserCheck: Bool = false
    var permissionTypeItems: [Any]?
    var keychainService: String?
    var keychainAccessGroup: String?
    var appGroupIdentifier: String?
    
    let medTaskRef = [
        "taskIdentifier"    : medicationTrackingTaskId,
        "resourceName"      : "MedicationTracking",
        "resourceBundle"    : Bundle(for: SBAScheduledActivityManagerTests.classForCoder()).bundleIdentifier ?? "",
        "classType"         : "TrackedDataObjectCollection"]
    let comboTaskRef = [
        "taskIdentifier"    : comboTaskId,
        "resourceName"      : "CombinedTask",
        "resourceBundle"    : Bundle(for: SBAScheduledActivityManagerTests.classForCoder()).bundleIdentifier ?? ""]
    let tappingTaskRef = [
        "taskIdentifier"    : tappingTaskId,
        "resourceName"      : "TappingTask",
        "resourceBundle"    : Bundle(for: SBAScheduledActivityManagerTests.classForCoder()).bundleIdentifier ?? ""]
    let memoryTaskRef = [
        "taskIdentifier"    : memoryTaskId,
        "schemaIdentifier"  : "Memory Activity",
        "taskType"          : "memory"]
    let voiceTaskRef = [
        "taskIdentifier"    : voiceTaskId,
        "schemaIdentifier"  : "Voice Activity",
        "taskType"          : "voice"]
    
    let walkingSchemaRef = [
        "schemaIdentifier"  : "Walking Activity",
        "schemaRevision"    : 7,
    ] as [String : Any]
    let memorySchemaRef = [
        "schemaIdentifier"  : "Memory Activity",
        "schemaRevision"    : 3,
        ] as [String : Any]
    let tappingSchemaRef = [
        "schemaIdentifier"  : "Tapping Activity",
        "schemaRevision"    : 5,
        ] as [String : Any]
    let voiceSchemaRef = [
        "schemaIdentifier"  : "Voice Activity",
        "schemaRevision"    : 1,
        ] as [String : Any]
    
    // MARK: test function overrrides
    var updatedScheduledActivities:[SBBScheduledActivity]?
    
    override func sendUpdated(scheduledActivities: [SBBScheduledActivity]) {
        updatedScheduledActivities = scheduledActivities
    }
    
    override func instantiateTaskViewController(for schedule: SBBScheduledActivity, task: ORKTask, taskRef: SBATaskReference) -> SBATaskViewController {
        return TestTaskViewController(task: task, taskRun: nil)
    }
    
}
