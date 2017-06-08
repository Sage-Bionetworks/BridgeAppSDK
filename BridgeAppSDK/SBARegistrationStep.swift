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
    
    public var shouldConfirmPassword: Bool {
        return true
    }
    
    open func defaultOptions(_ inputItem: SBASurveyItem?) -> [SBAProfileInfoOption] {
        return [.email, .password]
    }
    
    public override required init(identifier: String) {
        super.init(identifier: identifier)
        commonInit(inputItem:nil, factory:nil)
    }
    
    public init(inputItem: SBASurveyItem, factory: SBASurveyFactory? = nil) {
        super.init(identifier: inputItem.identifier)
        commonInit(inputItem:inputItem, factory:factory)
    }
    
    open override func validateParameters() {
        super.validateParameters()
        try! validate(options: self.options)
    }
    
    open func validate(options: [SBAProfileInfoOption]?) throws {
        guard let options = options else {
            throw SBAProfileInfoOptionsError.missingRequiredOptions
        }
        
        guard options.contains(.email) else {
            throw SBAProfileInfoOptionsError.missingEmail
        }
    }
    
    open override var isOptional: Bool {
        get { return false }
        set {}
    }
    
    open var passwordAnswerFormat: ORKTextAnswerFormat? {
        return self.formItem(for: SBAProfileInfoOption.password.rawValue)?.answerFormat as? ORKTextAnswerFormat
    }
    
    open override func stepViewControllerClass() -> AnyClass {
        return SBARegistrationStepViewController.classForCoder()
    }
    
    // MARK: NSCoding
    
    public required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

/**
 Allow developers to create their own step view controllers that do not inherit from 
 `ORKFormStepViewController`.
 */
public protocol SBARegistrationStepController: SBAOnboardingStepController {
    
    /**
     If there are data groups that were set in a previous step or via a custom onboarding manager,
     set them on the view controller using this property.
     */
    var dataGroups: [String]? { get }
    
    /**
     In general, this method should call through to super.goForward(). See `SBARegistrationStepViewController`
     */
    func goNext()
}

extension SBARegistrationStepController {
    
    public var failedValidationMessage: String {
        return Localization.localizedString("SBA_REGISTRATION_UNKNOWN_FAILED")
    }
    
    public var failedRegistrationTitle: String {
        return Localization.localizedString("SBA_REGISTRATION_FAILED_TITLE")
    }
    
    public func registerUser() {
        showLoadingView()
        
        // Set the other values from this form.
        updateUserProfileInfo()
        updateUserConsentSignature()
        
        let externalID = self.externalID ?? sharedUser.externalId
        let dataGroups = self.dataGroups ?? sharedUser.dataGroups
        let password = self.password ?? sharedUser.password ?? generatePassword()
        
        sharedUser.registerUser(email: email!, password: password, externalId: externalID, dataGroups: dataGroups) { [weak self] error in
            if let error = error {
                self?.handleFailedRegistration(error)
            }
            else if self?.sharedUser.email == nil || self?.sharedUser.password == nil {
                assertionFailure("Failed to store the emal or password")
            }
            else {
                self?.goNext()
            }
        }
    }
    
    func generatePassword() -> String {
        
        let lowercase = "abcdefghijklmnopqrstuvwxyz"
        let uppercase = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        let numeric = "0123456789"
        let symbol = "!@#$%^&*()"
        
        let length = 8 + arc4random_uniform(4)
        let all = [lowercase, uppercase, numeric, symbol]
        
        var indexSet = IndexSet(0..<all.count)
        var randomString = ""
        
        func appendRandom(from groupIndex: Int) {
            
            // Pick a group to add a letter from
            let letters = all[groupIndex]
            
            // Pick a letter from that group
            let rand = Int(arc4random_uniform(UInt32(letters.characters.count)))
            let position = letters.index(letters.startIndex, offsetBy: rand)
            let nextChar = letters[position]
            
            // Add it to the string
            randomString.append(nextChar)
        }
        
        // count up to the length (8 - 12 characters)
        for _ in 0 ..< length {
            let index = Int(arc4random_uniform(UInt32(all.count)))
            appendRandom(from: index)
            if indexSet.contains(index) {
                indexSet.remove(index)
            }
        }
        
        // Add from any group that wasn't already selected at least once
        if indexSet.count > 0 {
            for index in indexSet {
                appendRandom(from: index)
            }
        }
        
        return randomString
    }
}

open class SBARegistrationStepViewController: ORKFormStepViewController, SBARegistrationStepController {
    
    open var dataGroups: [String]?
    
    // MARK: SBASharedInfoController
    
    lazy public var sharedAppDelegate: SBAAppInfoDelegate = {
        return UIApplication.shared.delegate as! SBAAppInfoDelegate
    }()
    
    // MARK: Navigation overrides - cannot go back and override go forward to register
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Hide the back button
        self.backButtonItem = UIBarButtonItem()
    }
    
    // Override the default method for goForward and attempt user registration. Do not allow subclasses
    // to override this method
    final public override func goForward() {
        registerUser()
    }
    
    open func goNext() {
        // Then call super to go forward
        super.goForward()
    }
}
