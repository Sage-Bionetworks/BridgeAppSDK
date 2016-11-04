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

open class SBALoadingView: UIView {
    
    open var isAnimating: Bool {
        return loadingIndicator.isAnimating
    }
    
    lazy var loadingIndicator: UIActivityIndicatorView = {
        let loadingIndicator = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        loadingIndicator.hidesWhenStopped = false
        loadingIndicator.stopAnimating()
        loadingIndicator.center = CGPoint(x: self.containerView.bounds.size.width / 2.0, y: self.containerView.bounds.size.height / 2.0)
        self.containerView.addSubview(loadingIndicator)
        return loadingIndicator
    }()
    
    lazy var containerView: UIView = {
        let containerView = UIView()
        containerView.backgroundColor = UIColor(white: 0, alpha: 0.5)
        containerView.bounds = CGRect(x: 0, y: 0, width: 100, height: 100)
        containerView.layer.cornerRadius = 5
        self.addSubview(containerView)
        return containerView
    }()
    
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        containerView.center = CGPoint(x: self.bounds.size.width / 2.0, y: self.bounds.size.height / 2.0)
    }
    
    open func startAnimating() {
        self.alpha = 0.0
        self.superview?.addSubview(self)
        self.isHidden = false
        self.loadingIndicator.startAnimating()
        UIView.animate(withDuration: 0.2, animations: {
            self.alpha = 1.0
        })
    }
    
    open func stopAnimating(_ completion: (() -> Void)?) {
        UIView.animate(withDuration: 0.2, animations: {
            self.alpha = 0.0
            }, completion: {_ in
                self.isHidden = true
                self.loadingIndicator.stopAnimating()
                completion?()
        })
    }

}
