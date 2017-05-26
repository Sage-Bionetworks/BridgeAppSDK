//
//  SBASinglePermissionStepViewController.swift
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


open class SBASinglePermissionStepViewController: ORKStepViewController {
    
    @IBOutlet open weak var shadowGradient: SBAShadowGradient?
    @IBOutlet open weak var imageView: UIImageView?
    @IBOutlet open weak var textLabel: UILabel?
    @IBOutlet open weak var detailLabel: UILabel?
    @IBOutlet open weak var continueButton: SBARoundedButton?
    
    public var permissionStep : SBASinglePermissionStep? {
        return self.step as? SBASinglePermissionStep
    }
    
    open class var nibName: String {
        return String(describing: SBASinglePermissionStepViewController.self)
    }
    
    open class var nibBundle: Bundle {
        return Bundle(for: SBASinglePermissionStepViewController.classForCoder())
    }
    
    override public init(step: ORKStep?) {
        super.init(nibName: type(of: self).nibName, bundle: type(of: self).nibBundle)
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

        // Do any additional setup after loading the view.
        self.view.backgroundColor = UIColor.appBackgroundDark
        self.textLabel?.textColor = UIColor.appTextLight
        self.detailLabel?.textColor = UIColor.appTextLight
        self.continueButton?.shadowColor = UIColor.roundedButtonBackgroundLight
        self.continueButton?.shadowColor = UIColor.roundedButtonShadowLight
        self.continueButton?.titleColor = UIColor.roundedButtonTextDark
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Set the title
        self.title = self.step?.title
        
        // Update the displayed information for the step
        self.textLabel?.text = self.permissionStep?.text
        self.detailLabel?.text = self.permissionStep?.detailText ?? self.permissionStep?.permissionType.detail
        if let buttonText = self.permissionStep?.buttonTitle {
            self.continueButton?.setTitle(buttonText, for: .normal)
        }
        if let image = self.permissionStep?.image ?? self.permissionStep?.iconImage {
            self.imageView?.image = image
        }
        self.view.setNeedsLayout()
    }

    var permissionsGranted: Bool = false
    
    override open var result: ORKStepResult? {
        guard let result = super.result else { return nil }
        
        // Add a result for whether or not the permissions were granted
        let grantedResult = ORKBooleanQuestionResult(identifier: result.identifier)
        grantedResult.booleanAnswer = NSNumber(value: permissionsGranted)
        result.results = [grantedResult]
        
        return result
    }
    
    @IBAction func continueButtonTapped(_ sender: Any) {
        self.goForward()
    }
    
    override open func goForward() {
        guard let permissionStep = self.permissionStep else {
            assertionFailure("Step is not of expected type")
            super.goForward()
            return
        }
        
        SBAPermissionsManager.shared.requestPermissions(for: [permissionStep.permissionType], alertPresenter: self) { [weak self] (granted) in
            if granted || permissionStep.isOptional {
                self?.permissionsGranted = granted
                self?.goNext()
            }
            else if let strongSelf = self, let strongDelegate = strongSelf.delegate {
                let error = NSError(domain: "SBAPermissionsStepDomain", code: 1, userInfo: nil)
                strongDelegate.stepViewControllerDidFail(strongSelf, withError: error)
            }
        }
    }
    
    override open func skipForward() {
        goNext()
    }
    
    fileprivate func goNext() {
        super.goForward()
    }
}
