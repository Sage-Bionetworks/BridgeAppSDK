//
//  SBAProfileItem.swift
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
public protocol SBAProfileItem: NSObjectProtocol {
    /**
     profileKey is used to access a specific profile item, and so must be unique across all SBAProfileItems
     within an app.
     */
    var profileKey: String { get }
    
    /**
     sourceKey is the profile item's key within its internal data storage. By default it will be the
     same as profileKey, but can be different if needed (e.g. two different profile items happen to map to
     the same key in different storage types).
     */
    var sourceKey: String { get }
    
    /**
     isDemographicData is a flag indicating whether a profile item is part of the demographic data
     upload schema.
     */
    var isDemographicData: Bool { get }
    
    /**
     demographicKey is the profile item's key in the demographic data upload schema. By default it will
     be the same as profileKey, but can be different if needed.
     */
    var demographicKey: String { get }
    
    /**
     itemType specifies what type to store the profileItem as. Defaults to String if not otherwise specified.
     */
    var itemType: SBAProfileTypeIdentifier { get }
    
    /**
     The value property is used to get and set the profile item's value in whatever internal data
     storage is used by the implementing class.
     */
    var value: Any? { get set }
    
    /**
     jsonValue is used to get and set the profile item's value directly from appropriate JSON.
     */
    var jsonValue: SBBJSONValue? { get set }
    
    /**
     demographicJsonValue is used when formatting the item as demographic data for upload to Bridge.
     By default it will fall through to the getter for the jsonValue property, but can be different
     if needed.
     */
    var demographicJsonValue: SBBJSONValue? { get }
    
    /**
     Is the value read-only?
     */
    var readonly: Bool { get }
    
    /**
     Some of the stored value types have a unit associated with them that is used to 
     build the model object into an `HKQuantity`.
     */
    var unit: HKUnit? { get }
    
    /**
     Class type for the value item (or items if array) for this profile item.
     */
    var valueClassType: String? { get }
}

extension SBAProfileItem {
    func commonJsonValueGetter() -> SBBJSONValue? {
        return commonItemTypeToJson(val: self.value)
    }
    
    public func commonItemTypeToJson(val: Any?) -> SBBJSONValue? {
        guard val != nil else { return NSNull() }
        switch self.itemType {
        case SBAProfileTypeIdentifier.string:
            return val as? NSString
            
        case SBAProfileTypeIdentifier.number:
            return val as? NSNumber
            
        case SBAProfileTypeIdentifier.bool:
            return val as? NSNumber
            
        case SBAProfileTypeIdentifier.date:
            return (val as? NSDate)?.iso8601String() as NSString?
            
        case SBAProfileTypeIdentifier.hkBiologicalSex:
            return (val as? HKBiologicalSex)?.rawValue as NSNumber?
            
        case SBAProfileTypeIdentifier.hkQuantity:
            guard let quantity = val as? HKQuantity else { return nil }
            return NSNumber(value: quantity.doubleValue(for: self.unit ?? commonDefaultUnit()))
            
        case SBAProfileTypeIdentifier.dictionary, SBAProfileTypeIdentifier.array:
            return (val as? SBAJSONObject)?.jsonObject() as? SBBJSONValue
            
        case SBAProfileTypeIdentifier.set:
            guard let set = val as? Set<AnyHashable> else { return nil }
            return (Array(set) as SBAJSONObject).jsonObject() as? SBBJSONValue
            
        default:
            return nil
        }
    }
    
    func commonJsonValueSetter(value: SBBJSONValue?) {
        guard value != nil else {
            self.value = nil
            return
        }
        
        guard let itemValue = commonJsonToItemType(value: value) else { return }
        self.value = itemValue
    }
    
    public func commonJsonToItemType(value: SBBJSONValue?) -> Any? {
        guard value != nil else {
            return nil
        }
        
        var itemValue: Any? = nil
        switch self.itemType {
        case SBAProfileTypeIdentifier.string:
            itemValue = String(describing: value!)
            
        case SBAProfileTypeIdentifier.number:
            guard let val = value! as? NSNumber else { return nil }
            itemValue = val
            
        case SBAProfileTypeIdentifier.bool:
            guard let val = value! as? Bool else { return nil }
            itemValue = val
            
        case SBAProfileTypeIdentifier.date:
            guard let stringVal = value! as? String,
                    let dateVal = NSDate(iso8601String: stringVal)
                else { return nil }
            itemValue = dateVal
            
        case SBAProfileTypeIdentifier.hkBiologicalSex:
            guard let val = value! as? Int else { return nil }
            itemValue = HKBiologicalSex(rawValue: val)
            
        case SBAProfileTypeIdentifier.hkQuantity:
            guard let val = value! as? NSNumber else { return nil }
            itemValue = HKQuantity(unit: self.unit ?? commonDefaultUnit(), doubleValue: val.doubleValue)
            
        case SBAProfileTypeIdentifier.dictionary:
            guard let dictionary = value! as? [AnyHashable : Any] else { return nil }
            itemValue = commonMapObject(with: dictionary)
            
        case SBAProfileTypeIdentifier.array:
            guard let array = value! as? [Any] else { return nil }
            itemValue = array.map({ (obj) -> Any? in
                if let dictionary = value! as? [AnyHashable : Any] {
                    return commonMapObject(with: dictionary)
                }
                else {
                    return obj
                }
            })
            
        case SBAProfileTypeIdentifier.set:
            guard let set = value! as? Set<AnyHashable> else { return nil }
            itemValue = set.map({ (obj) -> Any? in
                if let dictionary = value! as? [AnyHashable : Any] {
                    return commonMapObject(with: dictionary)
                }
                else {
                    return obj
                }
            })
            
        default:
            break
        }
        
        return itemValue
    }
    
    func commonMapObject(with dictionary: [AnyHashable : Any]) -> Any? {
        if let cType = self.valueClassType {
            return SBAClassTypeMap.shared.object(with: dictionary, classType: cType)
        }
        else {
            return SBAClassTypeMap.shared.object(with: dictionary) ?? dictionary
        }
    }
    
    func commonDemographicJsonValue() -> SBBJSONValue? {
        guard let jsonVal = self.commonJsonValueGetter() else { return nil }
        if self.itemType == .hkBiologicalSex {
            return (self.value as? HKBiologicalSex)?.demographicDataValue
        }
        
        return jsonVal
    }
    
    func commonCheckTypeCompatible(newValue: Any?) -> Bool {
        guard newValue != nil else { return true }
        
        switch self.itemType {
        case SBAProfileTypeIdentifier.string:
            return true // anything can be cast to a string
            
        case SBAProfileTypeIdentifier.number:
            if (newValue as? NSNumber != nil) {
                return true
            }
            else if let quantity = newValue as? HKQuantity {
                return quantity.is(compatibleWith: self.unit ?? commonDefaultUnit())
            }
            return false
            
        case SBAProfileTypeIdentifier.bool:
            return newValue as? NSNumber != nil
            
        case SBAProfileTypeIdentifier.date:
            return newValue as? NSDate != nil
            
        case SBAProfileTypeIdentifier.hkBiologicalSex:
            return newValue as? HKBiologicalSex != nil
            
        case SBAProfileTypeIdentifier.hkQuantity:
            guard let quantity = newValue as? HKQuantity else { return false }
            return quantity.is(compatibleWith: self.unit ?? commonDefaultUnit())
            
        case SBAProfileTypeIdentifier.dictionary:
            return newValue as? SBAJSONObject != nil
        
        case SBAProfileTypeIdentifier.array:
            return newValue as? NSArray != nil
            
        case SBAProfileTypeIdentifier.set:
            return newValue as? NSSet != nil
            
        default:
            return true   // Any extended type isn't included in the common validation
        }
    }
    
    func commonDefaultUnit() -> HKUnit {
        guard let option = SBAProfileInfoOption(rawValue: self.profileKey)
        else {
            return HKUnit.count()
        }
        switch option {
        case .height:
            return HKUnit(from: .centimeter)
            
        case .weight:
            return HKUnit(from: .kilogram)
            
        default:
            return HKUnit.count()
        }
    }
}

open class SBAProfileItemBase: NSObject, SBAProfileItem {
    
    /**
     The value property is used to get and set the profile item's value in whatever internal data
     storage is used by the implementing class.
     */
    open var value: Any? {
        get {
            // Look at the sourceKey, if not found then fall back to the fallback key and check that
            let value = storedValue(forKey: sourceKey)
            if value == nil, let fallback = fallbackKey {
                return storedValue(forKey: fallback)
            }
            else {
                return value
            }
        }
        
        set {
            guard !readonly else { return }
            setStoredValue(newValue)
        }
    }

    fileprivate let sourceDict: [AnyHashable: Any]
    
    open var profileKey: String {
        let key = #keyPath(profileKey)
        return sourceDict[key]! as! String
    }
    
    open var sourceKey: String {
        let key = #keyPath(sourceKey)
        return sourceDict[key] as? String ?? self.profileKey
    }
    
    open var isDemographicData: Bool {
        let key = #keyPath(isDemographicData)
        return sourceDict[key] as? Bool ?? false
    }
    
    open var demographicKey: String {
        let key = #keyPath(demographicKey)
        return sourceDict[key] as? String ?? self.profileKey
    }
    
    open var fallbackKey: String? {
        let key = #keyPath(fallbackKey)
        return sourceDict[key] as? String
    }
    
    open var itemType: SBAProfileTypeIdentifier {
        let key = #keyPath(itemType)
        guard let rawValue = sourceDict[key] as? String else { return .string }
        return SBAProfileTypeIdentifier(rawValue: rawValue)
    }
    
    public required init(dictionaryRepresentation dictionary: [AnyHashable: Any]) {
        sourceDict = dictionary
        super.init()
    }
    
    open var jsonValue: SBBJSONValue? {
        get {
            return self.commonJsonValueGetter()
        }
        
        set {
            commonJsonValueSetter(value: newValue)
        }
    }
    
    open var demographicJsonValue: SBBJSONValue? {
        return self.commonDemographicJsonValue()
    }
    
    open var readonly: Bool {
        let key = #keyPath(readonly)
        return sourceDict[key] as? Bool ?? false
    }
    
    open var unit: HKUnit? {
        let key = #keyPath(unit)
        guard let unitString = sourceDict[key] as? String else { return nil }
        return HKUnit(from: unitString)
    }
    
    open var valueClassType: String? {
        let key = #keyPath(valueClassType)
        return sourceDict[key] as? String
    }
    
    open func storedValue(forKey key: String) -> Any? {
        return _value
    }
    
    open func setStoredValue(_ newValue: Any?) {
        _value = newValue
    }
    
    fileprivate var _value: Any?
}

extension SBAKeychainWrapper: SBAKeychainWrapperProtocol {
}

open class SBAKeychainProfileItem: SBAProfileItemBase {
    
    var keychain: SBAKeychainWrapperProtocol
    
    public required init(dictionaryRepresentation dictionary: [AnyHashable: Any]) {
        
        // Look to see if this item uses a different keychain service or access group
        // than the default and instantiate if it does.
        let keychainService = dictionary["keychainService"] as? String
        let keychainAccessGroup = dictionary["keychainAccessGroup"] as? String
        
        if (keychainService != nil || keychainAccessGroup != nil) {
            keychain = SBAKeychainWrapper(service: keychainService, accessGroup: keychainAccessGroup)
        }
        else {
            // Otherwise, use the default
            keychain = SBAProfileManager.keychain
        }
        
        super.init(dictionaryRepresentation: dictionary)
    }

    override open func storedValue(forKey key: String) -> Any? {
        var err: NSError?
        let obj = keychain.object(forKey: key, error: &err)
        if let error = err {
            print("Error accessing keychain \(key): \(error.code) \(error)")
        }
        return self.typedValue(from: obj)
    }
    
    override open func setStoredValue(_ newValue: Any?) {
        do {
            if newValue == nil {
                try keychain.removeObject(forKey: sourceKey)
            } else {
                if !self.commonCheckTypeCompatible(newValue: newValue) {
                    assertionFailure("Error setting \(sourceKey) (\(profileKey)): \(String(describing: newValue)) not compatible with specified type \(itemType.rawValue)")
                    return
                }
                guard let secureVal = secureCodingValue(of: newValue) else {
                    assertionFailure("Error setting \(sourceKey) (\(profileKey)) in keychain: don't know how to convert \(String(describing: newValue))) to NSSecureCoding")
                    return
                }
                try keychain.setObject(secureVal, forKey: sourceKey)
            }
        }
        catch let error {
            assert(false, "Failed to set \(sourceKey) (\(profileKey)): \(String(describing: error))")
        }
    }
    
    open func secureCodingValue(of anyValue: Any?) -> NSSecureCoding? {
        guard anyValue != nil else { return nil }
        var retVal = anyValue as? NSSecureCoding
        if self.itemType == .hkBiologicalSex {
            // HKBiologicalSexObject exists and is NSSecureCoding, but iOS doesn't give
            // us any way to create one and set its value so we're stuck using NSNumber
            guard let sex = anyValue as? HKBiologicalSex else { return retVal }
            retVal = sex.rawValue as NSNumber
        }
        
        return retVal
    }
    
    open func typedValue(from secureCodingValue: NSSecureCoding?) -> Any? {
        var retVal: Any? = secureCodingValue
        if self.itemType == .hkBiologicalSex {
            guard let intVal = secureCodingValue as? Int else { return nil }
            retVal = HKBiologicalSex(rawValue: intVal)
        }
        
        return retVal
    }
}

public protocol PlistValue {
    // empty, just used to mark types as suitable for use in plists (and user defaults)
}

public protocol JSONValue: PlistValue {
    // empty, just used to mark types as acceptable for serializing to JSON
}

extension NSString: JSONValue {}
extension NSNumber: JSONValue {}
extension NSArray: JSONValue {}
extension NSDictionary: JSONValue {}
extension NSNull: JSONValue {}
extension String: JSONValue {}
extension Bool: JSONValue {}
extension Double: JSONValue {}
extension Float: JSONValue {}
extension Int: JSONValue {}
extension Int8: JSONValue {}
extension Int16: JSONValue {}
extension Int32: JSONValue {}
extension Int64: JSONValue {}
extension UInt: JSONValue {}
extension UInt8: JSONValue {}
extension UInt16: JSONValue {}
extension UInt32: JSONValue {}
extension UInt64: JSONValue {}
extension Array: JSONValue {}
extension Dictionary: JSONValue {}

extension NSData: PlistValue {}
extension NSDate: PlistValue {}
extension Data: PlistValue {}
extension Date: PlistValue {}

open class SBAUserDefaultsProfileItem: SBAProfileItemBase {
    var defaults: UserDefaults
    
    public required init(dictionaryRepresentation dictionary: [AnyHashable: Any]) {

        if let userDefaultsSuiteName = dictionary["userDefaultsSuiteName"] as? String,
            let customDefaults = UserDefaults(suiteName: userDefaultsSuiteName) {
            defaults = customDefaults
        }
        else {
            defaults = SBAProfileManager.userDefaults
        }
        
        super.init(dictionaryRepresentation: dictionary)
    }
    
    override open func storedValue(forKey key: String) -> Any? {
        return typedValue(from: defaults.object(forKey: key) as? PlistValue)
    }
    
    override open func setStoredValue(_ newValue: Any?) {
        if newValue == nil {
            defaults.removeObject(forKey: sourceKey)
        } else {
            if !self.commonCheckTypeCompatible(newValue: newValue) {
                assertionFailure("Error setting \(sourceKey) (\(profileKey)): \(String(describing: newValue)) not compatible with specified type\(itemType.rawValue)")
                return
            }
            guard let plistVal = pListValue(of: newValue) else {
                assertionFailure("Error setting \(sourceKey) (\(profileKey)) in user defaults: don't know how to convert \(String(describing: newValue)) to PlistValue")
                return
            }
            defaults.set(plistVal, forKey: sourceKey)
        }
    }
    
    open func pListValue(of anyValue: Any?) -> PlistValue? {
        guard anyValue != nil else { return nil }
        var retVal = anyValue! as? PlistValue
        if self.itemType == .hkBiologicalSex {
            retVal = (anyValue as? HKBiologicalSex)?.rawValue
        }
        
        return retVal
    }
    
    open func typedValue(from pListValue: PlistValue?) -> Any? {
        var retVal: Any? = pListValue
        if self.itemType == .hkBiologicalSex {
            guard let intVal = pListValue as? Int else { return nil }
            retVal = HKBiologicalSex(rawValue: intVal)
        }
        
        return retVal
    }

}

enum SBAProfileParticipantSourceKey: String {
    case firstName
    case lastName
    case email
    case externalId
    case notifyByEmail
    case sharingScope
    case dataGroups
}

open class SBAStudyParticipantProfileItem: SBAStudyParticipantCustomAttributesProfileItem {
    public static var studyParticipant: SBBStudyParticipant?
    
    override open func storedValue(forKey key: String) -> Any? {
        guard let studyParticipant = SBAStudyParticipantProfileItem.studyParticipant
            else {
                assertionFailure("Attempting to read \(key) (\(profileKey)) on nil SBBStudyParticipant")
                return nil
        }
        // special-case handling for an attribute to call through to the superclass implementation
        if let attributeKey = key.parseSuffix(prefix: "attributes", separator:".") {
            return super.storedValue(forKey: attributeKey)
        }
        
        guard let enumKey = SBAProfileParticipantSourceKey(rawValue: key)
            else {
                assertionFailure("Error reading \(key) (\(profileKey)): \(key) is not a valid SBBStudyParticipant key")
                return nil
        }
        
        var storedVal = studyParticipant.value(forKey: key)
        switch enumKey {
        case .sharingScope:
            guard let scopeString = storedVal as? String else { break }
            storedVal = SBBParticipantDataSharingScope(key: scopeString)
        default:
            break
        }
        
        return storedVal
    }
    
    override open func setStoredValue(_ newValue: Any?) {
        guard let studyParticipant = SBAStudyParticipantProfileItem.studyParticipant
            else {
                assertionFailure("Attempting to set \(sourceKey) (\(profileKey)) on nil SBBStudyParticipant")
                return
        }
        
        // special-case handling for an attribute to call through to the superclass implementation
        if let attributeKey = sourceKey.parseSuffix(prefix: "attributes", separator:".") {
            super.setStoredValue(newValue, forKey: attributeKey)
            return
        }
        
        guard let key = SBAProfileParticipantSourceKey(rawValue: sourceKey)
            else {
                assertionFailure("Error setting \(sourceKey) (\(profileKey)): \(sourceKey) is not a valid SBBStudyParticipant key")
                return
        }
        
        var setValue = newValue
        switch key {
        case .dataGroups:
            guard let _ = newValue as? Set<String>
                else {
                    assertionFailure("Error setting \(sourceKey) (\(profileKey)): value \(String(describing: newValue)) cannot be converted to Set")
                    return
            }
        case .sharingScope:
            guard let scope = newValue as? SBBParticipantDataSharingScope
                else {
                    assertionFailure("Error setting \(sourceKey) (\(profileKey)): value \(String(describing: newValue)) cannot be converted to SBBParticipantDataSharingScope")
                    return
            }
            setValue = SBBParticipantManager.dataSharingScopeStrings()[scope.rawValue]
        case .notifyByEmail:
            guard let _ = newValue as? Bool
                else {
                    assertionFailure("Error setting \(sourceKey) (\(profileKey)): value \(String(describing: newValue)) cannot be converted to Bool")
                    return
            }
        default:
            // the rest are String, and anything can be converted to String
            break
        }
        
        studyParticipant.setValue(setValue, forKeyPath: sourceKey)
        
        // save the change to Bridge
        SBABridgeManager.updateParticipantRecord(studyParticipant) { (_, _) in }
    }
}


open class SBAStudyParticipantCustomAttributesProfileItem: SBAProfileItemBase {
    override open func storedValue(forKey key: String) -> Any? {
        guard let attributes = SBAStudyParticipantProfileItem.studyParticipant?.attributes
            else {
                assertionFailure("Attempting to read \(key) (\(profileKey)) on nil SBBStudyParticipantCustomAttributes")
                return nil
        }
        guard attributes.responds(to: NSSelectorFromString(key))
            else {
                assertionFailure("Error reading \(key) (\(profileKey)): \(key) is not a defined SBBStudyParticipantCustomAttributes key")
                return nil
        }
        guard let rawValue = attributes.value(forKey: key) as? SBBJSONValue else { return nil }
        guard let value = commonJsonToItemType(value: rawValue)
            else {
                assertionFailure("Error reading \(key) (\(profileKey)): \(String(describing: rawValue)) is not convertible to item type \(itemType)")
                return nil
        }
        
        return value
    }
    
    override open func setStoredValue(_ newValue: Any?) {
        self.setStoredValue(newValue, forKey: sourceKey)
    }
    
    open func setStoredValue(_ newValue: Any?, forKey key: String) {
        guard let studyParticipant = SBAStudyParticipantProfileItem.studyParticipant,
                let attributes = studyParticipant.attributes
            else {
                assertionFailure("Attempting to set \(key) (\(profileKey)) on nil SBBStudyParticipantCustomAttributes")
                return
        }
        guard attributes.responds(to: NSSelectorFromString(key))
            else {
                assertionFailure("Error reading \(key) (\(profileKey)): \(key) is not a defined SBBStudyParticipantCustomAttributes key")
                return
        }
        guard newValue != nil
            else {
                attributes.setValue(nil, forKey: key)
                return
        }
        guard let jsonValue = commonItemTypeToJson(val: newValue)
            else {
                assertionFailure("Error setting \(key) (\(profileKey)): \(String(describing: value)) is not convertible to JSON")
                return
        }
        
        attributes.setValue(jsonValue, forKey: key)
        
        // save the change to Bridge
        SBABridgeManager.updateParticipantRecord(studyParticipant) { (_, _) in }
    }
}

open class SBAWhatAndWhen: NSObject, Comparable {
    static var valueKey: String { return #keyPath(value) }
    static var dateKey: String { return #keyPath(date) }
    static var isNewKey: String { return #keyPath(isNew) }
    open var value: SBBJSONValue
    open var date: NSDate
    var isNew: Bool
    
    public init(dictionaryRepresentation dictionary: [String: SBBJSONValue]) {
        value = dictionary[SBAWhatAndWhen.valueKey]!
        let dateString = dictionary[SBAWhatAndWhen.dateKey] as! String
        date = NSDate(iso8601String: dateString)
        let isNewJson = dictionary[SBAWhatAndWhen.isNewKey] as? NSNumber
        isNew = isNewJson != nil ? isNewJson!.boolValue : false
        super.init()
    }
    
    public init(_ value: SBBJSONValue, asOf date: NSDate, isNew:Bool = false) {
        self.value = value
        self.date = date
        self.isNew = isNew
        super.init()
    }
    
    public func dictionaryRepresentation() -> [String: SBBJSONValue] {
        return [
            SBAWhatAndWhen.valueKey: value,
            SBAWhatAndWhen.dateKey: date.iso8601String() as NSString
        ]
    }
    
    public func cachedDictionaryRepresentation() -> [String: SBBJSONValue] {
        var dict = self.dictionaryRepresentation()
        dict[SBAWhatAndWhen.isNewKey] = isNew as NSNumber
        return dict
    }
}

public func < (lhs: SBAWhatAndWhen, rhs: SBAWhatAndWhen) -> Bool {
    // arbitrary JSON isn't comparable, so we'll just compare dates and, secondarily, isNew
    let comparison = lhs.date.compare(rhs.date as Date)
    guard comparison == .orderedSame else { return comparison == .orderedAscending }
    
    // we'll call false < true as far as isNew is concerned
    return lhs.isNew == false && rhs.isNew == true
}

public func == (lhs: SBAWhatAndWhen, rhs: SBAWhatAndWhen) -> Bool {
    return (lhs.date as Date) == (rhs.date as Date) &&
            lhs.value.isEqual(rhs.value) &&
            lhs.isNew == rhs.isNew
}


/**
 The activity to which an SBAClientDataProfileItem is attached should be scheduled such that there is always an appropriate
 SBBScheduledActivity object on which to save it (i.e. doesn't expire before being rescheduled). Its clientData must also be
 a JSON dictionary, and the values set here will be stored at the top level by sourceKey as a list of dictionaries containing
 "date" and "value" entries. If the value of the item is changed more quickly than it is rescheduled, the "date" timestamp
 allows there to be more than one entry per SBBScheduledActivity instance, so this type of profile item can be used to record
 and/or retrieve a time series of values.
 */
open class SBAClientDataProfileItem: SBAProfileItemBase {
    // ClientData profile items are attached to and read from the most date-appropriate instance
    // of a SBBScheduledActivity for a given activityIdentifier. Since those are not always available
    // when the app needs to read and write Profile item values, we also keep track of the latest
    // (most current) value in a local keychain cache, and store any newly-set values there until
    // they can be written to an SBBScheduledActivity.
    static var cachedItemsKey: String = "SBAClientDataProfileItemCachedItems"
    private static var toBeUpdatedToBridge: Set<SBBScheduledActivity> = Set<SBBScheduledActivity>()
    static var keychain: SBAKeychainWrapperProtocol = SBAProfileManager.keychain
    
    // In the normal case (all values have been written to an SBBScheduledActivity instance), the
    // array of values for a given profile item will consist of one element, the latest. They are
    // arrays rather than single dictionaries so that multiple values with different timestamps can
    // be stored until they can be written to an SBBScheduledActivity, if for example the app
    // is not able to connect to the Bridge servers for an extended period. It's also useful if,
    // say, your app allows adding or editing events in the past.
    static var currentValues: [String: [[String: SBBJSONValue]]] {
        get {
            var error: NSError?
            let dict = keychain.object(forKey: cachedItemsKey, error: &error)
            var values = [String: [[String: SBBJSONValue]]]()
            if error != nil {
                if error!.code == Int(errSecItemNotFound) {
                    self.currentValues = values
                }
                else {
                    print("Error accessing keychain \(cachedItemsKey): \(error!.code) \(error!)")
                }
            }
            else {
                values = dict as! [String : [[String : SBBJSONValue]]]
            }
            
            return values
        }
        
        set {
            do {
                try keychain.setObject(newValue as NSSecureCoding, forKey: cachedItemsKey)
            }
            catch let error {
                assert(false, "Failed to set \(cachedItemsKey): \(String(describing: error))")
            }
        }
    }
    
    static func addToCurrentValues(_ jsonWhatAndWhen: [String: SBBJSONValue], forProfileKey key: String) {
        var currentValuesForKey = currentValues[key] ?? [[String: SBBJSONValue]]()
        currentValuesForKey.append(jsonWhatAndWhen)
        currentValues[key] = jsonWhatsAndWhensSortedByWhen(currentValuesForKey)
    }
    
    public static var scheduledActivities: [SBBScheduledActivity]? {
        didSet {
            // get all the SBAClientDataProfileItem instances from SBAProfileManager
            guard scheduledActivities != nil && scheduledActivities!.count > 0,
                    let clientDataItems: [SBAClientDataProfileItem] = SBAProfileManager.shared?.profileItems().values.mapAndFilter({ return $0 as? SBAClientDataProfileItem })
                else {
                    return
            }
            
            var updatedDemographicData = false
            for item in clientDataItems {
                // for each one, get all its current cached values and all available values from Bridge
                let cachedItems = item.dateAndJsonValuesFromCachedItems()
                let bridgeValues = item.jsonWhatsAndWhensFromBridge()
                if cachedItems == nil && bridgeValues.count == 0 { continue }
                
                // if cached items is missing or empty, just set it with the latest value from Bridge as its only element
                // and skip ahead to the next item
                let latest = bridgeValues.last
                if cachedItems == nil || cachedItems!.count == 0 {
                    addToCurrentValues(latest!, forProfileKey: item.profileKey)
                    continue
                }
                
                // go through the cached items one-by-one and handle appropriately
                for cachedItem in cachedItems! {
                    // if cached date/value is new, attach it to the appropriate SBBScheduledActivity instance
                    if cachedItem.isNew {
                        let whatAndWhenJson = cachedItem.dictionaryRepresentation()
                        item.setToAppropriateScheduledActivity(whatAndWhenJson)
                        if item.isDemographicData { updatedDemographicData = true }
                    }
                }
                
                // now remove all but the last one (they're always sorted by date)
                let finalCachedItem = cachedItems!.last!
                
                // using dictionaryRepresentation() instead of cachedDictionaryRepresentation() leaves off
                // any isNew flag from the cached item, so it won't keep trying to update it to Bridge
                var finalCachedJson = finalCachedItem.dictionaryRepresentation()
                
                // if latest value from Bridge is newer, cache it instead
                guard latest != nil
                    else {
                        currentValues[item.profileKey] = [finalCachedJson]
                        continue
                }
                let bridgeItem = SBAWhatAndWhen(dictionaryRepresentation: latest!)
                if finalCachedItem.date.compare(bridgeItem.date as Date) == .orderedAscending {
                    finalCachedJson = latest!
                }
                
                // set it
                currentValues[item.profileKey] = [finalCachedJson]
            }
            
            // if we ended up updating any SBBScheduledActivity instances, push the changes to Bridge
            guard toBeUpdatedToBridge.count > 0 else { return }
            let updatesArray = Array(toBeUpdatedToBridge)
            toBeUpdatedToBridge.removeAll()
            SBABridgeManager.updateScheduledActivities(updatesArray)
            
            // if there were any updates to demographic data items, upload demographic data
            guard updatedDemographicData,
                    let profileManager = SBAProfileManager.shared as? SBAProfileManager
                else {
                    return
            }
            profileManager.uploadDemographicData()
        }
    }
    
    open var taskIdentifier: String? {
        let key = #keyPath(taskIdentifier)
        return sourceDict[key] as? String
    }
    
    open var surveyIdentifier: String? {
        let key = #keyPath(surveyIdentifier)
        return sourceDict[key] as? String
    }
    
    open var activityIdentifier: String {
        let key = #keyPath(activityIdentifier)
        let explicitActivityIdentifer = sourceDict[key] as? String
        guard let identifier = explicitActivityIdentifer ?? taskIdentifier ?? surveyIdentifier
            else {
                assertionFailure("One of activityIdentifier, taskIdentifier, or surveyIdentifier must be set for a ClientDataProfileItem")
                return ""
        }
        return identifier
    }
    
    static func jsonWhatsAndWhensSortedByWhen(_ jsonWhatsAndWhens: [[String: SBBJSONValue]]) -> [[String: SBBJSONValue]] {
        return jsonWhatsAndWhens.sorted(by: {
            return SBAWhatAndWhen(dictionaryRepresentation: $0) < SBAWhatAndWhen(dictionaryRepresentation: $1)
        })
    }
    
    func jsonWhatsAndWhensFromBridge() -> [[String: SBBJSONValue]] {
        // pull out all the non-empty lists of date/value instances for this activityIdentifier and key into one non-empty list
        guard let valueArrays = SBAClientDataProfileItem.scheduledActivities?.mapAndFilter({ (scheduledActivity) -> [[String: SBBJSONValue]]? in
                    guard scheduledActivity.activityIdentifier == activityIdentifier,
                            let clientData = scheduledActivity.clientData as? NSDictionary,
                            let valueArray = clientData[sourceKey] as? [[String : SBBJSONValue]],
                            valueArray.count > 0
                        else { return nil }
                    
                    return valueArray
                }),
                valueArrays.count > 0
            else { return [] }
        
        // consolidate them all into one list, sort by date, and return that
        var whatsAndWhens = [[String: SBBJSONValue]]();
        for valueArray in valueArrays {
            whatsAndWhens.append(contentsOf: valueArray)
        }
        return SBAClientDataProfileItem.jsonWhatsAndWhensSortedByWhen(whatsAndWhens)
    }
    
    func dateAndJsonValuesFromCachedItems() -> [SBAWhatAndWhen]? {
        guard let whatsAndWhens = SBAClientDataProfileItem.currentValues[profileKey] else { return nil }
        return whatsAndWhens.map({ return SBAWhatAndWhen(dictionaryRepresentation: $0) })
    }
    
    override open func storedValue(forKey key: String) -> Any? {
        guard let whatAndWhen = dateAndJsonValuesFromCachedItems()?.last else { return nil }
        guard let value = commonJsonToItemType(value: whatAndWhen.value)
            else {
                assertionFailure("Error reading \(key) (\(profileKey)): \(String(describing: whatAndWhen.value)) is not convertible to item type \(itemType)")
                return nil
        }
        
        if value is NSNull {
            return nil
        }
        
        return value
    }
    
    override open func setStoredValue(_ newValue: Any?) {
        setStoredValue(newValue, asOf: Date())
    }
    
    func setToAppropriateScheduledActivity(_ jsonWhatAndWhen: [String: SBBJSONValue]) {
        // potential SBBScheduledActivity instances to update will have the right activityIdentifier and will expire after, if at all
        let when = SBAWhatAndWhen(dictionaryRepresentation: jsonWhatAndWhen).date as Date
        guard let activities = SBAClientDataProfileItem.scheduledActivities?.mapAndFilter({ (scheduledActivity) -> SBBScheduledActivity? in
                    if scheduledActivity.activityIdentifier == activityIdentifier {
                        return scheduledActivity
                    }
                    return nil
                }),
                activities.count > 0
            else { return }
        
        // the appropriate activity is either the most recent one scheduled before our asOf date, or the oldest one if none
        // were scheduled before (e.g. if the value was set during onboarding before the account was created).
        var bestActivity: SBBScheduledActivity = activities.first!
        for activity in activities.reversed() {
            if activity.scheduledOn <= when {
                bestActivity = activity
                break
            }
        }
        
        if bestActivity.startedOn == nil {
            bestActivity.startedOn = when
        }
        
        setTo(bestActivity, jsonWhatAndWhen: jsonWhatAndWhen)
    }
    
    func setTo(_ scheduledActivity: SBBScheduledActivity, jsonWhatAndWhen: [String: SBBJSONValue]) {
        let when = SBAWhatAndWhen(dictionaryRepresentation: jsonWhatAndWhen).date as Date
        let clientData = scheduledActivity.clientData as? NSMutableDictionary ?? NSMutableDictionary()
        var jsonWhatsAndWhens = clientData[sourceKey] as? [[String: SBBJSONValue]] ?? [[String: SBBJSONValue]]()
        jsonWhatsAndWhens.append(jsonWhatAndWhen)
        
        // make sure the jsonWhatsAndWhens are in ascending order by date
        jsonWhatsAndWhens = SBAClientDataProfileItem.jsonWhatsAndWhensSortedByWhen(jsonWhatsAndWhens)
        clientData[sourceKey] = jsonWhatsAndWhens
        scheduledActivity.clientData = clientData
        
        if  scheduledActivity.finishedOn == nil || when > scheduledActivity.finishedOn! {
            scheduledActivity.finishedOn = when
        }

        // add the found SBBScheduledActivity to the set of those that need to be updated to Bridge
        SBAClientDataProfileItem.toBeUpdatedToBridge.insert(scheduledActivity)
    }
    
    open func setStoredValue(_ newValue: Any?, asOf when: Date) {
        guard let jsonValue = commonItemTypeToJson(val: newValue) else { return }
        
        let whatAndWhen = SBAWhatAndWhen(jsonValue, asOf: when as NSDate, isNew: true)
        
        // store it in local cache so it will get updated to Bridge next time
        SBAClientDataProfileItem.addToCurrentValues(whatAndWhen.cachedDictionaryRepresentation(), forProfileKey: profileKey)
    }
    
    open func setValue(_ newValue: Any?, asOf when: Date, to scheduledActivity: SBBScheduledActivity) {
        guard let jsonValue = commonItemTypeToJson(val: newValue) else { return }
        
        let whatAndWhen = SBAWhatAndWhen(jsonValue, asOf: when as NSDate)
        
        // store it to the specified scheduled activity's clientData
        setTo(scheduledActivity, jsonWhatAndWhen: whatAndWhen.dictionaryRepresentation())
    }
    
    open func valuesAndDates() -> [SBAWhatAndWhen] {
        let fromBridge = self.jsonWhatsAndWhensFromBridge().map({ return SBAWhatAndWhen(dictionaryRepresentation: $0) })
        let fromCache = SBAClientDataProfileItem.currentValues[profileKey]?.map({ return SBAWhatAndWhen(dictionaryRepresentation: $0) }) ?? [SBAWhatAndWhen]()
        let setOfAll = Set(fromBridge).union(fromCache)
        return Array(setOfAll).sorted()
    }
    
    /**
     This should at least be called whenever the app is leaving the foreground, and at other appropriate times
     such as closing a view controller where clientData-based profile items are edited.
     
     Calling it at app launch is also appropriate, and has the handy side effect of prepopulating scheduledActivities
     with all SBBScheduledActivity objects currently in BridgeSDK's cache.
     */
    public class func updateChangesToBridge() {
        // figure out the date range for new values in the local cache
        let calendar = Calendar.current
        var startDate: Date = calendar.startOfDay(for: Date())
        var endDate: Date = calendar.date(byAdding: .day, value: 1, to: startDate)!
        for whatsAndWhensJson in SBAClientDataProfileItem.currentValues.values {
            for whatAndWhenJson in whatsAndWhensJson {
                let whatAndWhen = SBAWhatAndWhen(dictionaryRepresentation: whatAndWhenJson)
                guard whatAndWhen.isNew else { continue }
                let whenDate = whatAndWhen.date as Date
                startDate = whenDate < startDate ? whenDate : startDate
                endDate = whenDate > endDate ? whenDate : endDate
            }
        }
        
        // fetch scheduled activities from Bridge covering those dates so we're fairly sure to have instances
        // to save the values on
        SBABridgeManager.fetchScheduledActivities(from: startDate, to: endDate) { (activities, error) in
            if error == nil {
                // now fetch all the scheduled activities we've got in the cache
                SBABridgeManager.fetchAllCachedScheduledActivities(completion: { (cachedActivities, cacheError) in
                    if cacheError == nil {
                        guard let scheduledActivities = cachedActivities as? [SBBScheduledActivity],
                            scheduledActivities.count > 0
                            else { return }
                        
                        // Setting this will trigger any new cached item values to be saved to the appropriate
                        // SBBScheduledActivity instance and pushed to Bridge.
                        SBAClientDataProfileItem.scheduledActivities = scheduledActivities
                    }
                })
            }
        }
    }
}


open class SBAFullNameProfileItem: SBAStudyParticipantProfileItem, SBANameDataSource {
    
    override open var value: Any? {
        
        get {
            return self.fullName
        }
        
        set {
            // readonly
        }
    }
    
    override open var readonly: Bool {
        return true
    }
    
    fileprivate dynamic var givenNameKey: String {
        let key = #keyPath(givenNameKey)
        return sourceDict[key] as? String ?? SBAProfileSourceKey.givenName.rawValue
    }
    
    fileprivate dynamic var familyNameKey: String {
        let key = #keyPath(familyNameKey)
        return sourceDict[key] as? String ?? SBAProfileSourceKey.familyName.rawValue
    }
    
    open var name: String? {
        return self.storedValue(forKey: givenNameKey) as? String 
    }
    
    open var familyName: String? {
        return self.storedValue(forKey: familyNameKey) as? String
    }
    
}

open class SBABirthDateProfileItem: SBAStudyParticipantCustomAttributesProfileItem {
    
    override open var demographicJsonValue: SBBJSONValue? {
        guard let age = (self.value as? Date)?.currentAge() else { return nil }
        return NSNumber(value: age)
    }
}
