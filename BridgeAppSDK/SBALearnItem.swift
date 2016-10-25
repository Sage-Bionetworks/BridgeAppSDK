//
//  SBALearnItem.swift
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

import Foundation

public protocol SBALearnItem: class {
    
    /**
     Check validity as a SBALearnItem
     */
    func isValidLearnItem() -> Bool
    
    /**
     Title to show in the Learn tab table view cell
     */
    var learnTitle: String! { get }
    
    /**
     Content file (html) to load for the Detail view for this item
     */
    var learnURL: URL! { get }
    
    /**
     The image to use as the item's icon in the Learn tab table view cell
     */
    var learnIconImage: UIImage? { get }
}

extension NSDictionary : SBALearnItem {
    
    public func isValidLearnItem() -> Bool {
        guard let _ = self["title"] as? String, let _ = _learnURL
        else {
            assertionFailure("\(self) is missing required info")
            return false
        }
        return true
    }
    
    public var learnTitle : String! {
        return self["title"] as! String
    }
    
    public var learnURL: URL! {
        return _learnURL!
    }
    fileprivate var _learnURL : URL? {
        guard let urlString = self["details"] as? String else { return nil }
        if urlString.hasPrefix("http") || urlString.hasPrefix("file") {
            return URL(string: urlString)
        }
        else {
            return SBAResourceFinder.shared.url(forResource: urlString, withExtension:"html")
        }
    }
    
    public var learnIconImage : UIImage? {
        guard let imageName = self["iconImage"] as? String else { return nil }
        return SBAResourceFinder.shared.image(forResource: imageName)?.withRenderingMode(.alwaysTemplate)
    }
}
