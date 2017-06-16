//
//  SBAProfileManager.swift
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

public var SBAProfileItemsJSONFilename = "ProfileItems"
public var SBAProfileQuestionsJSONFilename = "ProfileQuestions"
public var SBAProfileManagerClassType = "ProfileManager"

/**
 Profile manager error types
 */
public enum SBAProfileManagerErrorType {
    case unknownProfileKey
}

/**
 Profile manager error object
 */
public class SBAProfileManagerError: NSObject, Error {
    var errorType: SBAProfileManagerErrorType
    var profileKey: String
    
    public init(errorType: SBAProfileManagerErrorType, profileKey key: String) {
        self.errorType = errorType
        self.profileKey = key
        super.init()
    }
}

public protocol SBAProfileManagerProtocol: NSObjectProtocol {

    /**
     Get a list of the profile keys defined for this app.
     
     @return A String array of profile item keys.
     */
    func profileKeys() -> [String]
    
    /**
     Get the profile items defined for this app.
     
     @return A Dictionary of SBAProfileItem objects by profileKey.
     */
    func profileItems() -> [String: SBAProfileItem]
    
    /**
     Get the value of a profile item by its profileKey.
     
     @return The value (optional) of the specified item.
     */
    func value(forProfileKey: String) -> Any?
    
    /**
     Set the value of the profile item by its profileKey.
     
     @throws Throws an error if there is no profile item with the specified profileKey.
     @param value The new value to set for the profile item.
     @param key The profileKey of the item whose value is to be set.
     */
    func setValue(_ value: Any?, forProfileKey key: String) throws

}


open class SBAProfileManager: SBADataObject, SBAProfileManagerProtocol {
    
    // The default keychain and user defaults are created by the info manager
    public static let keychain = SBAInfoManager.shared.createKeychainWrapper()
    public static let userDefaults = SBAInfoManager.shared.userDefaults

    /**
     The shared instance of the profile manager. Loads from SBAProfileItemsJSONFilename, which
     defaults to "ProfileItems".
     
     If you subclass SBAProfileManager, or just want this method to return a different class that
     implements the SBAProfileManagerProtocol, you will need to override the mapping for the default
     value of SBAProfileManagerClassType ("ProfileManager") in your ClassTypeMap.plist to map to your
     class instead of this one. Alternatively you could change the value of SBAProfileManagerClassType
     before accessing this, and map *that* in your ClassTypeMap.plist; or just set SBAProfileManagerClassType
     to the fully qualified class name without setting up any mappings.
     */
    public static let shared: SBAProfileManagerProtocol? = {
        SBABridgeManager.addResourceBundleIfNeeded()
        let bundles = SBAInfoManager.shared.resourceBundles.reversed()
        // The SBAUser will default to the profile manager if available, but if not will fall-back
        // to older methods for storing information.
        let sharedProfileManager = SBAProfileManager()
        
        for bundle in bundles {
            guard let json = SBAResourceFinder.shared.json(forResource: SBAProfileItemsJSONFilename, bundle:bundle),
                let profileManager = SBAClassTypeMap.shared.object(with:json, classType:SBAProfileManagerClassType) as? SBAProfileManager
                else {
                    continue
            }
            sharedProfileManager.add(items: profileManager.items)
        }
        
        return sharedProfileManager
    }()

    private dynamic var items: [SBAProfileItem] = []
    lazy private var itemsKeys: [String] = {
        return self.items.map({ $0.profileKey })
    }()
    
    lazy private var itemsMap: [String: SBAProfileItem] = {
        var allItems: [String: SBAProfileItem] = [:]
        for item in self.items {
            allItems[item.profileKey] = item
        }
        return allItems
    }()
    
    // Merge new items into existing list, overwriting old ones with new ones when the profileKey is the same.
    // Mustn't be called once either itemsKeys or itemsMap has been accessed, and mustn't access either.
    fileprivate func add(items newItems: [SBAProfileItem]) {
        var itemsByKey: [String: SBAProfileItem] = [:]
        for item in items {
            itemsByKey[item.profileKey] = item
        }
        for newItem in newItems {
            itemsByKey[newItem.profileKey] = newItem
        }
        items = Array(itemsByKey.values)
    }
   
    // MARK: SBADataObject overrides
    
    override open func dictionaryRepresentationKeys() -> [String] {
        return super.dictionaryRepresentationKeys().appending(#keyPath(items))
    }
    
    override open func defaultValue(forKey key: String) -> Any? {
        if key == #keyPath(items) {
            return [SBAProfileItem]()
        } else {
            return super.defaultValue(forKey: key)
        }
    }
    
    // MARK: SBAProfileManagerProtocol
    
    /**
     @return A list of all the profile keys known to the profile manager.
     */
    public func profileKeys() -> [String] {
        return itemsKeys
    }
    
    /**
     @return A map of all the profile items by profileKey.
     */
    public func profileItems() -> [String: SBAProfileItem] {
        return itemsMap
    }
    
    /**
     Get the value of a profile item by its profileKey.
     
     @param key The profileKey for the profile item to be retrieved.
     @return The value of the profile item, as stored in whatever underlying storage it uses.
     */
    public func value(forProfileKey key: String) -> Any? {
        guard let item = self.itemsMap[key] else { return nil }
        
        return item.value
    }
    
    /**
     Set (or clear) a new value on a profile item by profileKey.
     @param value The new value to set.
     @param key The profileKey of the profile item on which to set the new value.
     */
    public func setValue(_ value: Any?, forProfileKey key: String) throws {
        guard let item = self.itemsMap[key] else {
            throw SBAProfileManagerError(errorType: .unknownProfileKey, profileKey: key)
        }
        
        item.value = value
    }
}
