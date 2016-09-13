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

public class SBAConsentReviewStep: ORKPageStep, SBAProfileInfoForm {
    
    static let nameStepIdentifier = "name"
    static let signatureStepIdentifier = "signature"
    static let reviewStepIdentifier = "review"
    static let consentResultIdentifier = "consent"
    
    public var surveyItemType: SBASurveyItemType {
        return .consent(.review)
    }
    
    public var formItems: [ORKFormItem]? {
        get { return nameStep?.formItems }
        set (newValue) { nameStep?.formItems = newValue }
    }
    
    public override var title: String? {
        didSet {
            self.nameStep?.title = self.title
        }
    }
    
    public override var text: String? {
        didSet {
            self.nameStep?.text = self.text
        }
    }
    
    var nameStep: ORKFormStep? {
        guard let step = self.stepWithIdentifier(SBAConsentReviewStep.nameStepIdentifier) as? ORKFormStep
            else { return nil }
        return step
    }
    
    var reviewStep: ORKConsentReviewStep? {
        guard let step = self.stepWithIdentifier(SBAConsentReviewStep.reviewStepIdentifier) as? ORKConsentReviewStep
            else { return nil }
        return step
    }
    
    var signatureStep: ORKSignatureStep? {
        guard let step = self.stepWithIdentifier(SBAConsentReviewStep.signatureStepIdentifier) as? ORKSignatureStep
            else { return nil }
        return step
    }
    
    public init(inputItem: SBAFormStepSurveyItem, inDocument consentDocument: ORKConsentDocument) {
        
        var steps: [ORKStep] = []
        
        // Always add the review step
        let signature = consentDocument.signatures?.first?.copy() as? ORKConsentSignature
        signature?.requiresName = false
        signature?.requiresSignatureImage = false
        let reviewStep = ORKConsentReviewStep(identifier: SBAConsentReviewStep.reviewStepIdentifier, signature: signature, inDocument: consentDocument)
        reviewStep.reasonForConsent = Localization.localizedString("SBA_CONSENT_SIGNATURE_CONTENT")
        steps.append(reviewStep)
        
        // Only add the name/signature if required
        if let reviewOptions = inputItem as? SBAConsentReviewOptions where reviewOptions.requiresSignature {
            
            let nameStep = ORKFormStep(identifier: SBAConsentReviewStep.nameStepIdentifier)
            nameStep.title = Localization.localizedString("CONSENT_NAME_TITLE")
            nameStep.optional = false
            steps.append(nameStep)

            let signatureStep = ORKSignatureStep(identifier: SBAConsentReviewStep.signatureStepIdentifier)
            signatureStep.optional = false
            steps.append(signatureStep)
        }
        
        // Initialize super using the built steps
        super.init(identifier: inputItem.identifier, steps: steps)
        
        // Initialize common if there is a name step to initialize
        if let _ = self.nameStep {
            commonInit(inputItem)
        }
    }
    
    public func defaultOptions(inputItem: SBASurveyItem?) -> [SBAProfileInfoOption] {
        return [.name]   // by default
    }
    
    public override func validateParameters() {
        super.validateParameters()
        try! validate(options: self.options)
    }
    
    public func validate(options options: [SBAProfileInfoOption]?) throws {
        guard let options = options else {
            return  // nil options is ok
        }
        
        // If the options is not nil, then should contain the name
        guard options.contains(.name) else {
            throw SBAProfileInfoOptionsError.MissingName
        }
    }
    
    // MARK: Step navigation
    
    override public func stepAfterStepWithIdentifier(identifier: String?, withResult result: ORKTaskResult) -> ORKStep? {
        // If this is a non-consented review step then do not continue to name/signature
        if identifier == SBAConsentReviewStep.reviewStepIdentifier,
            let stepResult = result.stepResultForStepIdentifier(identifier!),
            let reviewResult = stepResult.results?.first as? ORKConsentSignatureResult where !reviewResult.consented {
            return nil
        }
        return super.stepAfterStepWithIdentifier(identifier, withResult: result)
    }
    
    // MARK: View controller
    
    override public func stepViewControllerClass() -> AnyClass {
        return SBAConsentReviewStepViewController.classForCoder()
    }
    
    // MARK: Required initializers
    
    public required init(identifier: String) {
        super.init(identifier: identifier, steps: nil)
    }
    
    public required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

public class SBAConsentReviewResult: ORKResult {
    
    public var consentSignature: SBAConsentSignature? {
        get {
            return self.userInfo?["consentSignature"] as? SBAConsentSignature
        }
        set(newValue) {
            var info = self.userInfo ?? [:]
            info["consentSignature"] = newValue
            self.userInfo = info
        }
    }
    
    public var isConsented: Bool {
        get {
            return self.userInfo?["isConsented"] as? Bool ?? false
        }
        set(newValue) {
            var info = self.userInfo ?? [:]
            info["isConsented"] = newValue
            self.userInfo = info
        }
    }
}

class SBAConsentReviewStepViewController: ORKPageStepViewController, SBASharedInfoController {
    
    lazy var sharedAppDelegate: SBAAppInfoDelegate = {
        return UIApplication.sharedApplication().delegate as! SBAAppInfoDelegate
    }()

    var consentStep: SBAConsentReviewStep? {
        return self.step as? SBAConsentReviewStep
    }
    
    override var result: ORKStepResult? {
        guard let stepResult = super.result else { return nil }
        guard let stepResults = stepResult.results else { return stepResult }
        
        // Create the consent result and signature
        let consentResult = SBAConsentReviewResult(identifier: step!.identifier)
        consentResult.startDate = stepResult.startDate
        consentResult.endDate = stepResult.endDate
        let signature = SBAConsentSignature(identifier: self.step?.identifier ?? SBAConsentReviewStep.signatureStepIdentifier)
        var orkSignature: ORKConsentSignature?
        let requiresSignature = (consentStep?.signatureStep != nil)
        
        // Look for all required steps to be filled
        var found = false
        let namePrefix = SBAConsentReviewStep.nameStepIdentifier + "."
        for result in stepResults {
            if let reviewResult = result as? ORKConsentSignatureResult {
                // Not found yet if signature required and the user has consented (consent review displayed first)
                found = !requiresSignature || !reviewResult.consented
                consentResult.isConsented = reviewResult.consented
                orkSignature = reviewResult.signature
            }
            else if result.identifier.hasPrefix(namePrefix),
                let option = SBAProfileInfoOption(rawValue: result.identifier.substringFromIndex(namePrefix.endIndex)) {
                switch option {
                    
                case .name:
                    if let textResult = result as? ORKTextQuestionResult {
                        signature.signatureName = textResult.textAnswer
                        orkSignature?.familyName = signature.signatureName
                        orkSignature?.givenName = ""
                    }
                    
                case .birthdate:
                    if let dateResult = result as? ORKDateQuestionResult {
                        signature.signatureBirthdate = dateResult.dateAnswer
                    }
                    
                default:
                    break; // ignored
                }
            }
            else if let signatureResult = result as? ORKSignatureResult {
                found = true
                signature.signatureImage = signatureResult.signatureImage
                signature.signatureDate = signatureResult.endDate
                orkSignature?.signatureImage = signatureResult.signatureImage
            }
        }
        
        // If everything is finished then add the consent result and signature
        if (found) {
            consentResult.consentSignature = signature
            stepResult.addResult(consentResult)
        }
        
        return stepResult
    }
    
    var consentReviewResult: SBAConsentReviewResult? {
        return self.result?.results?.findObject({ $0 is SBAConsentReviewResult}) as? SBAConsentReviewResult
    }
    
    // Override the default method for goForward and attempt user registration. Do not allow subclasses
    // to override this method
    final override func goForward() {
        
        // Check that the user has consented or fail with an error
        guard let consentResult = self.consentReviewResult where consentResult.isConsented else {
            let error = NSError(domain: "SBAConsentReviewStepDomain",
                                code: -1,
                                userInfo: [NSLocalizedDescriptionKey : Localization.localizedString("SBA_REGISTRATION_NOT_CONSENTED")])
            self.delegate?.stepViewControllerDidFail(self, withError: error)
            return
        }
        
        // set the consent to the shared user
        sharedUser.consentSignature = consentResult.consentSignature
        
        // finally call through to super to continue once the consent signature has been stored
        super.goForward()
    }
}

