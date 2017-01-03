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

/**
 Enum defining the default sections used by the `SBAScheduledActivityManager` to display 
 scheduled activities.
 */
public enum SBAScheduledActivitySection {
    case none
    case expiredYesterday
    case today
    case keepGoing
    case tomorrow
    case comingUp
}

/**
 UI Delegate for the data source.
 */
public protocol SBAScheduledActivityManagerDelegate: SBAAlertPresenter {
    
    /**
     Callback that a reload of the scheduled activities has finished.
    */
    func reloadFinished(_ sender: Any?)
}

/**
 Default data source handler for scheduled activities. This manager is intended to get `SBBScheduledActivity`
 objects from the Bridge server and can present the associated tasks.
 */
open class SBAScheduledActivityManager: NSObject, ORKTaskViewControllerDelegate, SBAScheduledActivityDataSource {
    
    /**
     The delegate is required for presenting tasks and refreshing the UI.
    */
    open weak var delegate: SBAScheduledActivityManagerDelegate?
    
    /**
     `SBABridgeInfo` instance. By default, this is the shared bridge info defined by the app delegate.
     */
    open var bridgeInfo: SBABridgeInfo! {
        return _bridgeInfo
    }
    fileprivate var _bridgeInfo: SBABridgeInfo!
    
    /**
     `SBAUserWrapper` instance. By default, this is the shared user defined by the app delegate.
    */
    open var user: SBAUserWrapper! {
        return _user
    }
    fileprivate var _user: SBAUserWrapper!
    
    
    // MARK: initializers
    
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
        guard let appDelegate = UIApplication.shared.delegate as? SBAAppInfoDelegate else { return }
        _bridgeInfo = appDelegate.bridgeInfo
        _user = appDelegate.currentUser
        self.daysAhead = self.bridgeInfo.cacheDaysAhead
        self.daysBehind = self.bridgeInfo.cacheDaysBehind
    }

    // MARK: Data source management
    
    /**
     Sections to display - this sets up the predicates for filtering activities
    */
    open var sections: [SBAScheduledActivitySection] = [.today, .keepGoing]
    
    /**
     By default, this is an array of the activities fetched by the call to the server in `reloadData`.
    */
    open var activities: [SBBScheduledActivity] = []
    
    /**
     Number of days ahead to fetch
    */
    open var daysAhead: Int!
    
    /**
     Number of days behind to fetch
    */
    open var daysBehind: Int!

    // MARK: SBAScheduledActivityDataSource
    
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
                self?.load(scheduledActivities: scheduledActivities)
                self?.reloading = false
            })
        }
    }
    
    open func numberOfSections() -> Int {
        return sections.count
    }
    
    open func numberOfRows(for section: Int) -> Int {
        return scheduledActivities(for: section).count
    }
    
    open func scheduledActivity(at indexPath: IndexPath) -> SBBScheduledActivity? {
        let schedules = scheduledActivities(for: (indexPath as NSIndexPath).section)
        guard (indexPath as NSIndexPath).row < schedules.count else {
            assertionFailure("Requested row greater than number of rows in section")
            return nil
        }
        return schedules[(indexPath as NSIndexPath).row]
    }
    
    open func shouldShowTask(for indexPath: IndexPath) -> Bool {
        guard let schedule = scheduledActivity(at: indexPath), shouldShowTask(for: schedule)
            else {
                return false
        }
        return true
    }
    
    open func didSelectRow(at indexPath: IndexPath) {
        
        // Only if the task was created should something be done.
        guard let schedule = scheduledActivity(at: indexPath) else { return }
        guard isAvailable(schedule: schedule) else {
            // Block performing a task that is scheduled for the future
            let message = messageForUnavailableSchedule(schedule)
            self.delegate?.showAlertWithOk(title: nil, message: message, actionHandler: nil)
            return
        }
        
        // If this is a valid schedule then create the task view controller
        guard let taskViewController = createTaskViewController(for: schedule)
            else {
                assertionFailure("Failed to create task view controller for \(schedule)")
                return
        }
        
        self.delegate?.presentViewController(taskViewController, animated: true, completion: nil)
    }
    
    open func title(for section: Int) -> String? {
        
        // Always return nil for the first section and if there are no rows in the section
        guard scheduledActivities(for: section).count > 0, let scheduledActivitySection = scheduledActivitySection(for: section)
            else {
                return nil
        }
        
        // Return default localized string for each section
        switch scheduledActivitySection {
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
    
    
    // MARK: Data handling
    
    /**
     Called once the response from the server returns the scheduled activities.
     
     @param     scheduledActivities     The list of activities returned by the service.
     */
    open func load(scheduledActivities: [SBBScheduledActivity]) {
        
        // schedule notifications
        setupNotifications(for: scheduledActivities)
        
        // Filter out any sections that aren't shown
        let filters = sections.mapAndFilter({ filterPredicate(for: $0) })
        let includedSections = NSCompoundPredicate(orPredicateWithSubpredicates: filters)
        
        // Filter the scheduled activities to only include those that *this* version of the app is designed
        // to be able to handle. Currently, that means only taskReference activities with an identifier that
        // maps to a known task.
        self.activities = scheduledActivities.filter({ (schedule) -> Bool in
            return bridgeInfo.taskReferenceForSchedule(schedule) != nil && includedSections.evaluate(with: schedule)
        })
        
        // reload table
        self.delegate?.reloadFinished(self)
        
        // preload all the surveys so that they can be accessed offline
        for schedule in scheduledActivities {
            if schedule.activity.survey != nil {
                SBABridgeManager.loadSurvey(schedule.activity.survey, completion:{ (_, _) in
                })
            }
        }
    }
    
    /**
     Called on load to setup notifications for the returned scheduled activities.
     
     @param     scheduledActivities     The list of activities for which to schedule notifications
     */
    @objc(setupNotificationsForScheduledActivities:)
    open func setupNotifications(for scheduledActivities: [SBBScheduledActivity]) {
        // schedule notifications
        SBANotificationsManager.shared.setupNotifications(for: scheduledActivities)
    }
    
    /**
     Array of `SBBScheduledActivity` objects for a given table section
     
     @param     tableSection    The section index into the table (maps to IndexPath)
     @return                    The list of `SBBScheduledActivity` objects for this table section.
     */
    @objc(scheduledActivitiesForTableSection:)
    open func scheduledActivities(for tableSection: Int) -> [SBBScheduledActivity] {
        guard let predicate = filterPredicate(for: tableSection) else { return [] }
        return activities.filter({ predicate.evaluate(with: $0) })
    }
    
    private func scheduledActivitySection(for tableSection: Int) -> SBAScheduledActivitySection? {
        guard tableSection < sections.count else { return nil }
        return sections[tableSection]
    }

    /**
     Predicate to use to filter the activities for a given table section
     
     @param     tableSection    The section index into the table (maps to IndexPath)
     @return                    The predicate to use to filter the table section
     */
    @objc(filterPredicateForTableSection:)
    open func filterPredicate(for tableSection: Int) -> NSPredicate? {
        guard let section = scheduledActivitySection(for: tableSection) else { return nil }
        return filterPredicate(for: section)
    }
    
    private func filterPredicate(for section: SBAScheduledActivitySection) -> NSPredicate? {
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
            return SBBScheduledActivity.scheduledComingUpPredicate(numberOfDays: self.daysAhead)
            
        case .none:
            return nil
        }
    }
    
    /**
     By default, a scheduled activity is available if it is available now or
     it is completed.
     
     @param     schedule    The schedule to check
     @return                `YES` if the task can be run and `NO` if the task is scheduled for the future or expired.
     */
    open func isAvailable(schedule: SBBScheduledActivity) -> Bool {
        return schedule.isNow || schedule.isCompleted
    }
    
    /**
     If a schedule is unavailable, then the user is shown an alert explaining when it will 
     become available.
     
     @param     schedule    The schedule to check
     @return                The message to display in an alert for a schedule that is not currently available.
     */
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
    

    // MARK: Task management
    
    /**
     Get the scheduled activity that is associated with this task view controller.
     
     @param     taskViewController  The task view controller being displayed.
     @return                        The schedule associated with this task view controller (if available)
     */
    @objc(scheduledActivityForTaskViewController:)
    open func scheduledActivity(for taskViewController: ORKTaskViewController) -> SBBScheduledActivity? {
        guard let vc = taskViewController as? SBATaskViewController,
            let scheduleIdentifier = vc.scheduleIdentifier
            else {
                return nil
        }
        return activities.find({ $0.scheduleIdentifier == scheduleIdentifier })
    }
    
    /**
     Get the scheduled activity that is associated with this task identifier.
     
     @param     taskIdentifier  The task identifier for a given schedule
     @return                    The task identifier associated with the given schedule (if available)
     */
    @objc(scheduledActivityForTaskIdentifier:)
    open func scheduledActivity(for taskIdentifier: String) -> SBBScheduledActivity? {
        return activities.find({ $0.taskIdentifier == taskIdentifier })
    }

    
    // MARK: ORKTaskViewControllerDelegate
    
    fileprivate let offMainQueue = DispatchQueue(label: "org.sagebase.BridgeAppSDK.SBAScheduledActivityManager")
    open func taskViewController(_ taskViewController: ORKTaskViewController, didFinishWith reason: ORKTaskViewControllerFinishReason, error: Error?) {
        
        // default behavior is to only record the task results if the task completed
        if reason == ORKTaskViewControllerFinishReason.completed {
            recordTaskResults(for: taskViewController)
        }
        else {
            taskViewController.task?.resetTrackedDataChanges()
        }
        
        taskViewController.dismiss(animated: true) {
            self.offMainQueue.async {
                self.deleteOutputDirectory(for: taskViewController)
                self.debugPrintSandboxFiles()
            }
        }
    }
    
    open func taskViewController(_ taskViewController: ORKTaskViewController, stepViewControllerWillAppear stepViewController: ORKStepViewController) {
        
        // If cancel is disabled then hide on all but the first step
        if let step = stepViewController.step, shouldHideCancel(for: step, taskViewController: taskViewController) {
            stepViewController.cancelButtonItem = UIBarButtonItem(title: nil, style: .plain, target: nil, action: nil)
        }
        
        // If it is the last step in the task *and* it's a completion step (not a step
        // that might change the results) then record the task result. This allows the 
        // results to be recorded and updated prior to ending the task and ensures that
        // even if the user forgets to tap the "Done" button, their results will be 
        // recorded.
        if let step = stepViewController.step, let task = taskViewController.task,
            task.isCompletion(step: step, with: taskViewController.result) {
            recordTaskResults(for: taskViewController)
        }
    }
    
    
    // MARK: Convenience methods
    
    /**
     Method for creating the task view controller. This is marked final with the intention that any class
     that has a custom implementation should override one of the protected subclass methods used to
     create the view controller.
     
     @param     schedule    The schedule to use to create the task
     @return                The created task view controller
    */
    @objc(createTaskViewControllerForSchedule:)
    public final func createTaskViewController(for schedule: SBBScheduledActivity) -> SBATaskViewController? {
        let (inTask, inTaskRef) = createTask(for: schedule)
        guard let task = inTask, let taskRef = inTaskRef else { return nil }
        let taskViewController = instantiateTaskViewController(for: schedule, task: task, taskRef: taskRef)
        setup(taskViewController: taskViewController, schedule: schedule, taskRef: taskRef)
        return taskViewController
    }
    
    // MARK: Protected subclass methods
    
    /**
     Delete the output directory for a task once completed.
     
     @param     taskViewController  The task view controller being displayed.
     */
    @objc(deleteOutputDirectoryForTaskViewController:)
    open func deleteOutputDirectory(for taskViewController: ORKTaskViewController) {
        guard let outputDirectory = taskViewController.outputDirectory else { return }
        do {
            try FileManager.default.removeItem(at: outputDirectory)
        } catch let error as NSError {
            print("Error removing ResearchKit output directory: \(error.localizedFailureReason)")
            debugPrint("\tat: \(outputDirectory)")
        }
    }
    
    fileprivate func debugPrintSandboxFiles() {
        #if DEBUG
        DispatchQueue.main.async {
            let fileMan = FileManager.default
            let homeDir = URL.init(string: NSHomeDirectory())
            let directoryEnumerator = fileMan.enumerator(at: homeDir!, includingPropertiesForKeys: [URLResourceKey.nameKey, URLResourceKey.isDirectoryKey, URLResourceKey.fileSizeKey], options: FileManager.DirectoryEnumerationOptions.init(rawValue:0), errorHandler: nil)
            
            var mutableFileInfo = Dictionary<URL, Int>()
            while let originalURL = directoryEnumerator?.nextObject() as? URL {
                let fileURL = originalURL.resolvingSymlinksInPath();
                do {
                    let urlResourceValues = try fileURL.resourceValues(forKeys: [URLResourceKey.isDirectoryKey, URLResourceKey.fileSizeKey])
                    if !urlResourceValues.isDirectory! {
                        let fileSizeOrNot = urlResourceValues.fileSize ?? -1
                        mutableFileInfo[fileURL] = fileSizeOrNot
                    }
                } catch let error as NSError {
                    debugPrint("Error: \(error.localizedDescription)")
                }
            }
            
            debugPrint("\(mutableFileInfo.count) files left in our sandbox:")
            for fileURL in mutableFileInfo.keys {
                let fileSize = mutableFileInfo[fileURL]
                debugPrint("\(fileURL.path) size:\(fileSize)")
            };
        }
        #endif
    }

    /**
     Should the cancel button be hidden for this step?
     
     @param     step                The step to be displayed
     @param     taskViewController  The task view controller being displayed.
     @return                        `YES` if the cancel button should be hidden, otherwise `NO`
    */
    @objc(shouldHideCancelForStep:taskViewController:)
    open func shouldHideCancel(for step: ORKStep, taskViewController: ORKTaskViewController) -> Bool {
        
        // Return false if cancel is *not* disabled
        guard let schedule = scheduledActivity(for: taskViewController),
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

    /**
     Whether or not the task should be enabled. This is different from whether or not a task is "available"
     in that it *only* applies to activities that are "greyed out" because they are expired, or because
     the task does not allow multiple runs of a completed activity.
     
     @param     schedule    The schedule to check
     @return                `YES` if this schedule is displayed as `enabled` (now or future)
    */
    @objc(shouldShowTaskForSchedule:)
    open func shouldShowTask(for schedule: SBBScheduledActivity) -> Bool {
        // Allow user to perform a task again as long as the task is not expired
        guard let taskRef = bridgeInfo.taskReferenceForSchedule(schedule) else { return false }
        return !schedule.isExpired && (!schedule.isCompleted || taskRef.allowMultipleRun)
    }
    
    /**
     Instantiate the appropriate task view controller.
     
     @param     schedule    The schedule associated with this task
     @param     task        The task to use to instantiate the view controller
     @param     taskRef     The task reference associated with this task
     @return                A new instance of a `SBATaskReference`
    */
    open func instantiateTaskViewController(for schedule: SBBScheduledActivity, task: ORKTask, taskRef: SBATaskReference) -> SBATaskViewController {
        return SBATaskViewController(task: task, taskRun: nil)
    }
    
    /**
     Create the task and task reference for the given schedule.
     
     @param     schedule    The schedule associated with this task
     @return    task        The task instantiated from this schedule
                taskRef     The task reference associated with this task
    */
    open func createTask(for schedule: SBBScheduledActivity) -> (task: ORKTask?, taskRef: SBATaskReference?) {
        guard let taskRef = bridgeInfo.taskReferenceForSchedule(schedule) else { return (nil, nil) }
        let factory = createFactory(for: schedule, taskRef: taskRef)
        let task = taskRef.transformToTask(with: factory, isLastStep: true)
        if let surveyTask = task as? SBASurveyTask {
            surveyTask.title = schedule.activity.label
        }
        return (task, taskRef)
    }
    
    /**
     Create a factory to use when creating a survey or active task. Override to create a custom
     survey factory that can be used to vend custom steps.
     
     @param     schedule    The schedule associated with this task
     @param     taskRef     The task reference associated with this task
     @return                The factory to use for creating the task
    */
    open func createFactory(for schedule: SBBScheduledActivity, taskRef: SBATaskReference) -> SBASurveyFactory {
        return SBASurveyFactory()
    }
    
    /**
     Once the task view controller is instantiated, set up the delegate and schedule identifier.
     Override to setup any custom handling associated with this view controller.
     
     @param     taskViewController  The task view controller to be displayed.
     @param     schedule            The schedule associated with this task
     @param     taskRef             The task reference associated with this task
    */
    open func setup(taskViewController: SBATaskViewController, schedule: SBBScheduledActivity, taskRef: SBATaskReference) {
        taskViewController.scheduleIdentifier = schedule.scheduleIdentifier
        taskViewController.delegate = self
    }
    
    /**
     Subclass can override to provide custom implementation. By default, will return `YES`
     unless this is a survey with an error or the results have already been uploaded.
     
     @param     schedule            The schedule associated with this task
     @param     taskViewController  The task view controller that was displayed.
    */
    @objc(shouldRecordResultForSchedule:taskViewController:)
    open func shouldRecordResult(for schedule: SBBScheduledActivity, taskViewController: ORKTaskViewController) -> Bool {
        
        // Check if the flag has been set that the results are already being uploaded.
        // This allows tasks to be uploaded with the call to task finished *or* in the previous
        // step if the last step is a completion step, but will keep the results from being
        // uploaded more than once.
        if let vc = taskViewController as? SBATaskViewController, vc.hasUploadedResults {
            return false
        }
        
        // Look to see if this is an online survey which has failed to download
        // In this case, do not mark on the server as completed.
        if let task = taskViewController.task as? SBASurveyTask, task.error != nil {
            return false
        }
        
        return true
    }
    
    /**
     This method is called during task finish to handle data sync to the Bridge server.
     It includes updating tracked data changes (such as data groups), marking the schedule
     as finished and archiving the results.
     
     @param     schedule            The schedule associated with this task
     @param     taskViewController  The task view controller that was displayed.
    */
    @objc(recordTaskResultsForTaskViewController:)
    open func recordTaskResults(for taskViewController: ORKTaskViewController) {
        
        // Check if the results of this survey should be uploaded
        guard let schedule = scheduledActivity(for: taskViewController),
            shouldRecordResult(for: schedule, taskViewController:taskViewController)
        else {
            return
        }
        
        // Mark the flag that the results are being uploaded for this task
        if let vc = taskViewController as? SBATaskViewController {
            vc.hasUploadedResults = true
        }
        
        // Update any data stores and groups associated with this task
        taskViewController.task?.commitTrackedDataChanges(user: user,
                                                          taskResult: taskViewController.result,
                                                          completion:handleDataGroupsUpdate)
        
        // Archive the results
        let results = activityResults(for: schedule, taskViewController: taskViewController)
        let archives = results.mapAndFilter({ archive(for: $0) })
        SBADataArchive.encryptAndUploadArchives(archives)
        
        // Update the schedule on the server
        update(schedule: schedule, taskViewController: taskViewController)
    }
    
    /**
     This method is called during task finish to send Bridge server an update to the
     schedule with the `finishedOn` and `startedOn` values set to the start/end timestamp
     for the task view controller.
     
     @param     schedule            The schedule associated with this task
     @param     taskViewController  The task view controller that was displayed.
    */
    open func update(schedule: SBBScheduledActivity, taskViewController: ORKTaskViewController) {
        
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
                    let subschedule = scheduledActivity(for: taskId) , !subschedule.isCompleted {
                    // If schedule is found then set its start/stop time and add to list to update
                    subschedule.startedOn = schedule.startedOn
                    subschedule.finishedOn = schedule.finishedOn
                    scheduledActivities += [subschedule]
                }
            }
        }
        
        // Send message to server
        sendUpdated(scheduledActivities: scheduledActivities)
    }
    
    /**
     Send message to Bridge server to update the given schedules. This includes both the task
     that was completed and any tasks that were performed as a requirement of completion of the
     primary task (such as a required one-time survey).
    */
    open func sendUpdated(scheduledActivities: [SBBScheduledActivity]) {
        SBABridgeManager.updateScheduledActivities(scheduledActivities) {[weak self] (_, _) in
            self?.reloadData()
        }
    }
    
    /**
     Expose method for building archive to allow for testing and subclass override. This method is 
     called during task finish to archive the result for each activity result included in this task.
     @param     activityResult      The `SBAActivityResult` to archive
     @return                        The `SBAActivityArchive` object created with the results for this activity.
    */
    @objc(archiveForActivityResult:)
    open func archive(for activityResult: SBAActivityResult) -> SBAActivityArchive? {
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
    
    
    /**
     Optional method for inserting json prevalidation for a given activity result.
    */
    @objc(jsonValidationMappingForActivityResult:)
    open func jsonValidationMapping(activityResult: SBAActivityResult) -> [String: NSPredicate]?{
        return nil
    }
    
    /**
     Expose method for building results to allow for testing and subclass override. This method is
     called during task finish to parse the `ORKTaskResult` into one or more subtask results. By default,
     this method can split a task into different schema tables for upload to the Bridge server. 
     
     @param     schedule            The schedule associated with this task
     @param     taskViewController  The task view controller that was displayed.
     @return                        An array of `SBAActivityResult` that can be used to build an archive.
     */
    @objc(activityResultsForSchedule:taskViewController:)
    open func activityResults(for schedule: SBBScheduledActivity, taskViewController: ORKTaskViewController) -> [SBAActivityResult] {
        
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
                        let subschedule = scheduledActivity(for: taskId) ?? schedule
                        if subResults.count > 0 {
                            
                            // add dataStore results but only if this is not a data collection itself
                            var subsetResults = subResults
                            if !isDataCollection {
                                for dataStore in dataStores {
                                    if let momentInDayResults = dataStore.momentInDayResults {
                                        // Mark the start/end date with the start timestamp of the first step
                                        for stepResult in momentInDayResults {
                                            stepResult.startDate = subsetResults.first!.startDate
                                            stepResult.endDate = stepResult.startDate
                                        }
                                        // Add the results at the beginning
                                        subsetResults = momentInDayResults + subsetResults
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
    
    /**
     Expose method for handling data groups updating to allow for testing and subclass override.
    */
    open func handleDataGroupsUpdate(error: Error?) {
        if (error != nil) {
            // syoung 09/30/2016 If there was an error with updating the data groups (offline, etc) then
            // reset the last tracked survey date to force prompting for the survey again. While this is 
            // less than ideal UX, it will ensure that there isn't a data sync issue due to the server 
            // setting data groups and not knowing which are more recent.
            SBATrackedDataStore.shared.lastTrackingSurveyDate = nil
        }
    }
    
}

extension ORKTask {
    
    func commitTrackedDataChanges(user: SBAUserWrapper, taskResult: ORKTaskResult, completion: ((Error?) -> Void)?) {
        recursiveUpdateTrackedDataStores(shouldCommit: true)
        updateDataGroups(user: user, taskResult: taskResult, completion: completion)
    }
    
    func resetTrackedDataChanges() {
        recursiveUpdateTrackedDataStores(shouldCommit: false)
    }
    
    private func recursiveUpdateTrackedDataStores(shouldCommit: Bool) {
        guard let navTask = self as? SBANavigableOrderedTask else { return }
        
        // If this task has a conditional rule then update it
        if let collection = navTask.conditionalRule as? SBATrackedDataObjectCollection, collection.dataStore.hasChanges {
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
                subtaskStep.subtask.recursiveUpdateTrackedDataStores(shouldCommit: shouldCommit)
            }
        }
    }
    
    private func updateDataGroups(user: SBAUserWrapper, taskResult: ORKTaskResult, completion: ((Error?) -> Void)?) {
        let previousGroups: Set<String> = Set(user.dataGroups ?? [])
        let groups = recursiveUnionDataGroups(previousGroups: previousGroups, taskResult: taskResult)
        if groups != previousGroups {
            // If the user groups are changed then update
            user.updateDataGroups(Array(groups), completion: completion)
        }
        else {
            // Otherwise call completion
            completion?(nil)
        }
    }
    
    // recursively search for a data group step
    private func recursiveUnionDataGroups(previousGroups: Set<String>, taskResult: ORKTaskResult) -> Set<String> {
        guard let navTask = self as? ORKOrderedTask else { return previousGroups }
        var dataGroups = previousGroups
        for step in navTask.steps {
            if let dataGroupsStep = step as? SBADataGroupsStep,
                let result = taskResult.stepResult(forStepIdentifier: dataGroupsStep.identifier) {
                dataGroups = dataGroupsStep.union(previousGroups: dataGroups, stepResult: result)
            }
            else if let subtaskStep = step as? SBASubtaskStep {
                let subtaskResult = ORKTaskResult(identifier: subtaskStep.subtask.identifier)
                let (subResults, _) = subtaskStep.filteredStepResults(taskResult.results as! [ORKStepResult])
                subtaskResult.results = subResults
                dataGroups = subtaskStep.subtask.recursiveUnionDataGroups(previousGroups: dataGroups, taskResult: subtaskResult)
            }
        }
        return dataGroups
    }
    
}






