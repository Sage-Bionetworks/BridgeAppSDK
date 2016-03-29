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
    public static var localeBundle = {
        return NSBundle.init(forClass: Localization.classForCoder())
    }()
        
    static func localizedString(key: String) -> String {
        var str = NSLocalizedString(key, tableName: nil, bundle: localeBundle, value: key, comment: "")
        if (str == key) {
            if let defaultStr = listOfAllLocalizedStrings[key] {
                str = defaultStr
            }
        }
        return str
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
            trim(bundleInfo? ["CFBundleDisplayName"]) ??
            trim(bundleInfo? ["CFBundleName"]) ??
            trim(bundleInfo? ["CFBundleExecutable"]) ??
            trim(mainBundle.objectForInfoDictionaryKey("CFBundleDisplayName")) ??
            trim(mainBundle.objectForInfoDictionaryKey("CFBundleName")) ??
            trim(mainBundle.objectForInfoDictionaryKey("CFBundleExecutable")) ??
            trim(localizedBundleInfo? ["CFBundleDisplayName"]) ??
            trim(localizedBundleInfo? ["CFBundleName"]) ??
            trim(localizedBundleInfo? ["CFBundleExecutable"]) ??
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
    private static var listOfAllLocalizedStrings: [String : String] = {
        return [
            "SBA_CONSENT_TITLE" : NSLocalizedString("SBA_CONSENT_TITLE", tableName: nil, bundle: localeBundle, value: "Consent", comment: "Consent title"),
            "SBA_CONSENT_SIGNATURE_CONTENT" : NSLocalizedString("SBA_CONSENT_SIGNATURE_CONTENT", tableName: nil, bundle: localeBundle, value:"By agreeing you confirm that you read the consent and that you wish to take part in this research study.", comment:"Consent signature page content"),
            "SBA_CONSENT_PERSON_TITLE" : NSLocalizedString("SBA_CONSENT_PERSON_TITLE", tableName: nil, bundle: localeBundle, value: "Participant", comment: "Title for the person participating in the study"),
            "SBA_OTHER" : NSLocalizedString("SBA_OTHER", tableName: nil, bundle: localeBundle, value: "Other", comment: "Word to use in a muliple choice list that allows 'other' as a choice"),
            "SBA_RESET_PASSCODE_TITLE" : NSLocalizedString("SBA_RESET_PASSCODE_TITLE", tableName: nil, bundle: localeBundle, value: "Reset Passcode", comment: "Prompt to change passcode"),
            "SBA_RESET_PASSCODE_MESSAGE" : NSLocalizedString("SBA_RESET_PASSCODE_MESSAGE", tableName: nil, bundle: localeBundle, value: "In order to reset your passcode, you'll need to log out of the app completely and log back in using your email and password.", comment: "Description of what happens when passcode is reset."),
            "SBA_LOGOUT" : NSLocalizedString("SBA_LOGOUT", tableName: nil, bundle: localeBundle, value: "Log out", comment: "Log out button text."),
            "SBA_TESTER_ALERT_TITLE" : NSLocalizedString("SBA_TESTER_ALERT_TITLE", tableName: nil, bundle: localeBundle, value: "Are you a tester?", comment: "Question if the user is a quality assurance tester"),
            "SBA_TESTER_ALERT_MESSAGE_%1$@_%2$@" : NSLocalizedString("SBA_TESTER_ALERT_MESSAGE_%1$@_%2$@", tableName: nil, bundle: localeBundle, value: "Based on your email address, we have detected you are a tester for %1$@.  If this is correct, select %2$@ so we can store your data separately.", comment: "Message informing user if and what happens if they are a tester"),
        ]
    }()
    
}
