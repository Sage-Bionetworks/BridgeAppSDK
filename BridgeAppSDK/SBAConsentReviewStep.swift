//
//  SBAConsentReviewStep.swift
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

public class SBAConsentReviewStep: ORKConsentReviewStep, SBAProfileInfoForm {
    
    public var surveyItemType: SBASurveyItemType {
        return .consent(.review)
    }
    
    public override required init(identifier: String) {
        super.init(identifier: identifier)
    }
    
    public init(inputItem: SBAFormStepSurveyItem, inDocument consentDocument: ORKConsentDocument) {
        
        // Initialize super
        super.init(identifier: inputItem.identifier, signature: consentDocument.signatures?.first, inDocument: consentDocument)
        
        // Set default strings before commonInit
        self.reasonForConsent = Localization.localizedString("SBA_CONSENT_SIGNATURE_CONTENT")
        self.title = Localization.localizedString("CONSENT_NAME_TITLE")
        
        // Initialize common
        commonInit(inputItem)
        
        // Copy options from commonInit back into the signature for this document
        let requiresNameAndSignature = (self.formItemForIdentifier(SBAProfileInfoOption.name.rawValue) != nil)
        self.signature?.requiresName = requiresNameAndSignature
        self.signature?.requiresSignatureImage = requiresNameAndSignature
    }
    
    public func defaultOptions(inputItem: SBAFormStepSurveyItem?) -> [SBAProfileInfoOption] {
        if let dictionary = inputItem as? NSDictionary,
            let requiresSignature = dictionary["requiresSignature"] as? Bool
            where !requiresSignature {
            // special-case the json key for requiresSignature and return empty set if signature is not required
            // (json is more human-readable)
            return []
        }
        return [.name]   // by default
    }
    
    public override func validateParameters() {
        super.validateParameters()
        try! validateOptions(self.options)
    }
    
    public func validateOptions(options: [SBAProfileInfoOption]?) throws {
        guard let options = options else {
            throw SBAProfileInfoOptionsError.MissingRequiredOptions
        }
        
        guard options.count == 0 || options.contains(.name) || options.contains(.externalID) else {
            throw SBAProfileInfoOptionsError.MissingNameOrExternalID
        }
    }
    
    // MARK: NSCoding
    
    public required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}