//
//  SBAGenericPageStepViewController.swift
//  ResearchUXFactory
//
//  Created by Josh Bruhin on 6/13/17.
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

class SBAGenericPageStepViewController: ORKPageStepViewController, UIPageViewControllerDelegate {
    
    override func stepViewController(for step: ORKStep) -> ORKStepViewController {
        
        // return our Generic Step VC
        let stepVC = SBAGenericStepViewController(step: step, result: nil)
        
        if let pageStep = self.step as? ORKPageStep {
            
            // set progress on the view
            stepVC.stepCount = pageStep.steps.count
            stepVC.stepIndex = pageStep.steps.index(of: step)! + 1
        }
        
        return stepVC
        
    }
    
    // TODO: Josh Bruhin, 6-13-17 - find a way to optionally remove the leftBarButtonItem.
    // Our configuration has an option to show our back button in the navigationView instead of the
    // navigationBar. Normally, this is done at the SBAGenericStepViewController level, but when a
    // pageViewController is being used - like for consent - it's done at that level. So, we need to
    // be able to check our configuration and optionally remove the leftBarButtonItem.
    
    // Problem is, super sets the leftBarButtonItem in the completion block of its pageViewController.setViewControllers()
    // method, which fires after all the potential overridable methods we have. This also fires after the
    // viewWillAppear() method of the stepVC for each scene, which is too bad because we could do it
    // there, too. We could just override super's goToStep() method, but there's a fair bit of functionality
    // there using some stuff we don't have access to.
}
