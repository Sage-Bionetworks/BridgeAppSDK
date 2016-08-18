//
//  SBAOnboardingCompleteStep.swift
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

import ResearchKit

public class SBAOnboardingCompleteStep: ORKTableStep {
    
    override public init(identifier: String) {
        super.init(identifier: identifier)
    }
    
    required public init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    convenience init(inputItem: SBASurveyItem) {
        self.init(identifier: inputItem.identifier)
        self.title = inputItem.stepTitle
        self.detailText = inputItem.stepText
        self.optional = false
    }
    
    let reuseIdentifier = "OnboardingComplete"
    
    public var detailText: String? {
        get { return self.items?.first as? String }
        set(newValue) { self.items = (newValue == nil) ? nil : [newValue!] }
    }
    
    override public func reuseIdentifierForRowAtIndexPath(indexPath: NSIndexPath) -> String {
        return reuseIdentifier
    }

    override public func registerCellsForTableView(tableView: UITableView) {
        let bundle = NSBundle(forClass: SBAOnboardingCompleteTableViewCell.classForCoder())
        let nib = UINib(nibName: "SBAOnboardingCompleteTableViewCell", bundle: bundle)
        tableView.registerNib(nib, forCellReuseIdentifier: reuseIdentifier)
    }
    
    override public func configureCell(cell: UITableViewCell, indexPath: NSIndexPath, tableView: UITableView) {
        guard let onboardingCell = cell as? SBAOnboardingCompleteTableViewCell else { return }
        onboardingCell.appNameLabel.text = Localization.localizedAppName
        onboardingCell.descriptionLabel.text = self.detailText
    }
}
