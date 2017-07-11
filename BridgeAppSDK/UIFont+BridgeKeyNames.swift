//
//  UIColor+BridgeKeyNames.swift
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

extension UIFont {
    
    /*
     * Zeplin thinks it can reference SF font by name like "SanFranciscoText-Light",
     * but we need to convert that name to the system font with weight for it to work
     */
    class func sfFont(_ size : CGFloat, _ weight: CGFloat) -> UIFont! {
        return UIFont.systemFont(ofSize: size, weight: weight)
    }
    
    class func sfFontItalic(_ size : CGFloat) -> UIFont! {
        return UIFont.italicSystemFont(ofSize: size)
    }

    // MARK: Rounded button
    
    open class var roundedButtonTitle: UIFont {
        return sfFont(19.0, UIFontWeightSemibold)
    }
    
    // MARK: Generic step view controller - header view labels

    open class var headerViewHeaderLabel: UIFont {
        return sfFont(23.0, UIFontWeightRegular)
    }
    
    open class var headerViewDetailsLabel: UIFont {
        return sfFont(17.0, UIFontWeightRegular)
    }
    
    open class var headerViewPromptLabel: UIFont {
        return sfFont(15.0, UIFontWeightRegular)
    }

    open class var headerViewStepCountLabel: UIFont {
        return sfFont(14.0, UIFontWeightRegular)
    }
    
    // MARK: Generic step view controller - choice cell

    open class var choiceCellLabel: UIFont {
        return sfFont(19.0, UIFontWeightSemibold)
    }
    
    // MARK: Generic step view controller - text field cell

    open class var textFieldCellLabel: UIFont {
        return sfFont(15.0, UIFontWeightRegular)
    }

    open class var textFieldCellText: UIFont {
        return sfFont(19.0, UIFontWeightRegular)
    }

    open class var textFieldFeaturedCellText: UIFont {
        return sfFont(33.0, UIFontWeightRegular)
    }
}
