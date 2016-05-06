//
//  SBAActivityTableViewController.swift
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
import ResearchKit
import BridgeSDK

public class SBAActivityTableViewController: UITableViewController, SBAScheduledActivityManagerDelegate {
    
    public var scheduledActivityManager : SBAScheduledActivityManager  {
        return _scheduledActivityManager
    }
    private let _scheduledActivityManager : SBAScheduledActivityManager = SBAScheduledActivityManager()
    
    override public func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.scheduledActivityManager.delegate = self
        self.scheduledActivityManager.reloadData()
    }
    
    // MARK: data refresh
    
    public func reloadTable(scheduledActivityManager: SBAScheduledActivityManager) {
        // reload table
        self.tableView.reloadData()
    }
    
    // MARK: table cell customization

    public func dequeueReusableCell(tableView: UITableView, indexPath: NSIndexPath) -> UITableViewCell {
        return tableView.dequeueReusableCellWithIdentifier("ActivityCell", forIndexPath: indexPath)
    }
    
    public func configureCell(cell: UITableViewCell, tableView: UITableView, indexPath: NSIndexPath) {
        guard let activityCell = cell as? SBAActivityTableViewCell,
            let schedule = scheduledActivityManager.scheduledActivityAtIndexPath(indexPath) else {
                return
        }
        
        // The only cell type that is supported in the base implementation is an SBAActivityTableViewCell
        let activity = schedule.activity
        activityCell.complete = schedule.isCompleted
        activityCell.titleLabel.text = activity.label
        activityCell.subtitleLabel.text = activity.labelDetail
        activityCell.timeLabel?.text = schedule.scheduledTime
        
        // Modify the label colors if disabled
        if (scheduledActivityManager.shouldShowTaskForSchedule(schedule)) {
            activityCell.titleLabel.textColor = UIColor.blackColor()
        }
        else {
            activityCell.titleLabel.textColor = UIColor.grayColor()
        }
    }
    
    
    // Mark: UITableViewController overrides
    
    override public func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return scheduledActivityManager.numberOfSections()
    }
    
    override public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return scheduledActivityManager.numberOfRowsInSection(section)
    }
    
    override public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = dequeueReusableCell(tableView, indexPath: indexPath)
        configureCell(cell, tableView: tableView, indexPath: indexPath)
        return cell
    }
    
    override public func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        return scheduledActivityManager.shouldShowTaskForIndexPath(indexPath) ? indexPath : nil
    }
    
    override public func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        scheduledActivityManager.didSelectRowAtIndexPath(indexPath)
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    override public func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return scheduledActivityManager.sectionTitle(section)
    }
}

