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

public let SBAProfileJSONFilename = "Profile"

open class SBAProfileManager: NSObject, SBAProfileDataSource {
    var sections: [SBAProfileSection] = []
    
    // MARK: initializers
    
    public override convenience init() {
        self.init(jsonName: SBAProfileJSONFilename)
    }
    
    public init(jsonName: String) {
        super.init()
        commonInit(jsonName: jsonName)
    }
    
    func commonInit(jsonName: String) {
        guard let json = SBAResourceFinder.shared.json(forResource: jsonName),
              let jsonSections = json["sections"] as? [SBAProfileSection]
            else { return }
        sections = jsonSections
    }
    
    // MARK: View controller
    
    /**
     Set up and return a view controller for displaying a Profile view.
     By default, it will instantiate an SBAProfileViewController with this instance set as its
     SBAProfileDataSource. Override this method to provide your own view controller
     for the Profile view.
     
     @return A view controller for displaying the Profile view.
     */
    open func initializeViewController() -> UIViewController {
        
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
