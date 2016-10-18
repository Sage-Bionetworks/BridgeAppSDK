//
//  SBAMultilineTableViewCell.swift
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

open class SBAMultipleLineTableViewCell: UITableViewCell {
    
    @IBOutlet weak var titleLabel: UILabel?
    @IBOutlet weak var subtitleLabel: UILabel?
    
    override public init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        
        // Add title
        let titleLabel = UILabel(frame: CGRect.zero)
        titleLabel.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline)
        titleLabel.textAlignment = .center
        self.titleLabel = titleLabel
        self.contentView.addSubview(titleLabel)
        
        // Add subtitle
        let subtitleLabel = UILabel(frame: CGRect.zero)
        subtitleLabel.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.body)
        subtitleLabel.numberOfLines = 0
        self.subtitleLabel = subtitleLabel
        self.contentView.addSubview(subtitleLabel)

        // Setup constraints
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let titleTop = NSLayoutConstraint(item: titleLabel, attribute: .top, relatedBy: .equal, toItem: self.contentView, attribute: .topMargin, multiplier: 1.0, constant: 0)
        let titleLeft = NSLayoutConstraint(item: titleLabel, attribute: .leading, relatedBy: .equal, toItem: self.contentView, attribute: .leadingMargin, multiplier: 1.0, constant: 0)
        let titleRight = NSLayoutConstraint(item: titleLabel, attribute: .trailing, relatedBy: .equal, toItem: self.contentView, attribute: .trailingMargin, multiplier: 1.0, constant: 0)

        let subtitleTop = NSLayoutConstraint(item: subtitleLabel, attribute: .top, relatedBy: .equal, toItem: titleLabel, attribute: .bottom, multiplier: 1.0, constant: 8)
        let subtitleLeft = NSLayoutConstraint(item: subtitleLabel, attribute: .leading, relatedBy: .equal, toItem: self.contentView, attribute: .leadingMargin, multiplier: 1.0, constant: 0)
        let subtitleRight = NSLayoutConstraint(item: subtitleLabel, attribute: .trailing, relatedBy: .equal, toItem: self.contentView, attribute: .trailingMargin, multiplier: 1.0, constant: 0)
        let subtitleBottom = NSLayoutConstraint(item: subtitleLabel, attribute: .bottom, relatedBy: .equal, toItem: self.contentView, attribute: .bottomMargin, multiplier: 1.0, constant: 0)
        
        self.contentView.addConstraints([titleTop, titleLeft, titleRight, subtitleTop, subtitleLeft, subtitleRight, subtitleBottom])
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

}
