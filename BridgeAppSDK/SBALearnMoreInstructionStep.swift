//
//  SBALearnMoreInstructionStep.swift
//  BridgeAppSDK
//
//  Created by Shannon Young on 5/4/16.
//  Copyright © 2016 Sage Bionetworks. All rights reserved.
//

import ResearchKit

public class SBALearnMoreAction: SBADataObject {
    
    let learnMoreButtonTextKey = "learnMoreButtonText"
    public dynamic var learnMoreButtonText: String?
    
    override public func dictionaryRepresentationKeys() -> [String] {
        return super.dictionaryRepresentationKeys() + [learnMoreButtonTextKey]
    }
    
    public func learnMoreAction(step: SBADirectNavigationStep, taskViewController: ORKTaskViewController) {
        assertionFailure("Abstract method")
    }
    
}

public class SBAURLLearnMoreAction: SBALearnMoreAction {
    
    public var learnMoreURL: NSURL! {
        get {
            if (_learnMoreURL == nil) {
                if let url = NSURL(string: identifier) {
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
    private var _learnMoreURL: NSURL!

    override public func learnMoreAction(step: SBADirectNavigationStep, taskViewController: ORKTaskViewController) {
        let vc = SBAWebViewController(nibName: nil, bundle: nil)
        vc.url = learnMoreURL
        vc.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Done, target: vc, action: #selector(vc.dismissViewController))
        let navVC = UINavigationController(rootViewController: vc)
        taskViewController.presentViewController(navVC, animated: true, completion: nil)
    }
}

public class SBASkipAction: SBALearnMoreAction {
    
    override public var learnMoreButtonText: String? {
        get {
            return super.learnMoreButtonText ?? Localization.localizedString("SBA_SKIP_STEP")
        }
        set(newValue) {
            super.learnMoreButtonText = newValue
        }
    }
    
    override public func learnMoreAction(step: SBADirectNavigationStep, taskViewController: ORKTaskViewController) {
        step.nextStepIdentifier = self.identifier
        taskViewController.goForward()
    }
    
}

