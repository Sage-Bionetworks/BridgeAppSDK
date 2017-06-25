//
//  SBABridgeManagerTests.swift
//  BridgeAppSDK
//
//  Copyright © 2017 Sage Bionetworks. All rights reserved.
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

class SBABridgeManagerTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    // fetchScheduledActivitiesWithStartDate
    
    func testFetchScheduledActivitiesWithStartDate_6Ahead_10Behind() {
        
        let activityManager = TestActivityManager()
        let schedules = buildSchedule(daysAhead: 6, daysBehind: 10)
        activityManager.getScheduledActivitiesForRange_Result = schedules
        SBBComponentManager.registerComponent(activityManager, for: SBBActivityManager.classForCoder())
        
        let now = Date()
        let startDate = now.addingNumberOfDays(7)
        let endDate = now.addingNumberOfDays(-10)
        
        let exp = expectation(description: "Schedule returned")
        var result: [SBBScheduledActivity]?
        SBABridgeManager.fetchScheduledActivities(from: startDate, to: endDate) { (output, _) in
            result = output as? [SBBScheduledActivity]
            exp.fulfill()
        }
        
        // Wait for the expectation to be fulfilled
        waitForExpectations(timeout: 1) { error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }
        }
        
        XCTAssertNotNil(result)
        XCTAssertTrue(activityManager.getScheduledActivitiesForRange_called)
        XCTAssertEqual(activityManager.getScheduledActivitiesForRange_scheduledFrom, startDate)
        XCTAssertEqual(activityManager.getScheduledActivitiesForRange_scheduledTo, endDate)
        
        // Check that the duplicates are removed
        guard result != nil else { return }
        XCTAssertEqual(result!.count, 68)
    }
    
    func testFetchScheduledActivitiesWithStartDate_0Ahead_10Behind() {
        
        let activityManager = TestActivityManager()
        let schedules = buildSchedule(daysAhead: 1, daysBehind: 10)
        activityManager.getScheduledActivitiesForRange_Result = schedules
        SBBComponentManager.registerComponent(activityManager, for: SBBActivityManager.classForCoder())
        
        let now = Date()
        let startDate = now.addingNumberOfDays(-3)
        let endDate = now.addingNumberOfDays(-10)
        
        let exp = expectation(description: "Schedule returned")
        var result: [SBBScheduledActivity]?
        SBABridgeManager.fetchScheduledActivities(from: startDate, to: endDate) { (output, _) in
            result = output as? [SBBScheduledActivity]
            exp.fulfill()
        }
        
        // Wait for the expectation to be fulfilled
        waitForExpectations(timeout: 1) { error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }
        }
        
        XCTAssertNotNil(result)
        XCTAssertFalse(activityManager.getScheduledActivities_called)
        XCTAssertTrue(activityManager.getScheduledActivitiesForRange_called)
        XCTAssertEqual(activityManager.getScheduledActivitiesForRange_scheduledFrom, startDate)
        XCTAssertEqual(activityManager.getScheduledActivitiesForRange_scheduledTo, endDate)
    }
    
    // MARK: build schedules
    
    func createActivityGuids() -> [String] {
        return [UUID().uuidString, UUID().uuidString, UUID().uuidString, UUID().uuidString]
    }
    
    func buildSchedule(daysAhead:Int, daysBehind:Int) -> [SBBScheduledActivity] {
        
        let midnight = Date().startOfDay()
        let guids = createActivityGuids()
        var schedules:[SBBScheduledActivity] = []
        
        for ii in (-1*daysBehind)...daysAhead {
            for guid in guids {
                let schedule = createSchedule(guid: guid, scheduledOn: midnight.addingNumberOfDays(ii))
                schedules.append(schedule)
            }
        }
        
        return schedules
    }
    
    func createSchedule(guid: String, scheduledOn: Date) -> SBBScheduledActivity {
        
        let schedule = SBBScheduledActivity()
        schedule.guid = UUID().uuidString
        schedule.scheduledOn = scheduledOn
        schedule.expiresOn = scheduledOn.addingNumberOfDays(1)
        
        let activity = SBBActivity()
        activity.guid = guid
        schedule.activity = activity
        
        return schedule
    }
}

class TestActivityManager : NSObject, SBBActivityManagerProtocol {
    
    fileprivate let taskQueue = DispatchQueue(label: UUID().uuidString)
    
    // MARK: getScheduledActivities
    
    var getScheduledActivities_Result: [SBBScheduledActivity]?
    var getScheduledActivities_Error: Error?
    
    var getScheduledActivities_called: Bool = false
    var getScheduledActivities_daysAhead: Int = 0
    var getScheduledActivities_daysBehind: Int = 0
    var getScheduledActivities_cachingPolicy: SBBCachingPolicy = SBBCachingPolicy.noCaching
    

    func getScheduledActivities(forDaysAhead daysAhead: Int, daysBehind: Int, cachingPolicy policy: SBBCachingPolicy, withCompletion completion: @escaping SBBActivityManagerGetCompletionBlock) -> URLSessionTask {
        
        getScheduledActivities_called = true
        getScheduledActivities_daysAhead = daysAhead
        getScheduledActivities_daysBehind = daysBehind
        getScheduledActivities_cachingPolicy = policy
        
        taskQueue.async {
            completion(self.getScheduledActivities_Result, self.getScheduledActivities_Error)
        }
        
        return URLSessionTask()
    }
    
    func getScheduledActivities(forDaysAhead daysAhead: Int, cachingPolicy policy: SBBCachingPolicy, withCompletion completion: @escaping SBBActivityManagerGetCompletionBlock) -> URLSessionTask {
        return self.getScheduledActivities(forDaysAhead: daysAhead, daysBehind: 0, cachingPolicy: policy, withCompletion: completion)
    }
    
    func getScheduledActivities(forDaysAhead daysAhead: Int, withCompletion completion: @escaping SBBActivityManagerGetCompletionBlock) -> URLSessionTask {
        return self.getScheduledActivities(forDaysAhead: daysAhead, daysBehind: 0, cachingPolicy: .noCaching, withCompletion: completion)
    }
    
    
    // MARK: Not implemented
    
    func start(_ scheduledActivity: SBBScheduledActivity, asOf startDate: Date, withCompletion completion: SBBActivityManagerUpdateCompletionBlock? = nil) -> URLSessionTask {
        return URLSessionTask()
    }

    func finish(_ scheduledActivity: SBBScheduledActivity, asOf finishDate: Date, withCompletion completion: SBBActivityManagerUpdateCompletionBlock? = nil) -> URLSessionTask {
        return URLSessionTask()
    }
    
    func delete(_ scheduledActivity: SBBScheduledActivity, withCompletion completion: SBBActivityManagerUpdateCompletionBlock? = nil) -> URLSessionTask {
        return URLSessionTask()
    }
    
    func setClientData(_ clientData: SBBJSONValue, for scheduledActivity: SBBScheduledActivity, withCompletion completion: SBBActivityManagerUpdateCompletionBlock? = nil) -> URLSessionTask {
        return URLSessionTask()
    }

    public func updateScheduledActivities(_ scheduledActivities: [Any], withCompletion completion: SBBActivityManagerUpdateCompletionBlock? = nil) -> URLSessionTask {
        return URLSessionTask()
    }


    // MARK: getScheduledActivitiesForGuid
    
    var getScheduledActivitiesForRange_Result: [SBBScheduledActivity]?
    var getScheduledActivitiesForRange_Error: Error?
    var getScheduledActivitiesForRange_called: Bool = false
    var getScheduledActivitiesForRange_scheduledFrom: Date?
    var getScheduledActivitiesForRange_scheduledTo: Date?
    var getScheduledActivitiesForRange_cachingPolicy: SBBCachingPolicy = SBBCachingPolicy.noCaching
    
    public func getScheduledActivities(from scheduledFrom: Date, to scheduledTo: Date, cachingPolicy policy: SBBCachingPolicy, withCompletion completion: @escaping SBBActivityManagerGetCompletionBlock) -> URLSessionTask {
        
        getScheduledActivitiesForRange_called = true
        getScheduledActivitiesForRange_scheduledFrom = scheduledFrom
        getScheduledActivitiesForRange_scheduledTo = scheduledTo
        getScheduledActivitiesForRange_cachingPolicy = policy
        
        taskQueue.async {
            completion(self.getScheduledActivitiesForRange_Result, self.getScheduledActivitiesForRange_Error)
        }
        
        return URLSessionTask()
    }

    public func getScheduledActivities(from scheduledFrom: Date, to scheduledTo: Date, withCompletion completion: @escaping SBBActivityManagerGetCompletionBlock) -> URLSessionTask {
        return getScheduledActivities(from: scheduledFrom, to: scheduledTo, cachingPolicy: .fallBackToCached, withCompletion: completion)
    }

    
}



