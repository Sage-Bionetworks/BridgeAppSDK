//
//  SBAConsentDocument.swift
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

public class SBAConsentDocumentFactory: SBASurveyFactory {
    
    lazy public var consentDocument: ORKConsentDocument = {
        
        // Setup the consent document
        let consentDocument = ORKConsentDocument()
        consentDocument.title = Localization.localizedString("SBA_CONSENT_TITLE")
        consentDocument.signaturePageTitle = Localization.localizedString("SBA_CONSENT_TITLE")
        consentDocument.signaturePageContent = Localization.localizedString("SBA_CONSENT_SIGNATURE_CONTENT")
        
        // Add the signature
        let signature = ORKConsentSignature(forPersonWithTitle: Localization.localizedString("SBA_CONSENT_PERSON_TITLE"), dateFormatString: nil, identifier: "participant")
        consentDocument.addSignature(signature)
        
        return consentDocument
    }()
    
    public convenience init?(jsonNamed: String) {
        guard let json = SBAResourceFinder().jsonNamed(jsonNamed) else { return nil }
        self.init(dictionary: json)
    }
    
    public convenience init(dictionary: NSDictionary) {
        self.init()
        
        // Load the sections
        if let sections = dictionary["sections"] as? [NSDictionary] {
            self.consentDocument.sections = sections.map({ $0.createConsentSection() })
        }
        
        // Load the document for the HTML content
        if let properties = dictionary["documentProperties"] as? NSDictionary,
            let documentHtmlContent = properties["htmlDocument"] as? String {
            self.consentDocument.htmlReviewContent = SBAResourceFinder().htmlNamed(documentHtmlContent)
        }
        
        // After loading the consentDocument, map the steps
        self.mapSteps(dictionary)
    }
    
    override public func createSurveyStepWithCustomType(inputItem: SBASurveyItem) -> ORKStep {
        guard let subtype = inputItem.surveyItemType.consentSubtype() else {
            return super.createSurveyStepWithCustomType(inputItem)
        }
        switch (subtype) {
            
        case .Visual:
            return ORKVisualConsentStep(identifier: inputItem.identifier,
                document: self.consentDocument)
            
        case .SharingOptions:
            let share = inputItem as! SBAConsentSharingOptions
            let step = ORKConsentSharingStep(identifier: inputItem.identifier,
                investigatorShortDescription: share.investigatorShortDescription,
                investigatorLongDescription: share.investigatorLongDescription,
                localizedLearnMoreHTMLContent: share.localizedLearnMoreHTMLContent)
            
            if let additionalText = inputItem.prompt, let text = step.text {
                step.text = "\(text)\n\n\(additionalText)"
            }
            if let textChoices = inputItem.items?.map({inputItem.createTextChoice($0)}) {
                step.answerFormat = ORKTextChoiceAnswerFormat(style: .SingleChoice, textChoices: textChoices)
            }
            
            return step;
            
        case .Review:
            return ORKConsentReviewStep(identifier: inputItem.identifier,
                signature: self.consentDocument.signatures?.first,
                inDocument: self.consentDocument)
        }
    }
}
