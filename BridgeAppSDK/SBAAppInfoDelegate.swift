//
//  SBAAppInfoDelegate.swift
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

/**
 The App Info Delegate is intended as a light-weight implementation for pointing to
 a current user and bridge info.
 */
@objc
public protocol SBAAppInfoDelegate: NSObjectProtocol {
    
    /**
     The current user object points to a model object that implements the `SBAUserWrapper` protocol.
     The user is designed to handle participant state specific to the current user such as login, 
     consent, name, etc.
    */
    var currentUser: SBAUserWrapper { get }
    
    /**
     The bridge info object points to a model object that implements the `SBABridgeInfo` protocol.
     The bridge info object is designed to vend information needed to sync this app to the Bridge
     server. This includes mapping a task identifier to a task and schema, setting the study identifier,
     handling caching requirements, storing the name of the pem file used for archiving, as well as
     other information that is less commonly required by the app.
    */
    var bridgeInfo: SBABridgeInfo { get }
}

extension SBAAppInfoDelegate {
    func initializeBridgeServerConnection() {
        
        // Clearout the keychain if needed.
        // WARNING: This will force login
        currentUser.resetUserKeychainIfNeeded()
        
        // Setup the study
        SBABridgeManager.setup(withStudy: bridgeInfo.studyIdentifier,
                               cacheDaysAhead: bridgeInfo.cacheDaysAhead,
                               cacheDaysBehind: bridgeInfo.cacheDaysAhead,
                               environment: bridgeInfo.environment,
                               authDelegate: currentUser)
        
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
}
