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

public class SBAActivityTableViewController: UITableViewController, SBASharedInfoController, ORKTaskViewControllerDelegate {
    
    private var activities: [SBBScheduledActivity] = []
    
    override public func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.reloadData()
    }
    
    // MARK: Customizable implementations
    
    // TODO: syoung 04/14/2016 This is a WIP first draft of an implementation of schedule fetching that
    // works for Lilly but is not complete for Parkinsons (which include a separate section for "keep going"
    // activities *and* includes surveys that are build server-side (currently not supported by this implementation)
    
    public func reloadData() {
        
        SBAUserBridgeManager.fetchChangesToScheduledActivities(activities, todayOnly: true) { (obj, error) in
            guard (error == nil), let scheduledActivities = obj as? [SBBScheduledActivity] else { return }
            
            // filter the scheduled activities to only include those that *this* version of the app is designed
            // to be able to handle. Currently, that means only taskReference activities with an identifier that
            // maps to a known task.
            self.activities = scheduledActivities.filter({ (activity) -> Bool in
                return (activity.activity.task != nil) &&
                       (self.bridgeInfo.taskReferenceWithIdentifier(activity.activity.task.identifier) != nil)
            })
            
            // reload table
            self.tableView.reloadData()
        }
    }
    
    public func scheduledActivityAtIndexPath(indexPath: NSIndexPath) -> SBBScheduledActivity? {
        return activities[indexPath.row]
    }
    
    public func scheduledActivityForTaskViewController(taskViewController: ORKTaskViewController) -> SBBScheduledActivity? {
        return activities.findObject({$0.guid == taskViewController.taskRunUUID.UUIDString})
    }
    
    public func dequeueReusableCell(tableView: UITableView, indexPath: NSIndexPath) -> UITableViewCell {
        return tableView.dequeueReusableCellWithIdentifier("ActivityCell", forIndexPath: indexPath)
    }
    
    public func configureCell(cell: UITableViewCell, tableView: UITableView, indexPath: NSIndexPath) {
        guard let activityCell = cell as? SBAActivityTableViewCell,
            let schedule = scheduledActivityAtIndexPath(indexPath) else {
                return
        }
        
        // The only cell type that is supported in the base implementation is an SBAActivityTableViewCell
        let activity = schedule.activity
        activityCell.complete = schedule.isCompleted
        activityCell.titleLabel.text = activity.label
        activityCell.subtitleLabel.text = activity.labelDetail
        activityCell.timeLabel.text = schedule.scheduledTime
    }
    
    
    // Mark: UITableViewController overrides
    
    override public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return activities.count
    }
    
    override public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = dequeueReusableCell(tableView, indexPath: indexPath)
        configureCell(cell, tableView: tableView, indexPath: indexPath)
        return cell
    }
    
    override public func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        // Only if the task was created should something be done.
        guard let schedule = scheduledActivityAtIndexPath(indexPath),
            let task = SBASurveyFactory().createTaskWithTaskReference(schedule.activity.task.identifier) else {
            return
        }
        
        let taskViewController = SBATaskViewController(task: task, taskRunUUID: NSUUID(UUIDString: schedule.guid))
        taskViewController.delegate = self
        self.presentViewController(taskViewController, animated: true, completion: nil)
    }
    
    
    // MARK: ORKTaskViewControllerDelegate
    
    public func taskViewController(taskViewController: ORKTaskViewController, didFinishWithReason reason: ORKTaskViewControllerFinishReason, error: NSError?) {
        
        if reason == ORKTaskViewControllerFinishReason.Completed,
            let schedule = scheduledActivityForTaskViewController(taskViewController)
            where shouldRecordResult(schedule, taskViewController: taskViewController) {
            
            updateScheduledActivity(schedule, taskViewController: taskViewController)
            archiveResults(schedule, taskViewController: taskViewController)
        }
        
        taskViewController.dismissViewControllerAnimated(true) {}
    }
    
    // MARK: Protected subclass methods
    
    public func shouldRecordResult(schedule: SBBScheduledActivity, taskViewController: ORKTaskViewController) -> Bool {
        return true
    }
    
    public func updateScheduledActivity(schedule: SBBScheduledActivity, taskViewController: ORKTaskViewController) {
        
        // Set finish and start timestamps
        schedule.finishedOn = {
            if let sbaTaskViewController = taskViewController as? SBATaskViewController,
                let finishedOn = sbaTaskViewController.finishedOn {
                return finishedOn
            }
            else {
                return taskViewController.result.endDate ?? NSDate()
            }
        }()
        
        schedule.startedOn = taskViewController.result.startDate ?? schedule.finishedOn
        
        // Send message to server
        SBAUserBridgeManager.updateScheduledActivity(schedule)
    }
    
    public func archiveResults(schedule: SBBScheduledActivity, taskViewController: ORKTaskViewController) {
        // TODO: implement syoung 04/27/2016
    }
}

extension SBBScheduledActivity {
    
    var isCompleted: Bool {
        return self.finishedOn != nil
    }
    
    var scheduledTime: String {
        if (isCompleted) {
            return ""
        }
        else if (self.scheduledOn.timeIntervalSinceNow < 5*60) {
            return NSLocalizedString("Now", comment: "Time if now")
        }
        else {
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateFormat = "h:mm a"
            return dateFormatter.stringFromDate(self.scheduledOn).lowercaseString
        }
    }
}