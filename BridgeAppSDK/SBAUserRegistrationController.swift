//
//  SBAUserRegistrationController.swift
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

public protocol SBAUserRegistrationController: class, SBASharedInfoController, SBAAlertPresenter, SBALoadingViewPresenter {
    
    var result: ORKStepResult? { get }
    
    var failedValidationMessage: String { get }
    var failedRegistrationTitle: String { get }
}

extension SBAUserRegistrationController {
    
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
    
    public var gender: String? {
        guard let result = self.result?.result(forIdentifier: SBAProfileInfoOption.gender.rawValue) as? ORKChoiceQuestionResult else { return nil }
        return result.choiceAnswers?.first as? String
    }
    
    public var birthdate: Date? {
        guard let result = self.result?.result(forIdentifier: SBAProfileInfoOption.birthdate.rawValue) as? ORKDateQuestionResult else { return nil }
        return result.dateAnswer
    }
    
    func textAnswer(_ field: SBAProfileInfoOption) -> String? {
        guard let result = self.result?.result(forIdentifier: field.rawValue) as? ORKTextQuestionResult else { return nil }
        return result.textAnswer
    }
    
    // MARK: Error handling

    func handleFailedValidation(_ reason: String? = nil) {
        let message = reason ?? failedValidationMessage
        self.hideLoadingView({ [weak self] in
            self?.showAlertWithOk(self?.failedRegistrationTitle, message: message, actionHandler: nil)
            })
    }
    
    func handleFailedRegistration(_ error: NSError) {
        let message = error.localizedBridgeErrorMessage
        handleFailedValidation(message)
    }
    
}
