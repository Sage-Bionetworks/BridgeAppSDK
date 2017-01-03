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

/**
 The SBAConsentReviewStep is a class used to show consent review to the user.
 This includes the consent document in full form as a PDF, and can optionally include
 registration information or just include the person's name and/or birthdate.
 It can also be set up to include a signature. When using this version of the 
 consent review, the name is entered as a single field rather than as first name
 and last name.
 */
open class SBAConsentReviewStep: ORKPageStep, SBAProfileInfoForm {
    
    static let nameStepIdentifier = "name"
    static let signatureStepIdentifier = "signature"
    static let reviewStepIdentifier = "review"
    static let consentResultIdentifier = "consent"
    
    public var shouldConfirmPassword: Bool {
        return false
    }
    
    open var formItems: [ORKFormItem]? {
        get { return nameStep?.formItems }
        set (newValue) { nameStep?.formItems = newValue }
    }
    
    open override var title: String? {
        didSet {
            self.nameStep?.title = self.title
        }
    }
    
    open override var text: String? {
        didSet {
            self.nameStep?.text = self.text
        }
    }
    
    var nameStep: ORKFormStep? {
        guard let step = self.step(withIdentifier: SBAConsentReviewStep.nameStepIdentifier) as? ORKFormStep
            else { return nil }
        return step
    }
    
    var reviewStep: ORKConsentReviewStep? {
        guard let step = self.step(withIdentifier: SBAConsentReviewStep.reviewStepIdentifier) as? ORKConsentReviewStep
            else { return nil }
        return step
    }
    
    var signatureStep: ORKSignatureStep? {
        guard let step = self.step(withIdentifier: SBAConsentReviewStep.signatureStepIdentifier) as? ORKSignatureStep
            else { return nil }
        return step
    }
    
    public init(inputItem: SBAFormStepSurveyItem, inDocument consentDocument: ORKConsentDocument, factory: SBASurveyFactory? = nil) {
        
        var steps: [ORKStep] = []
        
        // Always add the review step
        let signature = consentDocument.signatures?.first?.copy() as? ORKConsentSignature
        signature?.requiresName = false
        signature?.requiresSignatureImage = false
        let reviewStep = ORKConsentReviewStep(identifier: SBAConsentReviewStep.reviewStepIdentifier, signature: signature, in: consentDocument)
        reviewStep.reasonForConsent = Localization.localizedString("SBA_CONSENT_SIGNATURE_CONTENT")
        steps.append(reviewStep)
        
        // Only add the name/signature if required
        if let reviewOptions = inputItem as? SBAConsentReviewOptions, reviewOptions.requiresSignature {
            
            let nameStep = ORKFormStep(identifier: SBAConsentReviewStep.nameStepIdentifier)
            nameStep.title = Localization.localizedString("CONSENT_NAME_TITLE")
            nameStep.isOptional = false
            steps.append(nameStep)

            let signatureStep = ORKSignatureStep(identifier: SBAConsentReviewStep.signatureStepIdentifier)
            signatureStep.isOptional = false
            steps.append(signatureStep)
        }
        
        // Initialize super using the built steps
        super.init(identifier: inputItem.identifier, steps: steps)
        
        // Initialize common if there is a name step to initialize
        if let _ = self.nameStep {
            commonInit(inputItem: inputItem, factory: factory)
        }
    }
    
    open func defaultOptions(_ inputItem: SBASurveyItem?) -> [SBAProfileInfoOption] {
        return [.name]   // by default
    }
    
    open override func validateParameters() {
        super.validateParameters()
        try! validate(options: self.options)
    }
    
    open func validate(options: [SBAProfileInfoOption]?) throws {
        guard let options = options else {
            return  // nil options is ok
        }
        
        // If the options is not nil, then should contain the name
        guard options.contains(.name) else {
            throw SBAProfileInfoOptionsError.missingName
        }
    }
    
    // MARK: Step navigation
    
    override open func stepAfterStep(withIdentifier identifier: String?, with result: ORKTaskResult) -> ORKStep? {
        // If this is a non-consented review step then do not continue to name/signature
        if identifier == SBAConsentReviewStep.reviewStepIdentifier,
            let stepResult = result.stepResult(forStepIdentifier: identifier!),
            let reviewResult = stepResult.results?.first as? ORKConsentSignatureResult , !reviewResult.consented {
            return nil
        }
        return super.stepAfterStep(withIdentifier: identifier, with: result)
    }
    
    // MARK: View controller
    
    override open func stepViewControllerClass() -> AnyClass {
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

/**
 The `SBAConsentReviewResult` is used to store information about a result
 that is sent to the Bridge server.
 */
open class SBAConsentReviewResult: ORKResult {
    
    open var consentSignature: SBAConsentSignature? {
        get {
            return self.userInfo?["consentSignature"] as? SBAConsentSignature
        }
        set(newValue) {
            var info = self.userInfo ?? [:]
            info["consentSignature"] = newValue
            self.userInfo = info
        }
    }
    
    open var isConsented: Bool {
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

open class SBAConsentReviewStepViewController: ORKPageStepViewController, SBASharedInfoController, SBAUserProfileController {
    
    lazy public var sharedAppDelegate: SBAAppInfoDelegate = {
        return UIApplication.shared.delegate as! SBAAppInfoDelegate
    }()
    
    open var failedValidationMessage = Localization.localizedString("SBA_REGISTRATION_UNKNOWN_FAILED")
    open var failedRegistrationTitle = Localization.localizedString("SBA_REGISTRATION_FAILED_TITLE")

    public var consentStep: SBAConsentReviewStep? {
        return self.step as? SBAConsentReviewStep
    }
    
    open override var result: ORKStepResult? {
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
                let option = SBAProfileInfoOption(rawValue: result.identifier.substring(from: namePrefix.endIndex)) {
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
    
    public var consentReviewResult: SBAConsentReviewResult? {
        return self.result?.results?.find({ $0 is SBAConsentReviewResult}) as? SBAConsentReviewResult
    }
    
    // Override the default method for goForward and either consent or set the consent signature
    // if not yet registered. Do not allow subclasses to override this method
    final public override func goForward() {
        
        // Check that the user has consented or fail with an error
        guard let consentResult = self.consentReviewResult, consentResult.isConsented,
            let consentSignature = consentResult.consentSignature else {
            let error = NSError(domain: "SBAConsentReviewStepDomain",
                                code: -1,
                                userInfo: [NSLocalizedDescriptionKey : Localization.localizedString("SBA_REGISTRATION_NOT_CONSENTED")])
            self.delegate?.stepViewControllerDidFail(self, withError: error)
            return
        }
        
        // set the consent to the shared user
        sharedUser.consentSignature = consentSignature
        if let name = consentSignature.signatureName {
            sharedUser.name = name
        }
        if let birthdate = consentSignature.signatureBirthdate {
            sharedUser.birthdate = birthdate
        }
        
        if sharedUser.isLoginVerified {
            // If the user has already verified login, then need to send reconsent info
            self.showLoadingView()
            sharedUser.sendUserConsented(consentSignature) { [weak self] error in
                if let error = error {
                    self?.handleFailedRegistration(error)
                }
                else {
                    self?.goNext()
                }
            }            
        }
        else {
            // Otherwise, the consent will be verified later (after registration and email verification)
            self.goNext()
        }
    }
    
    open func goNext() {
        // Then call super to go forward
        super.goForward()
    }
    
}

