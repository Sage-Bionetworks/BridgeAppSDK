//
//  SBAToggleTableViewCell.swift
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

import UIKit
import ResearchKit

protocol SBAToggleTableViewCellDelegate: class {
    func didChangeAnswer(cell: SBAToggleTableViewCell)
}

class SBAToggleTableViewCell: UITableViewCell {
    
    static let reuseIdentifier = "ToggleCell"
    
    weak var delegate: SBAToggleTableViewCellDelegate?

    @IBOutlet weak var preferredHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var questionLabel: UILabel!
    @IBOutlet weak var leftButton: UIButton!
    @IBOutlet weak var rightButton: UIButton!

    @IBAction func leftButtonTapped(_ sender: AnyObject) {
        self.choiceAnswer = leftAnswer
    }
    
    @IBAction func rightButtonTapped(_ sender: AnyObject) {
        self.choiceAnswer = rightAnswer
    }
    
    var result: ORKResult?
    
    var hasAnswer: Bool {
        return self.choiceAnswer != nil
    }
    
    private var choiceAnswer: Any? {
        didSet {
            
            // Update buttons
            updateTintColor()
            
            // update the associated result
            if let choiceResult = result as? ORKChoiceQuestionResult {
                choiceResult.choiceAnswers = {
                    guard let choice = self.choiceAnswer else { return nil }
                    return [choice]
                }()
            }
            else if let boolResult = result as? ORKBooleanQuestionResult {
                boolResult.booleanAnswer = choiceAnswer as? NSNumber
            }
            
            // send delegate message that the cell answer did change
            self.delegate?.didChangeAnswer(cell: self)
        }
    }

    override func tintColorDidChange() {
        super.tintColorDidChange()
        updateTintColor()
    }
    
    func updateTintColor() {
        self.leftButton.setTitleColor(SBAObjectNonNilEquality(choiceAnswer, leftAnswer) ? self.tintColor : UIColor.lightGray, for: .normal)
        self.rightButton.setTitleColor(SBAObjectNonNilEquality(choiceAnswer, rightAnswer) ? self.tintColor : UIColor.lightGray, for: .normal)
    }
    
    private var answerFormat: ORKTextChoiceAnswerFormat?
    
    private var leftAnswer: Any? {
        return self.answerFormat?.textChoices.first?.value
    }
    
    private var rightAnswer: Any? {
        return self.answerFormat?.textChoices.last?.value
    }
    
    func configure(formItem: ORKFormItem, stepResult: ORKStepResult?) {
        self.questionLabel.text = formItem.text
        
        // Get the initial result
        let initialResult = stepResult?.result(forIdentifier: formItem.identifier)

        // Setup for types that this cell can handle
        if let format = formItem.answerFormat as? ORKTextChoiceAnswerFormat {
            self.answerFormat = format
            self.result = initialResult ?? ORKChoiceQuestionResult(identifier: formItem.identifier)
        }
        else if let _ = formItem.answerFormat as? ORKBooleanAnswerFormat {
            self.answerFormat = ORKAnswerFormat.choiceAnswerFormat(with: .singleChoice, textChoices: [
                ORKTextChoice(text: Localization.buttonYes(), value: NSNumber(value: true)),
                ORKTextChoice(text: Localization.buttonNo(), value: NSNumber(value: false))
                ])
            self.result = initialResult ?? ORKBooleanQuestionResult(identifier: formItem.identifier)
        }
        else {
            assertionFailure("\(formItem.answerFormat) is not supported")
        }
        
        // Set the currently selected answer
        self.choiceAnswer = {
            if let choiceResult = initialResult as? ORKChoiceQuestionResult {
                return choiceResult.choiceAnswers?.first
            }
            else if let boolResult = initialResult as? ORKBooleanQuestionResult {
                return boolResult.booleanAnswer
            }
            return nil
        }()
        
        // Set the button titles
        self.leftButton.setTitle(self.answerFormat?.textChoices.first?.text, for: .normal)
        self.rightButton.setTitle(self.answerFormat?.textChoices.last?.text, for: .normal)
    }
}
