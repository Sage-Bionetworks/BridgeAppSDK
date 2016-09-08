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

public class SBARegistrationStep: ORKFormStep, SBAProfileInfoForm {
    
    static let confirmationIdentifier = "confirmation"
    
    static let defaultPasswordMinLength = 4
    static let defaultPasswordMaxLength = 16
    
    public var surveyItemType: SBASurveyItemType {
        return .account(.registration)
    }
    
    public override required init(identifier: String) {
        super.init(identifier: identifier)
        let options = SBAProfileInfoOptions(includes: defaultOptions(nil))
        self.formItems = options.makeFormItems(surveyItemType: self.surveyItemType)
    }
    
    public init?(inputItem: SBASurveyItem) {
        guard let survey = inputItem as? SBAFormStepSurveyItem else { return nil }
        super.init(identifier: inputItem.identifier)
        commonInit(survey)
    }
    
    public func defaultOptions(inputItem: SBAFormStepSurveyItem?) -> [SBAProfileInfoOption] {
        return [.name, .email, .password]
    }

    public override func validateParameters() {
        super.validateParameters()
        try! validate(options: self.options)
    }
    
    public func validate(options options: [SBAProfileInfoOption]?) throws {
        guard let options = options else {
            throw SBAProfileInfoOptionsError.MissingRequiredOptions
        }
        
        guard options.contains(.email) && options.contains(.password) else {
            throw SBAProfileInfoOptionsError.MissingEmail
        }
    }
    
    public override var optional: Bool {
        get { return false }
        set {}
    }
    
    public var passwordAnswerFormat: ORKTextAnswerFormat? {
        return self.formItemForIdentifier(SBAProfileInfoOption.password.rawValue)?.answerFormat as? ORKTextAnswerFormat
    }
    
    public override func stepViewControllerClass() -> AnyClass {
        return SBARegistrationStepViewController.classForCoder()
    }
    
    // MARK: NSCoding
    
    public required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}


public class SBARegistrationStepViewController: ORKFormStepViewController, SBASharedInfoController, SBALoadingViewPresenter {
    
    lazy public var sharedAppDelegate: SBAAppInfoDelegate = {
        return UIApplication.sharedApplication().delegate as! SBAAppInfoDelegate
    }()
    
    // Mark: Navigation overrides - cannot go back and override go forward to register
    
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
    
    func goNext() {
        
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
    
    public override var backButtonItem: UIBarButtonItem? {
        get { return nil }
        set {}
    }
    
    override public func goBackward() {
        // Do nothing
    }
    
    // MARK: Results
    
    public var email: String? {
        return textAnswer(.email)
    }
    
    public var password: String? {
        return textAnswer(.password)
    }
    
    public var externalID: String? {
        return textAnswer(.externalID)
    }

    public var dataGroups: [String]? {
        return nil
    }
    
    public var gender: String? {
        guard let result = self.result?.resultForIdentifier(SBAProfileInfoOption.gender.rawValue) as? ORKChoiceQuestionResult else { return nil }
        return result.choiceAnswers?.first as? String
    }
    
    public var birthdate: NSDate? {
        guard let result = self.result?.resultForIdentifier(SBAProfileInfoOption.birthdate.rawValue) as? ORKDateQuestionResult else { return nil }
        return result.dateAnswer
    }
    
    func textAnswer(field: SBAProfileInfoOption) -> String? {
        guard let result = self.result?.resultForIdentifier(field.rawValue) as? ORKTextQuestionResult else { return nil }
        return result.textAnswer
    }
    
    // MARK: Error handling
    
    public var failedValidationMessage = Localization.localizedString("SBA_REGISTRATION_INVALID_CODE")
    public var failedRegistrationTitle = Localization.localizedString("SBA_REGISTRATION_FAILED_TITLE")

    func handleFailedValidation(reason: String? = nil) {
        let message = reason ?? failedValidationMessage
        self.hideLoadingView({ [weak self] in
            self?.showAlertWithOk(self?.failedRegistrationTitle, message: message, actionHandler: nil)
        })
    }

    func handleFailedRegistration(error: NSError) {
        let message = error.localizedBridgeErrorMessage
        handleFailedValidation(message)
    }
}
