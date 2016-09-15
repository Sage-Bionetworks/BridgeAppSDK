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
    
    case none
    case expiredYesterday
    case today
    case keepGoing
    case tomorrow
    case comingUp
}

public protocol SBAScheduledActivityManagerDelegate: SBAAlertPresenter {
    func reloadTable(_ scheduledActivityManager: SBAScheduledActivityManager)
}

open class SBAScheduledActivityManager: NSObject, SBASharedInfoController, ORKTaskViewControllerDelegate, SBAScheduledActivityDataSource {
    
    open weak var delegate: SBAScheduledActivityManagerDelegate?
    
    public override init() {
        super.init()
        commonInit()
    }
    
    public init(delegate: SBAScheduledActivityManagerDelegate?) {
        super.init()
        self.delegate = delegate
        commonInit()
    }
    
    func commonInit() {
        self.daysAhead = self.bridgeInfo.cacheDaysAhead
        self.daysBehind = self.bridgeInfo.cacheDaysBehind
    }
    
    lazy open var sharedAppDelegate: SBAAppInfoDelegate = {
        return UIApplication.shared.delegate as! SBAAppInfoDelegate
    }()
    
    open var bridgeInfo: SBABridgeInfo {
        return self.sharedBridgeInfo
    }
    
    open var sections: [SBAScheduledActivitySection] = [.today, .keepGoing]
    open var activities: [SBBScheduledActivity] = []
    
    open var daysAhead: Int!
    open var daysBehind: Int!
    
    fileprivate var reloading: Bool = false
    open func reloadData() {
        
        // Exit early if already reloading activities. This can happen if the user flips quickly back and forth from
        // this tab to another tab.
        if (reloading) { return }
        reloading = true
        
        SBABridgeManager.fetchChanges(toScheduledActivities: activities, daysAhead: daysAhead, daysBehind: daysBehind) {
            [weak self] (obj, error) in
            // if we're using BridgeSDK caching, obj can contain valid schedules even in case of network error
            // if not, obj will be nil if error is not nil, so we don't need to check error
            guard let scheduledActivities = obj as? [SBBScheduledActivity] else { return }
            
            DispatchQueue.main.async(execute: {
                self?.loadActivities(scheduledActivities)
                self?.reloading = false
            })
        }
    }
    
    open func loadActivities(_ scheduledActivities: [SBBScheduledActivity]) {
        
        // schedule notifications
        setupNotificationsForScheduledActivities(scheduledActivities)
        
        // Filter out any sections that aren't shown
        let filters = sections.mapAndFilter({ filterPredicateForScheduledActivitySection($0) })
        let includedSections = NSCompoundPredicate(orPredicateWithSubpredicates: filters)
        
        // Filter the scheduled activities to only include those that *this* version of the app is designed
        // to be able to handle. Currently, that means only taskReference activities with an identifier that
        // maps to a known task.
        self.activities = scheduledActivities.filter({ (schedule) -> Bool in
            return bridgeInfo.taskReferenceForSchedule(schedule) != nil && includedSections.evaluate(with: schedule)
        })
        
        // reload table
        self.delegate?.reloadTable(self)
    }
    
    open func setupNotificationsForScheduledActivities(_ scheduledActivities: [SBBScheduledActivity]) {
        // schedule notifications
        SBANotificationsManager.sharedManager.setupNotificationsForScheduledActivities(scheduledActivities)
    }
    
    
    // MARK: Data Source Management
    
    open func numberOfSections() -> Int {
        return sections.count
    }
    
    open func numberOfRowsInSection(_ section: Int) -> Int {
        return scheduledActivitiesForSection(section).count
    }
    
    fileprivate func scheduledActivitySectionForTableSection(_ section: Int) -> SBAScheduledActivitySection {
        guard section < sections.count else { return .none }
        return sections[section]
    }
    
    open func scheduledActivitiesForSection(_ section: Int) ->[SBBScheduledActivity] {
        let scheduledActivitySection = scheduledActivitySectionForTableSection(section)
        guard let predicate = filterPredicateForScheduledActivitySection(scheduledActivitySection) else { return [] }
        return activities.filter({ predicate.evaluate(with: $0) })
    }
    
    open func sectionTitle(_ section: Int) -> String? {
        
        // Always return nil for the first section and if there are no rows in the section
        guard scheduledActivitiesForSection(section).count > 0
        else {
            return nil
        }
        
        // Return default localized string for each section
        switch scheduledActivitySectionForTableSection(section) {
        case .expiredYesterday:
            return Localization.localizedString("SBA_ACTIVITY_YESTERDAY")
        case .today:
            return Localization.localizedString("SBA_ACTIVITY_TODAY")
        case .keepGoing:
            return Localization.localizedString("SBA_ACTIVITY_KEEP_GOING")
        case .tomorrow:
            return Localization.localizedString("SBA_ACTIVITY_TOMORROW")
        case .comingUp:
            return Localization.localizedString("SBA_ACTIVITY_COMING_UP")
        case .none:
            return nil
        }
    }
    
    open func filterPredicateForScheduledActivitySection(_ section: SBAScheduledActivitySection) -> NSPredicate? {

        switch section {

        case .expiredYesterday:
            // expired yesterday section only showns those expired tasks that are also unfinished
            return SBBScheduledActivity.expiredYesterdayPredicate()
            
        case .today:
            return NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSCompoundPredicate(notPredicateWithSubpredicate: SBBScheduledActivity.optionalPredicate()),
                SBBScheduledActivity.availableTodayPredicate()])
            
        case .keepGoing:
            // Keep going section includes optional tasks that are either unfinished or were finished today
            return NSCompoundPredicate(andPredicateWithSubpredicates: [
                SBBScheduledActivity.optionalPredicate(),
                SBBScheduledActivity.unfinishedPredicate(),
                SBBScheduledActivity.availableTodayPredicate()])
        
        case .tomorrow:
            // scheduled for tomorrow only
            return SBBScheduledActivity.scheduledTomorrowPredicate()
        
        case .comingUp:
            return SBBScheduledActivity.scheduledComingUpPredicate(self.daysAhead)
            
        case .none:
            return nil
        }
    }
    
    open func scheduledActivityAtIndexPath(_ indexPath: IndexPath) -> SBBScheduledActivity? {
        let schedules = scheduledActivitiesForSection((indexPath as NSIndexPath).section)
        guard (indexPath as NSIndexPath).row < schedules.count else {
            assertionFailure("Requested row greater than number of rows in section")
            return nil
        }
        return schedules[(indexPath as NSIndexPath).row]
    }
    
    open func shouldShowTaskForIndexPath(_ indexPath: IndexPath) -> Bool {
        guard let schedule = scheduledActivityAtIndexPath(indexPath) , shouldShowTaskForSchedule(schedule)
        else {
            return false
        }
        return true
    }
    
    open func isScheduleAvailable(_ schedule: SBBScheduledActivity) -> Bool {
        return schedule.isNow || schedule.isCompleted
    }
    
    open func messageForUnavailableSchedule(_ schedule: SBBScheduledActivity) -> String {
        var scheduledTime: String!
        if schedule.isToday {
            scheduledTime = schedule.scheduledTime
        }
        else if schedule.isTomorrow {
            scheduledTime = Localization.localizedString("SBA_ACTIVITY_TOMORROW")
        }
        else {
            scheduledTime = DateFormatter.localizedString(from: schedule.scheduledOn, dateStyle: .medium, timeStyle: .none)
        }
        return Localization.localizedStringWithFormatKey("SBA_ACTIVITY_SCHEDULE_MESSAGE", scheduledTime)
    }
    
    open func didSelectRowAtIndexPath(_ indexPath: IndexPath) {
        
        // Only if the task was created should something be done.
        guard let schedule = scheduledActivityAtIndexPath(indexPath) else { return }
        guard isScheduleAvailable(schedule) else {
            // Block performing a task that is scheduled for the future
            let message = messageForUnavailableSchedule(schedule)
            self.delegate?.showAlertWithOk(nil, message: message, actionHandler: nil)
            return
        }
        
        // If this is a valid schedule then create the task view controller
        guard let taskViewController = createTaskViewControllerForSchedule(schedule)
        else {
            assertionFailure("Failed to create task view controller for \(schedule)")
            return
        }
        
        self.delegate?.presentViewController(taskViewController, animated: true, completion: nil)
    }
    

    // MARK: Task management
    
    open func scheduledActivityForTaskViewController(_ taskViewController: ORKTaskViewController) -> SBBScheduledActivity? {
        guard let vc = taskViewController as? SBATaskViewController,
            let guid = vc.scheduledActivityGUID
            else {
                return nil
        }
        return activities.find({ $0.guid == guid })
    }
    
    open func scheduledActivityForTaskIdentifier(_ taskIdentifier: String) -> SBBScheduledActivity? {
        return activities.find({ $0.taskIdentifier == taskIdentifier })
    }
    
    // MARK: ORKTaskViewControllerDelegate
    
    open func taskViewController(_ taskViewController: ORKTaskViewController, didFinishWith reason: ORKTaskViewControllerFinishReason, error: Error?) {
        
        if reason == ORKTaskViewControllerFinishReason.completed,
            let schedule = scheduledActivityForTaskViewController(taskViewController)
            , shouldRecordResult(schedule, taskViewController: taskViewController) {
            
            // Update any data stores associated with this task
            taskViewController.task?.updateTrackedDataStores(shouldCommit: true)
            
            // Archive the results
            let results = activityResultsForSchedule(schedule, taskViewController: taskViewController)
            let archives = results.mapAndFilter({ archiveForActivityResult($0) })
            SBADataArchive.encryptAndUploadArchives(archives)
            
            // Update the schedule on the server
            updateScheduledActivity(schedule, taskViewController: taskViewController)
        }
        else {
            taskViewController.task?.updateTrackedDataStores(shouldCommit: false)
        }
        
        taskViewController.dismiss(animated: true) {}
    }

    open func taskViewController(_ taskViewController: ORKTaskViewController, hasLearnMoreFor step: ORKStep) -> Bool {
        if let learnMoreStep = step as? SBAInstructionStep , learnMoreStep.learnMoreAction != nil {
            return true
        }
        return false
    }
    
    open func taskViewController(_ taskViewController: ORKTaskViewController, learnMoreForStep stepViewController: ORKStepViewController) {
        guard let learnMoreStep = stepViewController.step as? SBAInstructionStep,
            let learnMore = learnMoreStep.learnMoreAction else {
                return
        }
        learnMore.learnMoreAction(learnMoreStep, taskViewController: taskViewController)
    }
    
    open func taskViewController(_ taskViewController: ORKTaskViewController, stepViewControllerWillAppear stepViewController: ORKStepViewController) {
        
        // If this is a learn more step then set the button title
        if let learnMoreStep = stepViewController.step as? SBAInstructionStep,
            let learnMore = learnMoreStep.learnMoreAction {
            stepViewController.learnMoreButtonTitle = learnMore.learnMoreButtonText
        }
        
        // If cancel is disabled then hide on all but the first step
        if let step = stepViewController.step
            , shouldHideCancelForStep(step, taskViewController: taskViewController) {
            stepViewController.cancelButtonItem = UIBarButtonItem(title: nil, style: .plain, target: nil, action: nil)
        }
    }
    
    
    // MARK: Convenience methods
    
    public final func createTaskViewControllerForSchedule(_ schedule: SBBScheduledActivity) -> SBATaskViewController? {
        let (inTask, inTaskRef) = createTask(schedule)
        guard let task = inTask, let taskRef = inTaskRef else { return nil }
        let taskViewController = instantiateTaskViewController(schedule, task: task, taskRef: taskRef)
        setupTaskViewController(taskViewController, schedule: schedule, taskRef: taskRef)
        return taskViewController
    }
    
    // MARK: Protected subclass methods

    open func shouldHideCancelForStep(_ step: ORKStep, taskViewController: ORKTaskViewController) -> Bool {
        
        // Return false if cancel is *not* disabled
        guard let schedule = scheduledActivityForTaskViewController(taskViewController),
            let taskRef = bridgeInfo.taskReferenceForSchedule(schedule) , taskRef.cancelDisabled
        else {
            return false
        }
        
        // If the task does not respond then assume that cancel should be hidden for all steps
        guard let task = taskViewController.task as? SBATaskExtension
        else {
            return true
        }

        // Otherwise, do not disable the first step IF and ONLY IF there are more than 1 steps.
        return task.stepCount() == 1 || task.index(of: step) > 0;
    }

    open func shouldShowTaskForSchedule(_ schedule: SBBScheduledActivity) -> Bool {
        // Allow user to perform a task again as long as the task is not expired
        guard let taskRef = bridgeInfo.taskReferenceForSchedule(schedule) else { return false }
        return !schedule.isExpired && (!schedule.isCompleted || taskRef.allowMultipleRun)
    }
    
    open func instantiateTaskViewController(_ schedule: SBBScheduledActivity, task: ORKTask, taskRef: SBATaskReference) -> SBATaskViewController {
        return SBATaskViewController(task: task, taskRun: nil)
    }
    
    open func createTask(_ schedule: SBBScheduledActivity) -> (task: ORKTask?, taskRef: SBATaskReference?) {
        let taskRef = bridgeInfo.taskReferenceForSchedule(schedule)
        let task = taskRef?.transformToTask(factory: SBASurveyFactory(), isLastStep: true)
        if let surveyTask = task as? SBASurveyTask {
            surveyTask.title = schedule.activity.label
        }
        return (task, taskRef)
    }
    
    open func setupTaskViewController(_ taskViewController: SBATaskViewController, schedule: SBBScheduledActivity, taskRef: SBATaskReference) {
        taskViewController.scheduledActivityGUID = schedule.guid
        taskViewController.delegate = self
    }
    
    open func shouldRecordResult(_ schedule: SBBScheduledActivity, taskViewController: ORKTaskViewController) -> Bool {
        // Subclass can override to provide custom implementation. By default, will return true.
        return true
    }
    
    open func updateScheduledActivity(_ schedule: SBBScheduledActivity, taskViewController: ORKTaskViewController) {
        
        // Set finish and start timestamps
        schedule.finishedOn = {
            if let sbaTaskViewController = taskViewController as? SBATaskViewController,
                let finishedOn = sbaTaskViewController.finishedOn {
                return finishedOn as Date!
            }
            else {
                return taskViewController.result.endDate
            }
        }()
        
        schedule.startedOn = taskViewController.result.startDate
        
        // Add any additional schedules
        var scheduledActivities = [schedule]
        
        // Look at top-level steps for a subtask that might have its own schedule
        if let navTask = taskViewController.task as? SBANavigableOrderedTask {
            for step in navTask.steps {
                if let subtaskStep = step as? SBASubtaskStep, let taskId = subtaskStep.taskIdentifier,
                    let subschedule = scheduledActivityForTaskIdentifier(taskId) , !subschedule.isCompleted {
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
    
    open func sendUpdatedScheduledActivities(_ scheduledActivities: [SBBScheduledActivity]) {
        SBABridgeManager.updateScheduledActivities(scheduledActivities) {[weak self] (_, _) in
            self?.reloadData()
        }
    }
    
    // Expose method for building archive to allow for testing and subclass override
    open func archiveForActivityResult(_ activityResult: SBAActivityResult) -> SBAActivityArchive? {
        if let archive = SBAActivityArchive(result: activityResult,
                                            jsonValidationMapping: jsonValidationMapping(activityResult: activityResult)) {
            do {
                try archive.complete()
                return archive
            }
            catch {}
        }
        return nil
    }
    
    open func jsonValidationMapping(activityResult: SBAActivityResult) -> [String: NSPredicate]?{
        return nil
    }
    
    // Expose method for building results to allow for testing and subclass override
    open func activityResultsForSchedule(_ schedule: SBBScheduledActivity, taskViewController: ORKTaskViewController) -> [SBAActivityResult] {
        
        // If no results, return empty array
        guard taskViewController.result.results != nil else { return [] }
        
        let taskResult = taskViewController.result
        let surveyTask = taskViewController.task as? SBASurveyTask
        
        // Look at the task result start/end date and assign the start/end date for the split result
        // based on whether or not the inputDate is greater/less than the comparison date. This way,
        // the split result will have a start date that is >= the overall task start date and an
        // end date that is <= the task end date.
        func outputDate(_ inputDate: Date?, comparison:ComparisonResult) -> Date {
            let compareDate = (comparison == .orderedAscending) ? taskResult.startDate : taskResult.endDate
            guard let date = inputDate , date.compare(compareDate) == comparison else {
                return compareDate
            }
            return date
        }

        // Function for creating each split result
        func createActivityResult(_ identifier: String, schedule: SBBScheduledActivity, stepResults: [ORKStepResult]) -> SBAActivityResult {
            let result = SBAActivityResult(taskIdentifier: identifier, taskRun: taskResult.taskRunUUID, outputDirectory: taskResult.outputDirectory)
            result.results = stepResults
            result.schedule = schedule
            result.startDate = outputDate(stepResults.first?.startDate, comparison: .orderedAscending)
            result.endDate = outputDate(stepResults.last?.endDate, comparison: .orderedDescending)
            result.schemaRevision = surveyTask?.schemaRevision ?? bridgeInfo.schemaReferenceWithIdentifier(identifier)?.schemaRevision ?? 1
            return result
        }
        
        // mutable arrays for ensuring all results are collected
        var topLevelResults:[ORKStepResult] = taskViewController.result.consolidatedResults()
        var allResults:[SBAActivityResult] = []
        var dataStores:[SBATrackedDataStore] = []
        
        if let task = taskViewController.task as? SBANavigableOrderedTask {
            for step in task.steps {
                if let subtaskStep = step as? SBASubtaskStep {
                    
                    var isDataCollection = false
                    if let subtask = subtaskStep.subtask as? SBANavigableOrderedTask,
                        let dataCollection = subtask.conditionalRule as? SBATrackedDataObjectCollection {
                        // But keep a pointer to the dataStore
                        dataStores.append(dataCollection.dataStore)
                        isDataCollection = true
                    }
                    
                    if  let taskId = subtaskStep.taskIdentifier,
                        let schemaId = subtaskStep.schemaIdentifier {

                        // If this is a subtask step with a schemaIdentifier and taskIdentifier
                        // then split out the result
                        let (subResults, filteredResults) = subtaskStep.filteredStepResults(topLevelResults)
                        topLevelResults = filteredResults
                
                        // Add filtered results to each collection as appropriate
                        let subschedule = scheduledActivityForTaskIdentifier(taskId) ?? schedule
                        if subResults.count > 0 {
                            
                            // add dataStore results but only if this is not a data collection itself
                            var subsetResults = subResults
                            if !isDataCollection {
                                for dataStore in dataStores {
                                    if let momentInDayResult = dataStore.momentInDayResult {
                                        // Mark the start/end date with the start timestamp of the first step
                                        for stepResult in momentInDayResult {
                                            stepResult.startDate = subsetResults.first!.startDate
                                            stepResult.endDate = stepResult.startDate
                                        }
                                        // Add the results at the beginning
                                        subsetResults = momentInDayResult + subsetResults
                                    }
                                }
                            }
                            
                            // create the subresult and add to list
                            let substepResult: SBAActivityResult = createActivityResult(schemaId, schedule: subschedule, stepResults: subsetResults)
                            allResults.append(substepResult)
                        }
                    }
                    else if isDataCollection {
                        
                        // Otherwise, filter out the tracked object collection but do not create results
                        // because this is tracked via the dataStore
                        let (_, filteredResults) = subtaskStep.filteredStepResults(topLevelResults)
                        topLevelResults = filteredResults
                    }
                }
            }
        }
        
        // If there are any results that were not filtered into a subgroup then include them at the top level
        if topLevelResults.filter({ $0.hasResults }).count > 0 {
            let topResult = createActivityResult(taskResult.identifier, schedule: schedule, stepResults: topLevelResults)
            allResults.insert(topResult, at: 0)
        }
        
        return allResults
    }
}

extension ORKTask {
    
    func updateTrackedDataStores(shouldCommit: Bool) {
        guard let navTask = self as? SBANavigableOrderedTask else { return }
        
        // If this task has a conditional rule then update it
        if let collection = navTask.conditionalRule as? SBATrackedDataObjectCollection , collection.dataStore.hasChanges {
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






