//  SBALinePlotView.swift
//  elevateMS
//
//  Created by Michael L DePhillips on 4/1/17.
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

@IBDesignable open class SBALinePlotView : UIView {
    
    /**
     * The color of the line that is drawn in this view
     */
    @IBInspectable open var lineColor : UIColor = UIColor.gray {
        didSet {
            setNeedsDisplay()
        }
    }
    
    open var dashPattern : [CGFloat] = []
    
    override open func draw(_ rect: CGRect) {
        drawLinePlot(rect, color: lineColor, x: 0, width: rect.width, height: rect.height, dash: dashPattern, roundStart: true, roundEnd: true)
    }
    
    /**
     * @param rect the original rect of the draw(rect) function
     * @param color the color of the line that will be drawn
     * @param x the x position of where to start drawing the line
     * @param width the width of the line to be drawn
     * @param height the height of the line to be drawn
     * @param the dash pattern, if any, that will be applied to the line
     * @param roundStart if true, start of the line will be rounded
     * @param roundEnd if true, end of the line will be rounded
     */
    public func drawLinePlot(_ rect: CGRect, color: UIColor, x : CGFloat, width: CGFloat, height: CGFloat, dash : [CGFloat], roundStart : Bool, roundEnd : Bool)
    {
        let dashedLinePath = UIBezierPath()
        
        let halfHeight = CGFloat(rect.height * 0.5)
        dashedLinePath.move(to: CGPoint(x:x, y:halfHeight))
        dashedLinePath.addLine(to: CGPoint(x:(x + width), y:halfHeight))
        
        if (dash.count > 0) {
            dashedLinePath.setLineDash(dash, count: dash.count, phase: 0.0)
        }
        
        color.set()  // sets the color for the line
        dashedLinePath.lineWidth = height
        dashedLinePath.stroke()
        
        // Draw the round start and end caps
        if (roundStart) {
            drawEdgeCap(rect, xRect: x, xOval: x, ovalSize: height, color: color)
        }
        if (roundEnd) {
            drawEdgeCap(rect, xRect: (x + width) - halfHeight, xOval: (x + width) - rect.height, ovalSize: height, color: color)
        }
    }
    
    /**
     * @param rect the original rect of the draw(rect) function
     * @param xOval the x position of where to start drawing the end cap
     * @param xRect the x position of where to start drawing the graphics color clear rect
     * @param ovalSize the size of the end cap to be drawn
     * @param color the color of the end cap that will be drawn
     */
    public func drawEdgeCap(_ rect: CGRect, xRect : CGFloat, xOval : CGFloat, ovalSize : CGFloat, color : UIColor) {
        let halfHeight = CGFloat(rect.height * 0.5)
        
        // Since we drew the dashed lines completed over from left to right to get the
        // dashed line spacing correctly, we need to redraw the background color over the
        // edges of the line to make sure our oval shows over top
        
        let clearLineRect = UIBezierPath(rect: CGRect(x: xRect, y: 0, width: halfHeight, height: rect.height))
        // if backgroundColor isn't set, this will throw an error, but that is ok since we need one for this to work
        backgroundColor!.set()
        clearLineRect.fill()
        
        let yoffset = (rect.height - ovalSize) * 0.5
        let dot = UIBezierPath(ovalIn: CGRect(x: xOval, y: yoffset, width: ovalSize, height: ovalSize))
        dot.lineCapStyle = .round
        color.set()  // sets the color for the line
        dot.fill()
    }
}
