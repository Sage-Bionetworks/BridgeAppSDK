//
//  SBAConsentSharingOptions.swift
//  BridgeAppSDK
//
//  Created by Shannon Young on 2/18/16.
//  Copyright © 2016 Sage Bionetworks. All rights reserved.
//

import ResearchKit

public protocol SBAConsentSharingOptions: class {
    var investigatorShortDescription: String { get }
    var investigatorLongDescription: String { get }
    var localizedLearnMoreHTMLContent: String { get }
}

extension NSDictionary: SBAConsentSharingOptions {
    
    public var investigatorShortDescription: String {
        return self["investigatorShortDescription"] as? String ?? ""
    }
    
    public var investigatorLongDescription: String {
        return self["investigatorLongDescription"] as? String ?? ""
    }
    
    public var localizedLearnMoreHTMLContent: String {
        if let html = self["learnMoreHTMLContent"] as? String,
            let htmlContent = SBAResourceFinder().htmlNamed(html) {
            return htmlContent
        }
        return ""
    }
}

