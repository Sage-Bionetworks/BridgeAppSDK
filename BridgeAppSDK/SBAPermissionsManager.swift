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

extension SBAPermissionsManager {
    
    public static var shared: SBAPermissionsManager {
        return __shared()
    }
    
    /**
     Request permission for each permission in the list.
     
     @param     permissions     List of the permissions being requested
     @param     alertPresenter  Alert presenter to use for showing alert messages
     @param     completion      Completion handler to call when all the permissions have been requested
    */
    public func requestPermissions(for permissions: [SBAPermissionObjectType], alertPresenter: SBAAlertPresenter?, completion: ((Bool) -> Void)?) {
    
        // Exit early if there are no permissions
        guard permissions.count > 0 else {
            completion?(true)
            return
        }

        DispatchQueue.main.async(execute: {
            
            // Use an enumerator to recursively step thorough each permission and request permission
            // for that type.
            var allGranted = true
            let enumerator = (permissions as NSArray).objectEnumerator()
            
            func enumerateRequest() {
                guard let permission = enumerator.nextObject() as? SBAPermissionObjectType else {
                    completion?(allGranted)
                    return
                }

                if self.isPermissionGranted(for: permission) {
                    enumerateRequest()
                }
                else {
                    self.requestPermission(for: permission, completion: { [weak alertPresenter] (success, error) in
                        DispatchQueue.main.async(execute: {
                            allGranted = allGranted && success
                            if !success, let presenter = alertPresenter {
                                
                                    let title = Localization.localizedString("SBA_PERMISSIONS_FAILED_TITLE")
                                    let message = error?.localizedDescription ?? Localization.localizedString("SBA_PERMISSIONS_FAILED_MESSAGE")
                                    presenter.showAlertWithOk(title: title, message: message, actionHandler: { (_) in
                                        enumerateRequest()
                                    })
                                
                            }
                            else {
                                enumerateRequest()
                            }
                        })
                    })
                }
            }
            
            enumerateRequest()
        })
    }
    
    
    // MARK: Deprecated methods included for reverse-compatibility
    
    @available(*, deprecated)
    @objc(permissionTitleForType:)
    open func permissionTitle(for type: SBAPermissionsType) -> String {
        return self.typeIdentifierFor(for: type)?.defaultTitle() ?? ""
    }
    
    @available(*, deprecated)
    @objc(permissionDescriptionForType:)
    open func permissionDescription(for type: SBAPermissionsType) -> String {
        return self.typeIdentifierFor(for: type)?.defaultDescription() ?? ""
    }
}
