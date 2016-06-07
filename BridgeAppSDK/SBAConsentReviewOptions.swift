//
//  SBAConsentReviewOptions.swift
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

import ResearchKit

public enum SBAConsentSignatureItemType : String {
    case Name         = "name"
    case Signature    = "signature"
    case Birthdate    = "birthdate"
}

extension SBAConsentSignatureItemType: Equatable {
}

public func ==(lhs: SBAConsentSignatureItemType, rhs: SBAConsentSignatureItemType) -> Bool {
    return lhs.rawValue == rhs.rawValue
}

public struct SBAConsentReviewOptions {
    public let includes: [SBAConsentSignatureItemType]
    
    public init(includes: [SBAConsentSignatureItemType]) {
        self.includes = includes
    }
    
    public init(items: [String]) {
        self.includes = items.mapAndFilter({ SBAConsentSignatureItemType(rawValue: $0) })
    }
    
    public init(inputItem: SBASurveyItem) {
        // start with the default includes
        var includes: [SBAConsentSignatureItemType] = [.Name, .Signature]

        if let input = inputItem as? SBAFormStepSurveyItem, let items = input.items {
            // Map the items to a consent signature type
            includes = items.mapAndFilter({ (item) -> SBAConsentSignatureItemType? in
                if let type = item as? SBAConsentSignatureItemType {
                    return type
                }
                else if let key = item as? String {
                    return SBAConsentSignatureItemType(rawValue: key)
                }
                else {
                    return nil
                }
            })
        }
        else if let input = inputItem as? NSDictionary {
            // Include check of "requires" keys for reverse-compatibility. syoung 06/02/2016
            if let requiresName = input["requiresName"] as? Bool where !requiresName {
                includes.removeFirst()
            }
            if let requiresSignature = input["requiresSignature"] as? Bool where !requiresSignature {
                includes.removeLast()
            }
        }
        self.includes = includes
    }
    
    
    public var requiresName: Bool {
        return includes.contains(.Name)
    }
    
    public var requiresSignature: Bool {
        return includes.contains(.Signature)
    }
    
    public var requiresBirthdate: Bool {
        return includes.contains(.Birthdate)
    }
}
