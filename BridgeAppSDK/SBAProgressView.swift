//
//  SBAProgressView.swift
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

@IBDesignable open class SBAProgressView: UIView {

    @IBInspectable var progressColor : UIColor = UIColor.appBackgroundGreen {
        didSet {
            commonInit()
        }
    }
    
    @IBInspectable var stepNumber : UInt = 3 {
        didSet {
            commonInit()
        }
    }
    
    @IBInspectable var stepTotal : UInt = 10 {
        didSet {
            commonInit()
        }
    }

    let progressLayer = CALayer()
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    override open func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        commonInit()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    func commonInit() {
        
        // Set the frame for the progress layer
        if stepNumber > 0 && stepTotal > 0 {
            var progressFrame = self.bounds
            progressFrame.size.width = self.bounds.width * (CGFloat(stepNumber) / CGFloat(stepTotal))
            progressLayer.frame = progressFrame
        }
        
        // Set the color for the progress layer
        progressLayer.backgroundColor = progressColor.cgColor
        
        // Add if needed
        if layer.sublayers?.count ?? 0 == 0 {
            layer.addSublayer(progressLayer)
        }
    }
}
