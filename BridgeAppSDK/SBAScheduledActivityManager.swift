//
//  SBAScheduledActivityManager.swift
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
import BridgeSDK

// TODO: syoung 04/14/2016 This is a WIP first draft of an implementation of schedule fetching that
// works for Lilly but is not complete for Parkinsons (which include a separate section for "keep going"
// activities *and* includes surveys that are build server-side (currently not supported by this implementation)


public enum SBAScheduledActivitySection {
    
    case None
    case ExpiredYesterday
    case Today
    case KeepGoing
    case Tomorrow
}

public protocol SBAScheduledActivityManagerDelegate: SBAAlertPresenter {
    func reloadTable(scheduledActivityManager: SBAScheduledActivityManager)
}

public class SBAScheduledActivityManager: NSObject, SBASharedInfoController, ORKTaskViewControllerDelegate {
    
    public weak var delegate: SBAScheduledActivityManagerDelegate?
    
    public var sections: [SBAScheduledActivitySection] = [.Today, .KeepGoing]
    public var activities: [SBBScheduledActivity] = []
    
    private var reloading: Bool = false
    public func reloadData() {
        
        // Exit early if already reloading activities. This can happen if the user flips quickly back and forth from
        // this tab to another tab.
        if (reloading) { return }
        reloading = true
        
        SBAUserBridgeManager.fetchChangesToScheduledActivities(activities, todayOnly: false) { [weak self] (obj, error) in
            guard (error == nil), let scheduledActivities = obj as? [SBBScheduledActivity] else { return }
            
            dispatch_async(dispatch_get_main_queue(), {
                self?.loadActivities(scheduledActivities)
                self?.reloading = false
            })
        }
    }
    
    public func loadActivities(scheduledActivities: [SBBScheduledActivity]) {
        
        // Filter out any sections that aren't shown
        let filters = sections.mapAndFilter({ filterPredicateForScheduledActivitySection($0) })
        let includedSections = NSCompoundPredicate(orPredicateWithSubpredicates: filters)
        
        // Filter the scheduled activities to only include those that *this* version of the app is designed
        // to be able to handle. Currently, that means only taskReference activities with an identifier that
        // maps to a known task.
        self.activities = scheduledActivities.filter({ (schedule) -> Bool in
            return self.bridgeInfo.taskReferenceForSchedule(schedule) != nil && includedSections.evaluateWithObject(schedule)
        })
        
        // reload table
        self.delegate?.reloadTable(self)
    }
    
    
    // MARK: Data Source Management
    
    public func numberOfSections() -> Int {
        return sections.count
    }
    
    public func numberOfRowsInSection(section: Int) -> Int {
        return scheduledActivitiesForSection(section).count
    }
    
    private func scheduledActivitySectionForTableSection(section: Int) -> SBAScheduledActivitySection {
        guard section < sections.count else { return .None }
        return sections[section]
    }
    
    private func scheduledActivitiesForSection(section: Int) ->[SBBScheduledActivity] {
        let scheduledActivitySection = scheduledActivitySectionForTableSection(section)
        guard let predicate = filterPredicateForScheduledActivitySection(scheduledActivitySection) else { return [] }
        return activities.filter({ predicate.evaluateWithObject($0) })
    }
    
    public func sectionTitle(section: Int) -> String? {
        
        // Always return nil for the first section and if there are no rows in the section
        guard section > 0 && scheduledActivitiesForSection(section).count > 0
        else {
            return nil
        }
        
        // Return default localized string for each section
        switch scheduledActivitySectionForTableSection(section) {
        case .ExpiredYesterday:
            return Localization.localizedString("SBA_ACTIVITY_YESTERDAY")
        case .Today:
            return Localization.localizedString("SBA_ACTIVITY_TODAY")
        case .KeepGoing:
            return Localization.localizedString("SBA_ACTIVITY_KEEP_GOING")
        case .Tomorrow:
            return Localization.localizedString("SBA_ACTIVITY_TOMORROW")
        default:
            return nil
        }
    }
    
    public func filterPredicateForScheduledActivitySection(section: SBAScheduledActivitySection) -> NSPredicate? {

        switch section {
            
        case .ExpiredYesterday:
            // expired yesterday section only showns those expired tasks that are also unfinished
            return SBBScheduledActivity.expiredYesterdayPredicate()
            
        case .Today:
            return NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSCompoundPredicate(notPredicateWithSubpredicate: SBBScheduledActivity.optionalPredicate()),
                SBBScheduledActivity.availableTodayPredicate()])
            
        case .KeepGoing:
            // Keep going section includes optional tasks that are either unfinished or were finished today
            return NSCompoundPredicate(andPredicateWithSubpredicates: [
                SBBScheduledActivity.optionalPredicate(),
                SBBScheduledActivity.unfinishedPredicate(),
                SBBScheduledActivity.availableTodayPredicate()])
        
        case .Tomorrow:
            // scheduled for tomorrow only
            return SBBScheduledActivity.scheduledTomorrowPredicate()
            
        default:
            return nil
        }
    }
    
    public func scheduledActivityAtIndexPath(indexPath: NSIndexPath) -> SBBScheduledActivity? {
        let schedules = scheduledActivitiesForSection(indexPath.section)
        guard indexPath.row < schedules.count else {
            assertionFailure("Requested row greater than number of rows in section")
            return nil
        }
        return schedules[indexPath.row]
    }
    
    public func shouldShowTaskForIndexPath(indexPath: NSIndexPath) -> Bool {
        guard let schedule = scheduledActivityAtIndexPath(indexPath) where shouldShowTaskForSchedule(schedule)
        else {
            return false
        }
        return true
    }
    
    public func didSelectRowAtIndexPath(indexPath: NSIndexPath) {
        
        // Only if the task was created should something be done.
        guard let schedule = scheduledActivityAtIndexPath(indexPath) else { return }
        guard schedule.isNow || schedule.isCompleted else {
            // Block performing a task that is scheduled for the future
            let message = String(format: Localization.localizedString("SBA_ACTIVITY_SCHEDULE_MESSAGE"), schedule.scheduledTime)
            self.delegate?.showAlertWithOk(nil, message: message, actionHandler: nil)
            return
        }
        
        // If this is a valid schedule then create the task view controller
        guard let taskRef = self.bridgeInfo.taskReferenceForSchedule(schedule),
            let task = taskRef.transformToTask(SBASurveyFactory(), isLastStep: true),
            let taskViewController = createTaskViewController(task, schedule: schedule, taskRef: taskRef)
        else {
            assertionFailure("Failed to create task view controller for \(schedule)")
            return
        }
        
        // Once we have a view controller, then present it
        setupTaskViewController(taskViewController, schedule: schedule, taskRef: taskRef)
        
        self.delegate?.presentViewController(taskViewController, animated: true, completion: nil)
    }
    
    
    // MARK: Task management
    
    public func scheduledActivityForTaskViewController(taskViewController: ORKTaskViewController) -> SBBScheduledActivity? {
        guard let vc = taskViewController as? SBATaskViewController,
            let guid = vc.scheduledActivityGUID
            else {
                return nil
        }
        return activities.findObject({ $0.guid == guid })
    }
    
    public func scheduledActivityForTaskIdentifier(taskIdentifier: String) -> SBBScheduledActivity? {
        return activities.findObject({ $0.taskIdentifier == taskIdentifier })
    }
    
    // MARK: ORKTaskViewControllerDelegate
    
    public func taskViewController(taskViewController: ORKTaskViewController, hasLearnMoreForStep step: ORKStep) -> Bool {
        if let learnMoreStep = step as? SBADirectNavigationStep where learnMoreStep.learnMoreAction != nil {
            return true
        }
        return false
    }
    
    public func taskViewController(taskViewController: ORKTaskViewController, learnMoreForStep stepViewController: ORKStepViewController) {
        guard let learnMoreStep = stepViewController.step as? SBADirectNavigationStep,
            let learnMore = learnMoreStep.learnMoreAction else {
                return
        }
        learnMore.learnMoreAction(learnMoreStep, taskViewController: taskViewController)
    }
    
    public func taskViewController(taskViewController: ORKTaskViewController, stepViewControllerWillAppear stepViewController: ORKStepViewController) {
        
        // If this is a learn more step then set the button title
        if let learnMoreStep = stepViewController.step as? SBADirectNavigationStep,
            let learnMore = learnMoreStep.learnMoreAction {
            stepViewController.learnMoreButtonTitle = learnMore.learnMoreButtonText
        }
    }
    
    public func taskViewController(taskViewController: ORKTaskViewController, didFinishWithReason reason: ORKTaskViewControllerFinishReason, error: NSError?) {
        
        if reason == ORKTaskViewControllerFinishReason.Completed,
            let schedule = scheduledActivityForTaskViewController(taskViewController)
            where shouldRecordResult(schedule, taskViewController: taskViewController) {
            
            updateScheduledActivity(schedule, taskViewController: taskViewController)
            taskViewController.task?.updateTrackedDataStores(shouldCommit: true)
            archiveResults(schedule, taskViewController: taskViewController)
        }
        else {
            taskViewController.task?.updateTrackedDataStores(shouldCommit: false)
        }
        
        taskViewController.dismissViewControllerAnimated(true) {}
    }
    
    // MARK: Protected subclass methods
    
    public func shouldShowTaskForSchedule(schedule: SBBScheduledActivity) -> Bool {
        // Allow user to perform a task again as long as the task is not expired
        guard let taskRef = self.bridgeInfo.taskReferenceForSchedule(schedule) else { return false }
        return !schedule.isExpired && (!schedule.isCompleted || taskRef.allowMultipleRun)
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
        
        let results = activityResultsForSchedule(schedule, taskViewController: taskViewController)
        print(results)
        
        // TODO: implement syoung 04/27/2016 Stubbed out accessor
    }
    
    public func activityResultsForSchedule(schedule: SBBScheduledActivity, taskViewController: ORKTaskViewController) -> [SBAActivityResult] {
        
        // TODO: implement syoung 04/27/2016 Stubbed out accessor
        let taskResult = taskViewController.result
        let result = SBAActivityResult(taskIdentifier: taskResult.identifier, taskRunUUID: taskResult.taskRunUUID, outputDirectory: taskResult.outputDirectory)
        result.results = taskResult.results
        result.schedule = schedule
        return [result]
    }
}

extension ORKTask {
    
    func updateTrackedDataStores(shouldCommit shouldCommit: Bool) {
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
                subtaskStep.subtask.updateTrackedDataStores(shouldCommit: shouldCommit)
            }
        }
    }
    
}






