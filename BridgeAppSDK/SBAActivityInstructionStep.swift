//
//  SBAActivityInstructionStep.swift
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

open class SBAActivityInstructionStep: SBANavigationQuestionStep {
    
    public var schedule: SBBScheduledActivity!
    public var taskReference: SBATaskReference!
    
    override open func stepViewControllerClass() -> AnyClass {
        return SBAActivityInstructionStepViewController.self
    }
    
    override open func instantiateStepViewController(with result: ORKResult) -> ORKStepViewController {
        let vc = super.instantiateStepViewController(with: result)
        guard let activityVC = vc as? SBAActivityInstructionStepViewController else { return vc }
        activityVC.schedule = self.schedule
        activityVC.taskReference = self.taskReference
        return vc
    }
    
    open override func copy(with zone: NSZone?) -> Any {
        let copy = super.copy(with: zone) as! SBAActivityInstructionStep
        copy.schedule = self.schedule
        copy.taskReference = self.taskReference
        return copy
    }
}

extension SBAActivityInstructionStep: SBAInstructionTextProvider {
    
    open var instructionText: String? {
        // `SBBSurveyQuestion` objects have `prompt` and `promptDetail` fields whereas
        // `ORKQuestionStep` objects have `title` and `text` fields, BUT the `SBBSurveyInfoScreen`
        // type has `title`, `prompt`, and `promptDetail`. Because of this, if an `SBBSurveyQuestion`
        // has both a prompt and a promptDetail, then those values are mapped into title and text.
        // Because this is an instruction step but can have navigation defined for the "I can't do this right now"
        // button, we need to accomidate the structure of the `SBBSurveyQuestion` but map the title
        // to the text field and the detail to be more text.
        var text = self.title ?? ""
        if let detail = self.text {
            if text.characters.count > 0 {
                text.append("\n\n")
            }
            text.append(detail)
        }
        return text
    }
}
