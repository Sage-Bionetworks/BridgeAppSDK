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
public protocol SBAProfileItem: SBAJSONDictionaryRepresentableObject {    
    /**
     key is used to access a specific profile item, and so must be unique across all SBAProfileItems
     within an app.
     */
    var key: String { get }
    
    /**
     sourceKey is the profile item's key within its internal data storage. By default it will be the
     same as key, but can be different if needed (e.g. two different profile items happen to map to
     the same key in different storage types).
     */
    var sourceKey: String { get }
    
    /**
     demographicKey is the profile item's key in the demographic data upload schema. By default it will
     be the same as key, but can be different if needed.
     */
    var demographicKey: String { get }
    
    /**
     itemType specifies what type to store the profileItem as.
     */
    var itemType: String { get }
    
    /**
     The value property is used to get and set the profile item's value in whatever internal data
     storage is used by the implementing class.
     */
    var value: Any? { get set }
    
    /**
     jsonValue is used to get and set the profile item's value directly from appropriate JSON.
     */
    var jsonValue: JSONValue? { get set }
    
    /**
     demographicJsonValue is used when formatting the item as demographic data for upload to Bridge.
     By default it will fall through to the getter for the jsonValue property, but can be different
     if needed.
     */
    var demographicJsonValue: JSONValue? { get }
}

extension SBAProfileItem {
    func commonInit(dictionaryRepresentation dictionary: [AnyHashable: Any]) {
        self.key = dictionary[NSStringFromSelector(#selector(key))]!
        self.sourceKey = dictionary[NSStringFromSelector(#selector(sourceKey))] ?? self.key
        self.demographicKey = dictionary[NSStringFromSelector(#selector(demographicKey))] ?? self.key
        self.itemType = dictionary[NSStringFromSelector(#selector(itemType))]!
    }
    
    func commonJsonValueGetter() -> JSONValue? {
        guard let val = self.value else { return NSNull() }
        switch self.itemType {
        case "String":
            return val as? String
            
        case "Number":
            return val as? NSNumber
            
        case "Bool":
            return val as? Bool
            
        case "Date":
            return (val as? NSDate)?.iso8601String()
            
        case "HKBiologicalSex":
            return val as? NSNumber
            
        case "HKQuantity":
            return val as? NSNumber
            
        default:
            return nil
        }
    }
    
    func commonJsonValueSetter(value: Any?) {
        guard let val = value else {
            self.value = nil
            return
        }
        
        switch self.itemType {
        case "String":
            guard let val = value as? String else { return }
            self.value = val
            
        case "Number":
            guard let val = value as? NSNumber else { return }
            self.value = val
            
        case "Bool":
            guard let val = value as? Bool else { return }
            self.value = val
            
        case "Date":
            var dateVal = value as? Date
            if dateVal == nil {
                guard let stringVal = value as? String,
                        let dateFromString = NSDate(iso8601String: stringVal)
                    else { return }
                dateVal = dateFromString
            }
            self.value = dateVal
            
        case "HKBiologicalSex":
            guard let val = value as? NSNumber else { return }
            self.value = val
            
        case "HKQuantity":
            guard let val = value as? NSNumber else { return }
            self.value = val
            
        default:
            break
        }
    }
    
    func commonDemographicJsonValue() -> JSONValue? {
        guard let jsonVal = self.commonJsonValueGetter() else { return nil }
        if self.itemType == "HKBiologicalSex" {
            return (self.value as? HKBiologicalSex)?.demographicDataValue
        }
        
        return jsonVal
    }
    
    func commonCheckTypeCompatible(newValue: Any?) -> Bool {
        guard let newVal = newValue as? Any else { return true }
        
        switch self.itemType {
        case "String":
            return newVal as? String != nil
            
        case "Number":
            return newVal as? NSNumber != nil
            
        case "Bool":
            return newVal as? Bool != nil
            
        case "Date":
            return newVal as? Date  != nil
            
        case "HKBiologicalSex":
            return newVal as? NSNumber != nil
            
        case "HKQuantity":
            return newVal as? NSNumber != nil
            
        default:
            return nil
        }
    }
}

class SBAKeychainProfileItem: NSObject, SBAProfileItem {
    open var key: String
    open var sourceKey: String
    open var demographicKey: String
    open var itemType: String

    private var keychain: SBAKeychainWrapper
    
    public init(dictionaryRepresentation dictionary: [AnyHashable: Any]) {
        super.init()
        self.commonInit(dictionaryRepresentation: dictionary)
        keychain = SBAUser.shared.keychain
        
        let keychainService = dictionary[NSStringFromSelector(#selector(service))]
        let keychainAccessGroup = dictionary[NSStringFromSelector(#selector(accessGroup))]
        
        if (keychainService != nil || keychainAccessGroup != nil) {
            keychain = SBAKeychainWrapper(service: keychainService, accessGroup: keychainAccessGroup)
        }
    }
    
    open var value: Any? {
        get {
            var err: NSError?
            let obj = keychain.object(forKey: key, error: &err)
            if let error = err {
                print("Error accessing keychain \(key): \(error.code) \(error)")
            }
            return obj
        }
        
        set {
            do {
                if newValue == nil {
                    try keychain.removeObject(forKey: key)
                } else {
                    guard let compatible = self.commonCheckTypeCompatible(newValue: newValue) else {
                        print("Error setting \(key): \(newValue) not compatible with specified type\(itemType)")
                        return
                    }
                    guard let secureVal = newValue as? NSSecureCoding else {
                        print("Error setting \(key) in keychain: \(newValue) does not conform to NSSecureCoding")
                        return
                    }
                    try keychain.setObject(secureVal, forKey: key)
                }
            }
            catch let error as NSError {
                print("Failed to set \(key): \(error.code) \(error.localizedDescription)")
            }
        }
    }
    
    open var jsonValue: JSONValue? {
        get {
            return self.commonJsonValueGetter()
        }
        
        set {
            commonJsonValueSetter(value: newValue)
        }
    }
    
    open var demographicJsonValue: JSONValue? {
        get {
            return self.commonDemographicJsonValue()
        }
    }
}

public protocol JSONValue {}

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

public protocol PlistValue: JSONValue {}

extension NSData: PlistValue {}
extension NSDate: PlistValue {}
extension Data: PlistValue {}
extension Date: PlistValue {}


class SBAUserDefaultsProfileItem: NSObject, SBAProfileItem {
    open var key: String
    open var sourceKey: String
    open var demographicKey: String
    open var itemType: String
    
    private var defaults: UserDefaults
    
    public init(dictionaryRepresentation dictionary: [AnyHashable: Any]) {
        super.init()
        self.commonInit(dictionaryRepresentation: dictionary)
        defaults = SBAUser.shared.bridgeInfo?.userDefaults ?? UserDefaults.standard
        
        let userDefaultsSuiteName = dictionary[NSStringFromSelector(#selector(suiteName))]
        
        if (userDefaultsSuiteName != nil) {
            defaults = UserDefaults(suiteName: userDefaultsSuiteName) ?? defaults
        }
    }
    
    open var value: Any? {
        get {
            return defaults.object(forKey: key)
        }
        
        set {
            if newValue == nil {
                defaults.removeObject(forKey: key)
            } else {
                guard let compatible = self.commonCheckTypeCompatible(newValue: newValue) else {
                    print("Error setting \(key): \(newValue) not compatible with specified type\(itemType)")
                    return
                }
                guard let plistVal = newValue as? PlistValue else {
                    print("Error setting \(key) in user defaults: \(newValue) does not conform to PlistValue")
                    return
                }
                defaults.set(plistVal, forKey: key)
            }
        }
    }
    
    open var jsonValue: JSONValue? {
        get {
            return self.commonJsonValueGetter()
        }
        
        set {
            commonJsonValueSetter(value: newValue)
        }
    }
    
    open var demographicJsonValue: JSONValue? {
        get {
            return self.commonDemographicJsonValue()
        }
    }
}
