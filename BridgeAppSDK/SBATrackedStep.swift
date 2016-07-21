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

public protocol SBATrackedStep {
    var trackingType: SBATrackingStepType? { get }
}

public protocol SBATrackedStepSurveyItem: SBASurveyItem, SBATrackedStep {
}

public protocol SBATrackedNavigationStep: SBATrackedStep {
    var shouldSkipStep: Bool { get }
    func update(selectedItems selectedItems:[SBATrackedDataObject])
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

public class SBATrackedFormStep: ORKFormStep, SBATrackedNavigationStep {
    
    public var trackingType: SBATrackingStepType?

    private var frequencyAnswerFormat: ORKAnswerFormat?
    
    public override init(identifier: String) {
        super.init(identifier: identifier)
    }
    
    public init(surveyItem: SBATrackedStepSurveyItem, items:[SBATrackedDataObject]) {
        super.init(identifier: surveyItem.identifier)
        self.trackingType = surveyItem.trackingType!
        if let formSurvey = surveyItem as? SBAFormStepSurveyItem {
            formSurvey.mapStepValues(self)
        }
        if let range = surveyItem as? SBANumberRange where (self.trackingType == .frequency) {
            self.frequencyAnswerFormat = range.createAnswerFormat(.scale)
        }
        update(selectedItems: items)
    }
    
    public var shouldSkipStep: Bool {
        return _shouldSkipStep
    }
    private var _shouldSkipStep = false
    
    public func update(selectedItems selectedItems:[SBATrackedDataObject]) {
        guard let trackingType = self.trackingType else { return }
        switch trackingType {

        // For selection type, only care about building the form items for the first round
        case .selection where (self.formItems == nil):
            buildSelectionFormItem(selectedItems)
            
        case .frequency:
            updateFrequencyFormItems(selectedItems)
            
        default:
            break
        }
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
    
    
    // MARK: NSCoding
    
    required public init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        if let trackingTypeValue = aDecoder.decodeObjectForKey("trackingType") as? String,
            let trackingType = SBATrackingStepType(rawValue: trackingTypeValue) {
            self.trackingType = trackingType
        }
        self.frequencyAnswerFormat = aDecoder.decodeObjectForKey("frequencyAnswerFormat") as? ORKAnswerFormat
    }
    
    override public func encodeWithCoder(aCoder: NSCoder) {
        super.encodeWithCoder(aCoder)
        aCoder.encodeObject(self.trackingType?.rawValue, forKey: "trackingType")
        aCoder.encodeObject(self.frequencyAnswerFormat, forKey: "frequencyAnswerFormat")
    }
    
    // MARK: NSCopying
    
    override public func copyWithZone(zone: NSZone) -> AnyObject {
        let copy = super.copyWithZone(zone) as! SBATrackedFormStep
        copy._shouldSkipStep = self._shouldSkipStep
        copy.trackingType = self.trackingType
        copy.frequencyAnswerFormat = self.frequencyAnswerFormat
        return copy
    }
    
    // MARK: Equality
    
    override public func isEqual(object: AnyObject?) -> Bool {
        guard let object = object as? SBATrackedFormStep else { return false }
        return super.isEqual(object) &&
            object.shouldSkipStep == self.shouldSkipStep &&
            object.trackingType == self.trackingType &&
            SBAObjectEquality(object.frequencyAnswerFormat, self.frequencyAnswerFormat)
    }
    
    override public var hash: Int {
        return super.hash ^
            self.shouldSkipStep.hashValue ^
            (self.trackingType?.hashValue ?? 0) ^
            SBAObjectHash(self.frequencyAnswerFormat)
    }
}

