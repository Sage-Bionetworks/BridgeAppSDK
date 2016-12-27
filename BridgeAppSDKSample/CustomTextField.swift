//
//  CustomTextField.swift
//  BridgeAppSDK
//
//  Created by Eric Sieg on 12/26/16.
//  Copyright © 2016 Sage Bionetworks. All rights reserved.
//

import Foundation
import UIKit
import BridgeAppSDK

protocol CustomTextFieldDelegate: class {
    func editingDidEnd(_ rpTextField: CustomTextField)
    func editingDidBegin(_ rpTextField: CustomTextField)
}

class CustomTextField: UIView, UITextFieldDelegate {
    
    static let className = String(describing: CustomTextField.self)
    
    // Tags are reflective of View Tags in RpTextField.xib
    enum Tags: Int { case title = 1; case subtitle = 2; case textField = 3; case error = 4; case infoBtn = 5 }
    
    weak var titleLbl     : UILabel!
    weak var subtitleLbl  : UILabel!
    weak var errorBtn     : UIButton!  // Sometimes this field needs to be selected
    
    weak var textField    : UITextField!
    weak var infoBtn      : UIButton!
    
    weak var delegate     : CustomTextFieldDelegate?
    
    weak var formItemCell : ORKFormItemTextFieldBasedCell? {
        didSet {
            updateToMirrorFormItemCell()
        }
    }
    
    // When this is set, all user interaction will be disabled, and field will be locked at this value
    var lockFieldToDefaultValue = false
    var defaultValue: Any? {
        didSet {
            refreshDefaultValue()
        }
    }
    var defaultStringValue: String! {
        get {
            if let defaultValueUnwrapped = defaultValue {
                return String(describing: defaultValueUnwrapped)
            } else {
                return ""
            }
        }
    }
    
    var identifier: String?
    
    private class func instantiateContentView() -> UIView {
        return (UINib(
            nibName: className,
            bundle: Bundle.main
            ).instantiate(withOwner: nil, options: nil)[0] as? UIView)!
    }
    
    required override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    func commonInit() {
        let contentView = CustomTextField.instantiateContentView()
        addSubview(contentView)
        //addConstraints(NSLayoutConstraint.lockChild(child: contentView))
        
        for view in contentView.subviews.makeIterator() {
            switch(view.tag) {
            case Tags.title.rawValue:
                titleLbl = view as? UILabel
                titleLbl.text = nil
                break
            case Tags.subtitle.rawValue:
                subtitleLbl = view as? UILabel
                subtitleLbl.text = nil
                break
            case Tags.textField.rawValue:
                textField = view as? UITextField
                textField.delegate = self
                textField.addTarget(self, action: #selector(self.textFieldChanged(_:)), for: .editingChanged)
                textField.addTarget(self, action: #selector(self.editingDidEnd(_:)), for: .editingDidEnd)
                textField.addTarget(self, action: #selector(self.editingDidBegin(_:)), for: .editingDidBegin)
                break
            case Tags.error.rawValue:
                errorBtn = view as? UIButton;
                errorBtn.setTitle(nil, for: .normal)
                break
            case Tags.infoBtn.rawValue:
                infoBtn = view as? UIButton;
                break
            default: break
            }
        }
    }
    
    func commonAppearance() {
        backgroundColor = UIColor.blue
        textField.backgroundColor = UIColor.blue
    }
    
    // This is a special case method for when you want the
    // Error label to simply be another title description
    func makeErrorBeTitleButton(text: String, target: Any?, action: Selector) {
        // set label properties from the title to the error label
        errorBtn.setTitle(text, for: .normal)
        errorBtn.setTitleColor(titleLbl.textColor, for: .normal)
        errorBtn.titleLabel?.font = titleLbl.font
        errorBtn.isUserInteractionEnabled = true
        errorBtn.addTarget(target, action: action, for: .touchUpInside)
    }
    
    // This is special functionality that applies when you want to model this class
    // after a ORKFormItemTextFieldCell, which is the case with most of our view controllers
    func updateToMirrorFormItemCell() {
        if let formItem = formItemCell?.formItem() {
            
            if titleLbl.text == nil {
                titleLbl.text = formItem.text
            }
            if textField.placeholder == nil {
                textField.placeholder = formItem.placeholder
            }
            
            if let textAnswerFormat = formItem.answerFormat as? ORKTextAnswerFormat {
                textField.autocorrectionType = textAnswerFormat.autocorrectionType
                textField.autocapitalizationType = textAnswerFormat.autocapitalizationType
                
                // Multiple lines not supported for UITextField
                //textField.lines = textAnswerFormat.multipleLines
                
                textField.spellCheckingType = textAnswerFormat.spellCheckingType
                textField.keyboardType = textAnswerFormat.keyboardType
                textField.isSecureTextEntry = textAnswerFormat.isSecureTextEntry
            }
            
            textField.delegate = formItemCell?.textField().delegate
            
            refreshDefaultValue()
            textField.isEnabled = !lockFieldToDefaultValue
        }
    }
    
    func inputAccessoryButtonTapped() {
        textField.resignFirstResponder()
        delegate?.editingDidEnd(self)
    }
    
    func refreshDefaultValue() {
        if let defaultValueUnwrapped = defaultValue {
            textField.text = defaultStringValue
            formItemCell?.textField().text = defaultStringValue
            updateOrkAnswer(defaultValueUnwrapped)
            if lockFieldToDefaultValue {
                textField.textColor = UIColor.white
            } else {
                textField.textColor = UIColor.white
            }
        }
    }
    
    func updateOrkAnswer(_ answer: Any) {
        formItemCell?.inputValueDidChange()  // let it know that this has changed
    }
    
    // MARK - UITextField events
    
    func textFieldChanged(_ textField: UITextField) {
        // Forward the changes that happen to our UITextfields to the mirror data textfield
        formItemCell?.textField().text = textField.text
    }
    
    func editingDidEnd(_ textField: UITextField) {
        delegate?.editingDidEnd(self)
    }
    
    func editingDidBegin(_ textField: UITextField) {
        delegate?.editingDidBegin(self)
    }
    
    // MARK - UITextFieldDelegate, only called if not mirroring OrkFormItemCell
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return true
    }
}
