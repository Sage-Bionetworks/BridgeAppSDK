//
//  SBATextChoice.swift
//  BridgeAppSDK
//
//  Created by Shannon Young on 2/17/16.
//  Copyright © 2016 Sage Bionetworks. All rights reserved.
//

import ResearchKit

public protocol SBATextChoice  {
    var prompt: String? { get }
    var value: protocol<NSCoding, NSCopying, NSObjectProtocol> { get }
    var detailText: String? { get }
    var exclusive: Bool { get }
}

extension NSDictionary: SBATextChoice {
    
    public var value: protocol<NSCoding, NSCopying, NSObjectProtocol> {
        return (self["value"] as? protocol<NSCoding, NSCopying, NSObjectProtocol>) ?? self.prompt ?? self.identifier
    }
    
    public var detailText: String? {
        return self["detailText"] as? String
    }
    
    public var exclusive: Bool {
        let exclusive = self["exclusive"] as? Bool
        return exclusive ?? false
    }
}

extension ORKTextChoice: SBATextChoice {
    public var prompt: String? { return self.text }
}

extension NSString: SBATextChoice {
    public var prompt: String? { return self as String }
    public var value: protocol<NSCoding, NSCopying, NSObjectProtocol> { return self }
    public var detailText: String? { return nil }
    public var exclusive: Bool { return false }
}
