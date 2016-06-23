//
//  SBATrackedStep.swift
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

public protocol SBATrackedStepSurveyItem: SBASurveyItem {
    var trackingType: SBATrackingStepType? { get }
    var trackEach: Bool { get }
    var textFormat: String? { get }
}

public enum SBATrackingStepType: String {
    
    case introduction   = "introduction"
    case changed        = "changed"
    case completion     = "completion"
    case activity       = "activity"
    case selection      = "selection"
    case frequency      = "frequency"
    
    func isTrackedFormStepType() -> Bool {
        switch self {
        case .selection, .frequency, .activity:
            return true
        default:
            return false
        }
    }
}

extension SBATrackingStepType: Equatable {
}

public func ==(lhs: SBATrackingStepType, rhs: SBATrackingStepType) -> Bool {
    return lhs.rawValue == rhs.rawValue
}

public struct SBATrackingStepIncludes {
    
    let nextStepIfNoChange: SBATrackingStepType
    let includes:[SBATrackingStepType]
    
    private init(includes:[SBATrackingStepType]) {
        if (includes.contains(.changed) && !includes.contains(.activity)) {
            self.includes = [.changed, .selection, .frequency, .activity]
            self.nextStepIfNoChange = .completion
        }
        else {
            self.includes = includes
            self.nextStepIfNoChange = .activity
        }
    }
    
    public static let StandAloneSurvey = SBATrackingStepIncludes(includes: [.introduction, .selection, .frequency, .completion])
    public static let ActivityOnly = SBATrackingStepIncludes(includes: [.activity])
    public static let SurveyAndActivity = SBATrackingStepIncludes(includes: [.introduction, .selection, .frequency, .activity])
    public static let ChangedAndActivity = SBATrackingStepIncludes(includes: [.changed, .selection, .frequency, .activity])
    public static let ChangedOnly = SBATrackingStepIncludes(includes: [.changed])
    public static let None = SBATrackingStepIncludes(includes: [])
    
    func includeSurvey() -> Bool {
        return includes.contains(.introduction) || includes.contains(.changed)
    }
    
    func shouldInclude(trackingType: SBATrackingStepType) -> Bool {
        return includes.contains(trackingType)
    }
}

extension NSDictionary : SBATrackedStepSurveyItem {
    
    public var trackingType: SBATrackingStepType? {
        guard let trackingType = self["trackingType"] as? String else { return nil }
        return SBATrackingStepType(rawValue: trackingType)
    }
    
    public var textFormat: String? {
        return self["textFormat"] as? String
    }
    
    public var trackEach: Bool {
        return self["trackEach"] as? Bool ?? false
    }
    
}

extension SBATrackedDataObject: SBATextChoice {
    public var choiceText: String {
        return self.text
    }
    public var choiceDetail: String? {
        return nil
    }
    public var choiceValue: protocol<NSCoding, NSCopying, NSObjectProtocol> {
        return self.identifier
    }
    public var exclusive: Bool {
        return false
    }
}

public class SBATrackedFormStep: ORKFormStep {
    
    public var trackingType: SBATrackingStepType!
    public var trackEach: Bool = false
    
    public var trackedItemIdentifier: String? {
        return _trackedItemIdentifier
    }
    private var _trackedItemIdentifier: String?
    
    public var baseIdentifier: String {
        // If this *only* has the base then return that
        guard let suffix = identifierSuffix() where self.identifier.hasSuffix(suffix),
            let range = self.identifier.rangeOfString(suffix, options: .BackwardsSearch, range: nil, locale: nil)
            else {
                return self.identifier
        }
        return self.identifier.substringToIndex(range.startIndex)
    }
    
    private var textFormat: String?
    private var frequencyAnswerFormat: ORKAnswerFormat?
    
    public override init(identifier: String) {
        super.init(identifier: identifier)
    }
    
    public init(surveyItem: SBATrackedStepSurveyItem, items:[SBATrackedDataObject]) {
        super.init(identifier: surveyItem.identifier)
        self.trackingType = surveyItem.trackingType
        self.textFormat = surveyItem.textFormat
        self.trackEach = surveyItem.trackEach
        if let formSurvey = surveyItem as? SBAFormStepSurveyItem {
            formSurvey.mapStepValues(self)
            if (self.trackingType == .activity) {
                formSurvey.buildFormItems(self, isSubtaskStep: false)
            }
        }
        if let range = surveyItem as? SBANumberRange where (self.trackingType == .frequency) {
            self.frequencyAnswerFormat = range.createAnswerFormat(.scale)
        }
        update(selectedItems: items)
    }
    
    required public init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.textFormat = aDecoder.decodeObjectForKey("textFormat") as? String
        if let trackingTypeValue = aDecoder.decodeObjectForKey("trackingType") as? String,
        let trackingType = SBATrackingStepType(rawValue: trackingTypeValue) {
            self.trackingType = trackingType
        }
        self.frequencyAnswerFormat = aDecoder.decodeObjectForKey("frequencyAnswerFormat") as? ORKAnswerFormat
        self.trackEach = aDecoder.decodeBoolForKey("trackEach")
        self._trackedItemIdentifier = aDecoder.decodeObjectForKey("trackedItemIdentifier") as? String
    }
    
    override public func encodeWithCoder(aCoder: NSCoder) {
        super.encodeWithCoder(aCoder)
        aCoder.encodeObject(self.textFormat, forKey: "textFormat")
        aCoder.encodeObject(self.trackingType.rawValue, forKey: "trackingType")
        aCoder.encodeObject(self.frequencyAnswerFormat, forKey: "frequencyAnswerFormat")
        aCoder.encodeBool(self.trackEach, forKey: "trackEach")
        aCoder.encodeObject(self.trackedItemIdentifier, forKey: "trackedItemIdentifier")
    }
    
    override public func copyWithZone(zone: NSZone) -> AnyObject {
        let copy = super.copyWithZone(zone) as! SBATrackedFormStep
        copy._shouldSkipStep = self._shouldSkipStep
        copy.trackingType = self.trackingType
        copy.textFormat = self.textFormat
        copy.frequencyAnswerFormat = self.frequencyAnswerFormat
        copy.trackEach = self.trackEach
        copy._trackedItemIdentifier = self.trackedItemIdentifier
        return copy
    }
    
    public func copy(trackedItem trackedItem: SBATrackedDataObject) -> SBATrackedFormStep {
        let identifier = "\(baseIdentifier).\(trackedItem.identifier)"
        let copy = self.copyWithIdentifier(identifier)
        copy._trackedItemIdentifier = trackedItem.identifier
        copy.update(selectedItems:[trackedItem])
        return copy
    }
    
    public var shouldSkipStep: Bool {
        return _shouldSkipStep
    }
    private var _shouldSkipStep = false
    
    public func update(selectedItems selectedItems:[SBATrackedDataObject]) {
        switch self.trackingType! {

        // For selection type, only care about building the form items for the first round
        case .selection where (self.formItems == nil):
            buildSelectionFormItem(selectedItems)
            
        case .frequency:
            updateFrequencyFormItems(selectedItems)
            
        case .activity:
            updateActivityFormStep(selectedItems)
            
        default:
            break
        }
    }
    
    public func consolidatedResult(items:[SBATrackedDataObject], taskResult: ORKTaskResult) -> ORKStepResult? {
        if self.trackingType == .activity && self.trackEach {
            return consolidatedResultIfTrackEach(taskResult)
        }
        return taskResult.stepResultForStepIdentifier(self.baseIdentifier)
    }
    
    private func consolidatedResultIfTrackEach(taskResult: ORKTaskResult) -> ORKStepResult? {
    
        var startDate: NSDate!
        var endDate: NSDate!
        let resultIdentifier = self.baseIdentifier
        let prefix = "\(resultIdentifier)."
        
        let choiceAnswers = taskResult.results?.mapAndFilter({ (sResult) -> AnyObject? in
            
            // Filter out results that are not part of this step grouping
            guard let stepResult = sResult as? ORKStepResult where stepResult.identifier.hasPrefix(prefix),
                let formResults = stepResult.results where formResults.count == 1,
                let formResult = formResults.first as? ORKQuestionResultAnswerJSON,
                let answer = formResult.jsonSerializedAnswer()
            else {
                return nil
            }
            
            // get timestamps
            if (startDate == nil) {
                startDate = stepResult.startDate
            }
            endDate = stepResult.endDate
            
            // create and return a mapping of identifier to value
            let identifier = stepResult.identifier.substringFromIndex(prefix.endIndex)
            var value = answer.value
            if let array = value as? NSArray where array.count == 1 {
                value = array.firstObject!
            }
            return ["identifier" : identifier, "answer" : value] as NSDictionary
        })
        
        // If nothing was found and mapped then return nil
        guard choiceAnswers != nil && choiceAnswers!.count > 0 else {
            return nil
        }
        
        // Create and return a step result for the consolidated steps
        let questionResult = ORKChoiceQuestionResult(identifier: resultIdentifier)
        questionResult.startDate = startDate
        questionResult.endDate = endDate
        questionResult.questionType = ORKQuestionType.MultipleChoice
        questionResult.choiceAnswers = choiceAnswers
        
        let stepResult = ORKStepResult(stepIdentifier: resultIdentifier, results: [questionResult])
        stepResult.startDate = startDate
        stepResult.endDate = endDate
        
        return stepResult
    }
    
    // MARK: private consolidation
    
    private func buildSelectionFormItem(selectedItems:[SBATrackedDataObject]) {
        
        var choices = selectedItems.map { (item) -> ORKTextChoice in
            return item.createORKTextChoice()
        }
        
        // Add a choice for none of the above
        let noneChoice = ORKTextChoice(text: Localization.localizedString("SBA_NONE_OF_THE_ABOVE"),
                                       detailText: nil,
                                       value: "None",
                                       exclusive: true)
        choices += [noneChoice];
        
        // If this is an optional step, then include a choice for skipping
        if (self.optional) {
            let skipChoice = ORKTextChoice(text: Localization.localizedString("SBA_SKIP_CHOICE"),
                                           detailText: nil,
                                           value: "Skipped",
                                           exclusive: true)
            choices += [skipChoice]
            self.optional = false;
        }
        
        let answerFormat = ORKTextChoiceAnswerFormat(style: .MultipleChoice, textChoices: choices)
        let formItem = ORKFormItem(identifier: self.identifier + ".choices", text: nil, answerFormat: answerFormat)
        self.formItems = [formItem]
    }
    
    private func updateFrequencyFormItems(selectedItems:[SBATrackedDataObject]) {
        
        self.formItems = selectedItems.filter({ $0.usesFrequencyRange }).map { (item) -> ORKFormItem in
            return ORKFormItem(identifier: item.identifier, text: item.text, answerFormat: self.frequencyAnswerFormat)
        }
        _shouldSkipStep = (self.formItems == nil) || (self.formItems!.count == 0)
    }
    
    private func updateActivityFormStep(selectedItems:[SBATrackedDataObject]) {
        let trackedItems = selectedItems.filter({ $0.tracking && matchesTrackedItem($0)}).map({ $0.shortText })
        _shouldSkipStep = (trackedItems.count == 0)
        if let textFormat = self.textFormat where (trackedItems.count > 0) {
            self.text = String.localizedStringWithFormat(textFormat, Localization.localizedJoin(trackedItems))
        }
    }
    
    private func matchesTrackedItem(item: SBATrackedDataObject) -> Bool {
        if let trackedId = self.trackedItemIdentifier {
            return (trackedId == item.identifier)
        }
        else {
            return true
        }
    }
    
    private func identifierSuffix() -> String? {
        guard let trackedId = self.trackedItemIdentifier else {
            return nil
        }
        return ".\(trackedId)"
    }
}

