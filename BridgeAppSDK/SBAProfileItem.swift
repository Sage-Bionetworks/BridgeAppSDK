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
}

extension SBAProfileItem {
    func commonJsonValueGetter() -> SBBJSONValue? {
        guard let val = self.value else { return NSNull() }
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
            return val as? NSNumber
            
        default:
            return nil
        }
    }
    
    func commonJsonValueSetter(value: SBBJSONValue?) {
        guard value != nil else {
            self.value = nil
            return
        }
        
        switch self.itemType {
        case SBAProfileTypeIdentifier.string:
            guard let val = value as? String else { return }
            self.value = val
            
        case SBAProfileTypeIdentifier.number:
            guard let val = value as? NSNumber else { return }
            self.value = val
            
        case SBAProfileTypeIdentifier.bool:
            guard let val = value as? Bool else { return }
            self.value = val
            
        case SBAProfileTypeIdentifier.date:
            guard let stringVal = value as? String,
                    let dateVal = NSDate(iso8601String: stringVal)
                else { return }
            self.value = dateVal
            
        case SBAProfileTypeIdentifier.hkBiologicalSex:
            guard let val = value as? HKBiologicalSex else { return }
            self.value = val
            
        case SBAProfileTypeIdentifier.hkQuantity:
            guard let val = value as? NSNumber else { return }
            self.value = val
            
        default:
            break
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
            return newValue as? String != nil
            
        case SBAProfileTypeIdentifier.number:
            return newValue as? NSNumber != nil
            
        case SBAProfileTypeIdentifier.bool:
            return newValue as? NSNumber != nil
            
        case SBAProfileTypeIdentifier.date:
            return newValue as? NSDate  != nil
            
        case SBAProfileTypeIdentifier.hkBiologicalSex:
            return newValue as? HKBiologicalSex != nil
            
        case SBAProfileTypeIdentifier.hkQuantity:
            return newValue as? NSNumber != nil
            
        default:
            return false
        }
    }
}

open class SBAProfileItemBase: NSObject, SBAProfileItem {
    /**
     The value property is used to get and set the profile item's value in whatever internal data
     storage is used by the implementing class.
     */
    open var value: Any?

    fileprivate let sourceDict: [AnyHashable: Any]
    
    open var profileKey: String {
        get {
            let key = #keyPath(profileKey)
            return sourceDict[key]! as! String
        }
    }
    
    open var sourceKey: String {
        get {
            let key = #keyPath(sourceKey)
            return sourceDict[key] as? String ?? self.profileKey
        }
    }
    
    open var demographicKey: String {
        get {
            let key = #keyPath(demographicKey)
            return sourceDict[key] as? String ?? self.profileKey
        }
    }
    
    open var itemType: SBAProfileTypeIdentifier {
        get {
            let key = #keyPath(itemType)
            guard let rawValue = sourceDict[key] as? String else { return .string }
            return SBAProfileTypeIdentifier(rawValue: rawValue)
        }
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
        get {
            return self.commonDemographicJsonValue()
        }
    }
}

open class SBAKeychainProfileItem: SBAProfileItemBase {
    private let keychain: SBAKeychainWrapper
    
    public required init(dictionaryRepresentation dictionary: [AnyHashable: Any]) {
        var keychainToUse = SBAUser.shared.keychain
        
        let keychainService = dictionary["keychainService"] as! String?
        let keychainAccessGroup = dictionary["keychainAccessGroup"] as! String?
        
        if (keychainService != nil || keychainAccessGroup != nil) {
            keychainToUse = SBAKeychainWrapper(service: keychainService, accessGroup: keychainAccessGroup)
        }
        
        keychain = keychainToUse
        
        super.init(dictionaryRepresentation: dictionary)
    }
    
    override open var value: Any? {
        get {
            var err: NSError?
            let obj = keychain.object(forKey: profileKey, error: &err)
            if let error = err {
                print("Error accessing keychain \(profileKey): \(error.code) \(error)")
            }
            return self.typedValue(from: obj)
        }
        
        set {
            do {
                if newValue == nil {
                    try keychain.removeObject(forKey: profileKey)
                } else {
                    if !self.commonCheckTypeCompatible(newValue: newValue) {
                        assert(false, "Error setting \(profileKey): \(String(describing: newValue)) not compatible with specified type \(itemType.rawValue)")
                        return
                    }
                    guard let secureVal = secureCodingValue(of: newValue) else {
                        assert(false, "Error setting \(profileKey) in keychain: don't know how to convert \(String(describing: newValue))) to NSSecureCoding")
                        return
                    }
                    try keychain.setObject(secureVal, forKey: profileKey)
                }
            }
            catch let error {
                assert(false, "Failed to set \(profileKey): \(String(describing: error))")
            }
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
    private let defaults: UserDefaults
    
    public required init(dictionaryRepresentation dictionary: [AnyHashable: Any]) {
        var defaultsToUse = SBAUser.shared.bridgeInfo?.userDefaults ?? UserDefaults.standard
        
        let userDefaultsSuiteName = dictionary["userDefaultsSuiteName"] as! String?
        
        if (userDefaultsSuiteName != nil) {
            defaultsToUse = UserDefaults(suiteName: userDefaultsSuiteName) ?? defaultsToUse
        }
        
        defaults = defaultsToUse
        
        super.init(dictionaryRepresentation: dictionary)
    }
    
    override open var value: Any? {
        get {
            return typedValue(from: defaults.object(forKey: profileKey) as? PlistValue)
        }
        
        set {
            if newValue == nil {
                defaults.removeObject(forKey: profileKey)
            } else {
                if !self.commonCheckTypeCompatible(newValue: newValue) {
                    assert(false, "Error setting \(profileKey): \(String(describing: newValue)) not compatible with specified type\(itemType.rawValue)")
                    return
                }
                guard let plistVal = pListValue(of: newValue) else {
                    assert(false, "Error setting \(profileKey) in user defaults: don't know how to convert \(String(describing: newValue)) to PlistValue")
                    return
                }
                defaults.set(plistVal, forKey: profileKey)
            }
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
