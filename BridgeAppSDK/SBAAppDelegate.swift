//
//  SBAAppDelegate.swift
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
import BridgeSDK
import ResearchKit


/**
 The BridgeAppSDK delegate is used to define additional functionality on the app delegate.
 It is used throughout this SDK with the assumption that the UIAppDelegate will conform to 
 the methods defined by this protocol.
 */
@objc
public protocol SBABridgeAppSDKDelegate : UIApplicationDelegate, SBAAppInfoDelegate, SBBBridgeErrorUIDelegate, SBAAlertPresenter, SBAOnboardingAppDelegate {
}

/**
 Default name for a embedded json file that can be used to create a `SBAOnboardingManager`.
 (See Onboarding.json in the sample app for an example.)
 */
public let SBAOnboardingJSONFilename = "Onboarding"

/**
 Default name for the storyboard that defines the view controllers to display to a new user
 who has started the onboarding sign up process.
 */
public let SBASignUpStoryboardName = "SignUp"

/**
 Default name for the storyboard that defines the view controllers to display to a new user
 who has not registered or logged in. If this is not applicable to your application, you should
 override `showOnboardingViewController` to set a different view controller as the "root" using
 the method `transition(toRootViewController:state:animated:)`.
 */
public let SBAStudyOverviewStoryboardName = "StudyOverview"

/**
 Default name for the storyboard that defines the view controllers to display to a user who
 has completed registration. If this is not applicable to your application, you should
 override `showMainViewController` to set a different view controller as the "root" using
 the method `transition(toRootViewController:state:animated:)`.
 */
public let SBAMainStoryboardName = "Main"


@UIApplicationMain
@objc open class SBAAppDelegate: UIResponder, SBABridgeAppSDKDelegate, ORKPasscodeDelegate, ORKTaskViewControllerDelegate {
    
    open var window: UIWindow?
    
    public final class var shared: SBAAppDelegate? {
        return UIApplication.shared.delegate as? SBAAppDelegate
    }
    
    // MARK: UIApplicationDelegate
    
    open func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization before application launch.
        
        self.resetUserDataIfLoggedOut()
        self.initializeBridgeServerConnection()
        BridgeSDK.setErrorUIDelegate(self)
        
        // Save any outstanding clientData profile item updates to Bridge, and ensure the class has
        // access to all the SBBScheduledActivity objects in BridgeSDK's cache.
        SBAClientDataProfileItem.updateChangesToBridge()

        // Set the tint colors if applicable
        if let tintColor = UIColor.primaryTintColor {
            self.window?.tintColor = tintColor
        }
        if let tintColor = UIColor.taskNavigationBarTintColor {
            UINavigationBar.appearance(whenContainedInInstancesOf: [ORKTaskViewController.self]).barTintColor = tintColor
        }
        if let tintColor = UIColor.taskNavigationButtonTintColor {
            UINavigationBar.appearance(whenContainedInInstancesOf: [ORKTaskViewController.self]).tintColor = tintColor
        }
        
        // Replace the launch root view controller with an SBARootViewController
        // This allows transitioning between root view controllers while a lock screen
        // or onboarding view controller is being presented modally.
        self.window?.rootViewController = SBARootViewController(rootViewController: self.window?.rootViewController)

        return true
    }

    open func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        if shouldShowPasscode() {
            lockScreen()
        }
        else {
            showAppropriateViewController(animated: true)
        }
        
        return true
    }
    
    open func applicationWillResignActive(_ application: UIApplication) {
        if shouldShowPasscode() {
            // Hide content so it doesn't appear in the app switcher.
            rootViewController?.contentHidden = true
        }
        
        // Save any outstanding clientData profile item updates to Bridge.
        SBAClientDataProfileItem.updateChangesToBridge()
    }
    
    open func applicationDidBecomeActive(_ application: UIApplication) {
        // Make sure that the content view controller is not hiding content
        rootViewController?.contentHidden = false
        
        self.currentUser.ensureSignedInWithCompletion() { (error) in
            // Check if there are any errors during sign in that we need to address
            if let error = error, let errorCode = SBBErrorCode(rawValue: (error as NSError).code) {
                switch errorCode {
                    
                case SBBErrorCode.serverPreconditionNotMet:
                    DispatchQueue.main.async {
                        self.continueOnboardingFlowIfNeeded()
                    }
                    
                case SBBErrorCode.unsupportedAppVersion:
                    if !self.handleUnsupportedAppVersionError(error, networkManager: nil) {
                        self.registerCatastrophicStartupError(error)
                    }
                    
                default:
                    break
                }
            }
        }
    }
    
    open func applicationWillEnterForeground(_ application: UIApplication) {
        lockScreen()
    }
    
    open func application(_ application: UIApplication, didRegister notificationSettings: UIUserNotificationSettings) {
        SBAPermissionsManager.shared.appDidRegister(forNotifications: notificationSettings)
    }
    
    open func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        if identifier == kBackgroundSessionIdentifier {
            SBABridgeManager.restoreBackgroundSession(identifier, completionHandler: completionHandler)
        }
    }
    
    // MARK: Lock orientation to portrait by default
    
    open var defaultOrientationLock: UIInterfaceOrientationMask {
        return .portrait
    }
    
    open func resetOrientation() {
        orientationLock = nil
    }
    
    var orientationLock: UIInterfaceOrientationMask?
    
    open func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return orientationLock ?? defaultOrientationLock
    }
    
    
    // ------------------------------------------------
    // MARK: Default setup
    // ------------------------------------------------
    
    /**
     Bridge info used for setting up this study. By default, this is defined in a BridgeInfo.plist
     but the inheriting AppDelegate subclass can override this to set a different source.
    */
    open var bridgeInfo: SBABridgeInfo {
        return _bridgeInfo
    }
    private let _bridgeInfo: SBABridgeInfo = SBAInfoManager.shared
    
    /**
     A wrapper object for the current user. By default, this class will instantiate a singleton for
     the current user that implements SBAUser.
    */
    open var currentUser: SBAUserWrapper {
        return _currentUser
    }
    private let _currentUser = SBAUser.shared
    
    /**
     Called on launch. This will reset the keychain if the user's stored information
     indicates that they are logged out. This is necessary b/c deleting the app and reinstalling
     does not remove values stored in the keychain.
     */
    open func resetUserDataIfLoggedOut() {
        
        // If the user defaults keys all indicate logged out state
        // and *not* in the middle of onboarding, then reset the user.
        if !currentUser.isLoginVerified &&
            (currentUser.onboardingStepIdentifier == nil) &&
            !currentUser.isConsentVerified &&
            !currentUser.isRegistered {
            currentUser.resetStoredUserData()
        }
    }
    
    // ------------------------------------------------
    // MARK: RootViewController management
    // ------------------------------------------------
    
    /**
     The root view controller for this app. By default, this is setup in `willFinishLaunchingWithOptions`
     as the key window root view controller. This container view controller allows presenting 
     onboarding flow and/or a passcode modally while transitioning the underlying view controller 
     for the appropriate app state.
    */
    open var rootViewController: SBARootViewController? {
        return window?.rootViewController as? SBARootViewController
    }
    
    /**
     Convenience method for setting up and displaying the appropriate view controller
     for the current user state.
     
     @param animated  Should the transition be animated
    */
    open func showAppropriateViewController(animated: Bool) {
        
        let newState: SBARootViewControllerState = {
            if (self.catastrophicStartupError != nil) {
                return .catastrophicError
            }
            else if (self.currentUser.onboardingStepIdentifier != nil) {
                return .signup
            }
            else if (self.currentUser.isLoginVerified) {
                return .main
            }
            else {
                return .studyOverview
            }
        }()
        
        if (newState != self.rootViewController?.state) {
            switch(newState) {
            case .catastrophicError:
                showCatastrophicStartupErrorViewController(animated: animated)
            case .main:
                showMainViewController(animated: animated)
            case .signup:
                showSignUpViewController(animated: animated)
            case .studyOverview:
                showStudyOverviewViewController(animated: animated)
            default: break
            }
        }
        
        continueOnboardingFlowIfNeeded()
    }
    
    /**
     Convenience method for continuing an onboarding flow for reconsent or email verification.
    */
    open func continueOnboardingFlowIfNeeded() {
        if (self.currentUser.isLoginVerified && !self.currentUser.isConsentVerified) {
            presentOnboarding(for: .reconsent)
        }
        else if (!self.currentUser.isLoginVerified &&
            self.currentUser.isRegistered) &&
            (self.rootViewController?.state == .studyOverview) {
            // If this app uses the signup view, then let that view control the flow
            presentOnboarding(for: .signup)
        }
    }
    
    @available(*, unavailable, message:"Use `showStudyOverviewViewController(animated:)` instead.")
    public final func showOnboardingViewController(animated: Bool) {
        showStudyOverviewViewController(animated: animated)
    }
    
    /**
     Method for showing the study overview (onboarding) for a user who is not signed in.
     By default, this method looks for a storyboard named "StudyOverview" that is included
     in the main bundle.
     
     @param animated  Should the transition be animated
     */
    open func showStudyOverviewViewController(animated: Bool) {
        // Check that not already showing onboarding
        guard self.rootViewController?.state != .studyOverview else { return }
        
        // Get the default storyboard
        guard let storyboard = openStoryboard(SBAStudyOverviewStoryboardName),
            let vc = storyboard.instantiateInitialViewController()
            else {
                assertionFailure("Failed to load onboarding storyboard. If default onboarding is used, the storyboard should be implemented at the app level.")
                return
        }
        
        transition(toRootViewController: vc, state: .studyOverview, animated: animated)
    }
    
    open func showSignUpViewController(animated: Bool) {
        // Check that not already showing sign up
        guard self.rootViewController?.state != .signup else { return }
        
        // Get the default storyboard
        guard let storyboard = openStoryboard(SBASignUpStoryboardName),
            let vc = storyboard.instantiateInitialViewController()
            else {
                showStudyOverviewViewController(animated: animated)
                return
        }
        
        transition(toRootViewController: vc, state: .signup, animated: animated)
    }
    
    /**
     Method for showing the main view controller for a user who signed in.
     By default, this method looks for a storyboard named "Main" that is included 
     in the main bundle.
     
     @param animated  Should the transition be animated
    */
    open func showMainViewController(animated: Bool) {
        // Check that not already showing main
        guard self.rootViewController?.state != .main else { return }
        // Get the default storyboard
        guard let storyboard = openStoryboard(SBAMainStoryboardName),
            let vc = storyboard.instantiateInitialViewController()
            else {
                assertionFailure("Failed to load main storyboard. If default onboarding is used, the storyboard should be implemented at the app level.")
                return
        }
        transition(toRootViewController: vc, state: .main, animated: animated)
    }
    
    /**
     Convenience method for opening a storyboard
     
     @param name    Name of the storyboard to open (assumes main bundle)
     @return        Storyboard if found
    */
    open func openStoryboard(_ name: String) -> UIStoryboard? {
        return UIStoryboard(name: name, bundle: nil)
    }
    
    /**
     Convenience method for transitioning to the given view controller as the main window
     rootViewController.
     
     @param viewController      View controller to transition to
     @param state               State of the app 
     @param animated            Should the transition be animated
    */
    open func transition(toRootViewController viewController: UIViewController, state: SBARootViewControllerState, animated: Bool) {
        guard let window = self.window, rootViewController?.state != state else { return }
        if let root = self.rootViewController {
            root.set(viewController: viewController, state: state, animated: animated)
        }
        else {
            if (animated) {
                UIView.transition(with: window,
                    duration: 0.6,
                    options: UIViewAnimationOptions.transitionCrossDissolve,
                    animations: {
                        window.rootViewController = viewController
                    },
                    completion: nil)
            }
            else {
                window.rootViewController = viewController
            }
        }
    }
    
    /**
     Convenience method for presenting a modal view controller.
    */
    open func presentViewController(_ viewController: UIViewController, animated: Bool, completion: (() -> Void)?) {
        guard let rootVC = self.window?.rootViewController else { return }
        var topViewController: UIViewController = rootVC
        while (topViewController.presentedViewController != nil) {
            topViewController = topViewController.presentedViewController!
        }
        topViewController.present(viewController, animated: animated, completion: completion)
    }
    
    // ------------------------------------------------
    // MARK: Onboarding
    // ------------------------------------------------
    
    private weak var onboardingViewController: UIViewController?
    
    /**
     Should the onboarding be displayed (or ignored)? By default, if there isn't a catasrophic error,
     there isn't a lockscreen, and there isn't already an onboarding view controller then show it.
     */
    open func shouldShowOnboarding() -> Bool {
        return !self.hasCatastrophicError &&
            (self.passcodeViewController == nil) &&
            (self.onboardingViewController == nil)
    }
    
    /**
     Get an instance of an onboarding manager for the given `SBAOnboardingTaskType`
     By default, this assumes a json file named "Onboarding" (included in the main bundle) is used 
     to describe the onboarding for this application.
     
     @param onboardingTaskType  `SBAOnboardingTaskType` for which to get the manager. (Ingored by default)
    */
    open func onboardingManager(for onboardingTaskType: SBAOnboardingTaskType) -> SBAOnboardingManager {
        // By default, the onboarding manager returns an onboarding manager for
        return SBAOnboardingManager(jsonNamed: SBAOnboardingJSONFilename)!
    }
    
    /**
     Present onboarding flow for the given type. By default, this will present an SBATaskViewController
     modally with the app delegate as the delegate for the view controller.
     
     @param onboardingTaskType  `SBAOnboardingTaskType` to present
    */
    open func presentOnboarding(for onboardingTaskType: SBAOnboardingTaskType) {
        guard shouldShowOnboarding() else { return }
        let onboardingManager = self.onboardingManager(for: onboardingTaskType)
        guard let taskViewController = onboardingManager.initializeTaskViewController(for: onboardingTaskType)
        else {
            assertionFailure("Failed to create an onboarding manager.")
            return
        }
        
        // present the onboarding
        taskViewController.delegate = self
        self.onboardingViewController = taskViewController
        self.presentViewController(taskViewController, animated: true, completion: nil)
    }
    
    // MARK: ORKTaskViewControllerDelegate
    
    open func taskViewController(_ taskViewController: ORKTaskViewController, didFinishWith reason: ORKTaskViewControllerFinishReason, error: Error?) {
        
        // Discard the registration information that has been gathered so far if not completed
        if (reason != .completed) {
            self.currentUser.resetStoredUserData()
        }
        
        // Show the appropriate view controller
        showAppropriateViewController(animated: false)
        
        // Hide the taskViewController
        taskViewController.dismiss(animated: true, completion: nil)
        self.onboardingViewController = nil
    }
    
    
    // ------------------------------------------------
    // MARK: Catastrophic startup errors
    // ------------------------------------------------
    
    private var catastrophicStartupError: Error?
    
    /**
     Catastrophic Errors are errors from which the system cannot recover. By default, 
     this will display a screen that blocks all activity. The user is then asked to 
     update their app.
     @param animated  Should the transition be animated
     */
    open func showCatastrophicStartupErrorViewController(animated: Bool) {
        
        guard self.rootViewController?.state != .catastrophicError else { return }

        // If we cannot open the catastrophic error view controller (for some reason)
        // then this is a fatal error
        guard let vc = SBACatastrophicErrorViewController.instantiateWithMessage(catastrophicErrorMessage) else {
            fatalError(catastrophicErrorMessage)
        }
        
        // Present the view controller
        transition(toRootViewController: vc, state: .catastrophicError, animated: animated)
    }
    
    /**
     Is there a catastrophic error. 
     */
    public final var hasCatastrophicError: Bool {
        return catastrophicStartupError != nil
    }
    
    /**
     Register a catastrophic error. Once launch is complete, this will trigger showing 
     the error.
     */
    public final func registerCatastrophicStartupError(_ error: Error) {
        self.catastrophicStartupError = error
    }
    
    /**
     The error message to display for a catastrophic error.
    */
    open var catastrophicErrorMessage: String {
        return catastrophicStartupError?.localizedDescription ??
            Localization.localizedString("SBA_CATASTROPHIC_FAILURE_MESSAGE")
    }
    
    // ------------------------------------------------
    // MARK: SBBBridgeErrorUIDelegate
    // ------------------------------------------------
    
    /**
     Default implementation for handling a user who is not consented (because consent has been 
     revoked by the server).
    */
    open func handleUserNotConsentedError(_ error: Error, sessionInfo: Any, networkManager: SBBNetworkManagerProtocol?) -> Bool {
        currentUser.isConsentVerified = false
        DispatchQueue.main.async {
            if self.rootViewController?.state == .main {
                self.continueOnboardingFlowIfNeeded()
            }
        }
        return true
    }
    
    /**
     Default implementation for handling an unsupported app version is to display a
     catastrophic error.
     */
    open func handleUnsupportedAppVersionError(_ error: Error, networkManager: SBBNetworkManagerProtocol?) -> Bool {
        registerCatastrophicStartupError(error)
        DispatchQueue.main.async {
            if let _ = self.window?.rootViewController {
                self.showCatastrophicStartupErrorViewController(animated: true)
            }
        }
        return true
    }
    
    // ------------------------------------------------
    // MARK: SBABridgeAppSDKDelegate
    // ------------------------------------------------

    /**
     Default "main" resource bundle. This allows the application to specific a different bundle
     for a given resource by overriding this method in the app delegate.
    */
    @available(*, deprecated, message:"Use `resourceBundles` on `SBABridgeManager` instead.")
    public final func resourceBundle() -> Bundle {
        return Bundle.main
    }
    
    /**
     Default path to a resource. This allows the application to specific fine-grain control over
     where to search for a given resource. By default, this will look in the main bundle.
    */
    @available(*, deprecated, message:"Use `resourceBundles` on `SBABridgeManager` instead.")
    public final func path(forResource resourceName: String, ofType resourceType: String) -> String? {
        return self.resourceBundle().path(forResource: resourceName, ofType: resourceType)
    }
    
    // ------------------------------------------------
    // MARK: Passcode Display Handling
    // ------------------------------------------------

    private weak var passcodeViewController: UIViewController?
    
    /**
     Is the passcode blocking?
     */
    open func isShowingPasscode() -> Bool {
        return (self.passcodeViewController != nil)
    }
    
    /**
     Should the passcode be displayed. By default, if there isn't a catasrophic error,
     the user is registered and there is a passcode in the keychain, then show it.
    */
    open func shouldShowPasscode() -> Bool {
        return !self.hasCatastrophicError &&
            self.currentUser.isRegistered &&
            (self.passcodeViewController == nil) &&
            ORKPasscodeViewController.isPasscodeStoredInKeychain()
    }
    
    private func instantiateViewControllerForPasscode() -> UIViewController? {
        return ORKPasscodeViewController.passcodeAuthenticationViewController(withText: nil, delegate: self)
    }

    private func lockScreen() {
        
        guard self.shouldShowPasscode(), let vc = instantiateViewControllerForPasscode() else {
            return
        }
        
        window?.makeKeyAndVisible()
        
        vc.modalPresentationStyle = .fullScreen
        vc.modalTransitionStyle = .coverVertical
        
        passcodeViewController = vc
        presentViewController(vc, animated: false, completion: nil)        
    }
    
    private func dismissPasscodeViewController() {
        // Onboarding flow is shown modally (so that the participant can cancel it
        // and return to the study overview). Because of this, the lock screen must be dismissed
        // BEFORE the onboarding is presented. 
        self.showAppropriateViewController(animated: false)
        self.passcodeViewController?.presentingViewController?.dismiss(animated: true) {
            self.continueOnboardingFlowIfNeeded()
        }
        self.passcodeViewController = nil
    }
    
    private func resetPasscode() {
        
        // reset the user
        self.currentUser.resetStoredUserData()

        // then dismiss the passcode view controller
        dismissPasscodeViewController()
    }
    
    // MARK: ORKPasscodeDelegate
    
    open func passcodeViewControllerDidFinish(withSuccess viewController: UIViewController) {
        dismissPasscodeViewController()
    }
    
    open func passcodeViewControllerDidFailAuthentication(_ viewController: UIViewController) {
        // Do nothing in default implementation
    }
    
    open func passcodeViewControllerForgotPasscodeTapped(_ viewController: UIViewController) {
        
        let title = Localization.localizedString("SBA_RESET_PASSCODE_TITLE")
        let message = Localization.localizedString("SBA_RESET_PASSCODE_MESSAGE")
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: Localization.buttonCancel(), style: .cancel, handler: nil)
        alert.addAction(cancelAction)
        
        let logoutAction = UIAlertAction(title: Localization.localizedString("SBA_LOGOUT"), style: .destructive, handler: { _ in
            self.resetPasscode()
        })
        alert.addAction(logoutAction)
        
        viewController.present(alert, animated: true, completion: nil)
    }

}
