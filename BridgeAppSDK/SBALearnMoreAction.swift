//
//  SBALearnMoreAction.swift
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

import ResearchKit

open class SBALearnMoreAction: SBADataObject {
    
    let learnMoreButtonTextKey = "learnMoreButtonText"
    open dynamic var learnMoreButtonText: String?
    
    override open func dictionaryRepresentationKeys() -> [String] {
        return super.dictionaryRepresentationKeys() + [learnMoreButtonTextKey]
    }
    
    open func learnMoreAction(_ step: SBAInstructionStep, taskViewController: ORKTaskViewController) {
        assertionFailure("Abstract method")
    }
    
}

open class SBAURLLearnMoreAction: SBALearnMoreAction {
    
    open var learnMoreURL: URL! {
        get {
            if (_learnMoreURL == nil) {
                if let url = URL(string: identifier) {
                    _learnMoreURL = url
                }
                else if let url = SBAResourceFinder.sharedResourceFinder.urlNamed(identifier, withExtension: "html") {
                    _learnMoreURL = url
                }
            }
            return _learnMoreURL
        }
        set(newValue) {
            _learnMoreURL = newValue
        }
    }
    fileprivate var _learnMoreURL: URL!

    override open func learnMoreAction(_ step: SBAInstructionStep, taskViewController: ORKTaskViewController) {
        let vc = SBAWebViewController(nibName: nil, bundle: nil)
        vc.url = learnMoreURL
        vc.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: vc, action: #selector(vc.dismissViewController))
        let navVC = UINavigationController(rootViewController: vc)
        taskViewController.present(navVC, animated: true, completion: nil)
    }
}

open class SBAPopUpLearnMoreAction: SBALearnMoreAction {
    
    let learnMoreTextKey = "learnMoreText"
    open dynamic var learnMoreText: String!
    
    override open func dictionaryRepresentationKeys() -> [String] {
        return super.dictionaryRepresentationKeys() + [learnMoreTextKey]
    }
    
    open override func learnMoreAction(_ step: SBAInstructionStep, taskViewController: ORKTaskViewController) {
        taskViewController.showAlertWithOk(nil, message: learnMoreText, actionHandler: nil)
    }
    
}

open class SBASkipAction: SBALearnMoreAction {
    
    override open var learnMoreButtonText: String? {
        get {
            return super.learnMoreButtonText ?? Localization.localizedString("SBA_SKIP_STEP")
        }
        set(newValue) {
            super.learnMoreButtonText = newValue
        }
    }
    
    override open func learnMoreAction(_ step: SBAInstructionStep, taskViewController: ORKTaskViewController) {
        // Set the next step identifier
        step.nextStepIdentifier = self.identifier
        
        // add a result to this step view controller to mark that the task was skipped
        let skipResult = ORKTextQuestionResult(identifier: "skip")
        skipResult.textAnswer = step.task?.identifier ?? self.identifier
        taskViewController.currentStepViewController?.result?.addResult(skipResult)
        
        // go forward
        taskViewController.goForward()
    }
}

