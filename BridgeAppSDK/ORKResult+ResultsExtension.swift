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
private let kAnswerMapKey = "answers"

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

open class ArchiveableResult : NSObject {
    open let result: AnyObject
    open let filename: String
    
    init(result: AnyObject, filename: String) {
        self.result = result
        self.filename = filename
        super.init()
    }
}

public protocol BridgeUploadableData {
    // returns result object, result type, and filename
    func bridgeData(_ stepIdentifier: String) -> ArchiveableResult?
}

extension ORKResult: BridgeUploadableData {
    
    func dataFromFile(_ fileURL: NSURL) -> NSData? {
        return NSData.init(contentsOf: fileURL as URL)
    }
    
    func dataFromDictionary(_ dictionary: Dictionary<String, AnyObject>) -> NSData? {
        let jsonData: NSData
        do {
            jsonData = try JSONSerialization.data(withJSONObject: dictionary, options: JSONSerialization.WritingOptions.init(rawValue: 0)) as NSData
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
    
    func bridgifyFilename(_ filename: String) -> String {
        return filename.replacingOccurrences(of: ".", with: "_")
    }
    
    func filenameForArchive() -> String {
        return bridgifyFilename(self.identifier) + ".json"
    }
    
    public func bridgeData(_ stepIdentifier: String) -> ArchiveableResult? {
        // extend subclasses individually to override this as needed
        return ArchiveableResult(result: self.resultAsDictionary().jsonObject() as AnyObject, filename: self.filenameForArchive())
    }
    
}

extension ORKStepResult {
    override func resultAsDictionary() -> NSMutableDictionary {
        let stepResult = super.resultAsDictionary()
        guard let results = self.results  else { return stepResult }
        stepResult[kAnswerMapKey] = results.map({ $0.resultAsDictionary().jsonObject() })
        return stepResult;
    }
}

extension ORKStep {
    @objc(stepResultWithBridgeDictionary:)
    public func stepResult(bridgeDictionary: [String: AnyObject]) -> ORKStepResult {
        
        // Populate the result using the answer map
        let stepResult = self.stepResult(answerMap: bridgeDictionary[kAnswerMapKey] as? [String: AnyObject])
        
        // Add the start/end date
        if let startDateString = bridgeDictionary[kStartDateKey] as? String {
            stepResult.startDate = NSDate(iso8601String: startDateString) as Date
        }
        if let endDateString = bridgeDictionary[kEndDateKey] as? String {
            stepResult.endDate = NSDate(iso8601String: endDateString) as Date
        }
        
        return stepResult
    }
}

extension ORKFileResult {
    
    override public func bridgeData(_ stepIdentifier: String) -> ArchiveableResult? {
        guard let url = self.fileURL else {
            return nil
        }
        var ext = url.pathExtension
        if ext == "" {
            ext = "json"
        }
        let filename = bridgifyFilename(self.identifier + "_" + stepIdentifier) + "." + ext
        return ArchiveableResult(result: url as AnyObject, filename: filename)
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
            
            aSampleDictionary[kTapTimeStampKey]     = sample.timestamp as AnyObject?
            
            aSampleDictionary[kTapCoordinateKey]   = NSStringFromCGPoint(sample.location) as AnyObject?
            
            if (sample.buttonIdentifier == ORKTappingButtonIdentifier.none) {
                aSampleDictionary[kTappedButtonIdKey] = kTappedButtonNoneKey as AnyObject?
            } else if (sample.buttonIdentifier == ORKTappingButtonIdentifier.left) {
                aSampleDictionary[kTappedButtonIdKey] = kTappedButtonLeftKey as AnyObject?
            } else if (sample.buttonIdentifier == ORKTappingButtonIdentifier.right) {
                aSampleDictionary[kTappedButtonIdKey] = kTappedButtonRightKey as AnyObject?
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
            
            aGameRecord[kSpatialSpanMemoryGameRecordSeedKey]      = NSNumber(value: aRecord.seed)
            aGameRecord[kSpatialSpanMemoryGameRecordGameSizeKey]  = aRecord.gameSize as AnyObject?
            aGameRecord[kSpatialSpanMemoryGameRecordGameScoreKey] = aRecord.score as AnyObject?
            aGameRecord[kSpatialSpanMemoryGameRecordSequenceKey]  = aRecord.sequence as AnyObject?
            aGameRecord[kSpatialSpanMemoryGameStatusKey]          = gameStatusKeys[aRecord.gameStatus.rawValue] as AnyObject?
            
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
    
    func makeTouchSampleRecords(_ touchSamples: [ORKSpatialSpanMemoryGameTouchSample]?) -> NSArray
    {
        var samples = [[String: AnyObject]]()
        
        guard touchSamples != nil else {
            return samples as NSArray
        }
        for sample: ORKSpatialSpanMemoryGameTouchSample in touchSamples! {
            
            var aTouchSample = [String: AnyObject]()
            
            aTouchSample[kSpatialSpanMemoryTouchSampleTimeStampKey]   = sample.timestamp as AnyObject?
            aTouchSample[kSpatialSpanMemoryTouchSampleTargetIndexKey] = sample.targetIndex as AnyObject?
            aTouchSample[kSpatialSpanMemoryTouchSampleLocationKey]    = NSStringFromCGPoint(sample.location) as AnyObject?
            aTouchSample[kSpatialSpanMemoryTouchSampleIsCorrectKey]   = sample.isCorrect as AnyObject?
            
            samples += [aTouchSample]
        }
        return  samples as NSArray
    }
    
    func makeTargetRectangleRecords(_ targetRectangles: [NSValue]) -> NSArray
    {
        var rectangles = [String]()
        
        for value: NSValue in targetRectangles {
            let rectangle = value.cgRectValue
            let stringified = NSStringFromCGRect(rectangle)
            rectangles += [stringified]
        }
        return  rectangles as NSArray
    }
    
}

open class AnswerKeyAndValue: NSObject {
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
        case .none:
            return "None"
        case .scale:
            return "Scale"
        case .singleChoice:
            return "SingleChoice"
        case .multipleChoice:
            return "MultipleChoice"
        case .decimal:
            return "Decimal"
        case .integer:
            return "Integer"
        case .boolean:
            return "Boolean"
        case .text:
            return "Text"
        case .timeOfDay:
            return "TimeOfDay"
        case .dateAndTime:
            return "Date"
        case .date:
            return "Date"
        case .timeInterval:
            return "TimeInterval"
        case .location:
            return "Location"
        case .height:
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
        return AnswerKeyAndValue(key: "choiceAnswers", value: (choiceAnswers as NSArray).jsonObject() as AnyObject, questionType: self.questionType)
    }
}

extension ORKScaleQuestionResult {

    override public func jsonSerializedAnswer() -> AnswerKeyAndValue? {
        guard let answer = self.scaleAnswer else { return nil }
        return AnswerKeyAndValue(key: "scaleAnswer", value: answer.jsonObject() as AnyObject, questionType: .scale)
    }
}

extension ORKMoodScaleQuestionResult {
    
    override public func jsonSerializedAnswer() -> AnswerKeyAndValue? {
        guard let answer = self.scaleAnswer else { return nil }
        return AnswerKeyAndValue(key: "scaleAnswer", value: answer.jsonObject() as AnyObject, questionType: .scale)
    }
}

extension ORKBooleanQuestionResult {
    
    override public func jsonSerializedAnswer() -> AnswerKeyAndValue? {
        guard let answer = self.booleanAnswer else { return nil }
        return AnswerKeyAndValue(key: "booleanAnswer", value: answer.jsonObject() as AnyObject, questionType: .boolean)
    }
}

extension ORKTextQuestionResult {
    
    override public func jsonSerializedAnswer() -> AnswerKeyAndValue? {
        guard let answer = self.textAnswer else { return nil }
        return AnswerKeyAndValue(key: "textAnswer", value: answer as AnyObject, questionType: .text)
    }
}

extension ORKNumericQuestionResult {
    
    override public func jsonSerializedAnswer() -> AnswerKeyAndValue? {
        guard let answer = self.numericAnswer else { return nil }
        return AnswerKeyAndValue(key: "numericAnswer", value: answer.jsonObject() as AnyObject, questionType: self.questionType)
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
        guard let dateAnswer = self.dateComponentsAnswer else { return nil }
        var answer = dateAnswer
        answer.year = 0
        answer.month = 0
        answer.day = 0
        return AnswerKeyAndValue(key: "dateComponentsAnswer", value: (answer as NSDateComponents).jsonObject() as AnyObject, questionType: .timeOfDay)
    }
}

extension ORKTimeIntervalQuestionResult {
    
    override public func jsonSerializedAnswer() -> AnswerKeyAndValue? {
        guard let answer = self.intervalAnswer else { return nil }
        
        return AnswerKeyAndValue(key: "intervalAnswer", value: answer.jsonObject() as AnyObject, questionType: .timeInterval)
    }
}

extension ORKDateQuestionResult {
    
    override public func jsonSerializedAnswer() -> AnswerKeyAndValue? {
        guard let answer = self.dateAnswer else { return nil }
        let key = "dateAnswer"
        if self.questionType == ORKQuestionType.date {
            return AnswerKeyAndValue(key: key, value: (answer as NSDate).iso8601DateOnlyString() as AnyObject, questionType: self.questionType)
        }
        else {
            return AnswerKeyAndValue(key: key, value: (answer as NSDate).jsonObject() as AnyObject, questionType: self.questionType)
        }
    }
}

