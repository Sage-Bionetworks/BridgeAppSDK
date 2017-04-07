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
        return [.givenName, .familyName]   // by default
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
        guard options.contains(.fullName) || (options.contains(.givenName) && options.contains(.familyName)) else {
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
 Allow developers to create their own step view controllers that do not inherit from
 `ORKPageStepViewController`.
 */
public protocol SBAConsentReviewStepController: SBAOnboardingStepController {
    
    var requiresSignature: Bool { get }
    var consentAccepted: Bool? { get }
    var signatureImage: UIImage? { get }
    var signatureIdentifier: String { get }
    var signatureDate: Date { get }
    
    func handleConsentDeclined(with error: Error)
    func goNext()
}

extension SBAConsentReviewStepController {
    
    public func consentUser() {
        
        // Check that the user has consented or fail with an error
        guard (consentAccepted ?? false) && (!requiresSignature || (signatureImage != nil))
        else {
            let error = NSError(domain: "SBAConsentReviewStepDomain",
                                code: -1,
                                userInfo: [NSLocalizedDescriptionKey :
                                    Localization.localizedString("SBA_REGISTRATION_NOT_CONSENTED")])
            self.handleConsentDeclined(with: error)
            return
        }
        
        // set the consent to the shared user and update values from name/birthdate
        let consentSignature = SBAConsentSignature(identifier: self.signatureIdentifier)
        consentSignature.signatureDate = self.signatureDate
        consentSignature.signatureImage = self.signatureImage
        updateUserConsentSignature(consentSignature)
        
        // Update the user profile info
        updateUserProfileInfo()
        
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
}

open class SBAConsentReviewStepViewController: ORKPageStepViewController, SBAConsentReviewStepController {
    
    lazy public var sharedAppDelegate: SBAAppInfoDelegate = {
        return UIApplication.shared.delegate as! SBAAppInfoDelegate
    }()
    
    open var failedValidationMessage = Localization.localizedString("SBA_REGISTRATION_UNKNOWN_FAILED")
    open var failedRegistrationTitle = Localization.localizedString("SBA_REGISTRATION_FAILED_TITLE")

    public var consentStep: SBAConsentReviewStep? {
        return self.step as? SBAConsentReviewStep
    }
    
    public var requiresSignature: Bool {
        return (self.consentStep?.signatureStep != nil)
    }
    
    public var consentAccepted: Bool? {
        let consentResult = self.result?.results?.find({ $0 is ORKConsentSignatureResult }) as? ORKConsentSignatureResult
        return consentResult?.consented
    }
    
    public var signatureImage: UIImage? {
        let signatureResult = self.result?.results?.find({ $0 is ORKSignatureResult }) as? ORKSignatureResult
        return signatureResult?.signatureImage
    }
    
    public var signatureIdentifier: String {
        return (self.step?.identifier ?? SBAConsentReviewStep.signatureStepIdentifier)
    }
    
    public var signatureDate: Date {
        return self.result?.startDate ?? Date()
    }
    
    open func handleConsentDeclined(with error: Error) {
        self.delegate?.stepViewControllerDidFail(self, withError: error)
    }
    
    // Override the default method for goForward and either consent or set the consent signature
    // if not yet registered. Do not allow subclasses to override this method
    final public override func goForward() {
        consentUser()
    }
    
    open func goNext() {
        // Then call super to go forward
        super.goForward()
    }
}

