//
//  StudyOverviewViewController.swift
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
import BridgeAppSDK

class StudyOverviewViewController: UIViewController, ORKTaskViewControllerDelegate, SBASharedInfoController {
    
    // MARK: SBASharedInfoController
    
    lazy var sharedAppDelegate: SBAAppInfoDelegate = {
        return UIApplication.shared.delegate as! SBAAppInfoDelegate
    }()
    
    // MARK: actions

    @IBAction func signUpTapped(_ sender: AnyObject) {
        SBAAppDelegate.shared?.presentOnboarding(for: .registration)
    }
    
    @IBAction func loginTapped(_ sender: AnyObject) {
        SBAAppDelegate.shared?.presentOnboarding(for: .login)
    }
    
    @IBAction func externalIDTapped(_ sender: AnyObject) {
        
        // TODO: syoung 06/09/2016 Implement consent and use onboarding manager for external ID
        // Add consent signature.
        let appDelegate = UIApplication.shared.delegate as! SBABridgeAppSDKDelegate
        appDelegate.currentUser.consentSignature = SBAConsentSignature(identifier: "signature")
        
        // Create a task with an external ID and permissions steps and display the view controller
        let externalIDStep = SBAExternalIDStep(identifier: "externalID")
        let permissonsStep = SBAPermissionsStep(identifier: "permissions")
        let task = ORKOrderedTask(identifier: "registration", steps: [externalIDStep, permissonsStep])
        let vc = SBATaskViewController(task: task, taskRun: nil)
        vc.delegate = self
        self.present(vc, animated: true, completion: nil)
    }
    
    // MARK: ORKTaskViewControllerDelegate
    
    func taskViewController(_ taskViewController: ORKTaskViewController, didFinishWith reason: ORKTaskViewControllerFinishReason, error: Error?) {
        taskViewController.dismiss(animated: true) { 
            if (reason == .completed), let appDelegate = UIApplication.shared.delegate as? SBAAppDelegate {
                // If complete, then show the appropriate view controller
                appDelegate.showAppropriateViewController(animated: false)
            }
            else {
                // Discard the registration information that has been gathered so far
                self.sharedUser.resetStoredUserData()
            }
        }
    }
}
