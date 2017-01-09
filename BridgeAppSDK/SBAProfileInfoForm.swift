//
//  SBARegistrationForm.swift
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
 The `SBAProfileInfoOption` enum includes the list of demographics and account 
 registration items that are commonly required by research studies.
 */
public enum SBAProfileInfoOption : String {
    case email                  = "email"
    case password               = "password"
    case externalID             = "externalID"
    case name                   = "name"
    case birthdate              = "birthdate"
    case gender                 = "gender"
    case bloodType              = "bloodType"
    case fitzpatrickSkinType    = "fitzpatrickSkinType"
    case wheelchairUse          = "wheelchairUse"
    case height                 = "height"
    case weight                 = "weight"
    case wakeTime               = "wakeTime"
    case sleepTime              = "sleepTime"
}

/**
 List of possible errors for a given stage of onboarding
 */
enum SBAProfileInfoOptionsError: Error {
    case missingRequiredOptions
    case missingEmail
    case missingExternalID
    case missingName
    case notConsented
    case unrecognizedSurveyItemType
}

/**
 Protocol for extending all the profile info steps (used by the factory to create the
 appropriate default form items).
 */
public protocol SBAProfileInfoForm: SBAFormProtocol {
    
    /**
     Should this form step include password confirmation.
     */
    var shouldConfirmPassword: Bool { get }
    
    /**
     Used in common initialization to get the default options if the included options are nil.
     */
    func defaultOptions(_ inputItem: SBASurveyItem?) -> [SBAProfileInfoOption]
}

/**
 Shared factory methods for creating profile form steps.
 */
extension SBAProfileInfoForm {
    
    public var options: [SBAProfileInfoOption]? {
        return self.formItems?.mapAndFilter({ SBAProfileInfoOption(rawValue: $0.identifier) })
    }
    
    public func formItemForProfileInfoOption(_ profileInfoOption: SBAProfileInfoOption) -> ORKFormItem? {
        return self.formItems?.find({ $0.identifier == profileInfoOption.rawValue })
    }
    
    func commonInit(inputItem: SBASurveyItem?, factory: SBASurveyFactory?) {
        self.title = inputItem?.stepTitle
        self.text = inputItem?.stepText
        if let formStep = self as? ORKFormStep {
            formStep.footnote = inputItem?.stepFootnote
        }
        let options = SBAProfileInfoOptions(inputItem: inputItem) ?? SBAProfileInfoOptions(includes: defaultOptions(inputItem))
        self.formItems = options.makeFormItems(shouldConfirmPassword: self.shouldConfirmPassword, factory: factory)
    }
}

/**
 Model object for converting profile form items into `ORKFormItem` using a string key that
 maps to `SBAProfileInfoOption`
 */
public struct SBAProfileInfoOptions {
    
    /**
     Parsed list of common options to be included with this form.
    */
    public let includes: [SBAProfileInfoOption]
    
    /**
     iVar for storing custom options
    */
    public let customOptions: [Any]
    
    /**
     The Auto-capitalization and Keyboard for entering the external ID (if applicable)
    */
    let externalIDOptions: SBAExternalIDOptions
    
    public init(includes: [SBAProfileInfoOption]) {
        self.includes = includes
        self.externalIDOptions = SBAExternalIDOptions()
        self.customOptions = []
    }
    
    init(externalIDOptions: SBAExternalIDOptions) {
        self.includes = [.externalID]
        self.externalIDOptions = externalIDOptions
        self.customOptions = []
    }
    
    public init?(inputItem: SBASurveyItem?) {
        guard let surveyForm = inputItem as? SBAFormStepSurveyItem,
            let items = surveyForm.items else {
            return nil
        }
        
        // Map the includes, and if it is an external ID then also map the keyboard options
        var externalIDOptions = SBAExternalIDOptions(autocapitalizationType: .none, keyboardType: .default)
        var customOptions: [Any] = []
        self.includes = items.mapAndFilter({ (obj) -> SBAProfileInfoOption? in
            if let str = obj as? String {
                return SBAProfileInfoOption(rawValue: str)
            }
            else if let dictionary = obj as? [String : AnyObject],
                let identifier = dictionary["identifier"] as? String,
                let option = SBAProfileInfoOption(rawValue: identifier) {
                if option == .externalID {
                    externalIDOptions = SBAExternalIDOptions(options: dictionary)
                }
                return option
            }
            else {
                customOptions.append(obj)
            }
            return nil
        })
        self.externalIDOptions = externalIDOptions
        self.customOptions = customOptions
    }
    
    /**
     Factory method for converting to `ORKFormItem` array.
    */
    func makeFormItems(shouldConfirmPassword: Bool, factory:SBASurveyFactory? = nil) -> [ORKFormItem] {
        
        var formItems: [ORKFormItem] = []
        
        for option in self.includes {
            switch option {
                
            case .email:
                let formItem = makeEmailFormItem(with: option.rawValue)
                formItems.append(formItem)
            
            case .password:
                let (formItem, answerFormat) = makePasswordFormItem(with: option.rawValue)
                formItems.append(formItem)
                
                // confirmation
                if (shouldConfirmPassword) {
                    let confirmFormItem = makeConfirmationFormItem(formItem: formItem, answerFormat: answerFormat)
                    formItems.append(confirmFormItem)
                }
                
            case .externalID:
                let formItem = makeExternalIDFormItem(with: option.rawValue)
                formItems.append(formItem)
                
            case .name:
                let formItem = makeNameFormItem(with: option.rawValue)
                formItems.append(formItem)
                
            case .birthdate:
                let formItem = makeBirthdateFormItem(with: option.rawValue)
                formItems.append(formItem)
                
            case .gender:
                let formItem = makeGenderFormItem(with: option.rawValue)
                formItems.append(formItem)
                
            case .bloodType:
                let formItem = makeBloodTypeFormItem(with: option.rawValue)
                formItems.append(formItem)
                
            case .fitzpatrickSkinType:
                let formItem = makeFitzpatrickSkinTypeFormItem(with: option.rawValue)
                formItems.append(formItem)
                
            case .wheelchairUse:
                let formItem = makeWheelchairUseFormItem(with: option.rawValue)
                formItems.append(formItem)
                
            case .height:
                let formItem = makeHeightFormItem(with: option.rawValue)
                formItems.append(formItem)
                
            case .weight:
                let formItem = makeWeightFormItem(with: option.rawValue)
                formItems.append(formItem)
                
            case .wakeTime:
                let formItem = makeWakeTimeFormItem(with: option.rawValue)
                formItems.append(formItem)
                
            case .sleepTime:
                let formItem = makeSleepTimeFormItem(with: option.rawValue)
                formItems.append(formItem)
            }
        }
        
        let surveyFactory = factory ?? SBASurveyFactory()
        for item in customOptions {
            if let surveyItem = item as? SBAFormStepSurveyItem, surveyItem.isValidFormItem {
                let formItem = surveyFactory.createFormItem(surveyItem)
                formItems.append(formItem)
            }
        }
        
        return formItems
    }
    
    func makeEmailFormItem(with identifier: String) -> ORKFormItem {
        let answerFormat = ORKAnswerFormat.emailAnswerFormat()
        let formItem = ORKFormItem(identifier: identifier,
                                   text: Localization.localizedString("EMAIL_FORM_ITEM_TITLE"),
                                   answerFormat: answerFormat,
                                   optional: false)
        formItem.placeholder = Localization.localizedString("EMAIL_FORM_ITEM_PLACEHOLDER")
        return formItem
    }
    
    func makePasswordFormItem(with identifier: String) -> (ORKFormItem, ORKTextAnswerFormat) {
        let answerFormat = ORKAnswerFormat.textAnswerFormat()
        answerFormat.multipleLines = false
        answerFormat.isSecureTextEntry = true
        answerFormat.autocapitalizationType = .none
        answerFormat.autocorrectionType = .no
        answerFormat.spellCheckingType = .no
        
        let formItem = ORKFormItem(identifier: identifier,
                                   text: Localization.localizedString("PASSWORD_FORM_ITEM_TITLE"),
                                   answerFormat: answerFormat,
                                   optional: false)
        formItem.placeholder = Localization.localizedString("PASSWORD_FORM_ITEM_PLACEHOLDER")
        
        return (formItem, answerFormat)
    }
    
    func makeConfirmationFormItem(formItem: ORKFormItem, answerFormat: ORKTextAnswerFormat) -> ORKFormItem {
        // If this is a registration, go ahead and set the default password verification
        let minLength = SBARegistrationStep.defaultPasswordMinLength
        let maxLength = SBARegistrationStep.defaultPasswordMaxLength
        answerFormat.validationRegex = "[[:ascii:]]{\(minLength),\(maxLength)}"
        answerFormat.invalidMessage = Localization.localizedStringWithFormatKey("SBA_REGISTRATION_INVALID_PASSWORD_LENGTH_%@_TO_%@", NSNumber(value: minLength), NSNumber(value: maxLength))
        
        // Add a confirmation field
        let confirmIdentifier = SBARegistrationStep.confirmationIdentifier
        let confirmText = Localization.localizedString("CONFIRM_PASSWORD_FORM_ITEM_TITLE")
        let confirmError = Localization.localizedString("CONFIRM_PASSWORD_ERROR_MESSAGE")
        let confirmFormItem = formItem.confirmationAnswer(withIdentifier: confirmIdentifier, text: confirmText,
                                                                                errorMessage: confirmError)
        
        confirmFormItem.placeholder = Localization.localizedString("CONFIRM_PASSWORD_FORM_ITEM_PLACEHOLDER")
        
        return confirmFormItem
    }
    
    func makeExternalIDFormItem(with identifier: String) -> ORKFormItem {
        let answerFormat = ORKAnswerFormat.textAnswerFormat()
        answerFormat.multipleLines = false
        answerFormat.autocapitalizationType = self.externalIDOptions.autocapitalizationType
        answerFormat.autocorrectionType = .no
        answerFormat.spellCheckingType = .no
        answerFormat.keyboardType = self.externalIDOptions.keyboardType
        
        let formItem = ORKFormItem(identifier: identifier,
                                   text: Localization.localizedString("SBA_REGISTRATION_EXTERNALID_TITLE"),
                                   answerFormat: answerFormat,
                                   optional: false)
        formItem.placeholder = Localization.localizedString("SBA_REGISTRATION_EXTERNALID_PLACEHOLDER")
        
        return formItem
    }
    
    func makeNameFormItem(with identifier: String) -> ORKFormItem {
        
        let answerFormat = ORKAnswerFormat.textAnswerFormat()
        answerFormat.multipleLines = false
        answerFormat.autocapitalizationType = .words
        answerFormat.autocorrectionType = .no
        answerFormat.spellCheckingType = .no
        answerFormat.keyboardType = .default
        
        let formItem = ORKFormItem(identifier: identifier,
                                   text: Localization.localizedString("SBA_REGISTRATION_FULLNAME_TITLE"),
                                   answerFormat: answerFormat,
                                   optional: false)
        formItem.placeholder = Localization.localizedString("SBA_REGISTRATION_FULLNAME_PLACEHOLDER")
        
        return formItem
    }
    
    func makeBirthdateFormItem(with identifier: String) -> ORKFormItem {
        
        let characteristic = HKObjectType.characteristicType(forIdentifier: .dateOfBirth)!
        let answerFormat = SBAHealthKitCharacteristicTypeAnswerFormat(characteristicType: characteristic)
        answerFormat.shouldRequestAuthorization = false
        let formItem = ORKFormItem(identifier: identifier,
                                   text: Localization.localizedString("DOB_FORM_ITEM_TITLE"),
                                   answerFormat: answerFormat,
                                   optional: false)
        formItem.placeholder = Localization.localizedString("DOB_FORM_ITEM_PLACEHOLDER")
        
        return formItem
    }
    
    func makeGenderFormItem(with identifier: String) -> ORKFormItem {
        
        let characteristic = HKObjectType.characteristicType(forIdentifier: .biologicalSex)!
        let answerFormat = SBAHealthKitCharacteristicTypeAnswerFormat(characteristicType: characteristic)
        answerFormat.shouldRequestAuthorization = false
        let formItem = ORKFormItem(identifier: identifier,
                                   text: Localization.localizedString("GENDER_FORM_ITEM_TITLE"),
                                   answerFormat: answerFormat,
                                   optional: false)
        formItem.placeholder = Localization.localizedString("GENDER_FORM_ITEM_PLACEHOLDER")
        
        return formItem
    }
    
    func makeBloodTypeFormItem(with identifier: String) -> ORKFormItem {
        
        let characteristic = HKObjectType.characteristicType(forIdentifier: .bloodType)!
        let answerFormat = SBAHealthKitCharacteristicTypeAnswerFormat(characteristicType: characteristic)
        answerFormat.shouldRequestAuthorization = false
        let formItem = ORKFormItem(identifier: identifier,
                                   text: Localization.localizedString("BLOOD_TYPE_FORM_ITEM_TITLE"),
                                   answerFormat: answerFormat,
                                   optional: false)
        formItem.placeholder = Localization.localizedString("BLOOD_TYPE_FORM_ITEM_PLACEHOLDER")
        
        return formItem
    }
    
    func makeFitzpatrickSkinTypeFormItem(with identifier: String) -> ORKFormItem {
        
        let characteristic = HKObjectType.characteristicType(forIdentifier: .fitzpatrickSkinType)!
        let answerFormat = SBAHealthKitCharacteristicTypeAnswerFormat(characteristicType: characteristic)
        answerFormat.shouldRequestAuthorization = false
        let formItem = ORKFormItem(identifier: identifier,
                                   text: Localization.localizedString("FITZPATRICK_SKIN_TYPE_FORM_ITEM_TITLE"),
                                   answerFormat: answerFormat,
                                   optional: false)
        formItem.placeholder = Localization.localizedString("FITZPATRICK_SKIN_TYPE_FORM_ITEM_PLACEHOLDER")
        
        return formItem
    }
    
    func makeWheelchairUseFormItem(with identifier: String) -> ORKFormItem {
        
        let answerFormat: ORKAnswerFormat = {
            if #available(iOS 10.0, *) {
                let characteristic = HKObjectType.characteristicType(forIdentifier: .wheelchairUse)!
                let answerFormat = SBAHealthKitCharacteristicTypeAnswerFormat(characteristicType: characteristic)
                answerFormat.shouldRequestAuthorization = false
                return answerFormat
            } else {
                return ORKBooleanAnswerFormat()
            }
        }()

        let formItem = ORKFormItem(identifier: identifier,
                                   text: Localization.localizedString("WHEELCHAIR_USE_FORM_ITEM_TITLE"),
                                   answerFormat: answerFormat,
                                   optional: false)
        
        return formItem
    }
    
    func makeHeightFormItem(with identifier: String) -> ORKFormItem {
        
        // Get the locale unit
        var formatterUnit = LengthFormatter.Unit.meter
        let formatter = LengthFormatter()
        formatter.unitStyle = .medium
        formatter.isForPersonHeightUse = true
        formatter.unitString(fromMeters: 2.0, usedUnit: &formatterUnit)
        
        let unit: HKUnit = HKUnit(from: formatterUnit)
        let quantityType = HKObjectType.quantityType(forIdentifier: .height)!
        let answerFormat = ORKHealthKitQuantityTypeAnswerFormat(quantityType: quantityType, unit: unit, style: .integer)
        answerFormat.shouldRequestAuthorization = false
        let formItem = ORKFormItem(identifier: identifier,
                                   text: Localization.localizedString("HEIGHT_FORM_ITEM_TITLE"),
                                   answerFormat: answerFormat,
                                   optional: false)
        
        return formItem
    }
    
    func makeWeightFormItem(with identifier: String) -> ORKFormItem {
        
        // Get the locale unit
        var formatterUnit = MassFormatter.Unit.kilogram
        let formatter = MassFormatter()
        formatter.unitStyle = .medium
        formatter.isForPersonMassUse = true
        formatter.unitString(fromKilograms: 60.0, usedUnit: &formatterUnit)
        
        let unit: HKUnit = HKUnit(from: formatterUnit)
        let quantityType = HKObjectType.quantityType(forIdentifier: .bodyMass)!
        let answerFormat = ORKHealthKitQuantityTypeAnswerFormat(quantityType: quantityType, unit: unit, style: .integer)
        answerFormat.shouldRequestAuthorization = false
        let formItem = ORKFormItem(identifier: identifier,
                                   text: Localization.localizedString("WEIGHT_FORM_ITEM_TITLE"),
                                   answerFormat: answerFormat,
                                   optional: false)
        return formItem
    }
    
    func makeWakeTimeFormItem(with identifier: String) -> ORKFormItem {
        
        var components = DateComponents()
        components.calendar = Calendar(identifier: .gregorian)
        components.hour = 7
        components.minute = 0
        let answerFormat = ORKTimeOfDayAnswerFormat(defaultComponents: components)

        let formItem = ORKFormItem(identifier: identifier,
                                   text: Localization.localizedString("WAKE_TIME_FORM_ITEM_TEXT"),
                                   answerFormat: answerFormat,
                                   optional: false)
        return formItem
    }
    
    func makeSleepTimeFormItem(with identifier: String) -> ORKFormItem {
        
        var components = DateComponents()
        components.calendar = Calendar(identifier: .gregorian)
        components.hour = 10
        components.minute = 0
        let answerFormat = ORKTimeOfDayAnswerFormat(defaultComponents: components)
        
        let formItem = ORKFormItem(identifier: identifier,
                                   text: Localization.localizedString("SLEEP_TIME_FORM_ITEM_TEXT"),
                                   answerFormat: answerFormat,
                                   optional: false)
        return formItem
    }
}

class SBAHealthKitCharacteristicTypeAnswerFormat: ORKHealthKitCharacteristicTypeAnswerFormat {
    override func implied() -> ORKAnswerFormat {
        let answerFormat = super.implied()
        if let choiceFormat = answerFormat as? ORKTextChoiceAnswerFormat {
            return ORKValuePickerAnswerFormat(textChoices: choiceFormat.textChoices)
        }
        else {
            return answerFormat
        }
    }
}

