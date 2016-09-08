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

public enum SBAProfileInfoOption : String {
    case email            = "email"
    case password         = "password"
    case externalID       = "externalID"
    case name             = "name"
    case birthdate        = "birthdate"
    case gender           = "gender"
}

public enum SBARegistrationGender: String {
    case female, male, other
}

enum SBAProfileInfoOptionsError: ErrorType {
    case MissingRequiredOptions
    case MissingEmail
    case MissingExternalID
    case MissingName
    case NotConsented
    case UnrecognizedSurveyItemType
}

struct SBAExternalIDOptions {
    
    static let defaultAutocapitalizationType: UITextAutocapitalizationType = .AllCharacters
    static let defaultKeyboardType: UIKeyboardType = .ASCIICapable
    
    let autocapitalizationType: UITextAutocapitalizationType
    let keyboardType: UIKeyboardType
    
    init() {
        self.autocapitalizationType = SBAExternalIDOptions.defaultAutocapitalizationType
        self.keyboardType = SBAExternalIDOptions.defaultKeyboardType
    }
    
    init(autocapitalizationType: UITextAutocapitalizationType, keyboardType: UIKeyboardType) {
        self.autocapitalizationType = autocapitalizationType
        self.keyboardType = keyboardType
    }
    
    init(options: [NSObject : AnyObject]?) {
        self.autocapitalizationType = {
            if let autocap = options?["autocapitalizationType"] as? String {
                 return UITextAutocapitalizationType(key: autocap)
            }
            else {
                return SBAExternalIDOptions.defaultAutocapitalizationType
            }
        }()
        self.keyboardType = {
            if let keyboard = options?["keyboardType"] as? String {
                return UIKeyboardType(key: keyboard)
            }
            else {
                return SBAExternalIDOptions.defaultKeyboardType
            }
        }()
    }
}

public struct SBAProfileInfoOptions {
    
    public let includes: [SBAProfileInfoOption]
    public let customOptions: [AnyObject]
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
    
    public init?(inputItem: SBAFormStepSurveyItem) {
        guard let items = inputItem.items else {
            return nil
        }
        
        // Map the includes, and if it is an external ID then also map the keyboard options
        var externalIDOptions = SBAExternalIDOptions(autocapitalizationType: .None, keyboardType: .Default)
        var customOptions: [AnyObject] = []
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
                customOptions += [obj]
            }
            return nil
        })
        self.externalIDOptions = externalIDOptions
        self.customOptions = customOptions
    }
    
    func makeFormItems(surveyItemType surveyItemType: SBASurveyItemType) -> [ORKFormItem] {
        
        var formItems: [ORKFormItem] = []
        
        for option in self.includes {
            switch option {
                
            case .email:
                let answerFormat = ORKAnswerFormat.emailAnswerFormat()
                let formItem = ORKFormItem(identifier: option.rawValue,
                                           text: Localization.localizedString("EMAIL_FORM_ITEM_TITLE"),
                                           answerFormat: answerFormat,
                                           optional: false)
                formItem.placeholder = Localization.localizedString("EMAIL_FORM_ITEM_PLACEHOLDER")
                formItems.append(formItem)
            
            case .password:
                let answerFormat = ORKAnswerFormat.textAnswerFormat()
                answerFormat.multipleLines = false
                answerFormat.secureTextEntry = true
                answerFormat.autocapitalizationType = .None
                answerFormat.autocorrectionType = .No
                answerFormat.spellCheckingType = .No
                
                // Set default regex
                let minLength = SBARegistrationStep.defaultPasswordMinLength
                let maxLength = SBARegistrationStep.defaultPasswordMaxLength
                answerFormat.validationRegex = "[[:ascii:]]{\(minLength),\(maxLength)}"
                answerFormat.invalidMessage = Localization.localizedStringWithFormatKey("SBA_REGISTRATION_INVALID_PASSWORD_LENGTH_%@_TO_%@", NSNumber(integer: minLength), NSNumber(integer: maxLength))
                
                let formItem = ORKFormItem(identifier: option.rawValue,
                                                   text: Localization.localizedString("PASSWORD_FORM_ITEM_TITLE"),
                                                   answerFormat: answerFormat,
                                                   optional: false)
                formItem.placeholder = Localization.localizedString("PASSWORD_FORM_ITEM_PLACEHOLDER")
                formItems.append(formItem)
                
                // confirmation
                if (surveyItemType == .account(.registration)) {
                    let confirmIdentifier = SBARegistrationStep.confirmationIdentifier
                    let confirmText = Localization.localizedString("CONFIRM_PASSWORD_FORM_ITEM_TITLE")
                    let confirmError = Localization.localizedString("CONFIRM_PASSWORD_ERROR_MESSAGE")
                    let confirmFormItem = formItem.confirmationAnswerFormItemWithIdentifier(confirmIdentifier, text: confirmText,
                                                                                                    errorMessage: confirmError)
                    
                    confirmFormItem.placeholder = Localization.localizedString("CONFIRM_PASSWORD_FORM_ITEM_PLACEHOLDER")
                    formItems.append(confirmFormItem)
                }
                
            case .externalID:
                let answerFormat = ORKAnswerFormat.textAnswerFormat()
                answerFormat.multipleLines = false
                answerFormat.autocapitalizationType = self.externalIDOptions.autocapitalizationType
                answerFormat.autocorrectionType = .No
                answerFormat.spellCheckingType = .No
                answerFormat.keyboardType = self.externalIDOptions.keyboardType
                
                let formItem = ORKFormItem(identifier: option.rawValue,
                                           text: Localization.localizedString("SBA_REGISTRATION_EXTERNALID_TITLE"),
                                           answerFormat: answerFormat,
                                           optional: false)
                formItem.placeholder = Localization.localizedString("SBA_REGISTRATION_EXTERNALID_PLACEHOLDER")
                formItems.append(formItem)
                
            case .name:
                let answerFormat = ORKAnswerFormat.textAnswerFormat()
                answerFormat.multipleLines = false
                answerFormat.autocapitalizationType = .Words
                answerFormat.autocorrectionType = .No
                answerFormat.spellCheckingType = .No
                answerFormat.keyboardType = .Default
                
                let formItem = ORKFormItem(identifier: option.rawValue,
                                           text: Localization.localizedString("SBA_REGISTRATION_FULLNAME_TITLE"),
                                           answerFormat: answerFormat,
                                           optional: false)
                formItem.placeholder = Localization.localizedString("SBA_REGISTRATION_FULLNAME_PLACEHOLDER")
                formItems.append(formItem)
                
            case .birthdate:
                // Calculate default date (20 years old).
                let defaultDate = NSCalendar.currentCalendar().dateByAddingUnit(.Year, value: -20, toDate: NSDate(), options: NSCalendarOptions(rawValue: 0))
                let answerFormat = ORKAnswerFormat.dateAnswerFormatWithDefaultDate(defaultDate, minimumDate: nil, maximumDate: NSDate(), calendar: NSCalendar.currentCalendar())
                let formItem = ORKFormItem(identifier: option.rawValue,
                                           text: Localization.localizedString("DOB_FORM_ITEM_TITLE"),
                                           answerFormat: answerFormat,
                                           optional: false)
                formItem.placeholder = Localization.localizedString("DOB_FORM_ITEM_PLACEHOLDER")
                formItems.append(formItem)
                
            case .gender:
                let textChoices = [
                    ORKTextChoice(text: Localization.localizedString("GENDER_FEMALE"), value: SBARegistrationGender.female.rawValue),
                    ORKTextChoice(text: Localization.localizedString("GENDER_MALE"), value: SBARegistrationGender.male.rawValue),
                    ORKTextChoice(text: Localization.localizedString("GENDER_OTHER"), value: SBARegistrationGender.other.rawValue),
                    ]
                let answerFormat  = ORKValuePickerAnswerFormat(textChoices: textChoices)
                let formItem = ORKFormItem(identifier: option.rawValue,
                                           text: Localization.localizedString("GENDER_FORM_ITEM_TITLE"),
                                           answerFormat: answerFormat,
                                           optional: false)
                formItem.placeholder = Localization.localizedString("GENDER_FORM_ITEM_PLACEHOLDER")
                formItems.append(formItem)
                
            }
        }
        return formItems
    }
}

public protocol SBAFormProtocol : class {
    var identifier: String { get }
    var title: String? { get set }
    var text: String? { get set }
    var formItems: [ORKFormItem]? { get set }
    init(identifier: String)
}

extension SBAFormProtocol {
    public func formItemForIdentifier(identifier: String) -> ORKFormItem? {
        return self.formItems?.findObject({ $0.identifier == identifier })
    }
}

extension ORKFormStep: SBAFormProtocol {
}

public protocol SBAProfileInfoForm : SBAFormProtocol {
    var surveyItemType: SBASurveyItemType { get }
    func defaultOptions(inputItem: SBAFormStepSurveyItem?) -> [SBAProfileInfoOption]
    func validate(options options: [SBAProfileInfoOption]?) throws
}

extension SBAProfileInfoForm {
    
    public var options: [SBAProfileInfoOption]? {
        return self.formItems?.mapAndFilter({ SBAProfileInfoOption(rawValue: $0.identifier) })
    }
    
    func commonInit(inputItem: SBAFormStepSurveyItem) {
        self.title = inputItem.stepTitle
        self.text = inputItem.stepText
        let options = SBAProfileInfoOptions(inputItem: inputItem) ?? SBAProfileInfoOptions(includes: defaultOptions(inputItem))
        self.formItems = options.makeFormItems(surveyItemType: self.surveyItemType)
    }
}

