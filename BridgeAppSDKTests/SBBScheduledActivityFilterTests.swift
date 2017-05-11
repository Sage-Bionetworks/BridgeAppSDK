//
//  SBBScheduledActivityFilterTests.swift
//  BridgeAppSDK
//
//  Created by Shannon Young on 5/11/17.
//  Copyright © 2017 Sage Bionetworks. All rights reserved.
//

import XCTest
@testable import BridgeAppSDK
import BridgeSDK

class SBBScheduledActivityFilterTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testScheduledPredicate() {
        
        let today = Date().startOfDay()
        let today_expired = createScheduledActivityWithTask("a",
                                                            scheduleGuid: "TODAY_EXPIRED",
                                                            scheduledOn: today.addingNumberOfDays(-3),
                                                            expiresOn: today.addingTimeInterval(120))
        let today_finished = createScheduledActivityWithTask("b",
                                                             scheduleGuid: "TODAY_FINISHED",
                                                             scheduledOn: today.addingNumberOfDays(-3),
                                                             expiresOn: today.addingNumberOfDays(3),
                                                             finishedOn: Date())
        let today_todo = createScheduledActivityWithTask("b",
                                                         scheduleGuid: "NOT_DONE_AVAILABLE",
                                                         scheduledOn: today.addingNumberOfDays(-3),
                                                         expiresOn: today.addingNumberOfDays(3))
        
        let yesterday = today.addingNumberOfDays(-1)
        let yesterday_expired = createScheduledActivityWithTask("a",
                                                            scheduleGuid: "EXPIRED_YESTERDAY",
                                                            scheduledOn: yesterday.addingNumberOfDays(-3),
                                                            expiresOn: yesterday.addingTimeInterval(120))
        let yesterday_finished = createScheduledActivityWithTask("b",
                                                             scheduleGuid: "FINISHED_YESTERDAY",
                                                             scheduledOn: yesterday.addingNumberOfDays(-3),
                                                             expiresOn: today,
                                                             finishedOn: yesterday.addingTimeInterval(60*60))
        
        let schedules = [today_expired, today_finished, today_todo, yesterday_expired, yesterday_finished]
        
        let todayPredicate = SBBScheduledActivity.scheduledPredicate(on: Date())
        let todayFiltered = schedules.filter({ todayPredicate.evaluate(with: $0) }).map({ $0.guid! })
        let todayExpected = [today_expired, today_finished, today_todo].map({ $0.guid! })
        XCTAssertEqual(todayFiltered, todayExpected)
        
        let yesterdayPredicate = SBBScheduledActivity.scheduledPredicate(on: Date().addingNumberOfDays(-1))
        let yesterdayFiltered = schedules.filter({ yesterdayPredicate.evaluate(with: $0) }).map({ $0.guid! })
        let yesterdayExpected = [yesterday_expired, yesterday_finished].map({ $0.guid! })
        XCTAssertEqual(yesterdayFiltered, yesterdayExpected)
        
        let tomorrowPredicate = SBBScheduledActivity.scheduledPredicate(on: Date().addingNumberOfDays(1))
        let tomorrowFiltered = schedules.filter({ tomorrowPredicate.evaluate(with: $0) }).map({ $0.guid! })
        let tomorrowExpected = [today_todo].map({ $0.guid! })
        XCTAssertEqual(tomorrowFiltered, tomorrowExpected)
    }
    
    func testIncludeTasksPredicate() {
        
        let taskIdentifiers = ["a","b","c","d","e","f"]
        let schedules = taskIdentifiers.map({ return createScheduledActivityWithTask($0) })
        let predicate = SBBScheduledActivity.includeTasksPredicate(with: ["b","d"])
        let filtered = schedules.filter({ predicate.evaluate(with: $0) })
        let expected = [schedules[1],schedules[3]]
        
        XCTAssertEqual(filtered, expected)
    }

    // MARK: helper methods
    
    func createScheduledActivityWithTask(_ taskId: String,
                                         scheduleGuid: String? = nil,
                                         scheduledOn:Date = Date(),
                                         expiresOn:Date? = nil,
                                         finishedOn:Date? = nil,
                                         optional:Bool = false) -> SBBScheduledActivity {
        
        let schedule = SBBScheduledActivity()
        schedule.guid = scheduleGuid ?? UUID().uuidString
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
    
    func createScheduledActivityWithSurvey(_ surveyId: String,
                                           scheduleGuid: String? = nil,
                                           scheduledOn:Date = Date(),
                                           expiresOn:Date? = nil,
                                           finishedOn:Date? = nil,
                                           optional:Bool = false) -> SBBScheduledActivity {
        
        let schedule = SBBScheduledActivity()
        schedule.guid = scheduleGuid ?? UUID().uuidString
        schedule.activity = SBBActivity()
        schedule.activity.guid = UUID().uuidString
        schedule.activity.survey = SBBSurveyReference()
        schedule.activity.survey.identifier = surveyId
        schedule.scheduledOn = scheduledOn
        schedule.expiresOn = expiresOn
        schedule.finishedOn = finishedOn
        schedule.persistentValue = optional
        return schedule
    }
}
