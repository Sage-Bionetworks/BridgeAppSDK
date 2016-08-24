//
//  ORKResult+SBAExtension.swift
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

import ResearchKit

private let kStartDateKey = "startDate"
private let kEndDateKey = "endDate"
private let kIdentifierKey = "identifier"

private let kItemKey = "item"

private let kTappingViewSizeKey = "TappingViewSize"
private let kButtonRectLeftKey = "ButtonRectLeft"
private let kButtonRectRightKey = "ButtonRectRight"
private let kTapTimeStampKey = "TapTimeStamp"
private let kTapCoordinateKey = "TapCoordinate"
private let kTappedButtonIdKey = "TappedButtonId"
private let kTappedButtonNoneKey = "TappedButtonNone"
private let kTappedButtonLeftKey = "TappedButtonLeft"
private let kTappedButtonRightKey = "TappedButtonRight"
private let kTappingSamplesKey = "TappingSamples"

private let kSpatialSpanMemoryGameStatusKey = "MemoryGameStatus"
private let kSpatialSpanMemoryGameStatusUnknownKey = "MemoryGameStatusUnknown"
private let kSpatialSpanMemoryGameStatusSuccessKey = "MemoryGameStatusSuccess"
private let kSpatialSpanMemoryGameStatusFailureKey = "MemoryGameStatusFailure"
private let kSpatialSpanMemoryGameStatusTimeoutKey = "MemoryGameStatusTimeout"

private let kSpatialSpanMemorySummaryNumberOfGamesKey = "MemoryGameNumberOfGames"
private let kSpatialSpanMemorySummaryNumberOfFailuresKey = "MemoryGameNumberOfFailures"
private let kSpatialSpanMemorySummaryOverallScoreKey = "MemoryGameOverallScore"
private let kSpatialSpanMemorySummaryGameRecordsKey = "MemoryGameGameRecords"

private let kSpatialSpanMemoryGameRecordSeedKey = "MemoryGameRecordSeed"
private let kSpatialSpanMemoryGameRecordGameSizeKey = "MemoryGameRecordGameSize"
private let kSpatialSpanMemoryGameRecordGameScoreKey = "MemoryGameRecordGameScore"
private let kSpatialSpanMemoryGameRecordSequenceKey = "MemoryGameRecordSequence"
private let kSpatialSpanMemoryGameRecordTouchSamplesKey = "MemoryGameRecordTouchSamples"
private let kSpatialSpanMemoryGameRecordTargetRectsKey = "MemoryGameRecordTargetRects"

private let kSpatialSpanMemoryTouchSampleTimeStampKey = "MemoryGameTouchSampleTimestamp"
private let kSpatialSpanMemoryTouchSampleTargetIndexKey = "MemoryGameTouchSampleTargetIndex"
private let kSpatialSpanMemoryTouchSampleLocationKey = "MemoryGameTouchSampleLocation"
private let kSpatialSpanMemoryTouchSampleIsCorrectKey = "MemoryGameTouchSampleIsCorrect"

private let QuestionResultQuestionTextKey = "questionText"
private let QuestionResultQuestionTypeKey = "questionType"
private let QuestionResultQuestionTypeNameKey = "questionTypeName"
private let QuestionResultUserInfoKey = "userInfo"
private let QuestionResultSurveyAnswerKey = "answer"

private let NumericResultUnitKey = "unit"
private let DateAndTimeResultTimeZoneKey = "timeZone"

public class ArchiveableResult : NSObject {
    public let result: AnyObject
    public let filename: String
    
    init(result: AnyObject, filename: String) {
        self.result = result
        self.filename = filename
        super.init()
    }
}

public protocol BridgeUploadableData {
    // returns result object, result type, and filename
    func bridgeData(stepIdentifier: String) -> ArchiveableResult?
}

extension ORKResult: BridgeUploadableData {
    
    func dataFromFile(fileURL: NSURL) -> NSData? {
        return NSData.init(contentsOfURL: fileURL)
    }
    
    func dataFromDictionary(dictionary: Dictionary<String, AnyObject>) -> NSData? {
        let jsonData: NSData
        do {
            jsonData = try NSJSONSerialization.dataWithJSONObject(dictionary, options: NSJSONWritingOptions.init(rawValue: 0))
        } catch let error as NSError {
            fatalError("Failed to serialize JSON dictionary:\n\(error)")
        }
        
        return jsonData
    }
    
    func resultAsDictionary() -> NSMutableDictionary {
        let asDict = NSMutableDictionary()
        
        asDict[kIdentifierKey] = self.identifier
        asDict[kStartDateKey]  = self.startDate
        asDict[kEndDateKey]    = self.endDate

        return asDict
    }
    
    func bridgifyFilename(filename: String) -> String {
        return filename.stringByReplacingOccurrencesOfString(".", withString: "_")
    }
    
    func filenameForArchive() -> String {
        return bridgifyFilename(self.identifier) + ".json"
    }
    
    public func bridgeData(stepIdentifier: String) -> ArchiveableResult? {
        // extend subclasses individually to override this as needed
        return ArchiveableResult(result: self.resultAsDictionary().jsonObject(), filename: self.filenameForArchive())
    }
    
}

extension ORKFileResult {
    
    override public func bridgeData(stepIdentifier: String) -> ArchiveableResult? {
        guard let url = self.fileURL else {
            return nil
        }
        var ext = url.pathExtension
        if ext == nil || ext == "" {
            ext = "json"
        }
        let filename = bridgifyFilename(self.identifier + "_" + stepIdentifier) + "." + ext!
        return ArchiveableResult(result: url, filename: filename)
    }
    
}

extension ORKTappingIntervalResult {
    
    override func resultAsDictionary() -> NSMutableDictionary {
        let tappingResults = super.resultAsDictionary()
    
        let tappingViewSize = NSStringFromCGSize(self.stepViewSize)
        tappingResults[kTappingViewSizeKey] = tappingViewSize
    
        let leftButtonRect = NSStringFromCGRect(self.buttonRect1)
        tappingResults[kButtonRectLeftKey] = leftButtonRect;
    
        let rightButtonRect = NSStringFromCGRect(self.buttonRect2)
        tappingResults[kButtonRectRightKey] = rightButtonRect
    
        let sampleResults = self.samples?.map({ (sample) -> [String: AnyObject] in
            var aSampleDictionary = [String: AnyObject]();
            
            aSampleDictionary[kTapTimeStampKey]     = sample.timestamp
            
            aSampleDictionary[kTapCoordinateKey]   = NSStringFromCGPoint(sample.location)
            
            if (sample.buttonIdentifier == ORKTappingButtonIdentifier.None) {
                aSampleDictionary[kTappedButtonIdKey] = kTappedButtonNoneKey
            } else if (sample.buttonIdentifier == ORKTappingButtonIdentifier.Left) {
                aSampleDictionary[kTappedButtonIdKey] = kTappedButtonLeftKey
            } else if (sample.buttonIdentifier == ORKTappingButtonIdentifier.Right) {
                aSampleDictionary[kTappedButtonIdKey] = kTappedButtonRightKey
            }
            return aSampleDictionary
        }) ?? []
        
        tappingResults[kTappingSamplesKey] = sampleResults
        tappingResults[kItemKey] = self.filenameForArchive()
        
        return tappingResults
    }
    
}

extension ORKSpatialSpanMemoryResult {
    
    override func resultAsDictionary() -> NSMutableDictionary {
        let gameStatusKeys = [ kSpatialSpanMemoryGameStatusUnknownKey, kSpatialSpanMemoryGameStatusSuccessKey, kSpatialSpanMemoryGameStatusFailureKey, kSpatialSpanMemoryGameStatusTimeoutKey ]
        
        let memoryGameResults = super.resultAsDictionary()
        
        //
        //    ORK ORKSpatialSpanMemoryResult
        //
        memoryGameResults[kSpatialSpanMemorySummaryNumberOfGamesKey]    = self.numberOfGames
        memoryGameResults[kSpatialSpanMemorySummaryNumberOfFailuresKey] = self.numberOfFailures
        memoryGameResults[kSpatialSpanMemorySummaryOverallScoreKey]     = self.score
        
        //
        //    Memory Game Records
        //
        var gameRecords = [[String: AnyObject]]()
        
        for aRecord: ORKSpatialSpanMemoryGameRecord in self.gameRecords! {
            
            var aGameRecord = [String: AnyObject]()
            
            aGameRecord[kSpatialSpanMemoryGameRecordSeedKey]      = NSNumber(unsignedInt: aRecord.seed)
            aGameRecord[kSpatialSpanMemoryGameRecordGameSizeKey]  = aRecord.gameSize
            aGameRecord[kSpatialSpanMemoryGameRecordGameScoreKey] = aRecord.score
            aGameRecord[kSpatialSpanMemoryGameRecordSequenceKey]  = aRecord.sequence
            aGameRecord[kSpatialSpanMemoryGameStatusKey]          = gameStatusKeys[aRecord.gameStatus.rawValue]
            
            let touchSamples = makeTouchSampleRecords(aRecord.touchSamples)
            aGameRecord[kSpatialSpanMemoryGameRecordTouchSamplesKey] = touchSamples
            
            let rectangles = makeTargetRectangleRecords(aRecord.targetRects!)
            aGameRecord[kSpatialSpanMemoryGameRecordTargetRectsKey] = rectangles
            
            gameRecords += [aGameRecord]
        }
        memoryGameResults[kSpatialSpanMemorySummaryGameRecordsKey] = gameRecords
        memoryGameResults[kItemKey] = self.filenameForArchive()
        return memoryGameResults
    }
    
    func makeTouchSampleRecords(touchSamples: [ORKSpatialSpanMemoryGameTouchSample]?) -> NSArray
    {
        var samples = [[String: AnyObject]]()
        
        guard touchSamples != nil else {
            return samples
        }
        for sample: ORKSpatialSpanMemoryGameTouchSample in touchSamples! {
            
            var aTouchSample = [String: AnyObject]()
            
            aTouchSample[kSpatialSpanMemoryTouchSampleTimeStampKey]   = sample.timestamp
            aTouchSample[kSpatialSpanMemoryTouchSampleTargetIndexKey] = sample.targetIndex
            aTouchSample[kSpatialSpanMemoryTouchSampleLocationKey]    = NSStringFromCGPoint(sample.location)
            aTouchSample[kSpatialSpanMemoryTouchSampleIsCorrectKey]   = sample.correct
            
            samples += [aTouchSample]
        }
        return  samples
    }
    
    func makeTargetRectangleRecords(targetRectangles: [NSValue]) -> NSArray
    {
        var rectangles = [String]()
        
        for value: NSValue in targetRectangles {
            let rectangle = value.CGRectValue()
            let stringified = NSStringFromCGRect(rectangle)
            rectangles += [stringified]
        }
        return  rectangles
    }
    
}

public class AnswerKeyAndValue: NSObject {
    let key: String
    let value: AnyObject
    let questionType: ORKQuestionType
    
    init(key: String, value: AnyObject, questionType: ORKQuestionType) {
        self.key = key
        self.value = value
        self.questionType = questionType
        super.init()
    }
}

public protocol ORKQuestionResultAnswerJSON {
    func jsonSerializedAnswer() -> AnswerKeyAndValue?
}

extension ORKQuestionType {
    public var nameValue: String {
        switch self {
        case .None:
            return "None"
        case .Scale:
            return "Scale"
        case .SingleChoice:
            return "SingleChoice"
        case .MultipleChoice:
            return "MultipleChoice"
        case .Decimal:
            return "Decimal"
        case .Integer:
            return "Integer"
        case .Boolean:
            return "Boolean"
        case .Text:
            return "Text"
        case .TimeOfDay:
            return "TimeOfDay"
        case .DateAndTime:
            return "Date"
        case .Date:
            return "Date"
        case .TimeInterval:
            return "TimeInterval"
        case .Location:
            return "Location"
        case .Height:
            return "Height"
        }
    }
}

extension ORKQuestionResult: ORKQuestionResultAnswerJSON {
    
    override func resultAsDictionary() -> NSMutableDictionary {
        let choiceQuestionResult = super.resultAsDictionary()
        choiceQuestionResult[kItemKey] = self.identifier
        choiceQuestionResult[QuestionResultUserInfoKey] = self.userInfo
        if let answer = self.jsonSerializedAnswer() {
            choiceQuestionResult[answer.key] = answer.value
            choiceQuestionResult[QuestionResultSurveyAnswerKey] = answer.value
            choiceQuestionResult[QuestionResultQuestionTypeKey] = answer.questionType.rawValue
            choiceQuestionResult[QuestionResultQuestionTypeNameKey] = answer.questionType.nameValue
        }
        return choiceQuestionResult
    }
    
    public func jsonSerializedAnswer() -> AnswerKeyAndValue? {
        let className = NSStringFromClass(self.classForCoder)
        fatalError("jsonSerializedAnswer not implemented for \(className)")
    }
    
}

extension ORKChoiceQuestionResult {
    
    override public func jsonSerializedAnswer() -> AnswerKeyAndValue? {
        guard let choiceAnswers = self.choiceAnswers else { return nil }
        return AnswerKeyAndValue(key: "choiceAnswers", value: (choiceAnswers as NSArray).jsonObject(), questionType: self.questionType)
    }
}

extension ORKScaleQuestionResult {

    override public func jsonSerializedAnswer() -> AnswerKeyAndValue? {
        guard let answer = self.scaleAnswer else { return nil }
        return AnswerKeyAndValue(key: "scaleAnswer", value: answer.jsonObject(), questionType: .Scale)
    }
}

extension ORKMoodScaleQuestionResult {
    
    override public func jsonSerializedAnswer() -> AnswerKeyAndValue? {
        guard let answer = self.scaleAnswer else { return nil }
        return AnswerKeyAndValue(key: "scaleAnswer", value: answer.jsonObject(), questionType: .Scale)
    }
}

extension ORKBooleanQuestionResult {
    
    override public func jsonSerializedAnswer() -> AnswerKeyAndValue? {
        guard let answer = self.booleanAnswer else { return nil }
        return AnswerKeyAndValue(key: "booleanAnswer", value: answer.jsonObject(), questionType: .Boolean)
    }
}

extension ORKTextQuestionResult {
    
    override public func jsonSerializedAnswer() -> AnswerKeyAndValue? {
        guard let answer = self.textAnswer else { return nil }
        return AnswerKeyAndValue(key: "textAnswer", value: answer, questionType: .Text)
    }
}

extension ORKNumericQuestionResult {
    
    override public func jsonSerializedAnswer() -> AnswerKeyAndValue? {
        guard let answer = self.numericAnswer else { return nil }
        return AnswerKeyAndValue(key: "numericAnswer", value: answer.jsonObject(), questionType: self.questionType)
    }
    
    override func resultAsDictionary() -> NSMutableDictionary {
        let choiceQuestionResult = super.resultAsDictionary()
        if let unit = self.unit {
            choiceQuestionResult[NumericResultUnitKey] = unit
        }
        return choiceQuestionResult
    }
}

extension ORKTimeOfDayQuestionResult {
    
    override public func jsonSerializedAnswer() -> AnswerKeyAndValue? {
        guard let answer = self.dateComponentsAnswer else { return nil }
        answer.year = 0
        answer.month = 0
        answer.day = 0
        return AnswerKeyAndValue(key: "dateComponentsAnswer", value: answer.jsonObject(), questionType: .TimeOfDay)
    }
}

extension ORKTimeIntervalQuestionResult {
    
    override public func jsonSerializedAnswer() -> AnswerKeyAndValue? {
        guard let answer = self.intervalAnswer else { return nil }
        
        return AnswerKeyAndValue(key: "intervalAnswer", value: answer.jsonObject(), questionType: .TimeInterval)
    }
}

extension ORKDateQuestionResult {
    
    override public func jsonSerializedAnswer() -> AnswerKeyAndValue? {
        guard let answer = self.dateAnswer else { return nil }
        let key = "dateAnswer"
        if self.questionType == ORKQuestionType.Date {
            return AnswerKeyAndValue(key: key, value: answer.ISO8601DateOnlyString(), questionType: self.questionType)
        }
        else {
            return AnswerKeyAndValue(key: key, value: answer.jsonObject(), questionType: self.questionType)
        }
    }
}

