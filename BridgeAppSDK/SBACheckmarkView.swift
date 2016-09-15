//
//  SBACheckmarkView.swift
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

class SBACheckmarkView: UIView {
    
    func drawCheckmarkAnimated(_ animated:Bool) {
        
        guard animated else {
            _shapeLayer.strokeEnd = 1
            return
        }
        
        let timing = CAMediaTimingFunction(controlPoints: 0.180739998817444, 0, 0.577960014343262, 0.918200016021729)
        
        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.timingFunction = timing
        animation.fillMode = kCAFillModeBoth
        animation.fromValue = 0
        animation.toValue = 1
        animation.duration = 0.3
        
        _shapeLayer.strokeEnd = 0
        _shapeLayer.add(animation, forKey: "strokeEnd")
    }

    fileprivate var _shapeLayer: CAShapeLayer!
    fileprivate var _tickViewSize: CGFloat!
    
    static let defaultSize: CGFloat = 122
    
    init() {
        let tickViewSize = SBACheckmarkView.defaultSize
        let frame = CGRect(x: 0, y: 0, width: tickViewSize, height: tickViewSize)
        super.init(frame: frame)
        _tickViewSize = tickViewSize
        commonInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _tickViewSize = min(frame.size.width, frame.size.height)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        _tickViewSize = min(self.bounds.size.width, self.bounds.size.height)
        commonInit()
    }
    
    fileprivate func commonInit() {
        
        self.layer.cornerRadius = _tickViewSize / 2;
        self.backgroundColor = UIColor.greenTintColor()

        let ratio = _tickViewSize / SBACheckmarkView.defaultSize
        let path = UIBezierPath()
        path.move(to: CGPoint(x: ratio * 37, y: ratio * 65))
        path.addLine(to: CGPoint(x: ratio * 50, y: ratio * 78))
        path.addLine(to: CGPoint(x: ratio * 87, y: ratio * 42))
        path.lineCapStyle = CGLineCap.round
        path.lineWidth = min(max(1, ratio * 5), 5)

        let shapeLayer = CAShapeLayer()
        shapeLayer.path = path.cgPath
        shapeLayer.lineWidth = path.lineWidth
        shapeLayer.lineCap = kCALineCapRound
        shapeLayer.lineJoin = kCALineJoinRound
        shapeLayer.frame = self.layer.bounds
        shapeLayer.strokeColor = UIColor.white.cgColor
        shapeLayer.backgroundColor = UIColor.clear.cgColor
        shapeLayer.fillColor = nil
        shapeLayer.strokeEnd = 0
        self.layer.addSublayer(shapeLayer);
        _shapeLayer = shapeLayer;
        
        self.translatesAutoresizingMaskIntoConstraints = false
        
        self.accessibilityTraits |= UIAccessibilityTraitImage
        self.isAccessibilityElement = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        _shapeLayer.frame = self.layer.bounds;
    }

    override var intrinsicContentSize : CGSize {
        return CGSize(width: _tickViewSize, height: _tickViewSize)
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        return intrinsicContentSize
    }

}



