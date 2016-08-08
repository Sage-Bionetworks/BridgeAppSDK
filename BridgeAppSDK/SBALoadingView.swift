//
//  SBALoadingView.swift
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

public class SBALoadingView: UIView {
    
    public var isAnimating: Bool {
        return loadingIndicator.isAnimating()
    }
    
    lazy var loadingIndicator: UIActivityIndicatorView = {
        self.backgroundColor = UIColor(white: 0, alpha: 0.5)
        let loadingIndicator = UIActivityIndicatorView(activityIndicatorStyle: .WhiteLarge)
        loadingIndicator.hidesWhenStopped = false
        self.addSubview(loadingIndicator)
        return loadingIndicator
    }()
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        loadingIndicator.center = CGPoint(x: self.bounds.size.width / 2.0, y: self.bounds.size.height / 2.0)
    }
    
    public func startAnimating() {
        self.alpha = 0.0
        self.superview?.addSubview(self)
        self.hidden = false
        self.loadingIndicator.startAnimating()
        UIView.animateWithDuration(0.2, animations: {
            self.alpha = 1.0
        })
    }
    
    public func stopAnimating(completion: (() -> Void)?) {
        UIView.animateWithDuration(0.2, animations: {
            self.alpha = 0.0
            }, completion: {_ in
                self.hidden = true
                self.loadingIndicator.stopAnimating()
                completion?()
        })
    }

}
