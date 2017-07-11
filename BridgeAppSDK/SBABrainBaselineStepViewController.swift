//
//  SBABrainBaselineStepViewController.swift
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

open class SBABrainBaselineStep: ORKStep {
    
    public dynamic var testName: String!
    
    public init(inputItem: SBASurveyItem) {
        super.init(identifier: inputItem.identifier)
        
        self.title = inputItem.stepTitle
        self.text = inputItem.stepText

        self.testName = {
            let options: [String : AnyObject]? = inputItem.options ?? (inputItem as? [String : AnyObject])
            let key = #keyPath(testName)
            return (options?[key] as? String) ?? self.identifier
        }()
    }
    
    public override init(identifier: String) {
        super.init(identifier: identifier)
        self.testName = identifier
    }
    
    public required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.testName = aDecoder.decodeObject(forKey: #keyPath(testName)) as! String
    }
    
    override open func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder)
        aCoder.encode(self.testName, forKey: #keyPath(testName))
    }
    
    override open func copy(with zone: NSZone? = nil) -> Any {
        let copy = super.copy(with: zone) as! SBABrainBaselineStep
        copy.testName = self.testName
        return copy
    }
    
    override open func isEqual(_ object: Any?) -> Bool {
        guard let castObject = object as? SBABrainBaselineStep else { return false }
        return super.isEqual(object) && SBAObjectEquality(self.testName, castObject.testName)
    }
    
    override open var hash: Int {
        return super.hash ^ SBAObjectHash(self.testName)
    }
    
}

open class SBABrainBaselineStepViewController: ORKStepViewController {
    
    open class var nibName: String {
        return String(describing: SBABrainBaselineStepViewController.self)
    }
    
    open class var bundle: Bundle {
        return Bundle(for: SBABrainBaselineStepViewController.classForCoder())
    }
    
    @IBOutlet open weak var backgroundImageView: UIImageView?
    @IBOutlet open weak var shadowGradient: SBAShadowGradient?
    @IBOutlet open weak var deviceImageView: UIView!
    @IBOutlet open weak var instructionLabel: UILabel!
    
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

    public var startDate: Date?
    
    open var testName: String? {
        return (self.step as? SBABrainBaselineStep)?.testName
    }
    
    private var rotationObserver: NSObjectProtocol?
    
    override open func viewWillAppear(_ animated: Bool) {
        (UIApplication.shared.delegate as? SBAAppDelegate)?.orientationLock = .allButUpsideDown
        super.viewWillAppear(animated)
        
        // Do not allow going back
        self.backButtonItem = UIBarButtonItem()
        self.backgroundImageView?.backgroundColor = UIColor.appBackgroundDark
        self.instructionLabel.textColor = UIColor.appTextLight
        
        if startDate == nil {
            instructionLabel.text = self.step?.text ?? Localization.localizedString("BRAIN_BASELINE_INSTRUCTION_TEXT")
            start()
        }
    }
    
    override open func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Note: syoung 07/11/2017 This method is called *after* the OS sets up to dismiss the view
        // so also need to reset in the scheduled activity manager. (belt + suspenders)
        (UIApplication.shared.delegate as? SBAAppDelegate)?.resetOrientation()
        
        removeRotationObserver()
    }
    
    open func start() {
        
        // If the phone is not already in landscape mode, wait until it is before pushing the Brain Baseline
        // view controller. Otherwise just go for it.
        let orientation = UIDevice.current.orientation;
        if (!(orientation == UIDeviceOrientation.landscapeLeft || orientation == UIDeviceOrientation.landscapeRight)) {
            instructionLabel.text = self.step?.text
            self.rotationObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name.UIDeviceOrientationDidChange, object: nil, queue: OperationQueue.main, using: { (notification) in
                
                // If the new orientation is landscape mode, remove the notification observer and push the Brain
                // Baseline view controller. Otherwise keep waiting.
                let orientation = UIDevice.current.orientation;
                if (orientation == UIDeviceOrientation.landscapeLeft || orientation == UIDeviceOrientation.landscapeRight) {
                    self.removeRotationObserver()
                    self.deviceDidRotate()
                }
            })
        } else {
            self.deviceDidRotate()
        }
    }
    
    private func removeRotationObserver() {
        guard let observer = self.rotationObserver else { return }
        NotificationCenter.default.removeObserver(observer)
        self.rotationObserver = nil
    }
    
    private func deviceDidRotate() {
        self.startDate = Date()
        instructionLabel.text = ""
        deviceImageView.isHidden = true
        guard let viewController = createTestViewController()
        else {
            testDidFinish(result: nil)
            return
        }
        self.show(viewController, sender: self)
    }
    
    open func createTestViewController() -> UIViewController? {
        // Subclass must override to implement methods on private framework.
        assertionFailure("Abstract method")
        return nil
    }
    
    open override func show(_ vc: UIViewController, sender: Any?) {
        addChildViewController(vc)
        vc.view.frame = self.view.bounds
        view.addSubview(vc.view)
        vc.didMove(toParentViewController: self)
    }
    
    open func testDidFinish(result: Any?) {
        if result == nil {
            // If the user quit the brain baseline task then tell the task view controller delegate that
            // the result was discarded.
            self.taskViewController!.delegate?.taskViewController(self.taskViewController!, didFinishWith: .discarded, error: nil)
        }
        else {
            self.goForward()
        }
    }
}

extension SBAUserWrapper {
    
    /**
     Returns a unique identifier associated with this user.
     */
    public func uniqueIdentifier() -> String {
        
        // Look to see if there is a stored answer for a unique identifier that is
        // *not* the hashed email address. If so, return that. This is not defined
        // using a guard statement b/c we want an early exit if and only if the
        // identifier is already defined.
        let uniqueIdentifierUserKey = "uniqueIdentifier"
        if let uuid = self.storedAnswer(for: uniqueIdentifierUserKey) as? String {
            return uuid
        }
        
        // Create a unique identifier by hashing the email address (if available)
        guard let email = self.email, let data = email.data(using: .utf8) as NSData?, let md5 = data.hexMD5()
            else {
                // If the email cannot be hashed to create a unique identifier, then create and store a uuid
                let uuid = UUID().uuidString
                self.setStoredAnswer(uuid, forKey: uniqueIdentifierUserKey)
                return uuid
        }
        
        // If the md5 was created then return that
        return md5
    }
}

