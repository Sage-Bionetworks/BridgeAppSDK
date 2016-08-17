//
//  SBAActivityArchive.swift
//  BridgeAppSDK
//
//  Created by Shannon Young on 8/11/16.
//  Copyright © 2016 Sage Bionetworks. All rights reserved.
//

import XCTest

class SBAActivityArchive: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    // MARK: V1 Survey support
    
    func testSingleChoiceQuestionResult() {
        
        let result = ORKChoiceQuestionResult(identifier: "test")
        result.questionType = .SingleChoice
        result.choiceAnswers = ["answer"]
        
        guard let json = checkSharedArchiveKeys(result, stepIdentifier: "test", expectedFilename: "test.json") else {
            XCTAssert(false)
            return
        }
        
        // Check the values specific to this result type
        XCTAssertEqual(json["item"] as? String, "test")
        XCTAssertEqual(json["questionTypeName"] as? String, "SingleChoice")
        guard let choiceAnswers = json["choiceAnswers"] as? [String] else {
            XCTAssert(false, "\(json["choiceAnswers"]) not of expected type")
            return
        }
        XCTAssertEqual(choiceAnswers, ["answer"])
    }
    
    func testMultipleChoiceQuestionResult() {
        
        let result = ORKChoiceQuestionResult(identifier: "test")
        result.questionType = .MultipleChoice
        result.choiceAnswers = ["A", "B"]
        
        guard let json = checkSharedArchiveKeys(result, stepIdentifier: "test", expectedFilename: "test.json") else {
            XCTAssert(false)
            return
        }
        
        // Check the values specific to this result type
        XCTAssertEqual(json["item"] as? String, "test")
        XCTAssertEqual(json["questionTypeName"] as? String, "MultipleChoice")
        guard let choiceAnswers = json["choiceAnswers"] as? [String] else {
            XCTAssert(false, "\(json["choiceAnswers"]) not of expected type")
            return
        }
        XCTAssertEqual(choiceAnswers, ["A", "B"])
    }
    
    func testScaleQuestionResult() {
        
        let result = ORKScaleQuestionResult(identifier: "test")
        result.questionType = .Scale
        result.scaleAnswer = NSNumber(integer: 5)
        
        guard let json = checkSharedArchiveKeys(result, stepIdentifier: "test", expectedFilename: "test.json") else {
            XCTAssert(false)
            return
        }
        
        // Check the values specific to this result type
        XCTAssertEqual(json["item"] as? String, "test")
        XCTAssertEqual(json["questionTypeName"] as? String, "Scale")
        XCTAssertEqual(json["scaleAnswer"] as? NSNumber, NSNumber(integer: 5))
    }
    
    func testMoodScaleQuestionResult() {
        
        let result = ORKMoodScaleQuestionResult(identifier: "test")
        result.questionType = .SingleChoice
        result.scaleAnswer = NSNumber(integer: 5)
        
        guard let json = checkSharedArchiveKeys(result, stepIdentifier: "test", expectedFilename: "test.json") else {
            XCTAssert(false)
            return
        }
        
        // Check the values specific to this result type
        XCTAssertEqual(json["item"] as? String, "test")
        XCTAssertEqual(json["questionTypeName"] as? String, "Scale")
        XCTAssertEqual(json["scaleAnswer"] as? NSNumber, NSNumber(integer: 5))
    }
    
    func testBooleanQuestionResult() {
        
        let result = ORKBooleanQuestionResult(identifier: "test")
        result.questionType = .Boolean
        result.booleanAnswer = NSNumber(bool: true)
        
        guard let json = checkSharedArchiveKeys(result, stepIdentifier: "test", expectedFilename: "test.json") else {
            XCTAssert(false)
            return
        }
        
        // Check the values specific to this result type
        XCTAssertEqual(json["item"] as? String, "test")
        XCTAssertEqual(json["questionTypeName"] as? String, "Boolean")
        XCTAssertEqual(json["booleanAnswer"] as? NSNumber, NSNumber(bool: true))
    }
    
    func testTextQuestionResult() {
        
        let result = ORKTextQuestionResult(identifier: "test")
        result.questionType = .Text
        result.textAnswer = "foo bar"
        
        guard let json = checkSharedArchiveKeys(result, stepIdentifier: "test", expectedFilename: "test.json") else {
            XCTAssert(false)
            return
        }
        
        // Check the values specific to this result type
        XCTAssertEqual(json["item"] as? String, "test")
        XCTAssertEqual(json["questionTypeName"] as? String, "Text")
        XCTAssertEqual(json["textAnswer"] as? String, "foo bar")
    }
    
    func testNumericQuestionResult_Integer() {
        
        let result = ORKNumericQuestionResult(identifier: "test")
        result.questionType = .Integer
        result.numericAnswer = NSNumber(integer: 5)
        
        guard let json = checkSharedArchiveKeys(result, stepIdentifier: "test", expectedFilename: "test.json") else {
            XCTAssert(false)
            return
        }
        
        // Check the values specific to this result type
        XCTAssertEqual(json["item"] as? String, "test")
        XCTAssertEqual(json["questionTypeName"] as? String, "Integer")
        XCTAssertEqual(json["numericAnswer"] as? NSNumber, NSNumber(integer: 5))
    }
    
    func testNumericQuestionResult_Decimal() {
        
        let result = ORKNumericQuestionResult(identifier: "test")
        result.questionType = .Decimal
        result.numericAnswer = NSNumber(float: 1.2)
        
        guard let json = checkSharedArchiveKeys(result, stepIdentifier: "test", expectedFilename: "test.json") else {
            XCTAssert(false)
            return
        }
        
        // Check the values specific to this result type
        XCTAssertEqual(json["item"] as? String, "test")
        XCTAssertEqual(json["questionTypeName"] as? String, "Decimal")
        XCTAssertEqual(json["numericAnswer"] as? NSNumber, NSNumber(float: 1.2))
    }
    
    func testTimeOfDayQuestionResult() {
        
        let result = ORKTimeOfDayQuestionResult(identifier: "test")
        result.questionType = .TimeOfDay
        result.dateComponentsAnswer = NSDateComponents()
        result.dateComponentsAnswer?.hour = 5
        result.dateComponentsAnswer?.minute = 32
        
        guard let json = checkSharedArchiveKeys(result, stepIdentifier: "test", expectedFilename: "test.json") else {
            XCTAssert(false)
            return
        }
        
        // Check the values specific to this result type
        XCTAssertEqual(json["item"] as? String, "test")
        XCTAssertEqual(json["questionTypeName"] as? String, "TimeOfDay")
        XCTAssertEqual(json["dateComponentsAnswer"] as? String, "05:32:00")
    }
    
    func testDateQuestionResult_Date() {
        
        let result = ORKDateQuestionResult(identifier: "test")
        result.questionType = .Date
        result.dateAnswer = date(year: 1969, month: 8, day: 3)
        
        guard let json = checkSharedArchiveKeys(result, stepIdentifier: "test", expectedFilename: "test.json") else {
            XCTAssert(false)
            return
        }
        
        // Check the values specific to this result type
        XCTAssertEqual(json["item"] as? String, "test")
        XCTAssertEqual(json["questionTypeName"] as? String, "Date")
        XCTAssertEqual(json["dateAnswer"] as? String, "1969-08-03")
    }
    
    func testDateQuestionResult_DateAndTime() {
        
        let result = ORKDateQuestionResult(identifier: "test")
        result.questionType = .DateAndTime
        result.dateAnswer = date(year: 1969, month: 8, day: 3, hour: 4, minute: 10, second: 00)
        
        guard let json = checkSharedArchiveKeys(result, stepIdentifier: "test", expectedFilename: "test.json") else {
            XCTAssert(false)
            return
        }
        
        // Check the values specific to this result type
        XCTAssertEqual(json["item"] as? String, "test")
        XCTAssertEqual(json["questionTypeName"] as? String, "DateAndTime")
        let expectedAnswer = "1969-08-03T04:10:00.000" + timezoneString()
        XCTAssertEqual(json["dateAnswer"] as? String, expectedAnswer)
    }
    
    func testTimeIntervalQuestionResult() {
        // TODO: syoung 08/11/2016 Not currently used by any studies. The implementation that is available in RK
        // is limited and does not match the format expected by the server. Revisit this when there is a need to 
        // support it.
    }
    
    // MARK: Helper methods
    
    func checkSharedArchiveKeys(result: ORKResult, stepIdentifier: String, expectedFilename: String) -> [NSObject : AnyObject]? {
        
        result.startDate = date(year: 2016, month: 7, day: 4, hour: 8, minute: 29, second: 54)
        result.endDate = date(year: 2016, month: 7, day: 4, hour: 8, minute: 30, second: 23)
        
        // Create the archive
        let archiveObject = result.bridgeData(stepIdentifier)
        XCTAssertNotNil(archiveObject)
        
        guard let archiveResult = archiveObject else { return nil }
        
        XCTAssertEqual(archiveResult.filename, expectedFilename)
        
        guard let json = archiveResult.result as? [NSObject: AnyObject] else {
            XCTAssert(false, "\(archiveResult.result) not of expected type")
            return nil
        }
        
        // NSDate does not carry the timezone and thus, will always be
        // represented in the current timezone
        let expectedStart = "2016-07-04T08:29:54.000" + timezoneString()
        let expectedEnd = "2016-07-04T08:30:23.000" + timezoneString()
        XCTAssertEqual(json["startDate"] as? String, expectedStart)
        XCTAssertEqual(json["endDate"] as? String, expectedEnd)
        
        return json
    }
    
    func date(year year: Int, month: Int, day: Int, hour: Int = 0, minute: Int = 0, second: Int = 0) -> NSDate {
        
        let calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)!
        let components = NSDateComponents()
        components.day = day
        components.month = month
        components.year = year
        components.hour = hour
        components.minute = minute
        components.second = second
        return calendar.dateFromComponents(components)!
    }
    
    func timezoneString() -> String {
        let hoursUnit = 60 * 60
        let calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)!
        let timezoneHours: Int = calendar.timeZone.secondsFromGMT / hoursUnit
        let timezoneSeconds = abs(calendar.timeZone.secondsFromGMT - (timezoneHours * hoursUnit))
        let timezone = String(format: "%+.2d:%02d", timezoneHours, timezoneSeconds)
        return timezone
    }

}
