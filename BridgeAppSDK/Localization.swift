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
    
    /**
     * Locale bundle is defined as a variable rather than a singleton so that it can be 
     * changed to a different bundle from the default localized bundle.
     */
    static var localizationBundleForClass = {
        return NSBundle.init(forClass: Localization.classForCoder())
    }()
    
    public class var localeBundle: NSBundle {
        return localizationBundleForClass
    }
        
    public static func localizedString(key: String) -> String {
        var str = NSLocalizedString(key, tableName: nil, bundle: localeBundle, value: key, comment: "")
        if (str == key) {
            if let defaultStr = listOfAllLocalizedStrings[key] {
                str = defaultStr
            }
        }
        return str
    }
    
    static func localizedJoin(textList: [String]) -> String {
        switch (textList.count) {
        case 0:
            return ""
        case 1:
            return textList[0]
        case 2:
            return String(format: localizedString("SBA_TWO_ITEM_LIST_FORMAT"), textList[0], textList[1])
        default:
            let endText = String(format: localizedString("SBA_THREE_ITEM_LIST_FORMAT"),
                                 textList[textList.count - 3],
                                 textList[textList.count - 2],
                                 textList[textList.count - 1])
            let delimiter = localizedString("SBA_LIST_FORMAT_DELIMITER")
            let list = textList[0..<(textList.count - 3)] + [endText]
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
        return SBALocalizationMacroWrapper.localizedORKString("BOOL_YES")
    }
    
    public static func buttonNo() -> String {
        return SBALocalizationMacroWrapper.localizedORKString("BOOL_NO")
    }
    
    public static func buttonOK() -> String {
        return SBALocalizationMacroWrapper.localizedORKString("BUTTON_OK")
    }
    
    public static func buttonCancel() -> String {
        return SBALocalizationMacroWrapper.localizedORKString("BUTTON_CANCEL")
    }
    
    public static func buttonDone() -> String {
        return SBALocalizationMacroWrapper.localizedORKString("BUTTON_DONE")
    }
    
    public static func buttonNext() -> String {
        return SBALocalizationMacroWrapper.localizedORKString("BUTTON_NEXT")
    }
    
    public static func buttonGetStarted() -> String {
        return SBALocalizationMacroWrapper.localizedORKString("BUTTON_GET_STARTED")
    }
    
    // MARK: List of the strings used in this module.
    public class var listOfAllLocalizedStrings: [String : String] {
        return listOfMyLocalizedStrings
    }
    
    private static var listOfMyLocalizedStrings: [String : String] = {
        return [
            
            // Consent
            "SBA_CONSENT_TITLE" : NSLocalizedString("SBA_CONSENT_TITLE", tableName: nil, bundle: localeBundle, value: "Consent", comment: "Consent title"),
            "SBA_CONSENT_SIGNATURE_CONTENT" : NSLocalizedString("SBA_CONSENT_SIGNATURE_CONTENT", tableName: nil, bundle: localeBundle, value:"By agreeing you confirm that you read the consent and that you wish to take part in this research study.", comment:"Consent signature page content"),
            "SBA_CONSENT_PERSON_TITLE" : NSLocalizedString("SBA_CONSENT_PERSON_TITLE", tableName: nil, bundle: localeBundle, value: "Participant", comment: "Title for the person participating in the study"),
            
            // text choice questions
            "SBA_OTHER" : NSLocalizedString("SBA_OTHER", tableName: nil, bundle: localeBundle, value: "Other", comment: "Word to use in a muliple choice list that allows 'other' as a choice"),
            "SBA_NONE_OF_THE_ABOVE" : NSLocalizedString("SBA_NONE_OF_THE_ABOVE", tableName: nil, bundle: localeBundle, value: "None of the above", comment: "Selection choice for none of the above"),
            "SBA_SKIP_CHOICE" : NSLocalizedString("SBA_SKIP_CHOICE", tableName: nil, bundle: localeBundle, value: "Prefer not to answer", comment: "Text for selection when prefer not to answer (skip)"),
            "SBA_NOT_SURE_CHOICE" : NSLocalizedString("SBA_NOT_SURE_CHOICE", tableName: nil, bundle: localeBundle, value: "Not sure", comment: "Text for selection when not sure of the answer"),
            
            // Passcode Reset
            "SBA_RESET_PASSCODE_TITLE" : NSLocalizedString("SBA_RESET_PASSCODE_TITLE", tableName: nil, bundle: localeBundle, value: "Reset Passcode", comment: "Prompt to change passcode"),
            "SBA_RESET_PASSCODE_MESSAGE" : NSLocalizedString("SBA_RESET_PASSCODE_MESSAGE", tableName: nil, bundle: localeBundle, value: "In order to reset your passcode, you'll need to log out of the app completely and log back in using your email and password.", comment: "Description of what happens when passcode is reset."),
            
            // Logout
            "SBA_LOGOUT" : NSLocalizedString("SBA_LOGOUT", tableName: nil, bundle: localeBundle, value: "Log out", comment: "Log out button text."),
            
            // Tester
            "SBA_TESTER_ALERT_TITLE" : NSLocalizedString("SBA_TESTER_ALERT_TITLE", tableName: nil, bundle: localeBundle, value: "Are you a tester?", comment: "Question if the user is a quality assurance tester"),
            "SBA_TESTER_ALERT_MESSAGE_%1$@_%2$@" : NSLocalizedString("SBA_TESTER_ALERT_MESSAGE_%1$@_%2$@", tableName: nil, bundle: localeBundle, value: "Based on your email address, we have detected you are a tester for %1$@.  If this is correct, select %2$@ so we can store your data separately.", comment: "Message informing user if and what happens if they are a tester"),
            
            // Joining items
            "SBA_TWO_ITEM_LIST_FORMAT" : NSLocalizedString("SBA_TWO_ITEM_LIST_FORMAT", tableName: nil, bundle: localeBundle, value:"%@ or %@", comment:"Format of a list with two items (For example, 'Levodopa or Rytary')"),
            "SBA_THREE_ITEM_LIST_FORMAT" : NSLocalizedString("SBA_THREE_ITEM_LIST_FORMAT", tableName: nil, bundle: localeBundle, value:"%@, %@, or %@", comment:"Format of a list with three items (For example, 'Levodopa, Simet, or Rytary')"),
            "SBA_LIST_FORMAT_DELIMITER" : NSLocalizedString("SBA_LIST_FORMAT_DELIMITER", tableName: nil, bundle: localeBundle, value:", ", comment:"Delimiter for a list of more than 3 items. (For example, 'Foo, Levodopa, Simet, or Rytary')"),
            
            // Time interval
            "SBA_LESS_THAN_%@_AGO" : NSLocalizedString("SBA_LESS_THAN_%@_AGO", tableName: nil, bundle: localeBundle, value:"Less than %@ ago", comment:"Less than %@ time interval in the past"),
            "SBA_MORE_THAN_%@_AGO" : NSLocalizedString("SBA_MORE_THAN_%@_AGO", tableName: nil, bundle: localeBundle, value:"More than %@ ago", comment:"More than %@ time interval in the past"),
            "SBA_RANGE_%@_AGO" : NSLocalizedString("SBA_RANGE_%@_AGO", tableName: nil, bundle: localeBundle, value:"%@ ago", comment:"Range time interval in the past (Ex. '0-30 minutes ago'"),
            
            // Scheduling
            "SBA_NOW" : NSLocalizedString("SBA_NOW", tableName: nil, bundle: localeBundle, value:"Now", comment:"Time if now"),
            "SBA_EXPIRED" : NSLocalizedString("SBA_EXPIRED", tableName: nil, bundle: localeBundle, value:"Expired", comment:"Time if expired"),

        ]
    }()
    
}
