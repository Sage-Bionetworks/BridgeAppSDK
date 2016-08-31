//
//  Localization.swift
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

public class Localization: NSObject {
    
    static let localeMainBundle = NSBundle.mainBundle()
    static let localeBundle = NSBundle(forClass: Localization.classForCoder())
    static let localeORKBundle = NSBundle(forClass: ORKStep.classForCoder())
    
    public class var allBundles: [NSBundle] {
        return [localeMainBundle, localeBundle, localeORKBundle]
    }
        
    public static func localizedString(key: String) -> String {
        // Look in these bundles for a localization for the given key
        for bundle in allBundles {
            let tableName = defaultTableNameForBundle(bundle)
            let bundleStr = NSLocalizedString(key, tableName: tableName, bundle: bundle, value: key, comment: "")
            if bundleStr != key {
                // If something is found here then return
                return bundleStr
            }
        }
        // If the localized string isn't found in the localization bundles then 
        // fall back to the list of strings included here.
        if let defaultStr = listOfAllLocalizedStrings[key] {
            return defaultStr
        }
        // Fallback to the key
        return key
    }
    
    public static func defaultTableNameForBundle(bundle: NSBundle) -> String? {
        if (bundle == localeORKBundle) { return "ResearchKit" }
        if (bundle == localeBundle) { return "BridgeAppSDK" }
        return nil
    }
    
    public static func localizedStringWithFormatKey(key: String, _ arguments: CVarArgType...) -> String {
        return withVaList(arguments) {
            NSString(format: localizedString(key), locale: NSLocale.currentLocale(), arguments: $0)
        } as String
    }
    
    public static func localizedJoin(textList: [String]) -> String {
        switch (textList.count) {
        case 0:
            return ""
        case 1:
            return textList[0]
        case 2:
            return String.localizedStringWithFormat(localizedString("SBA_TWO_ITEM_LIST_FORMAT_%1$@_%2$@"), textList[0], textList[1])
        default:
            let endText = String.localizedStringWithFormat(localizedString("SBA_THREE_ITEM_LIST_FORMAT_%1$@_%2$@_%3$@"),
                                 textList[textList.count - 3],
                                 textList[textList.count - 2],
                                 textList[textList.count - 1])
            let delimiter = localizedString("SBA_LIST_FORMAT_DELIMITER")
            let list = Array([textList[0..<(textList.count - 3)], [endText]].flatten())
            return list.joinWithSeparator(delimiter)
        }
    }
    
    
    // MARK: Localized App Name
    
    public static var localizedAppName : String = {
        let mainBundle = NSBundle.mainBundle()
        let bundleInfo = mainBundle.infoDictionary
        let localizedBundleInfo = mainBundle.localizedInfoDictionary
        
        func trim(obj: AnyObject?) -> String? {
            guard let str = obj as? String else { return nil }
            let result = str.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
            guard result != "" else { return nil }
            return result
        }
        
        let result =
                trim(localizedBundleInfo? ["CFBundleDisplayName"]) ??
                trim(mainBundle.objectForInfoDictionaryKey("CFBundleDisplayName")) ??
                trim(bundleInfo? ["CFBundleDisplayName"]) ??
                trim(localizedBundleInfo? ["CFBundleName"]) ??
                trim(mainBundle.objectForInfoDictionaryKey("CFBundleName")) ??
                trim(bundleInfo? ["CFBundleName"]) ??
                trim(localizedBundleInfo? ["CFBundleExecutable"]) ??
                trim(mainBundle.objectForInfoDictionaryKey("CFBundleExecutable")) ??
                trim(bundleInfo? ["CFBundleExecutable"]) ??
                "???"
        
        return result
    }()
    
    
    // MARK: Common button titles that should keep consistent with ResearchKit
    
    public static func buttonYes() -> String {
        return localizedString("BOOL_YES")
    }
    
    public static func buttonNo() -> String {
        return localizedString("BOOL_NO")
    }
    
    public static func buttonOK() -> String {
        return localizedString("BUTTON_OK")
    }
    
    public static func buttonCancel() -> String {
        return localizedString("BUTTON_CANCEL")
    }
    
    public static func buttonDone() -> String {
        return localizedString("BUTTON_DONE")
    }
    
    public static func buttonNext() -> String {
        return localizedString("BUTTON_NEXT")
    }
    
    public static func buttonGetStarted() -> String {
        return localizedString("BUTTON_GET_STARTED")
    }
    
    // MARK: List of the strings used in this module.
    public class var listOfAllLocalizedStrings: [String : String] {
        return [:]
    }
}
