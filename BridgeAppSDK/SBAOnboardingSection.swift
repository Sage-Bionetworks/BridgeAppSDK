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
    
    case login              = "login"
    case eligibility        = "eligibility"
    case consent            = "consent"
    case registration       = "registration"
    case passcode           = "passcode"
    case emailVerification  = "emailVerification"
    case permissions        = "permissions"
    case profile            = "profile"
    case completion         = "completion"
    
    func ordinal() -> Int {
        let order:[SBAOnboardingSectionBaseType] = SBAOnboardingSectionBaseType.all
        guard let ret = order.index(of: self) else {
            assertionFailure("\(self) ordinal value is unknown")
            return (order.index(of: .completion)! - 1)
        }
        return ret
    }
    
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

public protocol SBAOnboardingSection {
    var onboardingSectionType: SBAOnboardingSectionType? { get }
    func defaultOnboardingSurveyFactory() -> SBASurveyFactory
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
