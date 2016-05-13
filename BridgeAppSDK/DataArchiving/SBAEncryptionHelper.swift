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

@objc public class SBAEncryptionHelper: NSObject {
    
    public class func pemPath() -> String? {
        let sharedAppDelegate = UIApplication.sharedApplication().delegate as! SBASharedAppDelegate
        let certificatePath = NSBundle.mainBundle().pathForResource(sharedAppDelegate.bridgeInfo.certificateName, ofType: "pem")
        return certificatePath
    }
//    
//    public func encryptFile(url: NSURL, completion: (encryptedUrl: NSURL, error: NSError?) -> Void) -> NSURL? {
//        let unencryptedData = NSData.init(contentsOfURL: url)
//        let sharedAppDelegate = UIApplication.sharedApplication().delegate as! SBASharedAppDelegate
//        let certificatePath = NSBundle.mainBundle().pathForResource(sharedAppDelegate.bridgeInfo.certificateName, ofType: "pem")
//        let encryptedData: NSData
//        do {
//            encryptedData = try SBAEncryption.cmsEncrypt(unencryptedData, identityPath: certificatePath)
//        } catch let error as NSError {
//            print("Error trying to cmsEncrypt the file at \(url.relativePath):\n\(error.description)")
//            return nil
//        }
//        if (encryptedData) {
//            NSString *encryptedPath = [[self workingDirectoryPath] stringByAppendingPathComponent:kEncryptedDataFilename];
//            
//            if ([encryptedZipData writeToFile:encryptedPath options:NSDataWritingAtomic error:&encryptionError]) {
//                url = [[NSURL alloc] initFileURLWithPath:encryptedPath];
//            }
//        }
//        
//        if (completion) {
//            completion(url, encryptionError);
//        }
//
//    }

}
