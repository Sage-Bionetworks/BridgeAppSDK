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

public var SBAProfileJSONFilename = "Profile"
public var SBAProfileItemsJSONFilename = "ProfileItems"
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
    var key: String
    
    public init(errorType: SBAProfileManagerErrorType, key: String) {
        self.errorType = errorType
        self.key = key
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
     
     @return A Dictionary of SBAProfileItem objects by key.
     */
    func profileItems() -> [String: SBAProfileItem]
    
    /**
     Get the value of a profile item by its key.
     
     @return The value (optional) of the specified item.
     */
    func value(forProfileKey: String) -> Any?
    
    /**
     Set the value of the profile item by its key.
     
     @throws Throws an error if there is no profile item with the specified key.
     @param value The new value to set for the profile item.
     */
    func setValue(_ value: Any?, forProfileKey key: String) throws
    
    /**
     Set up and return a view controller for displaying a Profile view.
     
     @return A view controller for displaying the Profile view.
     */
    func profileViewController() -> UIViewController?

}


open class SBAProfileManager: SBADataObject, SBAProfileManagerProtocol, SBAProfileDataSource {

    /**
     The shared instance of the profile manager. Loads from SBAProfileItemsJSONFilename, which
     defaults to "ProfileItems".
     */
    static let shared: SBAProfileManagerProtocol? = {
        guard let json = SBAResourceFinder.shared.json(forResource: SBAProfileItemsJSONFilename),
                let sharedProfileManager = SBAClassTypeMap.shared.object(with:json, classType:SBAProfileManagerClassType) as? SBAProfileManagerProtocol
            else { return nil }
        return sharedProfileManager
    }()

    private dynamic var items: [SBAProfileItem] = []
    lazy private var itemsKeys: [String] = {
        var allKeys: [String] = []
        for item in self.items {
            allKeys.append(item.key)
        }
        return allKeys
    }()
    
    lazy private var itemsMap: [String: SBAProfileItem] = {
        var allItems: [String: SBAProfileItem] = [:]
        for item in self.items {
            allItems[item.key] = item
        }
        return allItems
    }()
    
    private var sections: [SBAProfileSection] = []
   
    // MARK: SBADataObject overrides
    
    override open func dictionaryRepresentationKeys() -> [String] {
        return super.dictionaryRepresentationKeys().appending(#keyPath(items))
    }
    
    override open func defaultValue(forKey key: String) -> Any? {
        if key == "items" {
            return [] as [String]
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
     @return A map of all the profile items by key.
     */
    public func profileItems() -> [String: SBAProfileItem] {
        return itemsMap
    }
    
    /**
     Get the value of a profile item by its key.
     
     @param key The key for the profile item to be retrieved.
     @return The value of the profile item, as stored in whatever underlying storage it uses.
     */
    public func value(forProfileKey key: String) -> Any? {
        guard let item = self.itemsMap[key] else { return nil }
        
        return item.value
    }
    
    /**
     Set (or clear) a new value on a profile item by key.
     @param value The new value to set.
     @param key The key of the profile item on which to set the new value.
     */
    public func setValue(_ value: Any?, forProfileKey key: String) throws {
        guard let item = self.itemsMap[key] else {
            throw SBAProfileManagerError.init(errorType: .unknownProfileKey, key: key)
        }
        
        item.value = value
    }
    
    // MARK: View controller
    
    /**
     Get a view controller for displaying the profile. Instantiates and returns a default controller
     described in the JSON file specified by SBAProfileJSONFilename, which defaults to "Profile".
     */
    public func profileViewController() -> UIViewController? {
        return self.initializeViewController()
    }
    
    // Instantiate an SBAProfileViewController with this instance set as its SBAProfileDataSource. 
    func initializeViewController(fromJson jsonFile: String = SBAProfileJSONFilename) -> UIViewController? {
        // TODO: emm2017-05-08 implement this
//        guard let json = SBAResourceFinder.shared.json(forResource: jsonName),
//            let jsonSections = json["sections"] as? [SBAProfileSection]
//            else { return }
//        sections = jsonSections,
//        
//        let viewController = SBAProfileViewController()
        
        return nil
    }
    
    // MARK: SBAProfileDataSource
    
    public func numberOfSections() -> Int {
        return sections.count
    }
    
    public func numberOfRows(for section: Int) -> Int {
        if section >= sections.count { return 0 } // out of range
        return sections[section].items.count
    }
    
    public func profileItem(at indexPath: IndexPath) -> SBAProfileItem? {
        let section = indexPath.section
        let row = indexPath.row
        
        if section >= sections.count { return nil }
        if row >= sections[section].items.count { return nil }
        
        return sections[section].items[row]
    }
        
    public func title(for section: Int) -> String? {
        if section >= sections.count { return nil }
        return sections[section].title
    }
}
