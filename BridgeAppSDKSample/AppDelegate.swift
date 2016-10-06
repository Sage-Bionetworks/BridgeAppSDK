//
//  AppDelegate.swift
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

@UIApplicationMain
class AppDelegate: SBAAppDelegate, ORKTaskViewControllerDelegate {
    
    override var requiredPermissions: SBAPermissionsType {
        return [.coremotion, .localNotifications, .microphone]
    }
    
    override func showMainViewController(animated: Bool) {
        guard let storyboard = openStoryboard("Main"),
            let vc = storyboard.instantiateInitialViewController()
            else {
                assertionFailure("Failed to load main storyboard")
                return
        }
        self.transition(toRootViewController: vc, animated: animated)
    }
    
    override func showEmailVerificationViewController(animated: Bool) {
        let onboardingManager = SBAOnboardingManager(jsonNamed: "Onboarding")!
        let vc = onboardingManager.initializeTaskViewController(onboardingTaskType: .registration)!
        
        vc.delegate = self
        self.transition(toRootViewController: vc, animated: animated)
    }
    
    override func showOnboardingViewController(animated: Bool) {
        guard let storyboard = openStoryboard("Onboarding"),
            let vc = storyboard.instantiateInitialViewController()
            else {
                assertionFailure("Failed to load onboarding storyboard")
                return
        }
        self.transition(toRootViewController: vc, animated: animated)
    }
    
    func openStoryboard(_ name: String) -> UIStoryboard? {
        return UIStoryboard(name: name, bundle: nil)
    }
    
    // MARK: ORKTaskViewControllerDelegate
    
    func taskViewController(_ taskViewController: ORKTaskViewController, didFinishWith reason: ORKTaskViewControllerFinishReason, error: Error?) {

        // Discard the registration information that has been gathered so far if not completed
        if (reason != .completed) {
            self.currentUser.resetStoredUserData()
        }
        
        // Show the appropriate view controller
        showAppropriateViewController(false)
    }

}
