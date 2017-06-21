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
            return val as? NSNumber
            
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
            guard let val = value! as? HKBiologicalSex else { return nil }
            itemValue = val
            
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
