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

public struct HtmlRange {
    let open: Range<String.Index>
    let close: Range<String.Index>
}

extension String {
    
    public func trim() -> String? {
        let result = self.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        guard result != "" else { return nil }
        return result
    }
    
    public func parseSuffix(prefix: String, separator: String = "") -> String? {
        guard self.hasPrefix(prefix) else { return nil }
        let prefixWithSeparator = prefix + separator
        guard let range = self.range(of: prefixWithSeparator) else { return "" }
        return self.substring(from: range.upperBound)
    }
    
    public func removingNewlineCharacters() -> String {
        let set = CharacterSet.newlines
        // Since there can be two newline characters in a row, but we only want to replace that with a single 
        // space, use the custom reduce to strip out the new line characters and replace with a single space.
        let result = (self as NSString).components(separatedBy: set).reduce("") { (input, next) -> String in
            guard let nextTrimmed = next.trim() else { return input }
            guard input != "" else { return nextTrimmed }
            return input + " " + nextTrimmed
        }
        return result.replacingBreaklineHtmlTags()
    }
    
    public func replacingBreaklineHtmlTags() -> String {
        guard let trimmedString = trim() else { return "" }
        guard let range = trimmedString.htmlSearch(tag: "br", start: nil) else { return trimmedString }
        var result = trimmedString.substring(to: range.open.lowerBound)
        if range.open.upperBound < trimmedString.endIndex {
            result.append("\n")
            let remaining = trimmedString.substring(from: range.open.upperBound)
            result.append(remaining.replacingBreaklineHtmlTags())
        }
        return result
    }

    public func search(_ str: String, range: Range<String.Index>?) -> Range<String.Index>? {
        return self.range(of: str, options: .caseInsensitive, range: range, locale: nil)
    }
    
    public func htmlSearch(tag: String, start: String.Index?) -> HtmlRange? {
        guard (start == nil) || (start! < self.endIndex) else { return nil }
        
        // Find the next tag open
        let startRange: Range<String.Index>? = (start != nil) ? start!..<self.endIndex : nil
        guard let startOpenRange = search("<\(tag)", range: startRange),
            let endOpenRange = search(">", range: startOpenRange.upperBound..<self.endIndex)
        else {
                return nil
        }

        // If the end range is the same for the first open and the first end close
        // then they are the same.
        let openRange = startOpenRange.lowerBound..<endOpenRange.upperBound
        if let _ = search("/>", range: openRange) {
            return HtmlRange(open: openRange, close: openRange)
        }
        
        guard let startCloseRange = search("<\(tag)", range:openRange.upperBound..<self.endIndex),
            let endCloseRange = search("/>", range: startCloseRange.upperBound..<self.endIndex)
            else {
                return nil
        }
        
        return HtmlRange(open: openRange, close: startCloseRange.lowerBound..<endCloseRange.upperBound)
    }

}
