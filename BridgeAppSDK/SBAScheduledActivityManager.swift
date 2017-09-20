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

public enum SBAScheduleLoadState {
    case firstLoad
    case cachedLoad
    case fromServerWithFutureOnly
    case fromServerForFullDateRange
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
open class SBABaseScheduledActivityManager: NSObject, ORKTaskViewControllerDelegate {

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
    
    /**
     A predicate that can be used to evaluate whether or not a schedule should be included.
     This can include block predicates and is evaluated on a `SBBScheduledActivity` object.
     Default == `true`
     */
    open var scheduleFilterPredicate: NSPredicate = NSPredicate(value: true)

    // MARK: SBAScheduledActivityDataSource
    
    /**
     Reload the data by calling the `SBABridgeManager` and fetching changes to the scheduled activities.
     */
    open func reloadData() {
        
        // Fetch all schedules (including completed)
        let now = Date().startOfDay()
        let fromDate = now.addingNumberOfDays(-1 * daysBehind)
        let toDate = now.addingNumberOfDays(daysAhead + 1)
        
        loadScheduledActivities(from: fromDate, to: toDate)
    }
    
    /**
     Flush the loading state and data stored in memory.
     */
    open func resetData() {
        _loadingState = .firstLoad
        _loadingBlocked = false
        self.activities.removeAll()
    }
    
    /**
     Load a given range of schedules
     */
    open func loadScheduledActivities(from fromDate: Date, to toDate: Date) {
    
        // Exit early if already reloading activities. This can happen if the user flips quickly back and forth from
        // this tab to another tab.
        if (_reloading) {
            _loadingBlocked = true
            return
        }
        _loadingBlocked = false
        _reloading = true
        
        if _loadingState == .firstLoad {
            // If launching, then load from cache *first* before looking to the server
            // This will ensure that the schedule loads quickly (if not first time) and
            // will still load from server to get anything that may have changed dues to
            // added schedules or whatnot. Note: for this project, this is not expected
            // to yeild any different info, but the project could change. syoung 07/17/2017
            _loadingState = .cachedLoad
            SBABridgeManager.fetchAllCachedScheduledActivities() { [weak self] (obj, _) in
                self?.handleLoadedActivities(obj as? [SBBScheduledActivity], from: fromDate, to: toDate)
            }
        }
        else {
            self.loadFromServer(from: fromDate, to: toDate)
        }
    }
    
    fileprivate func loadFromServer(from fromDate: Date, to toDate: Date) {
        
        var loadStart = fromDate
        
        // First load the future and *then* look to the server for the past schedules.
        // This will result in a faster loading for someone who is logging in.
        let todayStart = Date().startOfDay()
        if shouldLoadFutureFirst && fromDate < todayStart && _loadingState == .cachedLoad {
            _loadingState = .fromServerWithFutureOnly
            loadStart = todayStart
        }
        else {
            _loadingState = .fromServerForFullDateRange
        }
        
        fetchScheduledActivities(from: loadStart, to: toDate) { [weak self] (activities, _) in
            self?.handleLoadedActivities(activities, from: fromDate, to: toDate)
        }
    }
    
    fileprivate func handleLoadedActivities(_ scheduledActivities: [SBBScheduledActivity]?, from fromDate: Date, to toDate: Date) {
        
        if _loadingState == .firstLoad {
            // If the loading state is first load then that means the data has been reset so we should ignore the response
            _reloading = false
            if _loadingBlocked {
                loadScheduledActivities(from: fromDate, to: toDate)
            }
            return
        }
        
        DispatchQueue.main.async {
            if let scheduledActivities = self.sortActivities(scheduledActivities) {
                self.load(scheduledActivities: scheduledActivities)
            }
            if self._loadingState == .fromServerForFullDateRange {
                // If the loading state is for the full range, then we are done.
                self._reloading = false
            }
            else {
                // Otherwise, load more range from the server
                self.loadFromServer(from: fromDate, to: toDate)
            }
        }
    }
    
    fileprivate func fetchScheduledActivities(from fromDate: Date, to toDate: Date, completion: @escaping ([SBBScheduledActivity]?, Error?) -> Swift.Void) {
        SBABridgeManager.fetchScheduledActivities(from: fromDate, to: toDate) {(obj, error) in
            completion(obj as? [SBBScheduledActivity], error)
        }
    }
    
    open func sortActivities(_ scheduledActivities: [SBBScheduledActivity]?) -> [SBBScheduledActivity]? {
        guard (scheduledActivities?.count ?? 0) > 0 else { return nil }
        return scheduledActivities!.sorted(by: { (scheduleA, scheduleB) -> Bool in
            guard (scheduleA.scheduledOn != nil) && (scheduleB.scheduledOn != nil) else { return false }
            return scheduleA.scheduledOn.compare(scheduleB.scheduledOn) == .orderedAscending
        })
    }
    
    /**
     When loading schedules, should the manager *first* load all the future schedules.
     If true, this will result in a staged call to the server, where first, the future 
     is loaded and then the server request is made to load past schedules. This will 
     result in a faster loading but may result in undesired behavior for a manager
     that relies upon the past results to build the displayed activities.
     */
    public var shouldLoadFutureFirst = true
    
    /**
     State management for what the current loading state is.  This is used to
     pre-load from cache before going to the server for updates.
     */
    public var loadingState: SBAScheduleLoadState {
        return _loadingState
    }
    fileprivate var _loadingState: SBAScheduleLoadState = .firstLoad
    
    /**
     State management for whether or not the schedules are reloading.
     */
    public var isReloading: Bool {
        return _reloading
    }
    fileprivate var _reloading: Bool = false
    fileprivate var _loadingBlocked: Bool = false
    
    // MARK: Data handling
    
    /**
     Called once the response from the server returns the scheduled activities.
     
     @param     scheduledActivities     The list of activities returned by the service.
     */
    open func load(scheduledActivities: [SBBScheduledActivity]) {
        
        // schedule notifications
        setupNotifications(for: scheduledActivities)
        
        // Filter the scheduled activities to only include those that *this* version of the app is designed
        // to be able to handle. Currently, that means only taskReference activities with an identifier that
        // maps to a known task.
        self.activities = filteredSchedules(scheduledActivities: scheduledActivities)
        
        // reload table
        self.delegate?.reloadFinished(self)
        
        // preload all the surveys so that they can be accessed offline
        if _loadingState == .fromServerForFullDateRange {
            for schedule in scheduledActivities {
                if schedule.activity.survey != nil {
                    SBABridgeManager.loadSurvey(schedule.activity.survey, completion:{ (_, _) in
                    })
                }
            }
        }
    }
    
    /**
     Filter the scheduled activities to only include those that *this* version of the app is designed
     to be able to handle. Currently, that means only taskReference activities with an identifier that
     maps to a known task.
     
     @param     scheduledActivities     The list of activities returned by the service.
     @return                            The filtered list of activities
     */
    open func filteredSchedules(scheduledActivities: [SBBScheduledActivity]) -> [SBBScheduledActivity] {
        if _loadingState == .fromServerWithFutureOnly {
            // The future only will be in a state where we already have the cached data,
            // And we will probably just be appending new data onto the cached data
            let filteredActivities = scheduledActivities.filter({ (activity) in
                return !self.activities.contains(where: { (existingActivity) -> Bool in
                    return existingActivity.guid == activity.guid
                })
            })
            return self.activities.appending(contentsOf: filteredActivities)
        }
        return scheduledActivities.filter({ (schedule) -> Bool in
            return bridgeInfo.taskReferenceForSchedule(schedule) != nil &&
                self.scheduleFilterPredicate.evaluate(with: schedule)
        })
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
        return activities.find({ $0.activityIdentifier == taskIdentifier })
    }

    
    // MARK: ORKTaskViewControllerDelegate
    
    fileprivate let offMainQueue = DispatchQueue(label: "org.sagebase.BridgeAppSDK.SBAScheduledActivityManager")
    open func taskViewController(_ taskViewController: ORKTaskViewController, didFinishWith reason: ORKTaskViewControllerFinishReason, error: Error?) {
        
        // Re-enable the passcode lock. This can be disabled by the display of an active step.
        SBAAppDelegate.shared?.disablePasscodeLock = false
        
        // syoung 07/11/2017 Kludgy work-around for locking interface orientation following showing a
        // view controller that requires landscape orientation
        SBAAppDelegate.shared?.resetOrientation()
        
        // default behavior is to only record the task results if the task completed
        if reason == ORKTaskViewControllerFinishReason.completed {
            recordTaskResults_async(for: taskViewController)
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
        
        // If this is an active step, then we are running an active task. Since most of these tasks are
        // timed, do not show the passcode if the user left the app (accidentally or otherwise) in response
        // to a banner notification.
        if stepViewController.step is ORKActiveStep || stepViewController.step is SBABrainBaselineStep {
            SBAAppDelegate.shared?.disablePasscodeLock = true
        }
        
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
            recordTaskResults_async(for: taskViewController)
        }
    }
    
    open func taskViewController(_ taskViewController: ORKTaskViewController, viewControllerFor step: ORKStep) -> ORKStepViewController? {
        
        // If this is the first step in an activity then look to see if there is a custom intro view controller
        if step.stepViewControllerClass() == ORKInstructionStepViewController.self,
            let task = taskViewController.task as? ORKOrderedTask, task.index(of: step) == 0,
            let schedule = self.scheduledActivity(for: taskViewController),
            let taskRef = bridgeInfo.taskReferenceForSchedule(schedule),
            let vc = instantiateActivityIntroductionStepViewController(for: schedule, step: step, taskRef: taskRef) {
            return vc
        }
        
        // If the default view controller for this step is an `ORKInstructionStepViewController` (and not a subclass)
        // then replace that implementation with the one from this framework.
        if step.stepViewControllerClass() == ORKInstructionStepViewController.self, let task = taskViewController.task {
            return instantiateInstructionStepViewController(for: step, task: task, result: taskViewController.result)
        }

        // If the default view controller for this step is an `ORKCompletionStepViewController` (and not a subclass)
        // then replace that implementation with the one from this framework.
        if step.stepViewControllerClass() == ORKCompletionStepViewController.self, let task = taskViewController.task {
            return instantiateCompletionStepViewController(for: step, task: task, result: taskViewController.result)
        }
        
        // If this is a permissions step then return a page step view controller instead.
        // This will display a paged view controller. Including at this level b/c we are trying to keep
        // ResearchUXFactory agnostic to the UI that Sage uses for our apps.  syoung 05/30/2017
        if step is SBAPermissionsStep {
            return ORKPageStepViewController(step: step)
        }
        
        // By default, return nil
        return nil
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
        } catch let error {
            print("Error removing ResearchKit output directory: \(error.localizedDescription)")
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
                } catch let error {
                    debugPrint("Error: \(error)")
                }
            }
            
            debugPrint("\(mutableFileInfo.count) files left in our sandbox:")
            for fileURL in mutableFileInfo.keys {
                let fileSize = mutableFileInfo[fileURL]
                debugPrint("\(fileURL.path) size:\(String(describing: fileSize))")
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
        let taskViewController =  SBATaskViewController(task: task, taskRun: nil)
        
        // Because of a bug in ResearchKit that looks at the _defaultResultSource ivar rather than 
        // the property, this will always return the view controller as the result source.
        // This allows us to attach a different source. syoung 07/10/2017
        taskViewController.defaultResultSource = createTaskResultSource(for: schedule, task: taskViewController.task!, taskRef: taskRef)
        
        return taskViewController
    }
    
    open func instantiateActivityIntroductionStepViewController(for schedule: SBBScheduledActivity, step: ORKStep, taskRef: SBATaskReference) -> SBAActivityInstructionStepViewController? {
        let vc = SBAActivityInstructionStepViewController(step: step)
        vc.schedule = schedule
        vc.taskReference = taskRef
        return vc
    }
    
    open func instantiateInstructionStepViewController(for step: ORKStep, task: ORKTask, result: ORKTaskResult) -> ORKStepViewController? {
        let vc = SBAInstructionStepViewController(step: step, result: result)
        if let progress = task.progress?(ofCurrentStep: step, with: result) {
            vc.stepNumber = progress.current + 1
            vc.stepTotal = progress.total
        }
        return vc
    }
    
    open func instantiateGenericStepViewController(for step: ORKStep, task: ORKTask, result: ORKTaskResult) -> ORKStepViewController? {
        let vc = SBAGenericStepViewController(step: step, result: result)
        if let progress = task.progress?(ofCurrentStep: step, with: result) {
            vc.stepCount = Int(progress.total)
            vc.stepIndex = Int(progress.current)
        }
        return vc
    }
    
    open func instantiateCompletionStepViewController(for step: ORKStep, task: ORKTask, result: ORKTaskResult)  -> ORKStepViewController? {
        let vc = SBACompletionStepViewController(step: step)
        return vc
    }
    
    /**
     Create the task and task reference for the given schedule.
     
     @param     schedule    The schedule associated with this task
     @return    task        The task instantiated from this schedule
                taskRef     The task reference associated with this task
    */
    open func createTask(for schedule: SBBScheduledActivity) -> (task: ORKTask?, taskRef: SBATaskReference?) {
        guard let taskRef = bridgeInfo.taskReferenceForSchedule(schedule) else { return (nil, nil) }
        
        // get a factory for this task reference
        let factory = createFactory(for: schedule, taskRef: taskRef)
        SBAInfoManager.shared.defaultSurveyFactory = factory
        
        // transform the task reference into a task using the given factory
        let task = taskRef.transformToTask(with: factory, isLastStep: true)
        if let surveyTask = task as? SBASurveyTask {
            surveyTask.title = schedule.activity.label
        }
        
        return (task, taskRef)
    }
    
    /**
     Create a task result source for the given schedule and task.
     
     @param     schedule    The schedule associated with this task
     @param     task        The task instantiated from this schedule
     @param     taskRef     The task reference associated with this task
     @return                The result source to attach to this task (if any)
     */
    open func createTaskResultSource(for schedule:SBBScheduledActivity, task: ORKTask, taskRef: SBATaskReference? = nil) -> ORKTaskResultSource? {
        
        // Look at top-level steps for a subtask that might have its own schedule
        var sources: [SBATaskResultSource] = []
        if let navTask = task as? SBANavigableOrderedTask {
            for step in navTask.steps {
                if let subtaskStep = step as? SBASubtaskStep,
                    let taskId = subtaskStep.taskIdentifier,
                    let subschedule = self.scheduledActivity(for: taskId),
                    let source = self.createTaskResultSource(for: subschedule, task: subtaskStep.subtask) as? SBATaskResultSource {
                    sources.append(source)
                }
            }
        }
        
        // Look for client data that can be used to generate a result source
        let answerMap: [String: Any]? = {
            if let array = schedule.clientData as? [[String : Any]] {
                return array.last
            }
            return schedule.clientData as? [String : Any]
        }()
        
        let hasTrackedSelection: Bool = {
            guard let collection = (task as? SBANavigableOrderedTask)?.conditionalRule as? SBATrackedDataObjectCollection
            else {
                return false
            }
            return collection.dataStore.selectedItems != nil
        }()
        
        if sources.count > 0 {
            // If the sources count is greater than 0 then return a combo result source (even if this schedule
            // does not have an answer map
            return SBAComboTaskResultSource(task: task, answerMap: answerMap ?? [:], sources: sources)
        }
        else if answerMap != nil || hasTrackedSelection {
            // Otherwise, if the answer map is non-nil, or there is a tracked data collection
            // then return a result source for this task specifically
            return SBASurveyTaskResultSource(task: task, answerMap: answerMap ?? [:])
        }
        else {
            // Finally, there is no result source applicable to this task so return nil
            return nil
        }
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
     Method to move upload to background thread.
     */
    func recordTaskResults_async(for taskViewController: ORKTaskViewController) {
        // Check if the results of this survey should be uploaded
        guard let schedule = scheduledActivity(for: taskViewController),
            let inTask = taskViewController.task,
            shouldRecordResult(for: schedule, taskViewController:taskViewController)
            else {
                return
        }
        
        // Mark the flag that the results are being uploaded for this task
        if let vc = taskViewController as? SBATaskViewController {
            vc.hasUploadedResults = true
        }
        
        let task = ((inTask as? NSCopying)?.copy(with: nil) as? ORKTask) ?? inTask
        let result = taskViewController.result.copy() as! ORKTaskResult
        let finishedOn = (taskViewController as? SBATaskViewController)?.finishedOn
        
        self.offMainQueue.async {
            self.recordTaskResults(for: schedule, task: task, result: result, finishedOn: finishedOn)
        }
    }
    
    @available(*, unavailable, message:"Use `recordTaskResults(for:task:result:finishedOn:)` instead.")
    open func recordTaskResults(for taskViewController: ORKTaskViewController) {
    }
    
    /**
     This method is called during task finish to handle data sync to the Bridge server.
     It includes updating tracked data changes (such as data groups), marking the schedule
     as finished and archiving the results.
     
     @param     schedule    The schedule associated with this task
     @param     task        The task being recorded. This is the main task and may include subtasks.
     @param     result      The task result. This is the main task result and may include subtask results.
     @param     finishedOn  The timestamp to use for when the task was finished.
    */
    @objc(recordTaskResultsForSchedule:task:result:finishedOn:)
    open func recordTaskResults(for schedule: SBBScheduledActivity, task: ORKTask, result: ORKTaskResult, finishedOn: Date?) {
        
        // Update any data stores and groups associated with this task
        task.commitTrackedDataChanges(user: user,
                                      taskResult: result,
                                      completion:handleDataGroupsUpdate)
        
        // Archive the results
        let results = activityResults(for: schedule, task: task, result:result)
        let archives = results.mapAndFilter({ archive(for: $0) })
        SBBDataArchive.encryptAndUploadArchives(archives)
        
        // Update the schedule on the server but only if the survey was not ended early
        if !didEndSurveyEarly(schedule: schedule, task: task, result: result) {
            update(schedule: schedule, task: task, result: result, finishedOn: finishedOn)
        }
    }
    
    @available(*, unavailable, message:"Use `update(schedule:task:result:finishedOn:)` instead.")
    open func update(schedule: SBBScheduledActivity, taskViewController: ORKTaskViewController) {
    }
    
    /**
     This method is called during task finish to send Bridge server an update to the
     schedule with the `finishedOn` and `startedOn` values set to the start/end timestamp
     for the task view controller.
     
     @param     schedule            The schedule associated with this task
     @param     task        The task being recorded. This is the main task and may include subtasks.
     @param     result      The task result. This is the main task result and may include subtask results.
     @param     finishedOn  The timestamp to use for when the task was finished.
    */
    open func update(schedule: SBBScheduledActivity, task: ORKTask, result: ORKTaskResult, finishedOn: Date?) {
        
        // Set finish and start timestamps
        schedule.finishedOn = finishedOn ?? result.endDate
        
        schedule.startedOn = result.startDate
        
        // Add any additional schedules
        var scheduledActivities = [schedule]
        
        // Look at top-level steps for a subtask that might have its own schedule
        if let navTask = task as? SBANavigableOrderedTask {
            for step in navTask.steps {
                if let subtaskStep = step as? SBASubtaskStep, let taskId = subtaskStep.taskIdentifier,
                    let subschedule = scheduledActivity(for: taskId) , !subschedule.isCompleted {
                    // If schedule is found then set its start/stop time and add to list to update
                    subschedule.startedOn = schedule.startedOn
                    subschedule.finishedOn = schedule.finishedOn
                    scheduledActivities.append(subschedule)
                }
            }
        }
        
        // Send message to server
        sendUpdated(scheduledActivities: scheduledActivities)
    }
    
    @available(*, unavailable, message:"Use `didEndSurveyEarly(schedule:task:result:)` instead.")
    open func didEndSurveyEarly(schedule: SBBScheduledActivity, taskViewController: ORKTaskViewController) -> Bool {
        return false
    }
    
    /**
     Check to see if the survey was ended early.
     
     @param     schedule    The schedule associated with this task
     @param     task        The task being recorded. This is the main task and may include subtasks.
     @param     result      The task result. This is the main task result and may include subtask results.
     @return                Whether or not the survey ended early and should *not* be marked as finished.
     */
    open func didEndSurveyEarly(schedule: SBBScheduledActivity, task: ORKTask, result: ORKTaskResult) -> Bool {
        if let endResult = result.firstResult( where: { $1 is SBAActivityInstructionResult }) as? SBAActivityInstructionResult,
            endResult.didEndSurvey {
            return true
        }
        return false
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
    
    @available(*, unavailable, message:"Use `activityResults(for:task:result:)` instead.")
    open func activityResults(for schedule: SBBScheduledActivity, taskViewController: ORKTaskViewController) -> [SBAActivityResult] {
        return []
    }
    
    /**
     Expose method for building results to allow for testing and subclass override. This method is
     called during task finish to parse the `ORKTaskResult` into one or more subtask results. By default,
     this method can split a task into different schema tables for upload to the Bridge server. 
     
     @param     schedule    The schedule associated with this task
     @param     task        The task being recorded. This is the main task and may include subtasks.
     @param     result      The task result. This is the main task result and may include subtask results.
     @return                An array of `SBAActivityResult` that can be used to build an archive.
     */
    @objc(activityResultsForSchedule:task:result:)
    open func activityResults(for schedule: SBBScheduledActivity, task: ORKTask, result: ORKTaskResult) -> [SBAActivityResult] {
        
        // If no results, return empty array
        guard result.results != nil else { return [] }
        
        let taskResult = result
        let surveyTask = task as? SBASurveyTask
        
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
        var topLevelResults:[ORKStepResult] = result.consolidatedResults()
        var allResults:[SBAActivityResult] = []
        var dataStores:[SBATrackedDataStore] = []
        
        if let task = task as? SBANavigableOrderedTask {
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
    
    public func commitTrackedDataChanges(user: SBAUserWrapper, taskResult: ORKTaskResult, completion: ((Error?) -> Void)?) {
        recursiveUpdateTrackedDataStores(shouldCommit: true)
        updateDataGroups(user: user, taskResult: taskResult, completion: completion)
    }
    
    public func resetTrackedDataChanges() {
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
        let (groups, changed) = self.union(currentGroups: user.dataGroups, with: taskResult)
        if changed, let dataGroups = groups {
            // If the user groups are changed then update
            user.updateDataGroups(dataGroups, completion: completion)
        }
        else {
            // Otherwise call completion
            completion?(nil)
        }
    }
}

/**
 syoung 05/03/2017
 UI/UX table data source for the presentation used in older apps. We tried to generalize how the schedule
 is displayed to the user (using a subclass of `SBAActivityTableViewController`) but doing so forces the model
 to work around this design for apps that handle scheduling using a different model.
 */
open class SBAScheduledActivityManager: SBABaseScheduledActivityManager, SBAScheduledActivityDataSource {
    
    /**
     Sections to display - this sets up the predicates for filtering activities.
     */
    open var sections: [SBAScheduledActivitySection]! {
        didSet {
            // Filter out any sections that aren't shown
            let filters = sections.mapAndFilter({ filterPredicate(for: $0) })
            self.scheduleFilterPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: filters)
        }
    }
    
    override func commonInit() {
        super.commonInit()
        // Set the default sections
        self.sections = [.today, .keepGoing]
    }
    
    open func numberOfSections() -> Int {
        return sections.count
    }
    
    open func numberOfRows(for section: Int) -> Int {
        return scheduledActivities(for: section).count
    }
    
    open func scheduledActivity(at indexPath: IndexPath) -> SBBScheduledActivity? {
        let schedules = scheduledActivities(for: indexPath.section)
        guard indexPath.row < schedules.count else {
            assertionFailure("Requested row greater than number of rows in section")
            return nil
        }
        return schedules[indexPath.row]
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
    
    /**
     Predicate to use to filter the activities for a given table section.
     
     @param     tableSection    The section index into the table (maps to IndexPath).
     @return                    The predicate to use to filter the table section.
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
     Array of `SBBScheduledActivity` objects for a given table section.
     
     @param     tableSection    The section index into the table (maps to IndexPath).
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
}

extension ORKTaskResult {
    
    public func firstResult(where evaluate: (_ stepResult: ORKStepResult, _ result: ORKResult) -> Bool) -> ORKResult? {
        guard let results = self.results as? [ORKStepResult] else { return nil }
        for stepResult in results {
            guard let stepResults = stepResult.results else { continue }
            for result in stepResults {
                if evaluate(stepResult, result) {
                    return result
                }
            }
        }
        return nil
    }
    
}

