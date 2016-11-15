//
//  SBARegistrationStep.swift
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

open class SBARegistrationStep: ORKFormStep, SBAProfileInfoForm {
    
    public static let confirmationIdentifier = "confirmation"
    
    static let defaultPasswordMinLength = 4
    static let defaultPasswordMaxLength = 16
    
    open var surveyItemType: SBASurveyItemType {
        return .account(.registration)
    }
    
    open func defaultOptions(_ inputItem: SBASurveyItem?) -> [SBAProfileInfoOption] {
        return [.name, .email, .password]
    }
    
    public override required init(identifier: String) {
        super.init(identifier: identifier)
        commonInit(inputItem:nil, healthStore: nil)
    }
    
    public init(inputItem: SBASurveyItem, healthStore:HKHealthStore? = nil) {
        super.init(identifier: inputItem.identifier)
        commonInit(inputItem:inputItem, healthStore: healthStore)
    }
    
    open override func validateParameters() {
        super.validateParameters()
        try! validate(options: self.options)
    }
    
    open func validate(options: [SBAProfileInfoOption]?) throws {
        guard let options = options else {
            throw SBAProfileInfoOptionsError.missingRequiredOptions
        }
        
        guard options.contains(.email) && options.contains(.password) else {
            throw SBAProfileInfoOptionsError.missingEmail
        }
    }
    
    open override var isOptional: Bool {
        get { return false }
        set {}
    }
    
    open var passwordAnswerFormat: ORKTextAnswerFormat? {
        return self.formItemForIdentifier(SBAProfileInfoOption.password.rawValue)?.answerFormat as? ORKTextAnswerFormat
    }
    
    open override func stepViewControllerClass() -> AnyClass {
        return SBARegistrationStepViewController.classForCoder()
    }
    
    // MARK: NSCoding
    
    public required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

open class SBARegistrationStepViewController: ORKFormStepViewController, SBAUserProfileController {
    
    /**
     If there are data groups that were set in a previous step or via a custom onboarding manager,
     set them on the view controller using this property.
     */
    open var dataGroups: [String]?
    

    // MARK: SBASharedInfoController
    
    lazy public var sharedAppDelegate: SBAAppInfoDelegate = {
        return UIApplication.shared.delegate as! SBAAppInfoDelegate
    }()
    
    // MARK: SBAUserProfileController
    
    open var failedValidationMessage = Localization.localizedString("SBA_REGISTRATION_UNKNOWN_FAILED")
    open var failedRegistrationTitle = Localization.localizedString("SBA_REGISTRATION_FAILED_TITLE")
    
    
    // MARK: Navigation overrides - cannot go back and override go forward to register
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // set the back button to empty items
        self.backButtonItem = UIBarButtonItem()
    }
    
    // Override the default method for goForward and attempt user registration. Do not allow subclasses
    // to override this method
    final public override func goForward() {
        
        showLoadingView()
        sharedUser.registerUser(email: email!, password: password!, externalId: externalID, dataGroups: dataGroups) { [weak self] error in
            if let error = error {
                self?.handleFailedRegistration(error)
            }
            else {
                self?.goNext()
            }
        }
    }
    
    open func goNext() {
        
        // successfully registered. Set the other values from this form.
        if let gender = self.gender {
            sharedUser.gender = gender
        }
        if let birthdate = self.birthdate {
            sharedUser.birthdate = birthdate
        }
        
        // Then call super to go forward
        super.goForward()
    }
    
    override open func goBackward() {
        // Do nothing
    }
    
}
