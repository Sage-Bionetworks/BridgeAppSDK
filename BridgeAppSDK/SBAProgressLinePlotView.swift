//
//  SBAProgressLinePlotView.swift
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
//
//  The ProgressLinePlotView separates the line plot view into 'X' number of sections,
//  and highlights the sections based on the progress from left to right

import UIKit

@IBDesignable open class SBAProgressLinePlotView : SBALinePlotView {
    
    /**
     * The width in pts of the gap between progress sections
     */
    @IBInspectable open var lineGap : CGFloat = 4.0 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    /**
     * The color of the filled up line sections (from left to right) based on the progress
     */
    @IBInspectable open var progressColor : UIColor = UIColor.blue {
        didSet {
            setNeedsDisplay()
        }
    }
    
    /**
     * The progress from 0 to [progressMax] that will fill this many line sections in the UI
     */
    @IBInspectable open var progress : Int = 1 {
        didSet {
            // clamp the value using the didSet method
            if progress < 0 {
                progress = 0
            }
            if progress > progressMax {
                progress = progressMax
            }
            setNeedsDisplay()
        }
    }
    
    /**
     * The progress max controlls the number of discrete sections to be drawn as the line plot
     */
    @IBInspectable open var progressMax : Int = 10 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    override open func draw(_ rect: CGRect) {
        // Calculate dash pattern from progressMax
        let gapWidthTotal = lineGap * CGFloat(progressMax - 1)
        let blockWidth = (rect.width - gapWidthTotal) / CGFloat(progressMax)
        dashPattern = [blockWidth, lineGap]
        
        super.draw(rect) // draw the line
        
        // Draw the highlighted section
        if (progress > 0) {
            var progressWidth = CGFloat(progress) * (lineGap + blockWidth)
            
            // Draw the end cap for the highlighted progress if we are at or beyond the max
            let drawEndCap = (progress >= progressMax)
            if (drawEndCap) {
                progressWidth = rect.width
            }
            
            super.drawLinePlot(rect, color: progressColor, x: 0, width: progressWidth, height: rect.height, dash: dashPattern, roundStart: true, roundEnd: drawEndCap)
        }
    }
}
