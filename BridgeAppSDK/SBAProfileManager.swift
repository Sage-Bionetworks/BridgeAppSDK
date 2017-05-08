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
import BridgeAppSDK
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
        super.init()
        self.errorType = errorType
        self.key = key
    }
}

public protocol SBAProfileManagerProtocol: NSObjectProtocol {

    /**
     Get a list of the profile keys defined for this app.
     
     @return A String array of profile item keys.
     */
    public func profileKeys() -> [String]
    
    /**
     Get the profile items defined for this app.
     
     @return A Dictionary of SBAProfileItem objects by key.
     */
    public func profileItems() -> [String: SBAProfileItem]
    
    /**
     Get the value of a profile item by its key.
     
     @return The value (optional) of the specified item.
     */
    public func value(forProfileKey: String) -> Any?
    
    /**
     Set the value of the profile item by its key.
     
     @throws Throws an error if there is no profile item with the specified key.
     @param value The new value to set for the profile item.
     */
    public func setValue(_ value: Any?, forProfileKey key: String) throws
    
    /**
     Set up and return a view controller for displaying a Profile view.
     
     @return A view controller for displaying the Profile view.
     */
    public func profileViewController() -> UIViewController?

}


open class SBAProfileManager: SBADataObject, SBAProfileManagerProtocol, SBAProfileDataSource {

    static let shared = {
        guard let json = SBAResourceFinder.shared.json(forResource: jsonName) as? [[String: Any]],
                let sharedProfileManager = SBAClassTypeMap.shared.object(with:json, classType:SBAProfileManagerClassType) as? SBAProfileManagerProtocol
            else { return nil }
        return sharedProfileManager
    }()

    private dynamic var items: [SBAProfileItem] = []
    private var itemsKeys: [String] = {
        var allKeys = []
        for item in items {
            allKeys.append(item.key)
        }
        return allKeys
    }()
    
    private var itemsMap: [String: SBAProfileItem] = {
        var allItems = [:]
        for item in items {
            allItems[item.key] = item
        }
        return allItems
    }()
    
    private var sections: [SBAProfileSection] = []
   
    // MARK: SBADataObject overrides
    
    override open func dictionaryRepresentationKeys() -> [String] {
        return super.dictionaryRepresentationKeys().appending(#keyPath(items))
    }
    
    // MARK: SBAProfileManagerProtocol
    
    public func profileKeys() -> [String] {
        return itemsKeys
    }
    
    public func profileItems() -> [String: SBAProfileItem] {
        return itemsMap
    }
    
    public func value(forProfileKey: String) -> Any? {
        guard let item = self.itemsMap[key] else { return nil }
        
        return item.value
    }
    
    public func setValue(_ value: Any?, forProfileKey key: String) throws {
        guard let item = self.itemsMap[key] else {
            throw SBAProfileManagerError.init(errorType: .unknownProfileKey, key: key)
        }
        
        item.value = value
    }
    
    // MARK: View controller
    
    public func profileViewController() -> UIViewController? {
        return self.initializeViewController()
    }
    
    // Instantiate an SBAProfileViewController with this instance set as its SBAProfileDataSource. 
    func initializeViewController(fromJson jsonFile: String = SBAProfileJSONFilename) -> UIViewController? {
        guard let json = SBAResourceFinder.shared.json(forResource: jsonName),
            let jsonSections = json["sections"] as? [SBAProfileSection]
            else { return }
        sections = jsonSections,
        
        let viewController = SBAProfileViewController()
        
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
