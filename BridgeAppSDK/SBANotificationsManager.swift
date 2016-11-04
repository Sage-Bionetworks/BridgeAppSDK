//
//  SBANotificationsManager.swift
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

enum SBAScheduledNotificationType: String {
    case scheduledActivity
}

open class SBANotificationsManager: NSObject, SBASharedInfoController {
    
    static let notificationType = "notificationType"
    static let identifier = "identifier"
    
    @objc(sharedManager)
    open static let shared = SBANotificationsManager()
    
    lazy open var sharedAppDelegate: SBAAppInfoDelegate = {
        return UIApplication.shared.delegate as! SBAAppInfoDelegate
    }()
    
    lazy open var sharedApplication: UIApplication = {
        return UIApplication.shared
    }()
    
    lazy open var permissionsManager: SBAPermissionsManager = {
        return SBAPermissionsManager.shared
    }()
    
    @objc(setupNotificationsForScheduledActivities:)
    open func setupNotifications(for scheduledActivities: [SBBScheduledActivity]) {
        permissionsManager.requestPermission(for: SBANotificationPermissionObjectType.localNotifications()) { [weak self] (granted, _) in
            if granted {
                self?.scheduleNotifications(scheduledActivities: scheduledActivities)
            }
        }
    }
    
    fileprivate func scheduleNotifications(scheduledActivities activities: [SBBScheduledActivity]) {
        
        // Cancel previous notifications
        cancelNotifications(notificationType: .scheduledActivity)
        
        // Add a notification for the scheduled activities that should include one
        let app = sharedApplication
        for sa in activities {
            if let taskRef = self.sharedBridgeInfo.taskReferenceForSchedule(sa)
                , taskRef.scheduleNotification  {
                let notif = UILocalNotification()
                notif.fireDate = sa.scheduledOn
                notif.soundName = UILocalNotificationDefaultSoundName
                notif.alertBody = Localization.localizedStringWithFormatKey("SBA_TIME_FOR_%@", sa.activity.label)
                notif.userInfo = [ SBANotificationsManager.notificationType: SBAScheduledNotificationType.scheduledActivity.rawValue,
                                   SBANotificationsManager.identifier: sa.scheduleIdentifier ]
                app.scheduleLocalNotification(notif)
            }
        }
    }
    
    fileprivate func cancelNotifications(notificationType: SBAScheduledNotificationType) {
        let app = sharedApplication
        if let scheduledNotifications = app.scheduledLocalNotifications {
            for notif in scheduledNotifications {
                if let type = notif.userInfo?[SBANotificationsManager.notificationType] as? String,
                    let notifType = SBAScheduledNotificationType(rawValue: type) , notifType == notificationType {
                    app.cancelLocalNotification(notif)
                }
            }
        }
    }
}
