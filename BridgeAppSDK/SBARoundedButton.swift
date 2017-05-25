//
//  SBARoundedButton.swift
//  elevateMS
//
//  Created by Michael L DePhillips on 4/5/17.
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

@IBDesignable open class SBARoundedButton : UIButton {
    
    @IBInspectable open var corners: CGFloat = CGFloat(5) {
        didSet {
            refreshView()
            setNeedsDisplay()
        }
    }

    @IBInspectable open var shadowColor: UIColor = UIColor.darkGray {
        didSet {
            refreshView()
            setNeedsDisplay()
        }
    }
    
    override open var isEnabled: Bool {
        didSet {
            // simple way to show disabled state
            self.alpha = isEnabled ? CGFloat(1) : CGFloat(0.3)
        }
    }
    
    open var titleFont: UIFont? {
        didSet {
            titleLabel?.font = titleFont
        }
    }
    
    open var titleColor: UIColor? {
        didSet {
            setTitleColor(titleColor, for: .normal)
        }
    }
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        refreshView()
    }
    
    open func commonInit() {
        refreshView()
    }
    
    func refreshView() {
        layer.cornerRadius = corners
        
        // Draw bottom button shadow
        let shadowRadius = corners * 1.2
        let shadowHeight = CGFloat(3)
        
        // Make sure the shadow shows up outside the view's bounds
        clipsToBounds = false
        layer.masksToBounds = false
        
        layer.shadowColor = shadowColor.cgColor
        layer.shadowOffset = CGSize(width: 0.0, height: shadowHeight)
        layer.shadowOpacity = 1.0
        layer.shadowRadius = 0.0 // this is actually blur radius
        // User this as the shadow path, since it has a larger corner radius
        // than the default layer's corner radius
        let shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: shadowRadius)
        layer.shadowPath = shadowPath.cgPath
    }
    
    override open func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        commonInit()
        setNeedsDisplay()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
}
