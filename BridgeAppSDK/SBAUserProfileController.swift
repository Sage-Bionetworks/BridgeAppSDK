//
//  SBAUserProfileController.swift
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

public protocol SBAStepViewControllerProtocol: class, SBASharedInfoController, SBAAlertPresenter, SBALoadingViewPresenter {
    
    var result: ORKStepResult? { get }
}

public protocol SBAUserProfileController: SBAStepViewControllerProtocol {
    var failedValidationMessage: String { get }
    var failedRegistrationTitle: String { get }
}

extension SBAUserProfileController {
    
    // MARK: Results
    
    public var name: String? {
        return textAnswer(.name)
    }
    
    public var email: String? {
        return textAnswer(.email)
    }
    
    public var password: String? {
        return textAnswer(.password)
    }
    
    public var externalID: String? {
        return textAnswer(.externalID)
    }
    
    public var gender: HKBiologicalSex? {
        guard let result = self.result?.result(forIdentifier: SBAProfileInfoOption.gender.rawValue) as? ORKChoiceQuestionResult
        else { return nil }
        if  let answer = (result.choiceAnswers?.first as? NSNumber)?.intValue {
            return HKBiologicalSex(rawValue: answer)
        }
        else if let answer = result.choiceAnswers?.first as? String {
            // The ORKHealthKitCharacteristicTypeAnswerFormat uses a string rather
            // than using the HKBiologicalSex enum directly so you have to convert
            let biologicalSex = ORKBiologicalSexIdentifier(rawValue: answer)
            switch (biologicalSex) {
            case ORKBiologicalSexIdentifier.female:
                return HKBiologicalSex.female
            case ORKBiologicalSexIdentifier.male:
                return HKBiologicalSex.male
            case ORKBiologicalSexIdentifier.other:
                return HKBiologicalSex.other
            default:
                return nil
            }
        }
        else {
            return nil
        }
    }
    
    public var birthdate: Date? {
        guard let result = self.result?.result(forIdentifier: SBAProfileInfoOption.birthdate.rawValue) as? ORKDateQuestionResult else { return nil }
        return result.dateAnswer
    }
    
    public var bloodType: HKBloodType? {
        guard let result = self.result?.result(forIdentifier: SBAProfileInfoOption.bloodType.rawValue) as? ORKChoiceQuestionResult
            else { return nil }
        if  let answer = (result.choiceAnswers?.first as? NSNumber)?.intValue {
            return HKBloodType(rawValue: answer)
        }
        else if let answer = result.choiceAnswers?.first as? String {
            // The ORKHealthKitCharacteristicTypeAnswerFormat uses a string rather
            // than using the HKBloodType enum directly so you have to convert
            let bloodType = ORKBloodTypeIdentifier(rawValue: answer)
            switch (bloodType) {
            case ORKBloodTypeIdentifier.abNegative:
                return HKBloodType.abNegative
            case ORKBloodTypeIdentifier.abPositive:
                return HKBloodType.abPositive
            case ORKBloodTypeIdentifier.aNegative:
                return HKBloodType.aNegative
            case ORKBloodTypeIdentifier.aPositive:
                return HKBloodType.aPositive
            case ORKBloodTypeIdentifier.bNegative:
                return HKBloodType.bNegative
            case ORKBloodTypeIdentifier.bPositive:
                return HKBloodType.bPositive
            case ORKBloodTypeIdentifier.oNegative:
                return HKBloodType.oNegative
            case ORKBloodTypeIdentifier.oPositive:
                return HKBloodType.oPositive
            default:
                return nil
            }
        }
        else {
            return nil
        }
    }
    
    public var fitzpatrickSkinType: HKFitzpatrickSkinType? {
        guard let result = self.result?.result(forIdentifier: SBAProfileInfoOption.bloodType.rawValue) as? ORKChoiceQuestionResult,
            let answer = (result.choiceAnswers?.first as? NSNumber)?.intValue
        else {
            return nil
        }
        return HKFitzpatrickSkinType(rawValue: answer)
    }
    
    public var wheelchairUse: Bool? {
        guard let result = self.result?.result(forIdentifier: SBAProfileInfoOption.bloodType.rawValue) as? ORKChoiceQuestionResult,
            let answer = (result.choiceAnswers?.first as? NSNumber)?.boolValue
            else {
                return nil
        }
        return answer
    }
    
    func textAnswer(_ field: SBAProfileInfoOption) -> String? {
        guard let result = self.result?.result(forIdentifier: field.rawValue) as? ORKTextQuestionResult else { return nil }
        return result.textAnswer
    }
    
    // MARK: Error handling

    func handleFailedValidation(_ reason: String? = nil) {
        let message = reason ?? failedValidationMessage
        self.hideLoadingView({ [weak self] in
            self?.showAlertWithOk(title: self?.failedRegistrationTitle, message: message, actionHandler: nil)
            })
    }
    
    func handleFailedRegistration(_ error: Error) {
        let message = (error as NSError).localizedBridgeErrorMessage
        handleFailedValidation(message)
    }
}
