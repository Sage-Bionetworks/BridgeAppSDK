//
//  SBAProfileDataSource.swift
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

public var SBAProfileJSONFilename = "Profile"
public var SBAProfileDataSourceClassType = "ProfileDataSource"

@objc
public protocol SBAProfileDataSource: class {
    /**
     Number of sections in the data source.
     @return    Number of sections.
     */
    func numberOfSections() -> Int
    
    /**
     Number of rows in the data source.
     @param     section    The section of the collection.
     @return               The number of rows in the given section.
     */
    @objc(numberOfRowsInSection:)
    func numberOfRows(for section: Int) -> Int
    
    /**
     The profile table item at the given index.
     @param indexPath   The index path for the profile table item.
     */
    @objc(profileTableItemAtIndexPath:)
    func profileTableItem(at indexPath: IndexPath) -> SBAProfileTableItem?
    
    /**
     Called when a row is selected.
     @param indexPath   The index path for the profile item.
     */
    @objc(didSelectRowAtIndexPath:)
    optional func didSelectRow(at indexPath: IndexPath)
    
    /**
     Title for the given section (if applicable)
     @param     section    The section of the collection.
     @return               The title for this section or `nil` if no title.
     */
    @objc(titleForSection:)
    optional func title(for section: Int) -> String?   
}

open class SBAProfileDataSourceObject: SBADataObject, SBAProfileDataSource {
    
    /**
     The shared instance of the profile data source. Loads from SBAProfileJSONFilename, which
     defaults to "Profile".
     
     If you subclass SBAProfileDataSourceObject, or just want this method to return a different class that
     implements the SBAProfileDataSource protocol, you will need to override the mapping for the default
     value of SBAProfileDataSourceClassType ("ProfileDataSource") in your ClassTypeMap.plist to map to your
     class instead of this one. Alternatively you could change the value of SBAProfileSectionClassType
     before accessing this, and map *that* in your ClassTypeMap.plist; or just set SBAProfileSectionClassType
     to the fully qualified class name without setting up any mappings.
     */
    public static let shared: SBAProfileDataSource? = {
        guard let json = SBAResourceFinder.shared.json(forResource: SBAProfileJSONFilename),
            let sharedProfileDataSource = SBAClassTypeMap.shared.object(with:json, classType:SBAProfileDataSourceClassType) as? SBAProfileDataSource
            else { return nil }
        return sharedProfileDataSource
    }()
    
    private dynamic var sections: [SBAProfileSection] = []

    // MARK: SBADataObject overrides
    
    override open func dictionaryRepresentationKeys() -> [String] {
        return super.dictionaryRepresentationKeys().appending(#keyPath(sections))
    }
    
    override open func defaultValue(forKey key: String) -> Any? {
        if (key == #keyPath(sections)) {
            return [SBAProfileSection]()
        } else {
            return super.defaultValue(forKey: key)
        }
    }

    // MARK: SBAProfileDataSource
    
    open func numberOfSections() -> Int {
        return sections.count
    }
    
    open func numberOfRows(for section: Int) -> Int {
        if section >= sections.count { return 0 } // out of range
        return sections[section].items.count
    }
    
    open func profileTableItem(at indexPath: IndexPath) -> SBAProfileTableItem? {
        let section = indexPath.section
        let row = indexPath.row
        
        if section >= sections.count { return nil }
        if row >= sections[section].items.count { return nil }
        
        return sections[section].items[row]
    }
    
    open func title(for section: Int) -> String? {
        if section >= sections.count { return nil }
        return sections[section].title
    }
}
