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
    case EmailAndPassword = "email"
    case ExternalID       = "externalID"
    case Name             = "name"
    case Birthdate        = "birthdate"
    case Gender           = "gender"
    case SignatureImage   = "signature"
}

public enum SBARegistrationGender: String {
    case Female     = "female"
    case Male       = "male"
    case Other      = "other"
}

enum SBAProfileInfoOptionsError: ErrorType {
    case MissingRequiredOptions
    case MissingEmailOrExternalID
    case MissingNameOrExternalID
    case UnrecognizedSurveyItemType
}

struct SBAExternalIDOptions {
    let autocapitalizationType: UITextAutocapitalizationType
    let keyboardType:           UIKeyboardType
}

public struct SBAProfileInfoOptions {
    
    public let includes: [SBAProfileInfoOption]
    let externalIDOptions: SBAExternalIDOptions
    
    public init(includes: [SBAProfileInfoOption]) {
        self.includes = includes
        self.externalIDOptions = SBAExternalIDOptions(autocapitalizationType: .None, keyboardType: .Default)
    }
    
    public init?(inputItem: SBAFormStepSurveyItem) {
        guard let items = inputItem.items else {
            return nil
        }
        
        // Map the includes, and if it is an external ID then also map the keyboard options
        var externalIDOptions = SBAExternalIDOptions(autocapitalizationType: .None, keyboardType: .Default)
        self.includes = items.mapAndFilter({ (obj) -> SBAProfileInfoOption? in
            if let str = obj as? String {
                return SBAProfileInfoOption(rawValue: str)
            }
            else if let dictionary = obj as? [String : AnyObject],
                let identifier = dictionary["identifier"] as? String,
                let option = SBAProfileInfoOption(rawValue: identifier) {
                if option == .ExternalID {
                    let autocapitalizationType = UITextAutocapitalizationType(key: dictionary["autocapitalizationType"] as? String)
                    let keyboardType = UIKeyboardType(key: dictionary["keyboardType"] as? String)
                    externalIDOptions = SBAExternalIDOptions(autocapitalizationType: autocapitalizationType, keyboardType: keyboardType)
                }
                return option
            }
            return nil
        })
        self.externalIDOptions = externalIDOptions
    }
    
}

public class SBASignatureImageAnswerFormat : ORKAnswerFormat {
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

public protocol SBAProfileInfoForm : SBAFormProtocol {
    var surveyItemType: SBASurveyItemType { get }
    func defaultOptions() -> [SBAProfileInfoOption]
    func validateOptions(options: [SBAProfileInfoOption]?) throws
}

extension SBAProfileInfoForm {
    
    public var options: [SBAProfileInfoOption]? {
        return self.formItems?.mapAndFilter({ SBAProfileInfoOption(rawValue: $0.identifier) })
    }
    
    func commonInit(inputItem: SBAFormStepSurveyItem) {
        self.title = inputItem.stepTitle
        self.text = inputItem.stepText
        let options = SBAProfileInfoOptions(inputItem: inputItem)
        makeFormItems(options ?? SBAProfileInfoOptions(includes: defaultOptions()))
    }
    
    func makeFormItems(options: SBAProfileInfoOptions) {
        
        // Validate the options
        try! validateOptions(options.includes)
        
        // Build the form items
        if self.formItems == nil {
            self.formItems = []
        }
        
        for option in options.includes {
            switch option {
                
            case .EmailAndPassword:
                let answerFormat = ORKAnswerFormat.emailAnswerFormat()
                let formItem = ORKFormItem(identifier: option.rawValue,
                                           text: Localization.localizedString("EMAIL_FORM_ITEM_TITLE"),
                                           answerFormat: answerFormat,
                                           optional: false)
                formItem.placeholder = Localization.localizedString("EMAIL_FORM_ITEM_PLACEHOLDER")
                self.formItems! += [formItem]
                
                let passwordAnswerFormat = ORKAnswerFormat.textAnswerFormat()
                passwordAnswerFormat.multipleLines = false
                passwordAnswerFormat.secureTextEntry = true
                passwordAnswerFormat.autocapitalizationType = .None
                passwordAnswerFormat.autocorrectionType = .No
                passwordAnswerFormat.spellCheckingType = .No
                
                let passwordFormItem = ORKFormItem(identifier: option.rawValue,
                                                   text: Localization.localizedString("PASSWORD_FORM_ITEM_TITLE"),
                                                   answerFormat: passwordAnswerFormat,
                                                   optional: false)
                passwordFormItem.placeholder = Localization.localizedString("PASSWORD_FORM_ITEM_PLACEHOLDER")
                self.formItems! += [passwordFormItem]
                
                if (self.surveyItemType == .Account(.Registration)) {
                    // password confirmation
                    let confirmAnswerFormat = ORKConfirmTextAnswerFormat(originalItemIdentifier: passwordFormItem.identifier, errorMessage: Localization.localizedString("CONFIRM_PASSWORD_ERROR_MESSAGE"))
                    confirmAnswerFormat.multipleLines = false
                    confirmAnswerFormat.secureTextEntry = true
                    confirmAnswerFormat.autocapitalizationType = .None
                    confirmAnswerFormat.autocorrectionType = .No
                    confirmAnswerFormat.spellCheckingType = .No
                    
                    let confirmFormItem = ORKFormItem(identifier: SBARegistrationStep.kPasswordConfirmationKey,
                                                      text: Localization.localizedString("CONFIRM_PASSWORD_FORM_ITEM_TITLE"),
                                                      answerFormat: confirmAnswerFormat,
                                                      optional: false)
                    confirmFormItem.placeholder = Localization.localizedString("CONFIRM_PASSWORD_FORM_ITEM_PLACEHOLDER")
                    self.formItems! += [confirmFormItem]
                }
                
            case .ExternalID:
                let answerFormat = ORKAnswerFormat.textAnswerFormat()
                answerFormat.multipleLines = false
                answerFormat.secureTextEntry = true
                answerFormat.autocapitalizationType = options.externalIDOptions.autocapitalizationType
                answerFormat.autocorrectionType = .No
                answerFormat.spellCheckingType = .No
                answerFormat.keyboardType = options.externalIDOptions.keyboardType
                
                let formItem = ORKFormItem(identifier: option.rawValue,
                                           text: Localization.localizedString("SBA_REGISTRATION_EXTERNALID_TITLE"),
                                           answerFormat: answerFormat,
                                           optional: false)
                formItem.placeholder = Localization.localizedString("SBA_REGISTRATION_EXTERNALID_PLACEHOLDER")
                self.formItems! += [formItem]
                
            case .Name:
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
                self.formItems! += [formItem]
                
            case .Birthdate:
                // Calculate default date (20 years old).
                let defaultDate = NSCalendar.currentCalendar().dateByAddingUnit(.Year, value: -20, toDate: NSDate(), options: NSCalendarOptions(rawValue: 0))
                let answerFormat = ORKAnswerFormat.dateAnswerFormatWithDefaultDate(defaultDate, minimumDate: nil, maximumDate: NSDate(), calendar: NSCalendar.currentCalendar())
                let formItem = ORKFormItem(identifier: option.rawValue,
                                           text: Localization.localizedString("DOB_FORM_ITEM_TITLE"),
                                           answerFormat: answerFormat,
                                           optional: false)
                formItem.placeholder = Localization.localizedString("DOB_FORM_ITEM_PLACEHOLDER")
                self.formItems! += [formItem]
                
            case .Gender:
                let textChoices = [
                    ORKTextChoice(text: Localization.localizedString("GENDER_FEMALE"), value: SBARegistrationGender.Female.rawValue),
                    ORKTextChoice(text: Localization.localizedString("GENDER_MALE"), value: SBARegistrationGender.Male.rawValue),
                    ORKTextChoice(text: Localization.localizedString("GENDER_OTHER"), value: SBARegistrationGender.Other.rawValue),
                    ]
                let answerFormat  = ORKValuePickerAnswerFormat(textChoices: textChoices)
                let formItem = ORKFormItem(identifier: option.rawValue,
                                           text: Localization.localizedString("GENDER_FORM_ITEM_TITLE"),
                                           answerFormat: answerFormat,
                                           optional: false)
                formItem.placeholder = Localization.localizedString("GENDER_FORM_ITEM_PLACEHOLDER")
                self.formItems! += [formItem]
                
            case .SignatureImage:
                let answerFormat = SBASignatureImageAnswerFormat()
                let formItem = ORKFormItem(identifier: option.rawValue,
                                           text: nil,
                                           answerFormat: answerFormat,
                                           optional: false)
                self.formItems! += [formItem]
                
            }
        }
    }
}

