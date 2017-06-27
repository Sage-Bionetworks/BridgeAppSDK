//
//  SBASingleLinePlotView.swift
//  elevateMS
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
//  The SingleLinePlotView displays the normal line plot view with a single rounded line,
//  and inserts a single highlighted, expanded section of the line plot at a specific location

import UIKit

@IBDesignable open class SBASingleLinePlotView : SBALinePlotView {
    
    /**
     * The color that the single point in the line plot shows up as
     */
    @IBInspectable open var valueColor : UIColor = UIColor.blue {
        didSet {
            setNeedsDisplay()
        }
    }
    
    /**
     * The width in pts of a single point in the line plot
     */
    @IBInspectable open var valueWidth : CGFloat = 20.0 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    /**
     * This controls the height of the background line, the single point view will be full height
     * The height from (0.0 to 1.0) which is a percentage of the total height of the view
     */
    @IBInspectable open var heightNormalized : CGFloat = 0.9 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    /**
     * The width in pts of the blank space to the right and left of the point in the line plot
     */
    @IBInspectable open var valueEdgeGaps : CGFloat = 2.0 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    /**
     * A value from (0.0 to 1.0) that will represent where the single point
     * on the line plot will show up, 0.0 is the far left, and 1.0 is the far right
     */
    @IBInspectable open var normalizedValue : Float = 0.5 {
        didSet {
            // clamp the value using the didSet method
            if (normalizedValue < 0.0) {
                normalizedValue = 0.0
            }
            if (normalizedValue > 1.0) {
                normalizedValue = 1.0
            }
            setNeedsDisplay()
        }
    }
    
    override open func draw(_ rect: CGRect) {
        // heightNormalized gives a slightly smaller line height which will make the value region pop visually
        let rectHeight = CGFloat(heightNormalized) * rect.height
        drawLinePlot(rect, color: lineColor, x: 0, width: rect.width, height: rectHeight, dash: [], roundStart: true, roundEnd: true)
        
        drawSinglePoint(rect)
    }
    
    /**
     * This method can be overridden to change the look and feel of the single point on the line
     * @param The original draw rect for the draw function
     */
    open func drawSinglePoint(_ rect: CGRect) {
        // Calculate dash pattern from min/max/value
        var startX = rect.width - (CGFloat(normalizedValue) * rect.width)
        startX = startX - (valueWidth * CGFloat(0.5)) - valueEdgeGaps
        
        // Draw first value edge gap
        var edgeGap = UIBezierPath(rect: CGRect(x: startX, y: 0, width: valueEdgeGaps, height: rect.height))
        // if backgroundColor isn't set, this will throw an error, but that is ok since we need one for this to work
        backgroundColor!.set()
        edgeGap.fill()
        
        // Move to value rect
        startX += valueEdgeGaps
        let valueRect = UIBezierPath(rect: CGRect(x: startX, y: 0, width: valueWidth, height: rect.height))
        // if backgroundColor set, will throw an error, that is ok since we need one for this to work
        valueColor.set()
        valueRect.fill()
        
        // Move to last edge gap
        startX += valueWidth
        edgeGap = UIBezierPath(rect: CGRect(x: startX, y: 0, width: valueEdgeGaps, height: rect.height))
        backgroundColor!.set()
        edgeGap.fill()
    }
}
