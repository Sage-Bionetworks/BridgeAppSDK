//
//  SBATaskViewController.swift
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

protocol SBATaskViewControllerStrongReference: class, NSSecureCoding {
    func attachTaskViewController(_ taskViewController: SBATaskViewController)
}

open class SBATaskViewController: ORKTaskViewController, SBASharedInfoController, ORKTaskViewControllerDelegate, ORKTaskResultSource {
    
    /**
     A strongly held reference to a delegate or result source that is used by the
     associated view controller. If used, the strongly held reference should ONLY
     hold a weak reference to this view controller or else this will result in a
     retain loop. Please excercise caution when using this reference.
     */
    var strongReference: SBATaskViewControllerStrongReference?
    
    /**
     A completion handler that can be called instead of using the delegate pattern.
    */
    public var finishTaskHandler: ((ORKTaskViewController, ORKTaskViewControllerFinishReason, Error?) -> Void)?

    /**
     Pointer to the scheduleIdentifier for tracking this task via `SBBScheduledActivity`
     */
    open var scheduleIdentifier: String?
    
    /**
     A localized string that represents the title of the Continue button.
     
     Most steps display a button that enables forward navigation. This button can have titles
     such as Next, Continue, or Done. Use this property to override the forward navigation
     button title for the step.
     */
    open var continueButtonText: String?
    
    /**
     Date indicating when the task was finished (verse when the completion handler will fire)
     */
    open var finishedOn: Date? {
        return _finishedOn
    }
    fileprivate var _finishedOn: Date?
    
    /**
     A flag that can be used to mark results as having already been uploaded.
    */
    open var hasUploadedResults: Bool = false
    
    open override var outputDirectory: URL? {
        get {
            if let superDirectory = super.outputDirectory {
                return superDirectory
            }
            
            let paths = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true)
            let path = (paths.last! as NSString).appendingPathComponent(self.taskRunUUID.uuidString)
            if !FileManager.default.fileExists(atPath: path) {
                do {
                    try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: [ FileAttributeKey.protectionKey.rawValue : FileProtectionType.completeUntilFirstUserAuthentication ])
                } catch let error as NSError {
                    print ("Error creating file: \(error)")
                }
            }
            
            let outputDirectory = URL(fileURLWithPath: path, isDirectory: true)
            super.outputDirectory = outputDirectory
            
            return outputDirectory
        }
        set {
            super.outputDirectory = newValue
        }
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        // Internally, ORKTaskViewController calls _defaultResultSource and *not*
        // self.defaultResultSource as one might (and did) assume, so the overridden 
        // property never gets called. syoung 09/30/2016
        super.defaultResultSource = self
    }
    
    open override func stepViewControllerWillAppear(_ stepViewController: ORKStepViewController) {
        updateStepViewController(stepViewController)
        super.stepViewControllerWillAppear(stepViewController)
    }
    
    /**
     Handle various customizations of the step view controller BEFORE calling `stepViewControllerWillAppear`
     on the delegate.
    */
    open func updateStepViewController(_ stepViewController: ORKStepViewController) {
        guard let step = stepViewController.step else { return }
        
        // If this is a learn more step then set the button title
        if let learnMoreStep = stepViewController.step as? SBAInstructionStep,
            let learnMore = learnMoreStep.learnMoreAction {
            stepViewController.learnMoreButtonTitle = learnMore.learnMoreButtonText
        }
        
        // If this is a completion step then mark the finsihed on date
        // as NOW (instead of when this step is dismissed)
        let isCompletionStep: Bool = {
            if let directStep = step as? SBAInstructionStep {
                return directStep.isCompletionStep
            }
            return step is ORKCompletionStep
        }()
        if isCompletionStep {
            _finishedOn = Date()
        }
        
        // If this is an ORKCompletionStepViewController then set the tint color for the 
        // checkmark and the default Done button placement.
        if let completionVC = stepViewController as? ORKCompletionStepViewController {
            completionVC.checkmarkColor = UIColor.greenTintColor()
            completionVC.shouldShowContinueButton = true
        }
        
        // If this is an audio step then change the tint color to blue
        if step is ORKAudioStep {
            stepViewController.view.tintColor = UIColor.blueTintColor()
        }
        
        // If there is a continue button text that should be used for all steps, then
        // set that here.
        if continueButtonText != nil {
            stepViewController.continueButtonTitle = continueButtonText
        }
    }

    // MARK: Initializers
    
    public override init(task: ORKTask?, taskRun taskRunUUID: UUID?) {
        super.init(task: task, taskRun: taskRunUUID)
    }
    
    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    // MARK: SBASharedInfoController
    
    lazy public var sharedAppDelegate: SBAAppInfoDelegate = {
        return UIApplication.shared.delegate as! SBAAppInfoDelegate
    }()
    
    // MARK: NSCoding
    
    public required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.scheduleIdentifier = aDecoder.decodeObject(forKey: "scheduleIdentifier") as? String
        self.strongReference = aDecoder.decodeObject(forKey: "strongReference") as? SBATaskViewControllerStrongReference
        self.strongReference?.attachTaskViewController(self)
    }
    
    open override func encode(with aCoder: NSCoder){
        super.encode(with: aCoder)
        aCoder.encode(self.scheduleIdentifier, forKey: "scheduleIdentifier")
        aCoder.encode(self.strongReference, forKey: "strongReference")
    }
    
    // MARK: ORKTaskResultSource
    
    // syoung 09/30/2016 Override the result source so that this task view controller can forward results
    // from either the task or an external result source.
    private var _internalResultSource: ORKTaskResultSource?
    override open var defaultResultSource: ORKTaskResultSource? {
        get {
            return self
        }
        set {
            _internalResultSource = newValue
        }
    }
    
    public func stepResult(forStepIdentifier stepIdentifier: String) -> ORKStepResult? {
        // Look first to the internal result source and if it returns a value, use that
        if let result = _internalResultSource?.stepResult(forStepIdentifier: stepIdentifier) {
            return result
        }
        // Next look at the task and check if it has a result associated with the step
        else if let result = (self.task as? ORKTaskResultSource)?.stepResult(forStepIdentifier: stepIdentifier) {
            return result
        }
        // Finally, look at the step and special-case certain steps
        else if let step = self.task?.step?(withIdentifier: stepIdentifier) {
            // Special-case the data groups step
            if let result = (step as? SBADataGroupsStep)?.stepResult(currentGroups: sharedUser.dataGroups) {
                return result
            }
        }
        return nil
    }
    
    // MARK: ORKTaskViewControllerDelegate
    
    // syoung 09/19/2016 Override the delegate so that this task view controller can catch the learn more
    // action and respond to it. This allows implementation of learn more (which is restricted by ResearchKit)
    // while still allowing a delegate pattern for implementation of other functionality.
    private var _internalDelegate: ORKTaskViewControllerDelegate?
    override open var delegate: ORKTaskViewControllerDelegate? {
        get {
            return self
        }
        set {
            _internalDelegate = newValue
        }
    }

    open func taskViewController(_ taskViewController: ORKTaskViewController, didFinishWith reason: ORKTaskViewControllerFinishReason, error: Error?) {
        if _internalDelegate != nil {
            _internalDelegate!.taskViewController(taskViewController, didFinishWith: reason, error: error)
        }
        else if finishTaskHandler != nil {
            finishTaskHandler?(taskViewController, reason, error)
        }
        else {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    open func taskViewController(_ taskViewController: ORKTaskViewController, recorder: ORKRecorder, didFailWithError error: Error) {
        _internalDelegate?.taskViewController?(taskViewController, recorder: recorder, didFailWithError: error)
    }
    
    open func taskViewControllerSupportsSaveAndRestore(_ taskViewController: ORKTaskViewController) -> Bool {
        return _internalDelegate?.taskViewControllerSupportsSaveAndRestore?(taskViewController) ?? false
    }
    
    open func taskViewControllerShouldConfirmCancel(_ taskViewController: ORKTaskViewController) -> Bool {
        return _internalDelegate?.taskViewControllerShouldConfirmCancel?(taskViewController) ?? true
    }
    
    open func taskViewController(_ taskViewController: ORKTaskViewController, hasLearnMoreFor step: ORKStep) -> Bool {
        if let hasLearnMore = _internalDelegate?.taskViewController?(taskViewController, hasLearnMoreFor: step), hasLearnMore {
            // If the delegate has a learn more for this step then fallback to that
            return true
        }
        else if let learnMoreStep = step as? SBALearnMoreActionStep, learnMoreStep.learnMoreAction != nil {
            return true
        }
        return false
    }
    
    open func taskViewController(_ taskViewController: ORKTaskViewController, learnMoreForStep stepViewController: ORKStepViewController) {
        // Call internal delegate method
        _internalDelegate?.taskViewController?(taskViewController, learnMoreForStep: stepViewController)
        
        // If there is a learnmore action, then call it
        guard let learnMoreStep = stepViewController.step as? SBALearnMoreActionStep,
            let learnMore = learnMoreStep.learnMoreAction else {
                return
        }
        learnMore.learnMoreAction(for: learnMoreStep, with: taskViewController)
    }
    
    open func taskViewController(_ taskViewController: ORKTaskViewController, viewControllerFor step: ORKStep) -> ORKStepViewController? {
        return _internalDelegate?.taskViewController?(taskViewController, viewControllerFor: step)
    }
    
    open func taskViewController(_ taskViewController: ORKTaskViewController, shouldPresent step: ORKStep) -> Bool {
        return _internalDelegate?.taskViewController?(taskViewController, shouldPresent: step) ?? true
    }
    
    open func taskViewController(_ taskViewController: ORKTaskViewController, stepViewControllerWillAppear stepViewController: ORKStepViewController) {
        _internalDelegate?.taskViewController?(taskViewController, stepViewControllerWillAppear: stepViewController)
    }
    
    open func taskViewController(_ taskViewController: ORKTaskViewController, stepViewControllerWillDisappear stepViewController: ORKStepViewController, navigationDirection direction: ORKStepViewControllerNavigationDirection) {
        _internalDelegate?.taskViewController?(taskViewController, stepViewControllerWillDisappear: stepViewController, navigationDirection: direction)
    }
    
    open func taskViewController(_ taskViewController: ORKTaskViewController, didChange result: ORKTaskResult) {
        _internalDelegate?.taskViewController?(taskViewController, didChange: result)
    }
    
}
