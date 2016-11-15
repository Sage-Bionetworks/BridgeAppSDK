//
//  SBAActivityArchive.swift
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
        result.questionType = .singleChoice
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
        
        guard let answer = json["answer"] as? String else {
            XCTAssert(false, "\(json["answer"]) not of expected type")
            return
        }
        XCTAssertEqual(answer, "answer")
    }
    
    func testMultipleChoiceQuestionResult() {
        
        let result = ORKChoiceQuestionResult(identifier: "test")
        result.questionType = .multipleChoice
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
        result.questionType = .scale
        result.scaleAnswer = NSNumber(value: 5)
        
        guard let json = checkSharedArchiveKeys(result, stepIdentifier: "test", expectedFilename: "test.json") else {
            XCTAssert(false)
            return
        }
        
        // Check the values specific to this result type
        XCTAssertEqual(json["item"] as? String, "test")
        XCTAssertEqual(json["questionTypeName"] as? String, "Scale")
        XCTAssertEqual(json["scaleAnswer"] as? NSNumber, NSNumber(value: 5))
    }
    
    func testMoodScaleQuestionResult() {
        
        let result = ORKMoodScaleQuestionResult(identifier: "test")
        result.questionType = .singleChoice
        result.scaleAnswer = NSNumber(value: 5)
        
        guard let json = checkSharedArchiveKeys(result, stepIdentifier: "test", expectedFilename: "test.json") else {
            XCTAssert(false)
            return
        }
        
        // Check the values specific to this result type
        XCTAssertEqual(json["item"] as? String, "test")
        XCTAssertEqual(json["questionTypeName"] as? String, "Scale")
        XCTAssertEqual(json["scaleAnswer"] as? NSNumber, NSNumber(value: 5))
    }
    
    func testBooleanQuestionResult() {
        
        let result = ORKBooleanQuestionResult(identifier: "test")
        result.questionType = .boolean
        result.booleanAnswer = NSNumber(value: true)
        
        guard let json = checkSharedArchiveKeys(result, stepIdentifier: "test", expectedFilename: "test.json") else {
            XCTAssert(false)
            return
        }
        
        // Check the values specific to this result type
        XCTAssertEqual(json["item"] as? String, "test")
        XCTAssertEqual(json["questionTypeName"] as? String, "Boolean")
        XCTAssertEqual(json["booleanAnswer"] as? NSNumber, NSNumber(value: true))
    }
    
    func testTextQuestionResult() {
        
        let result = ORKTextQuestionResult(identifier: "test")
        result.questionType = .text
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
        result.questionType = .integer
        result.numericAnswer = NSNumber(value: 5)
        
        guard let json = checkSharedArchiveKeys(result, stepIdentifier: "test", expectedFilename: "test.json") else {
            XCTAssert(false)
            return
        }
        
        // Check the values specific to this result type
        XCTAssertEqual(json["item"] as? String, "test")
        XCTAssertEqual(json["questionTypeName"] as? String, "Integer")
        XCTAssertEqual(json["numericAnswer"] as? NSNumber, NSNumber(value: 5))
    }
    
    func testNumericQuestionResult_Decimal() {
        
        let result = ORKNumericQuestionResult(identifier: "test")
        result.questionType = .decimal
        result.numericAnswer = NSNumber(value: 1.2)
        
        guard let json = checkSharedArchiveKeys(result, stepIdentifier: "test", expectedFilename: "test.json") else {
            XCTAssert(false)
            return
        }
        
        // Check the values specific to this result type
        XCTAssertEqual(json["item"] as? String, "test")
        XCTAssertEqual(json["questionTypeName"] as? String, "Decimal")
        XCTAssertEqual(json["numericAnswer"] as? NSNumber, NSNumber(value: 1.2))
    }
    
    func testTimeOfDayQuestionResult() {
        
        let result = ORKTimeOfDayQuestionResult(identifier: "test")
        result.questionType = .timeOfDay
        result.dateComponentsAnswer = DateComponents()
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
        result.questionType = .date
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
        result.questionType = .dateAndTime
        result.dateAnswer = date(year: 1969, month: 8, day: 3, hour: 4, minute: 10, second: 00)
        
        guard let json = checkSharedArchiveKeys(result, stepIdentifier: "test", expectedFilename: "test.json") else {
            XCTAssert(false)
            return
        }
        
        // Check the values specific to this result type
        XCTAssertEqual(json["item"] as? String, "test")
        XCTAssertEqual(json["questionTypeName"] as? String, "Date")
        let expectedAnswer = "1969-08-03T04:10:00.000" + timezoneString(for: result.dateAnswer!)
        XCTAssertEqual(json["dateAnswer"] as? String, expectedAnswer)
    }
    
    func testTimeIntervalQuestionResult() {
        // TODO: syoung 08/11/2016 Not currently used by any studies. The implementation that is available in RK
        // is limited and does not match the format expected by the server. Revisit this when there is a need to 
        // support it.
    }
    
    // MARK: Helper methods
    
    func checkSharedArchiveKeys(_ result: ORKResult, stepIdentifier: String, expectedFilename: String) -> [AnyHashable: Any]? {
        
        result.startDate = date(year: 2016, month: 7, day: 4, hour: 8, minute: 29, second: 54)
        result.endDate = date(year: 2016, month: 7, day: 4, hour: 8, minute: 30, second: 23)
        
        // Create the archive
        let archiveObject = result.bridgeData(stepIdentifier)
        XCTAssertNotNil(archiveObject)
        
        guard let archiveResult = archiveObject else { return nil }
        
        XCTAssertEqual(archiveResult.filename, expectedFilename)
        
        guard let json = archiveResult.result as? [AnyHashable: Any] else {
            XCTAssert(false, "\(archiveResult.result) not of expected type")
            return nil
        }
        
        // NSDate does not carry the timezone and thus, will always be
        // represented in the current timezone
        let expectedStart = "2016-07-04T08:29:54.000" + timezoneString(for: result.startDate)
        let expectedEnd = "2016-07-04T08:30:23.000" + timezoneString(for: result.endDate)
        let actualStart = json["startDate"] as? String
        let actualEnd = json["endDate"] as? String
        
        XCTAssertEqual(actualStart, expectedStart)
        XCTAssertEqual(actualEnd, expectedEnd)
        
        return json
    }
    
    func date(year: Int, month: Int, day: Int, hour: Int = 0, minute: Int = 0, second: Int = 0) -> Date {
        
        let calendar = Calendar(identifier: Calendar.Identifier.gregorian)
        var components = DateComponents()
        components.day = day
        components.month = month
        components.year = year
        components.hour = hour
        components.minute = minute
        components.second = second
        return calendar.date(from: components)!
    }
    
    func timezoneString(for date: Date) -> String {
        let hoursUnit = 60 * 60
        let calendar = Calendar(identifier: Calendar.Identifier.gregorian)
        let isDST = calendar.timeZone.isDaylightSavingTime(for: date)
        let isNowDST = calendar.timeZone.isDaylightSavingTime()
        let timezoneNowHours: Int = calendar.timeZone.secondsFromGMT() / hoursUnit
        let timezoneHours: Int = timezoneNowHours + (isDST && !isNowDST ? 1 : 0) + (!isDST && isNowDST ? -1 : 0)
        let timezone = String(format: "%+.2d:00", timezoneHours)
        return timezone
    }

}
