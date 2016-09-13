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
    func attachTaskViewController(taskViewController: SBATaskViewController)
}

public class SBATaskViewController: ORKTaskViewController {
    
    /**
     * A strongly held reference to a delegate or result source that is used by the
     * associated view controller. If used, the strongly held reference should ONLY
     * hold a weak reference to this view controller or else this will result in a 
     * retain loop. Please excercise caution when using this reference.
     */
    var strongReference: SBATaskViewControllerStrongReference?

    /**
     Pointer to the guid for tracking this task via `SBBScheduledActivity`
     */
    public var scheduledActivityGUID: String?
    
    /**
     Date indicating when the task was finished (verse when the completion handler will fire)
     */
    public var finishedOn: NSDate? {
        return _finishedOn
    }
    private var _finishedOn: NSDate?
    
    public override var outputDirectory: NSURL? {
        get {
            if let superDirectory = super.outputDirectory {
                return superDirectory
            }
            
            let paths = NSSearchPathForDirectoriesInDomains(.ApplicationSupportDirectory, .UserDomainMask, true)
            let path = (paths.last! as NSString).stringByAppendingPathComponent(self.taskRunUUID.UUIDString)
            if !NSFileManager.defaultManager().fileExistsAtPath(path) {
                do {
                    try NSFileManager.defaultManager().createDirectoryAtPath(path, withIntermediateDirectories: true, attributes: [ NSFileProtectionKey : NSFileProtectionCompleteUntilFirstUserAuthentication ])
                } catch let error as NSError {
                    print ("Error creating file: \(error)")
                }
            }
            
            let outputDirectory = NSURL(fileURLWithPath: path, isDirectory: true)
            super.outputDirectory = outputDirectory
            
            return outputDirectory
        }
        set {
            super.outputDirectory = newValue
        }
    }
    
    public override func stepViewControllerWillAppear(stepViewController: ORKStepViewController) {
        super.stepViewControllerWillAppear(stepViewController)
        guard let step = stepViewController.step else { return }
        
        let isCompletionStep: Bool = {
            if let directStep = step as? SBAInstructionStep {
                return directStep.isCompletionStep
            }
            return step is ORKCompletionStep
        }()

        if isCompletionStep {
            _finishedOn = NSDate()
            stepViewController.view.tintColor = UIColor.greenTintColor()
        }
        else if step is ORKAudioStep {
            stepViewController.view.tintColor = UIColor.blueTintColor()
        }
    }

    // MARK: Initializers
    
    public override init(task: ORKTask?, taskRunUUID: NSUUID?) {
        super.init(task: task, taskRunUUID: taskRunUUID)
    }
    
    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    // MARK: NSCoding
    
    public required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.scheduledActivityGUID = aDecoder.decodeObjectForKey("scheduledActivityGUID") as? String
        self.strongReference = aDecoder.decodeObjectForKey("strongReference") as? SBATaskViewControllerStrongReference
        self.strongReference?.attachTaskViewController(self)
    }
    
    public override func encodeWithCoder(aCoder: NSCoder) {
        super.encodeWithCoder(aCoder)
        aCoder.encodeObject(self.scheduledActivityGUID, forKey: "scheduledActivityGUID")
        aCoder.encodeObject(self.strongReference, forKey: "strongReference")
    }
}
