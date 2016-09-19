//
//  SBAPermissionsManager.swift
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

import Foundation

extension SBAPermissionsType {
    
    init(items: [UInt]?) {
        let rawValue = items?.reduce(0, |) ?? 0
        self.init(rawValue: rawValue)
    }
    
    init(key: String?) {
        guard let key = key else {
            self.init(rawValue: 0)
            return
        }
        switch key {
        case "camera":
            self.init(rawValue:SBAPermissionsType.camera.rawValue)
        case "coremotion":
            self.init(rawValue:SBAPermissionsType.coremotion.rawValue)
        case "healthKit":
            self.init(rawValue:SBAPermissionsType.healthKit.rawValue)
        case "location":
            self.init(rawValue:SBAPermissionsType.location.rawValue)
        case "localNotifications":
            self.init(rawValue:SBAPermissionsType.localNotifications.rawValue)
        case "microphone":
            self.init(rawValue:SBAPermissionsType.microphone.rawValue)
        case "photoLibrary":
            self.init(rawValue:SBAPermissionsType.photoLibrary.rawValue)
        default:
            let intValue = UInt(key) ?? 0
            self.init(rawValue: intValue)
        }
    }
    
    var items: [UInt] {
        var items: [UInt] = []
        for ii in UInt(0)...UInt(16) {
            let rawValue = 1 << ii
            let member = SBAPermissionsType(rawValue: rawValue)
            if self.contains(member) {
                items.append(rawValue)
            }
        }
        return items
    }
}

extension SBAPermissionsManager {
    
    public func requestPermissions(_ permissions: SBAPermissionsType, alertPresenter: SBAAlertPresenter?, completion: ((Bool) -> Void)?) {
        
        // Exit early if there are no permissions
        let items = permissions.items
        guard items.count > 0 else {
            completion?(true)
            return
        }
        
        // Use a dispatch group to iterate through all the permissions and accept them as
        // a batch, showing an alert for each if not authorized.
        let dispatchGroup = DispatchGroup()
        var allGranted = true
        
        for item in items {
            let permission = SBAPermissionsType(rawValue: item)
            if !self.isPermissionsGranted(for: permission) {
                dispatchGroup.enter()
                self.requestPermission(for: permission, withCompletion: { [weak alertPresenter] (success, error) in
                    allGranted = allGranted && success
                    if !success, let presenter = alertPresenter {
                        DispatchQueue.main.async(execute: {
                            let title = Localization.localizedString("SBA_PERMISSIONS_FAILED_TITLE")
                            let message = error?.localizedDescription ?? Localization.localizedString("SBA_PERMISSIONS_FAILED_MESSAGE")
                            presenter.showAlertWithOk(title, message: message, actionHandler: { (_) in
                                dispatchGroup.leave()
                            })
                        })
                    }
                    else {
                        dispatchGroup.leave()
                    }
                })
            }
        }
        
        dispatchGroup.notify(queue: DispatchQueue.main) {
            completion?(allGranted)
        }
    }
    
}
