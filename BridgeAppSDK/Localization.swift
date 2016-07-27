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
            let bundleStr = NSLocalizedString(key, tableName: nil, bundle: bundle, value: key, comment: "")
            if bundleStr != key {
                // If something is found where the returned
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
            "SBA_TWO_ITEM_LIST_FORMAT_%1$@_%2$@" : NSLocalizedString("SBA_TWO_ITEM_LIST_FORMAT_%1$@_%2$@", tableName: nil, bundle: localeBundle, value:"%1$@ or %2$@", comment:"Format of a list with two items (For example, 'Levodopa or Rytary')"),
            "SBA_THREE_ITEM_LIST_FORMAT_%1$@_%2$@_%3$@" : NSLocalizedString("SBA_THREE_ITEM_LIST_FORMAT_%1$@_%2$@_%3$@", tableName: nil, bundle: localeBundle, value:"%1$@, %2$@, or %3$@", comment:"Format of a list with three items (For example, 'Levodopa, Simet, or Rytary')"),
            "SBA_LIST_FORMAT_DELIMITER" : NSLocalizedString("SBA_LIST_FORMAT_DELIMITER", tableName: nil, bundle: localeBundle, value:", ", comment:"Delimiter for a list of more than 3 items. Include whitespace as appropriate. (For example, 'Foo, Levodopa, Simet, or Rytary')"),
            
            // Time interval
            "SBA_LESS_THAN_%@_AGO" : NSLocalizedString("SBA_LESS_THAN_%@_AGO", tableName: nil, bundle: localeBundle, value:"Less than %@ ago", comment:"Less than %@ time interval in the past"),
            "SBA_MORE_THAN_%@_AGO" : NSLocalizedString("SBA_MORE_THAN_%@_AGO", tableName: nil, bundle: localeBundle, value:"More than %@ ago", comment:"More than %@ time interval in the past"),
            "SBA_RANGE_%@_AGO" : NSLocalizedString("SBA_RANGE_%@_AGO", tableName: nil, bundle: localeBundle, value:"%@ ago", comment:"Range time interval in the past (Ex. '0-30 minutes ago'"),
            
            // Local notifications
            "SBA_TIME_FOR_%@" : NSLocalizedString("SBA_TIME_FOR_%@", tableName: nil, bundle: localeBundle, value:"Time for %@", comment:"Alert body for local notification that it's time to perform a scheduled activity"),
            
            // Scheduling
            "SBA_NOW" : NSLocalizedString("SBA_NOW", tableName: nil, bundle: localeBundle, value:"Now", comment:"Time if now"),
            "SBA_EXPIRED" : NSLocalizedString("SBA_EXPIRED", tableName: nil, bundle: localeBundle, value:"Expired", comment:"Time if expired"),
            
            // Skip step or activity
            "SBA_SKIP_STEP" : NSLocalizedString("SBA_SKIP_STEP", tableName: nil, bundle: localeBundle, value:"Skip", comment:"Skip button text"),
            "SBA_SKIP_ACTIVITY" : NSLocalizedString("SBA_SKIP_ACTIVITY", tableName: nil, bundle: localeBundle, value:"Skip this activity", comment:"Skip button text for skipping an activity."),
            "SBA_SKIP_ACTIVITY_INSTRUCTION" : NSLocalizedString("SBA_SKIP_ACTIVITY_INSTRUCTION", tableName: nil, bundle: localeBundle, value:"If you need to skip this activity, then tap the \"Skip this activity\" link below. Otherwise, tap Next to begin.", comment:"Skip activity explanation text for skipping an activity."),
            
            // Activity section titles
            "SBA_ACTIVITY_YESTERDAY" : NSLocalizedString("SBA_ACTIVITY_YESTERDAY", tableName: nil, bundle: localeBundle, value:"Yesterday", comment:"Title of activity section for expired tasks from the previous day"),
            "SBA_ACTIVITY_TODAY" : NSLocalizedString("SBA_ACTIVITY_TODAY", tableName: nil, bundle: localeBundle, value:"Today", comment:"Title of activity section for today's tasks"),
            "SBA_ACTIVITY_KEEP_GOING" : NSLocalizedString("SBA_ACTIVITY_KEEP_GOING", tableName: nil, bundle: localeBundle, value:"Keep Going", comment:"Title of activity section for unscheduled tasks"),
            "SBA_ACTIVITY_TOMORROW" : NSLocalizedString("SBA_ACTIVITY_TOMORROW", tableName: nil, bundle: localeBundle, value:"Tomorrow", comment:"Title of activity section for tomorrow's tasks"),
            "SBA_ACTIVITY_SCHEDULE_MESSAGE" : NSLocalizedString("SBA_ACTIVITY_SCHEDULE_MESSAGE", tableName: nil, bundle: localeBundle, value:"This activity is not available until %@", comment:"Message for when a participant tries to do an activity ahead of schedule"),
            
            // Progress step
            "SBA_PROGRESS_STEP_TITLE" : NSLocalizedString("SBA_PROGRESS_STEP_TITLE", tableName: nil, bundle: localeBundle, value:"Progress so far:", comment:"Title of a progress step."),
            "SBA_PROGRESS_CHECKMARK" : NSLocalizedString("SBA_PROGRESS_CHECKMARK", tableName: nil, bundle: localeBundle, value:"\u{2705}", comment:"Character to use for a step progress check mark"),
            "SBA_PROGRESS_UNCHECKED" : NSLocalizedString("SBA_PROGRESS_UNCHECKED", tableName: nil, bundle: localeBundle, value:"\u{2003}\u{2002}", comment:"Character to use for a step progress for unchecked"),
            
            // Registration
            "SBA_REGISTRATION_INVALID_CODE" : NSLocalizedString("SBA_REGISTRATION_INVALID_CODE", tableName: nil, bundle: localeBundle, value:"Please enter a valid Participant ID.", comment:"Message for invalid registration code"),
            "SBA_REGISTRATION_MATCH_FAILED" : NSLocalizedString("SBA_REGISTRATION_MATCH_FAILED", tableName: nil, bundle: localeBundle, value:"The Participant ID you entered does not match.", comment:"Message for registration codes that do not match"),
            "SBA_REGISTRATION_FAILED_TITLE" : NSLocalizedString("SBA_REGISTRATION_FAILED_TITLE", tableName: nil, bundle: localeBundle, value:"Registration Failed", comment:"Title for error when registration fails"),
            "SBA_REGISTRATION_EXTERNALID_TITLE" : NSLocalizedString("SBA_REGISTRATION_EXTERNALID_TITLE", tableName: nil, bundle: localeBundle, value:"Participant ID", comment:"Title for the external ID during registration."),
            "SBA_REGISTRATION_EXTERNALID_PLACEHOLDER" : NSLocalizedString("SBA_REGISTRATION_EXTERNALID_PLACEHOLDER", tableName: nil, bundle: localeBundle, value:"Enter Participant ID", comment:"Placeholder for the external ID during registration."),
            "SBA_REGISTRATION_FULLNAME_TITLE" : NSLocalizedString("SBA_REGISTRATION_FULLNAME_TITLE", tableName: nil, bundle: localeBundle, value:"Name", comment:"Title for the full name field during registration."),
            "SBA_REGISTRATION_FULLNAME_PLACEHOLDER" : NSLocalizedString("SBA_REGISTRATION_FULLNAME_PLACEHOLDER", tableName: nil, bundle: localeBundle, value:"Enter full name", comment:"Placeholder for the full name during registration."),
            "SBA_CONFIRM_EXTERNALID_TITLE" : NSLocalizedString("SBA_CONFIRM_EXTERNALID_TITLE", tableName: nil, bundle: localeBundle, value:"Confirm", comment:"Title for the confirmation for registering via external ID"),
            "SBA_CONFIRM_EXTERNALID_TEXT" : NSLocalizedString("SBA_CONFIRM_EXTERNALID_TEXT", tableName: nil, bundle: localeBundle, value:"Confirm Participant Study ID", comment:"Placeholder for the confirmation for registering via external ID"),
            
            // State
            "SBA_COMPLETED" : NSLocalizedString("SBA_COMPLETED", tableName: nil, bundle: localeBundle, value:"Completed", comment:"Short phrase to use to indicate that an activity is completed."),
        ]
    }()
    
}
