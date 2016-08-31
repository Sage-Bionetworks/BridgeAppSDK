//
//  String+Utilities.swift
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

extension String {
    
    public func trim() -> String? {
        let result = self.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        guard result != "" else { return nil }
        return result
    }
    
    public func parseSuffix(prefix: String, separator: String = "") -> String? {
        guard self.hasPrefix(prefix) else { return nil }
        let prefixWithSeparator = prefix + separator
        guard let range = self.rangeOfString(prefixWithSeparator) else { return "" }
        return self.substringFromIndex(range.endIndex)
    }
    
    public func stringByRemovingNewlineCharacters() -> String {
        guard let result = (self as NSString).mutableCopy() as? NSMutableString else { return self }
        let set = NSCharacterSet.newlineCharacterSet()
        var range = result.rangeOfCharacterFromSet(set)
        while (range.location != NSNotFound) {
            result.replaceCharactersInRange(range, withString: " ")
            range = result.rangeOfCharacterFromSet(set)
        }
        range = result.rangeOfString("  ")
        while (range.location != NSNotFound) {
            result.replaceCharactersInRange(range, withString: " ")
            range = result.rangeOfString("  ")
        }
        return result.copy() as! String
    }

}