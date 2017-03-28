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

@objc
public protocol SBAProfileItem: NSObjectProtocol {
    var title: String { get }
    var detail: String? { get }
    var isEditable: Bool { get }
    var value: Any? { get set }
}

class SBAKeychainProfileItem: NSObject, SBAProfileItem {
    private var key: String
    private var keychain: SBAKeychainWrapper
    open var title: String
    open var detail: String?
    open var isEditable: Bool
    
    public init(title: String, detail: String?, isEditable: Bool = true, key: String, keychain: SBAKeychainWrapper = SBAUser.shared.keychain) {
        self.key = key
        self.keychain = keychain
        self.title = title
        self.detail = detail
        self.isEditable = isEditable
        super.init()
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
}

public protocol PlistValue {}

extension NSData: PlistValue {}
extension NSString: PlistValue {}
extension NSNumber: PlistValue {}
extension NSDate: PlistValue {}
extension NSArray: PlistValue {}
extension NSDictionary: PlistValue {}
extension Data: PlistValue {}
extension String: PlistValue {}
extension Bool: PlistValue {}
extension Double: PlistValue {}
extension Float: PlistValue {}
extension Int: PlistValue {}
extension Int8: PlistValue {}
extension Int16: PlistValue {}
extension Int32: PlistValue {}
extension Int64: PlistValue {}
extension UInt: PlistValue {}
extension UInt8: PlistValue {}
extension UInt16: PlistValue {}
extension UInt32: PlistValue {}
extension UInt64: PlistValue {}
extension Date: PlistValue {}
extension Array: PlistValue {}
extension Dictionary: PlistValue {}


class SBAUserDefaultsProfileItem: NSObject, SBAProfileItem {
    private var key: String
    private var defaults: UserDefaults
    open var title: String
    open var detail: String?
    open var isEditable: Bool
    
    public init(title: String, detail: String?, isEditable: Bool = true, key: String, defaults: UserDefaults? = SBAUser.shared.bridgeInfo?.userDefaults) {
        self.key = key
        self.defaults = defaults != nil ? defaults! : UserDefaults.standard
        self.title = title
        self.detail = detail
        self.isEditable = isEditable
        super.init()
    }
    
    open var value: Any? {
        get {
            return defaults.object(forKey: key)
        }
        
        set {
            if newValue == nil {
                defaults.removeObject(forKey: key)
            } else {
                guard let plistVal = newValue as? PlistValue else {
                    print("Error setting \(key) in user defaults: \(newValue) does not conform to PlistValue")
                    return
                }
                defaults.set(plistVal, forKey: key)
            }
        }
    }
}
