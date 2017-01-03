//
//  SBAOnboardingSection.swift
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
import ResearchKit

/**
 Onboarding can be broken into different sections. Which section is required depends upon the 
 type of onboarding.
 */
public enum SBAOnboardingSectionBaseType: String {
    
    /**
     Section to include for login with a previously registered account.
     
     Included with `SBAOnboardingTaskType.login`
    */
    case login              = "login"
    
    /**
     Section to include for checking a potential participant's eligibility.
     Included with `SBAOnboardingTaskType.registration`
    */
    case eligibility        = "eligibility"
    
    /**
     Section to include for consenting a user. Either because the user is registering
     a new account or because there is a new consent document that the user must accept to
     continue participating in the study. Included with all onboarding types.
     */
    case consent            = "consent"
    
    /**
     Section to include to register a new account.
     Included with `SBAOnboardingTaskType.registration`
     */
    case registration       = "registration"
    
    /**
     Section to include if a passcode is to be set up for the app to lock the screen.
     Included with all types if there isn't already a passcode set up.
    */
    case passcode           = "passcode"
    
    /**
     Section to include during registration to allow the user to acknowledge that they have
     verified their email address.
     Included with `SBAOnboardingTaskType.registration`
    */
    case emailVerification  = "emailVerification"
    
    /**
     Section to include to set up any permissions that are included with either login or 
     registration.
    */
    case permissions        = "permissions"
    
    /**
     Additional profile information is included if this is a new user.
     Included with `SBAOnboardingTaskType.registration`
    */
    case profile            = "profile"
    
    /**
     An optional completion section that is included with either login or registration.
    */
    case completion         = "completion"
    
    /**
     The sort order for the sections.
    */
    func ordinal() -> Int {
        let order:[SBAOnboardingSectionBaseType] = SBAOnboardingSectionBaseType.all
        guard let ret = order.index(of: self) else {
            assertionFailure("\(self) ordinal value is unknown")
            return (order.index(of: .completion)! - 1)
        }
        return ret
    }
    
    /**
     List of all the sections include in the base types
    */
    public static var all: [SBAOnboardingSectionBaseType] {
        return [.login,
                .eligibility,
                .consent,
                .registration,
                .passcode,
                .emailVerification,
                .permissions,
                .profile,
                .completion]
    }
}

/**
 Enum for extending the base sections defined in this SDK.
 */
public enum SBAOnboardingSectionType {
    
    case base(SBAOnboardingSectionBaseType)
    case custom(String)
    
    public init(rawValue: String) {
        if let baseType = SBAOnboardingSectionBaseType(rawValue: rawValue) {
            self = .base(baseType)
        }
        else {
            self = .custom(rawValue)
        }
    }
    
    public func baseType() -> SBAOnboardingSectionBaseType? {
        if case .base(let baseType) = self {
            return baseType
        }
        return nil
    }
    
    public var identifier: String {
        switch (self) {
        case .base(let baseType):
            return baseType.rawValue
        case .custom(let customType):
            return customType
        }
    }
}

extension SBAOnboardingSectionType: Equatable {
}

public func ==(lhs: SBAOnboardingSectionType, rhs: SBAOnboardingSectionType) -> Bool {
    switch (lhs, rhs) {
    case (.base(let lhsValue), .base(let rhsValue)):
        return lhsValue == rhsValue;
    case (.custom(let lhsValue), .custom(let rhsValue)):
        return lhsValue == rhsValue;
    default:
        return false
    }
}

/**
 Protocol for defining an onboarding section.
 */
public protocol SBAOnboardingSection: NSSecureCoding {
    
    /**
     The onboarding section type for this section. Determines into which types of onboarding
     this section should be included.
    */
    var onboardingSectionType: SBAOnboardingSectionType? { get }
    
    /**
     The survey factory to be used by default with this section.
    */
    func defaultOnboardingSurveyFactory() -> SBASurveyFactory
    
    /**
     A dictionary representation for this class that can be used to encode it
    */
    func dictionaryRepresentation() -> [AnyHashable: Any]
}

extension NSDictionary: SBAOnboardingSection {
    
    public var onboardingSectionType: SBAOnboardingSectionType? {
        guard let onboardingType = self["onboardingType"] as? String else { return nil }
        return SBAOnboardingSectionType(rawValue: onboardingType);
    }
    
    public func defaultOnboardingSurveyFactory() -> SBASurveyFactory {
        let dictionary = self.objectWithResourceDictionary() as? NSDictionary ?? self
        if onboardingSectionType == .base(.consent) {
            return SBAConsentDocumentFactory(dictionary: dictionary)
        }
        else {
            return SBASurveyFactory(dictionary: dictionary)
        }
    }
    
    public func dictionaryRepresentation()  -> [AnyHashable: Any] {
        return self as! [AnyHashable: Any]
    }
}
