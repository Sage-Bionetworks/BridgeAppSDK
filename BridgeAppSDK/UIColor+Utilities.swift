//
//  UIColor+Utilities.swift
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

import UIKit

open class SBAColorInfo : NSObject {
    
    static let defaultColorInfo = SBAColorInfo(name: "ColorInfo")
    
    fileprivate var plist: [String : Any]?
    
    init(name: String) {
        super.init()
        self.plist = SBAResourceFinder.shared.plist(forResource: name)
    }
    
    func color(for colorKey: String) -> UIColor? {
        guard let colorHex = plist?[colorKey] as? String else {
            return nil
        }
        return UIColor(hexString: colorHex)
    }
}


extension UIColor {
    
    static public func color(for key: String) -> UIColor? {
        return SBAColorInfo.defaultColorInfo.color(for: key)
    }
    
    static public func primaryTintColor() -> UIColor? {
        return SBAColorInfo.defaultColorInfo.color(for: "primaryTintColor")
    }
    
    static public func greenTintColor() -> UIColor? {
        // For certain cases, we want to use a green checkmark and will override the default color
        return SBAColorInfo.defaultColorInfo.color(for: "greenTintColor") ?? UIColor(hexString: "#44d24e")
    }
    
    static public func blueTintColor() -> UIColor? {
        // For certain cases, we want to use a blue tint and will override the default color
        return SBAColorInfo.defaultColorInfo.color(for: "blueTintColor") ?? UIColor(red:0.132, green:0.684, blue:0.959, alpha:1.000)
    }
    
    public convenience init?(hexString: String) {
        let r, g, b: CGFloat
        
        // Look for the start of the hex numbers, stripping out the # or 0x if present
        var start = hexString.startIndex
        let prefixes = ["#", "0x"]
        for prefix in prefixes {
            if let range = hexString.range(of: prefix) {
                if range.lowerBound == start {
                    start = range.upperBound
                    break
                }
                else {
                    return nil
                }
            }
        }
        let hexColor = hexString.substring(from: start)
        
        // If there aren't 6 characters in the hex color then drop through to return nil
        if hexColor.characters.count == 6 {
            let scanner = Scanner(string: hexColor)
            var hexNumber: UInt64 = 0
            
            // scan the string into a hex and drop through to nil if unsuccessful
            if scanner.scanHexInt64(&hexNumber) {
                r = CGFloat((hexNumber & 0xff0000) >> 16) / 255
                g = CGFloat((hexNumber & 0x00ff00) >> 8) / 255
                b = CGFloat((hexNumber & 0x0000ff) >> 0) / 255
                
                self.init(red: r, green: g, blue: b, alpha: 1.0)
                return
            }
        }
        
        return nil
    }
}
