//
//  SBAProfileSection.swift
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

import Foundation
import ResearchUXFactory

@objc
public protocol SBAProfileSection: NSObjectProtocol {
    var title: String? { get }
    var icon: String? { get }
    var items: [SBAProfileTableItem] { get }
}

@objc
public protocol SBAProfileTableItem: NSObjectProtocol {
    var title: String { get }
    var detail: String? { get }
    var isEditable: Bool { get }
    var onSelected: SBAProfileOnSelectedAction { get }
}

open class SBAProfileSectionObject: SBADataObject, SBAProfileSection {
    open dynamic var title: String?
    open dynamic var icon: String?
    open dynamic var items: [SBAProfileTableItem] = []
    
    // MARK: SBADataObject overrides
    
    override open func dictionaryRepresentationKeys() -> [String] {
        return super.dictionaryRepresentationKeys().appending(contentsOf: [#keyPath(title), #keyPath(icon), #keyPath(items)])
    }

    override open func defaultValue(forKey key: String) -> Any? {
        if key == #keyPath(items) {
            return [SBAProfileTableItem]()
        } else {
            return super.defaultValue(forKey: key)
        }
    }
}

@objc
open class SBAProfileTableItemBase: NSObject, SBAProfileTableItem {
    public let sourceDict: [AnyHashable: Any]
    open var defaultOnSelectedAction = SBAProfileOnSelectedAction.noAction

    public required init(dictionaryRepresentation dictionary: [AnyHashable: Any]) {
        sourceDict = dictionary
        super.init()
    }

    open var title: String {
        get {
            let key = #keyPath(title)
            return sourceDict[key] as? String ?? ""
        }
    }
    
    open var detail: String? {
        get {
            let key = #keyPath(detail)
            return sourceDict[key] as? String
        }
    }
    
    open var isEditable: Bool {
        get {
            let key = #keyPath(isEditable)
            return sourceDict[key] as? Bool ?? false
        }
    }
    
    open var onSelected: SBAProfileOnSelectedAction {
        get {
            let key = #keyPath(onSelected)
            guard let rawValue = sourceDict[key] as? String else { return defaultOnSelectedAction }
            return SBAProfileOnSelectedAction(rawValue: rawValue) 
        }
    }
}

open class SBAHTMLProfileTableItem: SBAProfileTableItemBase {
    public required init(dictionaryRepresentation dictionary: [AnyHashable: Any]) {
        super.init(dictionaryRepresentation: dictionary)
        defaultOnSelectedAction = .showHTML
    }
    
    open var htmlResource: String {
        get {
            let key = #keyPath(htmlResource)
            return sourceDict[key]! as! String
        }
    }
    
    open var html: String? {
        return SBAResourceFinder.shared.html(forResource: htmlResource)
    }
    
    open var url: URL? {
        if htmlResource.hasPrefix("http") || htmlResource.hasPrefix("file") {
            return URL(string: htmlResource)
        }
        else {
            return SBAResourceFinder.shared.url(forResource: htmlResource, withExtension:"html")
        }
    }
    
    // HTML profile table items are not editable
    override open var isEditable: Bool {
        get {
            return false
        }
    }
}

open class SBAProfileItemProfileTableItem: SBAProfileTableItemBase {
    public required init(dictionaryRepresentation dictionary: [AnyHashable: Any]) {
        super.init(dictionaryRepresentation: dictionary)
        defaultOnSelectedAction = .editProfileItem
    }
    
    open var profileItemKey: String {
        let key = #keyPath(profileItemKey)
        return sourceDict[key]! as! String
    }
    
    lazy open var profileItem: SBAProfileItem = {
        let profileItems = SBAProfileManager.shared!.profileItems()
        return profileItems[self.profileItemKey]!
    }()
    
    func itemDetailFor(_ date: Date, format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.calendar = Calendar.current
        return formatter.string(from: date)
    }
    
    open func dateAsItemDetail(_ date: Date) -> String {
        guard let format = DateFormatter.dateFormat(fromTemplate: "Mdy", options: 0, locale: Locale.current)
            else { return String(describing: date) }
        return self.itemDetailFor(date, format: format)
    }
    
    open func dateTimeAsItemDetail(_ dateTime: Date) -> String {
        guard let format = DateFormatter.dateFormat(fromTemplate: "yEMdhma", options: 0, locale: Locale.current)
            else { return String(describing: dateTime) }
        return self.itemDetailFor(dateTime, format: format)
    }
    
    open func timeOfDayAsItemDetail(_ timeOfDay: Date) -> String {
        guard let format = DateFormatter.dateFormat(fromTemplate: "hma", options: 0, locale: Locale.current)
            else { return String(describing: timeOfDay) }
        return self.itemDetailFor(timeOfDay, format: format)
    }
    
    public func centimetersToFeetAndInches(_ centimeters: Double) -> (feet: Double, inches: Double) {
        let inches = centimeters / 2.54
        return ((inches / 12.0).rounded(), inches.truncatingRemainder(dividingBy: 12.0))
    }
    
    @objc(hkQuantityheightAsItemDetail:)
    open func heightAsItemDetail(_ height: HKQuantity) -> String {
        let heightInCm = height.doubleValue(for: HKUnit(from: .centimeter)) as NSNumber
        return self.heightAsItemDetail(heightInCm)
    }
    
    open func heightAsItemDetail(_ height: NSNumber) -> String {
        let formatter = LengthFormatter()
        formatter.isForPersonHeightUse = true
        let meters = height.doubleValue / 100.0 // cm -> m
        return formatter.string(fromMeters: meters)
    }
    
    @objc(hkQuantityWeightAsItemDetail:)
    open func weightAsItemDetail(_ weight: HKQuantity) -> String {
        let weightInKg = weight.doubleValue(for: HKUnit(from: .kilogram)) as NSNumber
        return self.weightAsItemDetail(weightInKg)
    }
    
    open func weightAsItemDetail(_ weight: NSNumber) -> String {
        let formatter = MassFormatter()
        formatter.isForPersonMassUse = true
        return formatter.string(fromKilograms: weight.doubleValue)
    }
    
    override open var detail: String? {
        guard let value = profileItem.value else { return "" }
        if let surveyItem = SBASurveyFactory.profileQuestionSurveyItems?.find(withIdentifier: profileItemKey) as? SBAFormStepSurveyItem,
            let choices = surveyItem.items as? [SBAChoice] {
            let selected = (value as? [Any]) ?? [value]
            let textList = selected.map({ (obj) -> String in
                switch surveyItem.surveyItemType {
                case .form(.singleChoice), .form(.multipleChoice),
                     .dataGroups(.singleChoice), .dataGroups(.multipleChoice):
                    return choices.find({ SBAObjectEquality($0.choiceValue, obj) })?.choiceText ?? String(describing: obj)
                case .account(.profile):
                    guard let options = surveyItem.items as? [String],
                            options.count == 1,
                            let option = SBAProfileInfoOption(rawValue: options[0])
                        else { return String(describing: obj) }
                    switch option {
                    case .birthdate:
                        guard let date = obj as? Date else { return String(describing: obj) }
                        return self.dateAsItemDetail(date)
                    case .height:
                        // could reasonably be stored either as an HKQuantity, or as an NSNumber of cm
                        let hkHeight = obj as? HKQuantity
                        if hkHeight != nil {
                            return self.heightAsItemDetail(hkHeight!)
                        }
                        guard let nsHeight = obj as? NSNumber else { return String(describing: obj) }
                        return self.heightAsItemDetail(nsHeight)
                    case .weight:
                        // could reasonably be stored either as an HKQuantity, or as an NSNumber of kg
                        let hkWeight = obj as? HKQuantity
                        if hkWeight != nil {
                            return self.weightAsItemDetail(hkWeight!)
                        }
                        guard let nsWeight = obj as? NSNumber else { return String(describing: obj) }
                        return self.weightAsItemDetail(nsWeight)
                    default:
                        return String(describing: obj)
                    }
                default:
                    return String(describing: obj)
                }
            })
            return Localization.localizedJoin(textList: textList)
        }
        return String(describing: value)
    }
    
    open var answerMapKeys: [String: String] {
        let key = #keyPath(answerMapKeys)
        return sourceDict[key] as? [String: String] ?? [self.profileItemKey: self.profileItemKey]
    }
}

open class SBAResourceProfileTableItem: SBAProfileTableItemBase {
    public required init(dictionaryRepresentation dictionary: [AnyHashable: Any]) {
        super.init(dictionaryRepresentation: dictionary)
        defaultOnSelectedAction = .showResource
    }
    
    open var resource: String {
        get {
            let key = #keyPath(resource)
            return sourceDict[key]! as! String
        }
    }
    
    // Resource profile table items are not editable
    override open var isEditable: Bool {
        get {
            return false
        }
    }
}
