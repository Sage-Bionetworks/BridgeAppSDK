//
//  SBATaskViewController.swift
//  BridgeAppSDK
//
//  Created by Shannon Young on 8/25/16.
//  Copyright © 2016 Sage Bionetworks. All rights reserved.
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
