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
    var items: [SBAProfileTableItem] { get }
}

@objc
public protocol SBAProfileTableItem: NSObjectProtocol {
    var title: String { get }
    var detail: String { get }
    var isEditable: Bool { get }
}

open class SBAProfileSectionObject: SBADataObject, SBAProfileSection {
    open dynamic var title: String?
    open dynamic var items: [SBAProfileTableItem] = []
    
    // MARK: SBADataObject overrides
    
    override open func dictionaryRepresentationKeys() -> [String] {
        return super.dictionaryRepresentationKeys().appending(contentsOf: [#keyPath(title), #keyPath(items)])
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
    let sourceDict: [AnyHashable: Any]

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
    
    open var detail: String {
        get {
            let key = #keyPath(detail)
            return sourceDict[key] as? String ?? ""
        }
    }
    
    open var isEditable: Bool {
        get {
            let key = #keyPath(isEditable)
            guard let editable = sourceDict[key] as? Bool else { return false }
            return editable
        }
    }
}

open class SBAHTMLProfileTableItem: SBAProfileTableItemBase {
    open var htmlResource: String {
        get {
            let key = #keyPath(htmlResource)
            return sourceDict[key]! as! String
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
    @objc
    open var profileItemKey: String {
        get {
            let key = #keyPath(profileItemKey)
            return sourceDict[key]! as! String
        }
    }
    
    lazy open var profileItem: SBAProfileItem = {
        let profileItems = SBAProfileManager.shared!.profileItems()
        return profileItems[self.profileItemKey]!
    }()

    override open var detail: String {
        get {
            return "\(profileItem.value ?? "")"
        }
    }
}
