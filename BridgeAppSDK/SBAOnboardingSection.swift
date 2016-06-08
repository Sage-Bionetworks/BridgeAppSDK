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

public enum SBAOnboardingSectionBaseType: String {
    case Introduction       = "introduction"
    case Login              = "login"
    case Eligibility        = "eligibility"
    case Consent            = "consent"
    case Registration       = "registration"
    case Passcode           = "passcode"
    case EmailVerification  = "emailVerification"
    case Permissions        = "permissions"
    case Profile            = "profile"
    case Completion         = "completion"
}

public enum SBAOnboardingSectionType {
    
    case Base(SBAOnboardingSectionBaseType)
    case Custom(String)
    
    public init(rawValue: String) {
        if let baseType = SBAOnboardingSectionBaseType(rawValue: rawValue) {
            self = .Base(baseType)
        }
        else {
            self = .Custom(rawValue)
        }
    }
}

extension SBAOnboardingSectionType: Equatable {
}

public func ==(lhs: SBAOnboardingSectionType, rhs: SBAOnboardingSectionType) -> Bool {
    switch (lhs, rhs) {
    case (.Base(let lhsValue), .Base(let rhsValue)):
        return lhsValue == rhsValue;
    case (.Custom(let lhsValue), .Custom(let rhsValue)):
        return lhsValue == rhsValue;
    default:
        return false
    }
}

public protocol SBAOnboardingSection {
    var onboardingSectionType: SBAOnboardingSectionType? { get }
    func defaultOnboardingSurveyFactory() -> SBASurveyFactory
}

extension NSDictionary: SBAOnboardingSection {
    
    public var onboardingSectionType: SBAOnboardingSectionType? {
        guard let onboardingType = self["onboardingType"] as? String else { return nil }
        return SBAOnboardingSectionType(rawValue: onboardingType);
    }
    
    public func defaultOnboardingSurveyFactory() -> SBASurveyFactory {
        let dictionary = self.objectWithResourceDictionary() as? NSDictionary ?? self
        if onboardingSectionType == .Base(.Consent) {
            return SBAConsentDocumentFactory(dictionary: dictionary)
        }
        else {
            return SBASurveyFactory(dictionary: dictionary)
        }
    }
}