//
//  Localization.swift
//  BridgeAppSDK
//
//  Created by Shannon Young on 2/17/16.
//  Copyright © 2016 Sage Bionetworks. All rights reserved.
//

import UIKit

class Localization: NSObject {
    
    static var localeBundle = {
        return NSBundle.init(forClass: Localization.classForCoder())
    }()
    
    static func localizedString(key: String) -> String {
        return NSLocalizedString(key, tableName: nil, bundle: localeBundle, value: key, comment: "")
    }
    
    // List of the strings used in this module. This func is never called but is included to allow running 
    // the localization macro
    func listOfAllLocalizedStrings() -> [String] {
        return [
            NSLocalizedString("SBA_CONSENT_TITLE", tableName: nil, bundle: Localization.localeBundle, value: "Consent", comment: "Consent title"),
            NSLocalizedString("SBA_CONSENT_SIGNATURE_CONTENT", tableName: nil, bundle: Localization.localeBundle, value:"By agreeing you confirm that you read the consent and that you wish to take part in this research study.", comment:"Consent signature page content"),
            NSLocalizedString("SBA_CONSENT_PERSON_TITLE", tableName: nil, bundle: Localization.localeBundle, value: "Participant", comment: "Title for the person participating in the study"),
        ]
    }

}
