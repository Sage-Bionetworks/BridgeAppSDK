//
//  SBAInstructionStepViewController.swift
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

open class SBABaseInstructionStepViewController: ORKStepViewController {
    
    @IBOutlet public weak var imageView: UIImageView?
    @IBOutlet public weak var belowImageView: UIImageView?
    @IBOutlet weak var imageSize: NSLayoutConstraint?
    @IBOutlet weak var belowImageSize: NSLayoutConstraint?
    
    @IBOutlet public weak var titleLabel: UILabel?
    @IBOutlet public weak var textLabel: UILabel?
    @IBOutlet public weak var learnMoreButton: UIButton?
    
    @IBOutlet public weak var backButton: SBARoundedButton?
    @IBOutlet public weak var nextButton: SBARoundedButton?
    
    var sbaIntructionStep: SBAInstructionStep? {
        return self.step as? SBAInstructionStep
    }
    
    public var instructionStep: ORKInstructionStep? {
        return self.step as? ORKInstructionStep
    }
    
    open var image: UIImage? {
        return (self.instructionStep?.image ?? self.instructionStep?.iconImage)
    }
    
    override open var learnMoreButtonTitle: String? {
        get {
            return sbaIntructionStep?.learnMoreAction?.learnMoreButtonText ?? super.learnMoreButtonTitle
        }
        set {
            super.learnMoreButtonTitle = newValue
        }
    }
    
    open var fullText: String {
        // Text (detail is same size and color according to current design)
        var text = self.step?.text ?? ""
        if let detail = self.instructionStep?.detailText {
            text.append("\n\n\(detail)")
        }
        return text
    }
    
    open var nextTitle: String {
        return self.sbaIntructionStep?.continueButtonTitle ?? self.continueButtonTitle ?? 
            (self.hasNextStep() ? Localization.buttonNext() : Localization.buttonDone())
    }
    
    // MARK: Navigation
    
    open func hasLearnMore() -> Bool {
        if (self.sbaIntructionStep?.learnMoreAction != nil) {
            return true
        }
        guard let taskViewController = self.taskViewController, let step = self.step else { return false }
        return taskViewController.delegate?.taskViewController?(taskViewController, hasLearnMoreFor: step) ?? false
    }
    
    @IBAction open func learnMoreTapped(_ sender: Any) {
        guard let taskViewController = self.taskViewController else { return }
        taskViewController.delegate?.taskViewController?(taskViewController, learnMoreForStep: self)
    }
    
    @IBAction func backTapped(_ sender: Any) {
        self.goBackward()
    }
    
    @IBAction func nextTapped(_ sender: Any) {
        self.goForward()
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.setupNavigation()
        
        self.setupImageView()
        self.setupTitle()
        self.setupLearnMore()

        // Text (detail is same size and color according to current design)
        self.textLabel?.text = fullText
    }
    
    open func setupTitle() {
        if let title = self.step?.title {
            self.titleLabel?.text = title
        }
        else {
            self.titleLabel?.isHidden = true
        }
    }
    
    open func shouldShowImageBelow() -> Bool {
        // TODO: syoung 06/08/2017 Make the model/UX handling more consistent and not reliant upon
        // special-casing by checking for class inheritance.
        return (self.belowImageView != nil) && ((self.step is SBAInstructionBelowImageStep) || (self.imageView == nil))
    }
    
    open func setupImageView() {
        if let image = self.image {
            
            // setup the image
            var imageConstraint: NSLayoutConstraint?
            if shouldShowImageBelow() {
                self.belowImageView?.image = image
                self.imageView?.removeFromSuperview()
                imageConstraint = self.belowImageSize
            }
            else {
                self.imageView?.image = image
                self.belowImageView?.removeFromSuperview()
                imageConstraint = self.imageSize
            }
            
            // Resize the image to never stretch the image (only shrink if needed)
            let imageSize = max(image.size.width, image.size.height)
            if let constraint = imageConstraint {
                constraint.constant = min(imageSize, constraint.constant)
            }
        }
        else {
            self.imageView?.removeFromSuperview()
            self.belowImageView?.removeFromSuperview()
        }
    }
    
    open func setupLearnMore() {
        // Learn More
        self.learnMoreButton?.isHidden = !self.hasLearnMore()
        let learnMoreTitle = self.learnMoreButtonTitle ?? Localization.localizedString("BUTTON_LEARN_MORE")
        self.learnMoreButton?.setTitle(learnMoreTitle, for: .normal)
    }
    
    open func setupNavigation() {
        
        if self.backButton != nil {
            // TODO: Add the back button once there is a consistent UI for displaying the step views
            // that does not include most views inheriting from ResearchKit.  syoung 06/06/2017
            self.backButtonItem = UIBarButtonItem()
            if self.hasPreviousStep() {
                self.backButton!.setTitle(Localization.localizedString("BUTTON_BACK"), for: .normal)
            }
            else if self.backButton?.superview != nil {
                self.backButton!.removeFromSuperview()
            }
        }
        
        // Set the title for the next button
        self.nextButton?.setTitle(nextTitle, for: .normal)
    }
}

open class SBAInstructionStepViewController: SBABaseInstructionStepViewController, UIScrollViewDelegate {
    
    open class var nibName: String {
        return String(describing: SBAInstructionStepViewController.self)
    }
    
    open class var bundle: Bundle {
        return Bundle(for: SBAInstructionStepViewController.classForCoder())
    }
    
    @IBOutlet public weak var scrollView: UIScrollView!
    
    @IBOutlet public weak var progressHeader: UIView?
    @IBOutlet public weak var progressBar: SBAProgressView?
    @IBOutlet public weak var progressLabel: UILabel?
    
    @IBOutlet public weak var footerView: UIView?

    open var stepNumber: UInt = 1 {
        didSet {
            didSetStepNumber()
        }
    }
    private func didSetStepNumber() {
        progressBar?.stepNumber = stepNumber
    }
    
    open var stepTotal: UInt = 0 {
        didSet {
            didSetStepTotal()
        }
    }
    private func didSetStepTotal() {
        progressHeader?.isHidden = (stepTotal == 0)
        progressBar?.stepTotal = stepTotal
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
    
    open override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = UIColor.appBackgroundLight
        self.scrollView.backgroundColor = UIColor.appBackgroundLight
        self.progressHeader?.backgroundColor = UIColor.clear
        self.footerView?.backgroundColor = UIColor.appBackgroundLight
        
        progressLabel?.textColor = UIColor.appTextDark
        titleLabel?.textColor = UIColor.appTextDark
        textLabel?.textColor = UIColor.appTextDark
        
        if let underlineButton = learnMoreButton as? SBAUnderlinedButton {
            underlineButton.textColor = UIColor.underlinedButtonTextDark
        }
        
        backButton?.backgroundColor = UIColor.roundedButtonBackgroundDark
        backButton?.shadowColor = UIColor.roundedButtonShadowDark
        backButton?.titleColor = UIColor.roundedButtonTextLight
        backButton?.corners = 26.0
        
        nextButton?.backgroundColor = UIColor.roundedButtonBackgroundDark
        nextButton?.shadowColor = UIColor.roundedButtonShadowDark
        nextButton?.titleColor = UIColor.roundedButtonTextLight
        nextButton?.corners = 26.0
        
        // Set the step number and total now that the view is loaded
        didSetStepNumber()
        didSetStepTotal()
        
        // Set up the image tint
        if let tintedImageView = self.imageView as? ORKTintedImageView {
            tintedImageView.shouldApplyTint = true
        }
    }
    
    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.updateShadows()
    }

    // MARK: Add shadows to scroll content "under" the footer
    
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
    
    open func calculateContainerBottom() -> CGFloat {
        let learnMoreHidden = (self.learnMoreButton?.superview == nil) || (self.learnMoreButton?.isHidden ?? true)
        let belowImageHidden = (self.belowImageView?.superview == nil) || (self.belowImageView?.isHidden ?? true)
        if !belowImageHidden {
            return self.belowImageView!.frame.maxY
        }
        else if !learnMoreHidden {
            return self.learnMoreButton!.frame.maxY
        }
        else {
            return self.textLabel?.frame.maxY ?? 0
        }
    }
    
    open func updateShadows() {
        let yBottom = scrollView.contentSize.height - scrollView.bounds.size.height - scrollView.contentOffset.y
        let containerBottom = calculateContainerBottom()
        let hasShadow = (yBottom >= (scrollView.contentSize.height - containerBottom))
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
