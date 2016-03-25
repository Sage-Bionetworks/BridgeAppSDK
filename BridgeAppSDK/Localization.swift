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

class Localization: NSObject {
    
    static var localeBundle = {
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
    
    // List of the strings used in this module. This func is never called but is included to allow running 
    // the localization macro
    static var listOfAllLocalizedStrings: [String : String] = {
        return [
            "SBA_CONSENT_TITLE" : NSLocalizedString("SBA_CONSENT_TITLE", tableName: nil, bundle: localeBundle, value: "Consent", comment: "Consent title"),
            "SBA_CONSENT_SIGNATURE_CONTENT" : NSLocalizedString("SBA_CONSENT_SIGNATURE_CONTENT", tableName: nil, bundle: localeBundle, value:"By agreeing you confirm that you read the consent and that you wish to take part in this research study.", comment:"Consent signature page content"),
            "SBA_CONSENT_PERSON_TITLE" : NSLocalizedString("SBA_CONSENT_PERSON_TITLE", tableName: nil, bundle: localeBundle, value: "Participant", comment: "Title for the person participating in the study"),
            "SBA_OTHER" : NSLocalizedString("SBA_OTHER", tableName: nil, bundle: localeBundle, value: "Other", comment: "Word to use in a muliple choice list that allows 'other' as a choice"),
            "SBA_RESET_PASSCODE_TITLE" : NSLocalizedString("SBA_RESET_PASSCODE_TITLE", tableName: nil, bundle: localeBundle, value: "Reset Passcode", comment: "Prompt to change passcode"),
            "SBA_RESET_PASSCODE_MESSAGE" : NSLocalizedString("SBA_RESET_PASSCODE_MESSAGE", tableName: nil, bundle: localeBundle, value: "In order to reset your passcode, you'll need to log out of the app completely and log back in using your email and password.", comment: "Description of what happens when passcode is reset."),
            "SBA_CANCEL" : NSLocalizedString("SBA_CANCEL", tableName: nil, bundle: localeBundle, value: "Cancel", comment: "Cancel button text."),
            "SBA_LOGOUT" : NSLocalizedString("SBA_LOGOUT", tableName: nil, bundle: localeBundle, value: "Log out", comment: "Log out button text."),
        ]
    }()

}
