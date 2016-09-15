//
//  SBAResourceFinder.swift
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

open class SBAResourceFinder: NSObject {
    
    static let sharedResourceFinder = SBAResourceFinder()
    
    func sharedResourceDelegate() -> SBABridgeAppSDKDelegate? {
        return UIApplication.shared.delegate as? SBABridgeAppSDKDelegate
    }
    
    func pathForResource(_ resourceNamed: String, ofType: String) -> String? {
        if let resourceDelegate = self.sharedResourceDelegate(),
            let path = resourceDelegate.path(forResource: resourceNamed, ofType: ofType) {
                return path
        }
        else if let path = Bundle.main.path(forResource: resourceNamed, ofType: ofType) {
            return path
        }
        else if let path = Bundle(for: self.classForCoder).path(forResource: resourceNamed, ofType: ofType) {
            return path
        }
        return nil
    }
    
    open func imageNamed(_ named: String) -> UIImage? {
        if let resourceDelegate = self.sharedResourceDelegate(),
            let image = UIImage(named: named, in: resourceDelegate.resourceBundle(), compatibleWith: nil) {
            return image
        }
        else if let image = UIImage(named: named) {
            return image
        }
        else if let image = UIImage(named: named, in: Bundle(for: self.classForCoder), compatibleWith: nil) {
            return image
        }
        return nil;
    }
    
    func dataNamed(_ resourceNamed: String, ofType: String) -> Data? {
        return dataNamed(resourceNamed, ofType: ofType, bundle: nil)
    }
    
    func dataNamed(_ resourceNamed: String, ofType: String, bundle: Bundle?) -> Data? {
        if let path = bundle?.path(forResource: resourceNamed, ofType: ofType) ??
            self.pathForResource(resourceNamed, ofType: ofType) {
            return (try? Data(contentsOf: URL(fileURLWithPath: path)))
        }
        return nil
    }
    
    open func htmlNamed(_ resourceNamed: String) -> String? {
        if let data = self.dataNamed(resourceNamed, ofType: "html"),
            let html = String(data: data, encoding: String.Encoding.utf8) {
            return importHTML(html)
        }
        return nil
    }
    
    func importHTML(_ input: String) -> String {
        
        // setup string
        var html = input
        func search(_ str: String, _ range: Range<String.Index>?) -> Range<String.Index>? {
            return html.range(of: str, options: .caseInsensitive, range: range, locale: nil)
        }
        
        // search for <import href="resourceName.html" /> and replace with contents of resource file
        var keepGoing = true
        while keepGoing {
            keepGoing = false
            if let startRange = search("<import", nil),
                let endRange = search("/>", startRange.upperBound..<html.endIndex),
                let hrefRange = search("href", startRange.upperBound..<endRange.upperBound),
                let fileStartRange = search("\"", hrefRange.upperBound..<endRange.upperBound),
                let fileEndRange = search(".html\"", fileStartRange.upperBound..<endRange.upperBound) {
                let resourceName = html.substring(with: fileStartRange.upperBound..<fileEndRange.lowerBound)
                if let importText = htmlNamed(resourceName) {
                    keepGoing = true
                    html.replaceSubrange(startRange.lowerBound..<endRange.upperBound, with: importText)
                }
            }
        }
        
        return html
    }
    
    func jsonNamed(_ resourceNamed: String) -> NSDictionary? {
        return jsonNamed(resourceNamed, bundle: nil)
    }
    
    func jsonNamed(_ resourceNamed: String, bundle: Bundle?) -> NSDictionary? {
        do {
            if let data = self.dataNamed(resourceNamed, ofType: "json", bundle: bundle) {
                let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers)
                return json as? NSDictionary
            }
        }
        catch let error as NSError {
            // Throw an assertion rather than throwing an exception (or rethrow)
            // so that production apps don't crash.
            assertionFailure("Failed to read json file: \(error)")
        }
        return nil
    }
    
    open func plistNamed(_ resourceNamed: String) -> NSDictionary? {
        if let path = self.pathForResource(resourceNamed, ofType: "plist"),
            let dictionary = NSDictionary(contentsOfFile: path) {
                return dictionary
        }
        return nil
    }
    
    open func urlNamed(_ resourceNamed: String, withExtension: String) -> URL? {
        if let resourceDelegate = self.sharedResourceDelegate(),
            let url = resourceDelegate.resourceBundle().url(forResource: resourceNamed, withExtension: withExtension)
            , (url as NSURL).checkResourceIsReachableAndReturnError(nil) {
                return url
        }
        else if let url = Bundle.main.url(forResource: resourceNamed, withExtension: withExtension)
            , (url as NSURL).checkResourceIsReachableAndReturnError(nil) {
            return url
        }
        else if let url = Bundle(for: self.classForCoder).url(forResource: resourceNamed, withExtension: withExtension)
            , (url as NSURL).checkResourceIsReachableAndReturnError(nil) {
                return url
        }
        return nil;
    }

}
