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
    
    public var activities: [SBBScheduledActivity] = []
    
    override public func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.reloadData()
    }
    
    // MARK: Customizable implementations
    
    // TODO: syoung 04/14/2016 This is a WIP first draft of an implementation of schedule fetching that
    // works for Lilly but is not complete for Parkinsons (which include a separate section for "keep going"
    // activities *and* includes surveys that are build server-side (currently not supported by this implementation)
    
    public func reloadData() {
        SBAUserBridgeManager.fetchChangesToScheduledActivities(activities, todayOnly: true) { [weak self] (obj, error) in
            guard (error == nil), let scheduledActivities = obj as? [SBBScheduledActivity] else { return }
            
            dispatch_async(dispatch_get_main_queue(), { 
                self?.loadActivities(scheduledActivities)
            })
        }
    }
    
    public func loadActivities(scheduledActivities: [SBBScheduledActivity]) {
        
        // filter the scheduled activities to only include those that *this* version of the app is designed
        // to be able to handle. Currently, that means only taskReference activities with an identifier that
        // maps to a known task.
        self.activities = scheduledActivities.filter({ (schedule) -> Bool in
            return taskReferenceForSchedule(schedule) != nil
        })
        
        // reload table
        self.tableView.reloadData()
    }
    
    public func scheduledActivityAtIndexPath(indexPath: NSIndexPath) -> SBBScheduledActivity? {
        return activities[indexPath.row]
    }
    
    public func scheduledActivityForTaskViewController(taskViewController: ORKTaskViewController) -> SBBScheduledActivity? {
        guard let vc = taskViewController as? SBATaskViewController,
              let guid = vc.scheduledActivityGUID
        else {
            return nil
        }
        return activities.findObject({ $0.guid == guid })
    }
    
    public func scheduledActivityForTaskIdentifier(taskIdentifier: String) -> SBBScheduledActivity? {
        return activities.findObject({ (schedule) -> Bool in
            return (schedule.activity.task != nil) && (schedule.activity.task.identifier == taskIdentifier)
        })
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
        
        // Modify the label colors if disabled
        let tintColor = UIColor.primaryTintColor() ?? self.view.tintColor
        if (shouldShowTaskForSchedule(schedule)) {
            activityCell.titleLabel.textColor = UIColor.blackColor()
            activityCell.timeLabel.textColor = tintColor
        }
        else {
            activityCell.titleLabel.textColor = UIColor.grayColor()
            activityCell.timeLabel.textColor = UIColor.disabledPrimaryTintColor() ?? tintColor?.colorWithAlphaComponent(0.8)
        }
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
    
    override public func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        guard let schedule = scheduledActivityAtIndexPath(indexPath) where shouldShowTaskForSchedule(schedule)
        else {
            return nil
        }
        return indexPath
    }
    
    override public func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        // Only if the task was created should something be done.
        guard let schedule = scheduledActivityAtIndexPath(indexPath),
            let taskRef = taskReferenceForSchedule(schedule),
            let task = taskRef.transformToTask(SBASurveyFactory(), isLastStep: true),
            let taskViewController = createTaskViewController(task, schedule: schedule, taskRef: taskRef)
        else {
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
            return
        }
        
        // Once we have a view controller, then present it
        setupTaskViewController(taskViewController, schedule: schedule, taskRef: taskRef)
        
        self.presentViewController(taskViewController, animated: true, completion: nil)
    }
    
    // MARK: ORKTaskViewControllerDelegate
    
    public func taskViewController(taskViewController: ORKTaskViewController, didFinishWithReason reason: ORKTaskViewControllerFinishReason, error: NSError?) {
        
        if reason == ORKTaskViewControllerFinishReason.Completed,
            let schedule = scheduledActivityForTaskViewController(taskViewController)
            where shouldRecordResult(schedule, taskViewController: taskViewController) {
            
            updateScheduledActivity(schedule, taskViewController: taskViewController)
            taskViewController.task?.updateTrackedDataStores(true)
            archiveResults(schedule, taskViewController: taskViewController)
        }
        else {
            taskViewController.task?.updateTrackedDataStores(false)
        }
        
        taskViewController.dismissViewControllerAnimated(true) {}
    }
    
    // MARK: Protected subclass methods
    
    public func shouldShowTaskForSchedule(schedule: SBBScheduledActivity) -> Bool {
        // Allow user to perform a task again as long as the task is not expired
        guard let taskRef = taskReferenceForSchedule(schedule) else { return false }
        return !schedule.isExpired && (!schedule.isCompleted || taskRef.allowMultipleRun)
    }
    
    public func taskReferenceForSchedule(schedule: SBBScheduledActivity) -> SBATaskReference? {
        if (schedule.activity.task != nil),
            let taskRef = self.bridgeInfo.taskReferenceWithIdentifier(schedule.activity.task.identifier) {
            return taskRef as SBATaskReference
        }
        return nil
    }
    
    public func createTaskViewController(task: ORKTask, schedule: SBBScheduledActivity, taskRef: SBATaskReference) -> SBATaskViewController? {
         return SBATaskViewController(task: task, taskRunUUID: nil)
    }
    
    public func setupTaskViewController(taskViewController: SBATaskViewController, schedule: SBBScheduledActivity, taskRef: SBATaskReference) {
        taskViewController.scheduledActivityGUID = schedule.guid
        taskViewController.delegate = self
        taskViewController.cancelDisabled = taskRef.cancelDisabled
    }
    
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
        
        // Add any additional schedules
        var scheduledActivities = [schedule]
        
        // Look at top-level steps for a subtask that might have its own schedule
        if let navTask = taskViewController.task as? SBANavigableOrderedTask {
            for step in navTask.steps {
                if let subtaskStep = step as? SBASubtaskStep, let taskId = subtaskStep.taskIdentifier,
                   let subschedule = scheduledActivityForTaskIdentifier(taskId) where !subschedule.isCompleted {
                    // If schedule is found then set its start/stop time and add to list to update
                    subschedule.startedOn = schedule.startedOn
                    subschedule.finishedOn = schedule.finishedOn
                    scheduledActivities += [subschedule]
                }
            }
        }
        
        // Send message to server
        sendUpdatedScheduledActivities(scheduledActivities)
    }
    
    public func sendUpdatedScheduledActivities(scheduledActivities: [SBBScheduledActivity]) {
        SBAUserBridgeManager.updateScheduledActivities(scheduledActivities)
    }
    
    public func archiveResults(schedule: SBBScheduledActivity, taskViewController: ORKTaskViewController) {
        // TODO: implement syoung 04/27/2016
    }
}

extension ORKTask {
    
    func updateTrackedDataStores(shouldCommit: Bool) {
        guard let navTask = self as? SBANavigableOrderedTask else { return }
        
        // If this task has a conditional rule then update it
        if let collection = navTask.conditionalRule as? SBATrackedDataObjectCollection where collection.dataStore.hasChanges {
            if (shouldCommit) {
                collection.dataStore.commitChanges()
            }
            else {
                collection.dataStore.reset()
            }
        }
        
        // recursively search for subtask with a data store
        for step in navTask.steps {
            if let subtaskStep = step as? SBASubtaskStep {
                subtaskStep.subtask.updateTrackedDataStores(shouldCommit)
            }
        }
    }
    
}

extension SBBScheduledActivity {
    
    var isCompleted: Bool {
        return self.finishedOn != nil
    }
    
    var isExpired: Bool {
        return (self.expiresOn != nil) && (NSDate().earlierDate(self.expiresOn) == self.expiresOn)
    }
    
    var scheduledTime: String {
        if (isCompleted) {
            return ""
        }
        else if (self.scheduledOn.timeIntervalSinceNow < 5*60) && !isExpired {
            return Localization.localizedString("SBA_NOW")
        }
        else {
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateFormat = "h:mm a"
            return dateFormatter.stringFromDate(self.scheduledOn).lowercaseString
        }
    }
}