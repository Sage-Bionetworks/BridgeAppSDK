//
//  SBAActivityInstructionStepViewController.swift
//  BridgeAppSDK
//
//  Copyright © 2017 Sage Bionetworks. All rights reserved.
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

public protocol SBAInstructionTextProvider: class {
    var instructionText: String? { get }
}

extension ORKInstructionStep: SBAInstructionTextProvider {
    
    open var instructionText: String? {
        var text = self.text ?? ""
        if let detail = self.detailText {
            if text.characters.count > 0 {
                text.append("\n\n")
            }
            text.append(detail)
        }
        return text
    }
}

open class SBAActivityInstructionResult: ORKChoiceQuestionResult {
    static let endSurveyChoice = "end"
    
    override public init() {
        super.init()
    }
    
    override public init(identifier: String) {
        super.init(identifier: identifier)
        self.choiceAnswers = [SBAActivityInstructionResult.endSurveyChoice]
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public var didEndSurvey: Bool {
        guard let choice = self.choiceAnswers?.first as? String else { return false }
        return choice == SBAActivityInstructionResult.endSurveyChoice
    }
}

open class SBAActivityInstructionStepViewController: ORKStepViewController, UITextViewDelegate {
    
    open class var nibName: String {
        return String(describing: SBAActivityInstructionStepViewController.self)
    }
    
    open class var bundle: Bundle {
        return Bundle(for: SBAActivityInstructionStepViewController.classForCoder())
    }
    
    @IBOutlet public var headerView: UIView?
    @IBOutlet public var titleLabel: UILabel?
    @IBOutlet public var subtitleLabel: UILabel?
    @IBOutlet public var iconImageView: UIImageView?
    
    @IBOutlet public var textView: UITextView?
    
    @IBOutlet public var footerView: UIView?
    @IBOutlet public var startButton: SBARoundedButton?
    @IBOutlet public var cancelButton: SBAUnderlinedButton?
    
    open var textColor: UIColor = UIColor.appTextDark
    
    public var schedule: SBBScheduledActivity!
    public var taskReference: SBATaskReference!
    
    open var instructionText: String? {
        guard let provider = self.step as? SBAInstructionTextProvider else { return nil }
        return provider.instructionText ?? self.step?.text
    }
    
    override public init(step: ORKStep?) {
        super.init(nibName: type(of: self).nibName, bundle: type(of: self).bundle)
        self.step = step
    }
    
    override public convenience init(step: ORKStep, result: ORKResult) {
        self.init(step: step)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()

        self.headerView?.backgroundColor = UIColor.appBackgroundDark
        self.titleLabel?.textColor = UIColor.appTextLight
        self.subtitleLabel?.textColor = UIColor.appTextLight
    
        self.view.backgroundColor = UIColor.appBackgroundLight
        self.textView?.backgroundColor = UIColor.clear
        self.footerView?.backgroundColor = UIColor.appBackgroundLight
        
        self.startButton?.shadowColor = UIColor.roundedButtonBackgroundDark
        self.startButton?.shadowColor = UIColor.roundedButtonShadowDark
        self.startButton?.titleColor = UIColor.roundedButtonTextLight
        
        self.cancelButton?.textColor = UIColor.underlinedButtonTextDark
        
        self.textView?.textColor = UIColor.appTextDark
        self.textView?.textContainerInset = UIEdgeInsets(top: 39, left: 43, bottom: 20, right: 43)
        
        // for iPad, increase text font sizes by 50%
        if UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad {
            if let titleFont = self.titleLabel?.font {
                self.titleLabel!.font = titleFont.withSize(titleFont.pointSize * 1.5)
            }
            if let subtitleFont = self.subtitleLabel?.font {
                self.subtitleLabel!.font = subtitleFont.withSize(subtitleFont.pointSize * 1.5)
            }
            if let textFont = self.textView?.font {
                self.textView!.font = textFont.withSize(textFont.pointSize * 1.5)
            }
        }
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Schedule and step should both be set before showing the view controller
        titleLabel?.text = schedule.activity.label
        subtitleLabel?.text = schedule.activity.labelDetail
        iconImageView?.image = taskReference.activityIcon
        
        // Set up the step text
        self.textView?.text = self.instructionText
    }
    
    override open var result: ORKStepResult? {
        guard let stepResult = super.result else { return nil }
        if _endSurveyResult != nil {
            stepResult.addResult(_endSurveyResult!)
        }
        return stepResult
    }
    private var _endSurveyResult:ORKChoiceQuestionResult?
    
    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.updateShadows()
    }
    
    @IBAction public func startTapped() {
        self.goForward()
    }
    
    @IBAction public func cancelTapped() {
        
        // Exit early if the step has a navigation rule for continuing
        if let navStep = self.step as? SBASurveyNavigationStep, (navStep.rules?.count ?? 0) > 0 {
            _endSurveyResult = SBAActivityInstructionResult(identifier: self.step!.identifier)
            self.goForward()
            return
        }
        
        // Otherwise, the default behavior is to discard the results
        guard let taskViewController = self.taskViewController, let taskDelegate = taskViewController.delegate else {
            dismiss(animated: true, completion: nil)
            return
        }
        taskDelegate.taskViewController(taskViewController, didFinishWith: .discarded, error: nil)
    }
    
    
    // MARK: Add shadows to scroll content "under" the header and footer

    open func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateShadows()
    }

    open func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            updateShadows()
        }
    }

    open func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        updateShadows()
    }
    
    open func updateShadows() {
        guard let scrollView = self.textView else { return }
        let yBottom = scrollView.contentSize.height - scrollView.bounds.size.height - scrollView.contentOffset.y
        let hasShadow = (yBottom >= scrollView.textContainerInset.bottom)
        guard hasShadow != shouldShowFooterShadow else { return }
        shouldShowFooterShadow = hasShadow
    }
    
    private var shouldShowFooterShadow: Bool = false {
        didSet {
            if shouldShowFooterShadow {
                footerView?.layer.shadowOffset = CGSize(width: 0, height: 1)
                footerView?.layer.shadowRadius = 3.0
                footerView?.layer.shadowColor = UIColor.black.cgColor
                footerView?.layer.shadowOpacity = 0.8
            }
            else {
                footerView?.layer.shadowOpacity = 0.0
            }
        }
    }
}
