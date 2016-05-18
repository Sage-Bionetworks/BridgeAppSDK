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

private var kStartDateKey = "startDate"
private var kEndDateKey = "endDate"
private var kIdentifierKey = "identifier"

private var kItemKey = "item"

private var kTappingViewSizeKey = "TappingViewSize"
private var kButtonRectLeftKey = "ButtonRectLeft"
private var kButtonRectRightKey = "ButtonRectRight"
private var kTapTimeStampKey = "TapTimeStamp"
private var kTapCoordinateKey = "TapCoordinate"
private var kTappedButtonIdKey = "TappedButtonId"
private var kTappedButtonNoneKey = "TappedButtonNone"
private var kTappedButtonLeftKey = "TappedButtonLeft"
private var kTappedButtonRightKey = "TappedButtonRight"
private var kTappingSamplesKey = "TappingSamples"

private var kSpatialSpanMemoryGameStatusKey = "MemoryGameStatus"
private var kSpatialSpanMemoryGameStatusUnknownKey = "MemoryGameStatusUnknown"
private var kSpatialSpanMemoryGameStatusSuccessKey = "MemoryGameStatusSuccess"
private var kSpatialSpanMemoryGameStatusFailureKey = "MemoryGameStatusFailure"
private var kSpatialSpanMemoryGameStatusTimeoutKey = "MemoryGameStatusTimeout"

private var kSpatialSpanMemorySummaryNumberOfGamesKey = "MemoryGameNumberOfGames"
private var kSpatialSpanMemorySummaryNumberOfFailuresKey = "MemoryGameNumberOfFailures"
private var kSpatialSpanMemorySummaryOverallScoreKey = "MemoryGameOverallScore"
private var kSpatialSpanMemorySummaryGameRecordsKey = "MemoryGameGameRecords"

private var kSpatialSpanMemoryGameRecordSeedKey = "MemoryGameRecordSeed"
private var kSpatialSpanMemoryGameRecordGameSizeKey = "MemoryGameRecordGameSize"
private var kSpatialSpanMemoryGameRecordGameScoreKey = "MemoryGameRecordGameScore"
private var kSpatialSpanMemoryGameRecordSequenceKey = "MemoryGameRecordSequence"
private var kSpatialSpanMemoryGameRecordTouchSamplesKey = "MemoryGameRecordTouchSamples"
private var kSpatialSpanMemoryGameRecordTargetRectsKey = "MemoryGameRecordTargetRects"

private var kSpatialSpanMemoryTouchSampleTimeStampKey = "MemoryGameTouchSampleTimestamp"
private var kSpatialSpanMemoryTouchSampleTargetIndexKey = "MemoryGameTouchSampleTargetIndex"
private var kSpatialSpanMemoryTouchSampleLocationKey = "MemoryGameTouchSampleLocation"
private var kSpatialSpanMemoryTouchSampleIsCorrectKey = "MemoryGameTouchSampleIsCorrect"

private var QuestionResultQuestionTextKey = "questionText"
private var QuestionResultQuestionTypeKey = "questionType"
private var QuestionResultUserInfoKey = "userInfo"

enum ResultType: Int {
    case URL, Dictionary, Data
}

class ArchiveableResult : NSObject {
    var result: AnyObject
    var resultType: ResultType
    var filename: String
    
    init(result: AnyObject, resultType: ResultType, filename: String) {
        self.result = result
        self.resultType = resultType
        self.filename = filename
    }
}

protocol BridgeUploadableData {
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
    
    func bridgifyFilename(filename: String) -> String {
        return filename.stringByReplacingOccurrencesOfString(".", withString: "_")
    }
    
    func bridgeData(stepIdentifier: String) -> ArchiveableResult? {
        // extend subclasses individually to override this as needed
        return ArchiveableResult.init(result: self.jsonObject(), resultType: .Dictionary, filename: bridgifyFilename(self.identifier) + ".json")
    }
}

extension ORKFileResult {
    override func bridgeData(stepIdentifier: String) -> ArchiveableResult? {
        guard let url = self.fileURL else {
            return nil
        }
        var ext = url.pathExtension
        if ext == nil || ext == "" {
            ext = "json"
        }
        return ArchiveableResult.init(result: url, resultType: .URL, filename: bridgifyFilename(self.identifier + "_" + stepIdentifier) + "." + ext!)
    }
}

extension ORKTappingIntervalResult {
    
    override func bridgeData(stepIdentifier: String) -> ArchiveableResult? {
        var tappingResults: Dictionary<String, AnyObject> = [:]
    
        let tappingViewSize = NSStringFromCGSize(self.stepViewSize)
        tappingResults[kTappingViewSizeKey] = tappingViewSize
    
        tappingResults[kStartDateKey] = self.startDate
        tappingResults[kEndDateKey]   = self.endDate
    
        let leftButtonRect = NSStringFromCGRect(self.buttonRect1)
        tappingResults[kButtonRectLeftKey] = leftButtonRect;
    
        let rightButtonRect = NSStringFromCGRect(self.buttonRect2)
        tappingResults[kButtonRectRightKey] = rightButtonRect
    
        var sampleResults: [[String: AnyObject]] = []
        for sample in self.samples! {
            var aSampleDictionary = [String: AnyObject]();
            
            aSampleDictionary[kTapTimeStampKey]     = sample.timestamp;
            
            aSampleDictionary[kTapCoordinateKey]   = NSStringFromCGPoint(sample.location);
            
            if (sample.buttonIdentifier == ORKTappingButtonIdentifier.None) {
                aSampleDictionary[kTappedButtonIdKey] = kTappedButtonNoneKey
            } else if (sample.buttonIdentifier == ORKTappingButtonIdentifier.Left) {
                aSampleDictionary[kTappedButtonIdKey] = kTappedButtonLeftKey
            } else if (sample.buttonIdentifier == ORKTappingButtonIdentifier.Right) {
                aSampleDictionary[kTappedButtonIdKey] = kTappedButtonRightKey
            }
            sampleResults += [aSampleDictionary]
        }
        tappingResults[kTappingSamplesKey] = sampleResults
        let filename = bridgifyFilename(self.identifier) + ".json"
        tappingResults[kItemKey] = filename
        
        return ArchiveableResult.init(result: (tappingResults as NSDictionary).jsonObject(), resultType: .Dictionary, filename: filename)
    }
}

extension ORKSpatialSpanMemoryResult {
    override func bridgeData(stepIdentifier: String) -> ArchiveableResult? {
        let gameStatusKeys = [ kSpatialSpanMemoryGameStatusUnknownKey, kSpatialSpanMemoryGameStatusSuccessKey, kSpatialSpanMemoryGameStatusFailureKey, kSpatialSpanMemoryGameStatusTimeoutKey ]
        
        var memoryGameResults = [String: AnyObject]()
        
        //
        //    ORK Result
        //
        memoryGameResults[kIdentifierKey] = self.identifier
        memoryGameResults[kStartDateKey]  = self.startDate
        memoryGameResults[kEndDateKey]    = self.endDate
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
        let filename = bridgifyFilename(self.identifier) + ".json"
        memoryGameResults[kItemKey] = filename
        return ArchiveableResult.init(result: (memoryGameResults as NSDictionary).jsonObject(), resultType: .Dictionary, filename: filename)
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

class AnswerKeyAndValue: NSObject {
    var key: String
    var value: AnyObject?
    
    init(key: String, value: AnyObject?) {
        self.key = key
        self.value = value
    }
}

protocol ORKQuestionResultAnswerJSON {
    func jsonSerializedAnswer() -> (AnswerKeyAndValue)?
}

private var _timeOnlyFormatter: NSDateFormatter? = nil

extension ORKQuestionResult: ORKQuestionResultAnswerJSON {
    
    func timeOnlyFormatter() -> NSDateFormatter {
        if _timeOnlyFormatter == nil {
            _timeOnlyFormatter = NSDateFormatter.init()
            _timeOnlyFormatter!.dateFormat = "HH:mm:ss.SSS"
            let enUSPOSIXLocale = NSLocale.init(localeIdentifier: "en_US_POSIX");
            _timeOnlyFormatter!.locale = enUSPOSIXLocale
        }
        
        return _timeOnlyFormatter!
    }
    override func bridgeData(stepIdentifier: String) -> ArchiveableResult? {
        let filename = bridgifyFilename(self.identifier) + ".json"
        return ArchiveableResult.init(result: self.jsonObject(), resultType: .Dictionary, filename: filename)
    }
    
    public override func jsonObject() -> AnyObject {
        var ChoiceQuestionResult = [String: AnyObject]()
        ChoiceQuestionResult[QuestionResultQuestionTextKey] = self.questionText
        ChoiceQuestionResult[QuestionResultQuestionTypeKey] = self.questionType.rawValue
        ChoiceQuestionResult[kIdentifierKey] = self.identifier
        ChoiceQuestionResult[kStartDateKey] = self.startDate
        ChoiceQuestionResult[kEndDateKey] = self.endDate
        ChoiceQuestionResult[QuestionResultUserInfoKey] = self.userInfo
        if let answer = self.jsonSerializedAnswer() {
            ChoiceQuestionResult[answer.key] = answer.value
        }
        return (ChoiceQuestionResult as NSDictionary).jsonObject()
    }
    
    func jsonSerializedAnswer() -> (AnswerKeyAndValue)? {
        let className = NSStringFromClass(self.classForCoder)
        fatalError("jsonSerializedAnswer not implemented for \(className)")
    }
    
    func jsonForAnswer(answer: AnyObject) -> AnyObject {
        let dateTime = answer as? NSDate
        switch self.questionType {
        case .TimeOfDay:
            return timeOnlyFormatter().stringFromDate(dateTime!)
        case .DateAndTime:
            return dateTime!.ISO8601String()
        case .Date:
            return dateTime!.ISO8601DateOnlyString()
        default:
            // TODO: Implement specific formatters for other questionTypes as needed
            return answer.jsonObject()
        }
    }
}

extension ORKChoiceQuestionResult {
    override func jsonSerializedAnswer() -> (AnswerKeyAndValue)? {
        let choiceAnswers = self.choiceAnswers?.map { (answer) -> AnyObject in
            return jsonForAnswer(answer)
        }
        return AnswerKeyAndValue.init(key: "choiceAnswers", value: choiceAnswers)
    }
}

