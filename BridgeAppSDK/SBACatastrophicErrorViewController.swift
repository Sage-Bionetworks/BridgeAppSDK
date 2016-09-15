//
//  SBACatastrophicErrorViewController.swift
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

class SBACatastrophicErrorViewController: UIViewController, SBASharedInfoController {

    lazy var sharedAppDelegate: SBAAppInfoDelegate = {
        return UIApplication.shared.delegate as! SBAAppInfoDelegate
    }()
    
    @IBOutlet weak var logoImageView: UIImageView!
    @IBOutlet weak var appNameLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var actionButton: UIButton!
    
    class func instantiateWithMessage(_ message: String) -> SBACatastrophicErrorViewController? {
        let storyboard = UIStoryboard(name: "CatastrophicError", bundle: Bundle(for: self.classForCoder()))
        let vc = storyboard.instantiateInitialViewController() as? SBACatastrophicErrorViewController
        vc?.initialMessage = message
        return vc
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        appNameLabel.text = Localization.localizedAppName
        logoImageView.image = sharedBridgeInfo.logoImage
        
        if let message = initialMessage {
            setupError(message: message)
        }
    }
    
    func setupError(message: String, buttonText: String? = nil, action: ((UIViewController) -> Void)? = nil) {
        
        // Update the state of the message label and action button to visible
        messageLabel.isHidden = false
        actionButton.isHidden = false
        
        // Set the message
        messageLabel.text = message
        
        // If the button title is nil set to default title
        let buttonTitle = buttonText ?? String.localizedStringWithFormat(Localization.localizedString("SBA_UPDATE_APP_BUTTON"), Localization.localizedAppName)
        actionButton.setTitle(buttonTitle, for: UIControlState())
        
        // If the action handler is nil then set to default of opening the app for update
        if action != nil {
            actionHandler = action
        }
        else {
            actionHandler = {[weak self] _ in
                guard let url = self?.sharedBridgeInfo.appUpdateURL else { return }
                UIApplication.shared.openURL(url as URL)
            }
        }
    }
    
    fileprivate var initialMessage: String?
    fileprivate var actionHandler : ((UIViewController) -> Void)?
    
    @IBAction func actionButtonTapped(_ sender: AnyObject) {
        actionHandler?(self)
    }
}
