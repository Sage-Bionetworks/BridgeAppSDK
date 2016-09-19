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
@objc open class SBAAppDelegate: UIResponder, UIApplicationDelegate, SBAAppInfoDelegate, SBABridgeAppSDKDelegate, SBBBridgeAppDelegate, SBAAlertPresenter, ORKPasscodeDelegate  {
    
    open var window: UIWindow?
    
    open var containerRootViewController: SBARootViewControllerProtocol? {
        return window?.rootViewController as? SBARootViewControllerProtocol
    }
    
    public final class var sharedDelegate: SBAAppDelegate? {
        return UIApplication.shared.delegate as? SBAAppDelegate
    }
    
    // MARK: UIApplicationDelegate
    
    open func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
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

    open func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        lockScreen()
        return true
    }
    
    open func applicationWillResignActive(_ application: UIApplication) {
        if shouldShowPasscode() {
            // Hide content so it doesn't appear in the app switcher.
            containerRootViewController?.contentHidden = true
        }
    }
    
    open func applicationDidBecomeActive(_ application: UIApplication) {
        // Make sure that the content view controller is not hiding content
        containerRootViewController?.contentHidden = false
        
        self.currentUser.ensureSignedInWithCompletion() { (error) in
            // Check if there are any errors during sign in that we need to address
            if let error = error, let errorCode = SBBErrorCode(rawValue: error.code) {
                switch errorCode {
                    
                case SBBErrorCode.serverPreconditionNotMet:
                    self.showReconsentIfNecessary()
                    
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
        SBAPermissionsManager.shared().appDidRegister(forRemoteNotifications: notificationSettings)
    }
    
    open func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        if identifier == kBackgroundSessionIdentifier {
            SBABridgeManager.restoreBackgroundSession(identifier, completionHandler: completionHandler)
        }
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
    private let _bridgeInfo = SBABridgeInfoPList()
    
    /**
     A wrapper object for the current user. By default, this class will instantiate a singleton for
     the current user that implements SBAUser.
    */
    open var currentUser: SBAUserWrapper {
        return _currentUser
    }
    private let _currentUser = SBAUser()
    
    /**
     Override to set the permissions for this application.
    */
    open var requiredPermissions: SBAPermissionsType {
        return SBAPermissionsType()
    }
    
    private func initializeBridgeServerConnection() {
        
        // Clearout the keychain if needed. 
        // WARNING: This will force login
        currentUser.resetUserKeychainIfNeeded()
        
        
        // These two lines actually, you know, set up BridgeSDK
        BridgeSDK.setup(withStudy: bridgeInfo.studyIdentifier,
                                 cacheDaysAhead: bridgeInfo.cacheDaysAhead,
                                 cacheDaysBehind: bridgeInfo.cacheDaysBehind,
                                 environment: bridgeInfo.environment)
        SBABridgeManager.setAuthDelegate(self.currentUser)
        
        // This is to kickstart any potentially "orphaned" file uploads from a background thread (but first create the upload
        // manager instance so its notification handlers get set up in time)
        let uploadManager = SBBComponentManager.component(SBBUploadManager.self) as! SBBUploadManagerProtocol
        DispatchQueue.global(qos: .background).async {
            let uploads = SBAEncryptionHelper.encryptedFilesAwaitingUploadResponse()
            for file in uploads {
                let fileUrl = URL(fileURLWithPath: file)
                
                // (if the upload manager already knows about this file, it won't try to upload again)
                // (also, use the method that lets BridgeSDK figure out the contentType since we don't have any better info about that)
                uploadManager.uploadFile(toBridge: fileUrl, completion: { (error) in
                    if error == nil {
                        // clean up the file now that it's been successfully uploaded so we don't keep trying
                        SBAEncryptionHelper.cleanUpEncryptedFile(fileUrl);
                    }
                })
            }
        }
    }
    
    
    // ------------------------------------------------
    // MARK: RootViewController management
    // ------------------------------------------------
    
    /**
     Convenience method for setting up and displaying the appropriate view controller
     for the current user state.
    */
    open func showAppropriateViewController(_ animated: Bool) {
        if (self.catastrophicStartupError != nil) {
            showCatastrophicStartupErrorViewController(animated: animated)
        }
        else if (self.currentUser.loginVerified) {
            showMainViewController(animated: animated)
            if (!self.currentUser.consentVerified) {
                showReconsentIfNecessary()
            }
        }
        else if (self.currentUser.hasRegistered) {
            showEmailVerificationViewController(animated: animated)
        }
        else {
            showOnboardingViewController(animated: animated)
        }
    }
    
    /**
     Abstract method for showing the reconsent flow
    */
    open func showReconsentIfNecessary() {
        assertionFailure("Not implemented. If used, this feature should be implemented at the app level.")
    }
    
    /**
     Abstract method for showing the study overview (onboarding) for a user who is not signed in
    */
    open func showOnboardingViewController(animated: Bool) {
        assertionFailure("Not implemented. If used, this feature should be implemented at the app level.")
    }
    
    /**
     Abstract method for showing the email verification view controller for a user who registered
     but not signed in
    */
    open func showEmailVerificationViewController(animated: Bool) {
        assertionFailure("Not implemented. If used, this feature should be implemented at the app level.")
    }
    
    /**
     Abstract method for showing the main view controller for a user who signed in
    */
    open func showMainViewController(animated: Bool) {
        assertionFailure("Not implemented. If used, this feature should be implemented at the app level.")
    }
    
    /**
     Convenience method for transitioning to the given view controller as the main window
     rootViewController.
    */
    open func transition(toRootViewController: UIViewController, animated: Bool) {
        guard let window = self.window else { return }
        if (animated) {
            UIView.transition(with: window,
                duration: 0.6,
                options: UIViewAnimationOptions.transitionCrossDissolve,
                animations: {
                    window.rootViewController = toRootViewController
                },
                completion: nil)
        }
        else {
            window.rootViewController = toRootViewController
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
    // MARK: Catastrophic startup errors
    // ------------------------------------------------
    
    private var catastrophicStartupError: Error?
    
    /**
     Catastrophic Errors are errors from which the system cannot recover. By default, 
     this will display a screen that blocks all activity. The user is then asked to 
     update their app.
     */
    open func showCatastrophicStartupErrorViewController(animated: Bool) {
        
        // If we cannot open the catastrophic error view controller (for some reason)
        // then this is a fatal error
        guard let vc = SBACatastrophicErrorViewController.instantiateWithMessage(catastrophicErrorMessage) else {
            fatalError(catastrophicErrorMessage)
        }
        
        // Present the view controller
        transition(toRootViewController: vc, animated: true)
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
        return (catastrophicStartupError as? NSError)?.localizedFailureReason ??
            catastrophicStartupError?.localizedDescription ??
            Localization.localizedString("SBA_CATASTROPHIC_FAILURE_MESSAGE")
    }
    
    
    // ------------------------------------------------
    // MARK: Unsupported App Version
    // ------------------------------------------------
    
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
    open func resourceBundle() -> Bundle {
        return Bundle.main
    }
    
    /**
     Default path to a resource. This allows the application to specific fine-grain control over
     where to search for a given resource. By default, this will look in the main bundle.
    */
    open func path(forResource resourceName: String, ofType resourceType: String) -> String? {
        return self.resourceBundle().path(forResource: resourceName, ofType: resourceType)
    }
    
    // ------------------------------------------------
    // MARK: Passcode Display Handling
    // ------------------------------------------------

    private weak var passcodeViewController: UIViewController?
    
    /**
     Should the passcode be displayed. By default, if there isn't a catasrophic error,
     the user is registered and there is a passcode in the keychain, then show it.
    */
    open func shouldShowPasscode() -> Bool {
        return !self.hasCatastrophicError &&
            self.currentUser.hasRegistered &&
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
    
    private func dismissPasscodeViewController(_ animated: Bool) {
        self.passcodeViewController?.presentingViewController?.dismiss(animated: animated, completion: nil)
    }
    
    private func resetPasscode() {
        
        // Dismiss the view controller unanimated
        dismissPasscodeViewController(false)
        
        // Show a plain white view controller while logging out
        let vc = UIViewController()
        vc.view.backgroundColor = UIColor.white
        transition(toRootViewController: vc, animated: false)
        
        // Logout the user
        self.currentUser.logout()
        
        // Show the appropriate view controller
        showAppropriateViewController(true)
    }
    
    // MARK: ORKPasscodeDelegate
    
    open func passcodeViewControllerDidFinish(withSuccess viewController: UIViewController) {
        dismissPasscodeViewController(true)
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
