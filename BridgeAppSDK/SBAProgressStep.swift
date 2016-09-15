//
//  SBAProgressStep.swift
//  BridgeAppSDK
//
//  Copyright © 2016 Sage Bionetworks. All rights reserved.
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

import ResearchKit

open class SBAProgressStep: ORKTableStep {
    
    // MARK: Default initializer
    
    public init(identifier: String, stepTitles:[String], index: Int) {
        let progessIdentifier = "\(identifier).\(stepTitles[index])"
        super.init(identifier: progessIdentifier)
        
        self.items = stepTitles.enumerated().map({ (idx: Int, title: String) -> SBACheckmarkItem in
            return SBACheckmarkItem(title: title, checked: (idx <= index))
        })
        self.title = Localization.localizedString("SBA_PROGRESS_STEP_TITLE")
    }
    
    // MARK: Copying
    
    public override init(identifier: String) {
        super.init(identifier: identifier)
    }
    
    // MARK: Encoding
    
    public required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
}

class SBACheckmarkItem: NSObject, NSSecureCoding, NSCopying {
    
    let checked: Bool
    let title: String
    
    init(title: String, checked: Bool) {
        self.title = title
        self.checked = checked
        super.init()
    }
    
    override var description: String {
        let checkmarkKey = self.checked ? "SBA_PROGRESS_CHECKMARK" : "SBA_PROGRESS_UNCHECKED"
        let mark = Localization.localizedString(checkmarkKey)
        return String.localizedStringWithFormat("%@ %@", mark, title)
    }
    
    // MARK: NSSecureCoding
    
    static var supportsSecureCoding : Bool {
        return true
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.title, forKey: "title")
        aCoder.encode(self.checked, forKey: "checked")
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        guard let title = aDecoder.decodeObject(forKey: "title") as? String else { return nil }
        self.init(title: title, checked: aDecoder.decodeBool(forKey: "checked"))
    }
    
    // MARK: NSCopying
    
    func copy(with zone: NSZone?) -> Any {
        return SBACheckmarkItem(title: self.title, checked: self.checked)
    }
    
    // MARK: Equality
    
    override func isEqual(_ object: Any?) -> Bool {
        guard let cast = object as? SBACheckmarkItem else { return false }
        return (self.title == cast.title) && (self.checked == cast.checked)
    }
    
    override var hash: Int {
        return self.title.hash ^ self.checked.hashValue
    }
    
}
