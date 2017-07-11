//
//  SBAVisualConsentStep.swift
//  ResearchUXFactory
//
//  Created by Josh Bruhin on 7/6/17.
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

class SBAVisualConsentStep: ORKPageStep {
    
    private var consentDocument: ORKConsentDocument!
    
    public init(identifier: String, consentDocument: ORKConsentDocument) {
        super.init(identifier: identifier, steps: SBAVisualConsentStep.instructionSteps(for: consentDocument))
    }
    
    override init(identifier: String, steps: [ORKStep]?) {
        super.init(identifier: identifier, steps: steps)
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func stepViewControllerClass() -> AnyClass {
        return SBAGenericPageStepViewController.classForCoder()
    }
    
    static func instructionSteps(for consentDocument: ORKConsentDocument) -> Array<SBAInstructionStep> {
        
        var steps = Array<SBAInstructionStep>()
        for section in consentDocument.sections! {
            
            // skip the 'onlyInDocument' section
            if section.type == .onlyInDocument { continue }
            
            // we don't have a step identifier as these are consent scenes, so let's use the consent
            // title as our identifier. Would prefer to use .type enum here, but most of the sections
            // are defined with same type - custom
            
            guard let identifier = section.title else { continue }
            
            let instructionStep = SBAInstructionStep(identifier: identifier)
            instructionStep.title = section.title
            instructionStep.text = section.summary
            instructionStep.image = section.image
            
            // if there's learn more content, add an action to the instruction step with the content
            if let htmlContent = section.htmlContent {
                let action = SBAURLLearnMoreAction(identifier: identifier)
                action.learnMoreHTML = htmlContent
                instructionStep.learnMoreAction = action
            }
            
            steps.append(instructionStep)
        }
        
        return steps
    }
}
