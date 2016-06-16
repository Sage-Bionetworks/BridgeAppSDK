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

@objc
public protocol SBAAppInfoDelegate: class {
    var currentUser: SBAUserWrapper { get }
    var bridgeInfo: SBABridgeInfo { get }
    var requiredPermissions: SBAPermissionsType { get }
}

@UIApplicationMain
@objc public class SBAAppDelegate: UIResponder, UIApplicationDelegate, SBAAppInfoDelegate, SBABridgeAppSDKDelegate, SBBBridgeAppDelegate, SBAAlertPresenter, ORKPasscodeDelegate  {
    
    public var window: UIWindow?
    
    public var containerRootViewController: SBARootViewControllerProtocol? {
        return window?.rootViewController as? SBARootViewControllerProtocol
    }
    
    public class var sharedDelegate: SBAAppDelegate? {
        return UIApplication.sharedApplication().delegate as? SBAAppDelegate
    }
    
    public func application(application: UIApplication, willFinishLaunchingWithOptions launchOptions: [NSObject : AnyObject]?) -> Bool {
        // Override point for customization before application launch.
        
        self.initializeBridgeServerConnection()
        
        // Set the window tint color if applicable
        if let tintColor = UIColor.primaryTintColor() {
            self.window?.tintColor = tintColor
        }
        
        // Setup the view controller
        self.showAppropriateViewController(false)
        
        return true
    }

    public func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject : AnyObject]?) -> Bool {
        lockScreen()
        return true
    }
    
    public func applicationWillResignActive(application: UIApplication) {
        if shouldShowPasscode() {
            // Hide content so it doesn't appear in the app switcher.
            containerRootViewController?.contentHidden = true
        }
    }
    
    public func applicationDidBecomeActive(application: UIApplication) {
        // Make sure that the content view controller is not hiding content
        containerRootViewController?.contentHidden = false
        
        self.currentUser.ensureSignedInWithCompletion() { (error) in
            // Check if there are any errors during sign in that we need to address
            if let error = error {
                if (error.code == SBBErrorCode.ServerPreconditionNotMet.rawValue) {
                    self.showReconsentIfNecessary()
                }
                else if (error.code == SBBErrorCode.UnsupportedAppVersion.rawValue) {
                    self.handleUnsupportedAppVersionError(error, networkManager: nil)
                }
            }
        }
    }
    
    public func applicationWillEnterForeground(application: UIApplication) {
        lockScreen()
    }
    
    public func application(application: UIApplication, didRegisterUserNotificationSettings notificationSettings: UIUserNotificationSettings) {
        SBAPermissionsManager.sharedManager().appDidRegisterForRemoteNotifications(notificationSettings)
    }
    
    // ------------------------------------------------
    // MARK: Optional property overrides
    // ------------------------------------------------
    
    /**
     * Should the email be checked on signUp for the '+test' pattern as part of the email
     * If YES, sign up process will check for special string in email addresses to auto-detect test users
     * If NO, sign up will treat all emails and data as valid in production
     */
    public var shouldPerformTestUserEmailCheckOnSignup : Bool {
        return false
    }
    
    // ------------------------------------------------
    // MARK: Default setup
    // ------------------------------------------------
    
    /**
    * Bridge info used for setting up this study. By default, this is defined in a BridgeInfo.plist
    * but the inheriting AppDelegate subclass can override this to set a different source.
    */
    public var bridgeInfo: SBABridgeInfo {
        return _bridgeInfo
    }
    private let _bridgeInfo = SBABridgeInfoPList()
    
    /**
     * A wrapper object for the current user. By default, this class will instantiate a singleton for
     * the current user that implements SBAUser.
     */
    public var currentUser: SBAUserWrapper {
        return _currentUser
    }
    private let _currentUser = SBAUser()
    
    /**
     * Override to set the permissions for this application.
     */
    public var requiredPermissions: SBAPermissionsType {
        return SBAPermissionsType.None
    }
    
    func initializeBridgeServerConnection() {
        BridgeSDK.setupWithStudy(bridgeInfo.studyIdentifier, useCache:bridgeInfo.useCache, environment: bridgeInfo.environment)
        SBAUserBridgeManager.setAuthDelegate(self.currentUser)
    }
    
    
    // ------------------------------------------------
    // MARK: RootViewController management
    // ------------------------------------------------
    
    public func showAppropriateViewController(animated: Bool) {
        if (self.catastrophicStartupError != nil) {
            showCatastrophicStartupErrorViewController(animated)
        }
        else if (self.currentUser.loginVerified) {
            showMainViewController(animated)
            if (!self.currentUser.consentVerified) {
                showReconsentIfNecessary()
            }
        }
        else if (self.currentUser.hasRegistered) {
            showEmailVerificationViewController(animated)
        }
        else {
            showOnboardingViewController(animated)
        }
    }
    
    public func showReconsentIfNecessary() {
        assertionFailure("Not implemented")
    }
    
    /**
    * Abstract method for showing the study overview (onboarding) for a user who is not signed in
    */
    public func showOnboardingViewController(animated: Bool) {
        assertionFailure("Not implemented")
    }
    
    /**
     * Abstract method for showing the email verification view controller for a user who registered 
     * but not signed in
     */
    public func showEmailVerificationViewController(animated: Bool) {
        assertionFailure("Not implemented")
    }
    
    /**
     * Abstract method for showing the main view controller for a user who signed in
     */
    public func showMainViewController(animated: Bool) {
        assertionFailure("Not implemented")
    }
    
    /**
     * Convenience method for transitioning to the given view controller as the main window
     * rootViewController.
     */
    public func transitionToRootViewController(viewController: UIViewController, animated: Bool) {
        guard let window = self.window else { return }
        if (animated) {
            UIView.transitionWithView(window,
                duration: 0.6,
                options: UIViewAnimationOptions.TransitionCrossDissolve,
                animations: {
                    window.rootViewController = viewController
                },
                completion: nil)
        }
        else {
            window.rootViewController = viewController
        }
    }
    
    /**
     * Convenience method for presenting a modal view controller.
     */
    public func presentViewController(viewController: UIViewController, animated: Bool, completion: (() -> Void)?) {
        guard let rootVC = self.window?.rootViewController else { return }
        var topViewController: UIViewController = rootVC
        while (topViewController.presentedViewController != nil) {
            topViewController = topViewController.presentedViewController!
        }
        topViewController.presentViewController(viewController, animated: animated, completion: completion)
    }
    
    
    // ------------------------------------------------
    // MARK: Catastrophic startup errors
    // ------------------------------------------------
    
    private var catastrophicStartupError: NSError?
    
    public var hasCatastrophicError: Bool {
        return catastrophicStartupError != nil
    }
    
    public func registerCatastrophicStartupError(error: NSError) {
        self.catastrophicStartupError = error
    }
    
    public func showCatastrophicStartupErrorViewController(animated: Bool) {
        // TODO: syoung 03/24/2016 Implement default method
        assertionFailure("Not implemented")
    }
    
    
    // ------------------------------------------------
    // MARK: Unsupported App Version
    // ------------------------------------------------
    
    public func handleUnsupportedAppVersionError(error: NSError, networkManager: SBBNetworkManagerProtocol?) -> Bool {
        registerCatastrophicStartupError(error)
        if let _ = self.window?.rootViewController {
            showCatastrophicStartupErrorViewController(true)
        }
        return true
    }
    
    
    // ------------------------------------------------
    // MARK: SBABridgeAppSDKDelegate
    // ------------------------------------------------

    public func resourceBundle() -> NSBundle {
        return NSBundle.mainBundle()
    }
    
    public func pathForResource(resourceName: String, ofType resourceType: String) -> String? {
        return self.resourceBundle().pathForResource(resourceName, ofType: resourceType)
    }
    
    public func taskReminderManager() -> SBATaskReminderManagerProtocol? {
        // TODO: syoung 04/14/2016 - Erin Mounts: please replace stubbed out implementation
        return nil
    }
    
    // ------------------------------------------------
    // MARK: Passcode Display Handling
    // ------------------------------------------------
    
    public func passcodeViewControllerDidFinishWithSuccess(viewController: UIViewController) {
        dismissPasscodeViewController(true)
    }
    
    public func passcodeViewControllerDidFailAuthentication(viewController: UIViewController) {
        // Do nothing in default implementation
    }
    
    public func passcodeViewControllerForgotPasscodeTapped(viewController: UIViewController) {
        
        let title = Localization.localizedString("SBA_RESET_PASSCODE_TITLE")
        let message = Localization.localizedString("SBA_RESET_PASSCODE_MESSAGE")
        let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        
        let cancelAction = UIAlertAction(title: Localization.buttonCancel(), style: .Cancel, handler: nil)
        alert.addAction(cancelAction)
        
        let logoutAction = UIAlertAction(title: Localization.localizedString("SBA_LOGOUT"), style: .Destructive, handler: { _ in
            self.resetPasscode()
        })
        alert.addAction(logoutAction)
        
        viewController.presentViewController(alert, animated: true, completion: nil)
    }
    
    public func shouldShowPasscode() -> Bool {
        return !self.hasCatastrophicError &&
            self.currentUser.hasRegistered &&
            (self.passcodeViewController == nil) &&
            ORKPasscodeViewController.isPasscodeStoredInKeychain()
    }
    
    public func instantiateViewControllerForPasscode() -> UIViewController? {
        return ORKPasscodeViewController.passcodeAuthenticationViewControllerWithText(nil, delegate: self) as? UIViewController
    }
    
    private weak var passcodeViewController: UIViewController?
    
    func lockScreen() {
        
        guard self.shouldShowPasscode(), let vc = instantiateViewControllerForPasscode() else {
            return
        }
        
        window?.makeKeyAndVisible()
        
        vc.modalPresentationStyle = .FullScreen
        vc.modalTransitionStyle = .CoverVertical
        
        passcodeViewController = vc
        presentViewController(vc, animated: false, completion: nil)        
    }
    
    func dismissPasscodeViewController(animated: Bool) {
        self.passcodeViewController?.presentingViewController?.dismissViewControllerAnimated(animated, completion: nil)
    }
    
    func resetPasscode() {
        
        // Dismiss the view controller unanimated
        dismissPasscodeViewController(false)
        
        // Show a plain white view controller while logging out
        let vc = UIViewController()
        vc.view.backgroundColor = UIColor.whiteColor()
        transitionToRootViewController(vc, animated: false)
        
        // Logout the user
        self.currentUser.logout()
        
        // Show the appropriate view controller
        showAppropriateViewController(true)
    }
    

}
