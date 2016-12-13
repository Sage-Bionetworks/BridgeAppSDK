//
//  SBAEncryptionHelper.swift
//  BridgeAppSDK
//
// Copyright © 2016 Sage Bionetworks. All rights reserved.
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

@objc open class SBAEncryptionHelper: NSObject {
    
    open class func pemPath() -> String? {
        let sharedAppDelegate = UIApplication.shared.delegate as? SBAAppInfoDelegate
        let bridgeInfo = sharedAppDelegate?.bridgeInfo ?? SBABridgeInfoPList.shared
        let certificatePath = Bundle.main.path(forResource: bridgeInfo.certificateName, ofType: "pem")
        return certificatePath
    }
    
    static let kEncryptedDataFilename = "encrypted.zip"
    
    class func isEncryptedURL(_ file: URL) -> Bool {
        return file.lastPathComponent == kEncryptedDataFilename
    }
    
    class func isEncryptedString(_ file: NSString) -> Bool {
        return file.lastPathComponent == kEncryptedDataFilename
    }
    
    class func encryptedDataPathRoot() -> String {
        return NSTemporaryDirectory()
    }
    
    open class func encryptedFilesAwaitingUploadResponse() -> [String] {
        let tmpDir = encryptedDataPathRoot()
        let fileMan = FileManager.default
        
        let tmpContents = fileMan.subpaths(atPath: tmpDir)
        let filesOfInterest = tmpContents?.mapAndFilter({ (file) -> String? in
            guard isEncryptedString(file as NSString) else { return nil }
            return (tmpDir as NSString).appendingPathComponent(file)
        })
        return filesOfInterest ?? []
    }

    open class func cleanUpEncryptedFile(_ file: URL) {
        let dirUrl = isEncryptedURL(file) ? file.deletingLastPathComponent() : file
        
        do {
            try FileManager.default.removeItem(at: dirUrl)
        } catch let error as NSError {
            print("Error thrown attempting to remove %@:\n%@", dirUrl, error)
        }
    }
}
