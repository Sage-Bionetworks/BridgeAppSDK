// 
//  SBADataArchive.h
//  BridgeAppSDK
// 
// Copyright (c) 2015, Apple Inc. All rights reserved. 
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

#import <Foundation/Foundation.h>
#import "SBAJSONObject.h"

NS_ASSUME_NONNULL_BEGIN

@class ORKResult;

@interface SBADataArchive : NSObject

@property (nonatomic, readonly) NSURL *unencryptedURL;

- (instancetype)init NS_UNAVAILABLE;

/**
 Designated Initializer
 
 @param     reference           Reference for the archive used as a directory name in temp directory
 
 @return    APCDataArchive      An instance of APCDataArchive
 */
- (id)initWithReference:(NSString *)reference NS_DESIGNATED_INITIALIZER;


/**
 Add a json serializable object to the info dictionary
 
 @param     object              JSON serializable object to be added to the info dictionary
 
 @param     key                 Key for the json object to be included
 */
- (void)setArchiveInfoObject:(id <SBAJSONObject>)object forKey:(NSString*)key;

/**
 Converts an ORKResult into json data and inserts into the archive.
 This is a "convenience" m
 
 @param     result                  ORKResult to be inserted into the zip archive.
 
 @param     filename                Filename for the json data to be included without path extension
 */
- (void)insertORKResultIntoArchive:(ORKResult *)result filename:(NSString *)filename;


/**
 Converts a dictionary into json data and inserts into the archive.
 
 @param     dictionary              Dictionary to be inserted into the zip archive.
 
 @param     filename                Filename for the json data to be included without path extension
 */
- (void)insertDictionaryIntoArchive:(NSDictionary *)dictionary filename:(NSString *)filename;


/**
 Inserts the data from the file at the url.
 
 @param     url                     URL where the file exists
 
 @param     filename                Filename for the json data to be included without path extension (path extension will be preserved from the url).
 */
- (void)insertURLIntoArchive:(NSURL*)url fileName:(NSString *)filename;

/**
 Inserts the data with the filename and path extension
 
 @param     data                    Data to add to archive
 
 @param     filename                Filename for the data to be included (path extension assumed to be json if excluded)
  */
- (void)insertDataIntoArchive :(NSData *)data filename:(NSString *)filename;

/**
 Inserts an info.json file into the archive.
 
 @param     errorHandler            Called to pass in the error. Take action based on the error.
 */
- (void)completeArchiveWithErrorHandler: (void(^)(NSError * _Nullable error))errorHandler;

/**
 Completes the archive, encrypts it, and uploads it to Bridge, then removes the archive.

 @param     completion              Completion handler. Receives an NSError object or nil; returns void.
 */
-(void)encryptAndUploadArchiveWithCompletion:(void (^)(NSError * _Nullable error))completion;

/**
 Guarantees to delete the archive and its working directory container.
 Call this method when you are finished with the archive, for example after encrypting or uploading.
 */
- (void) removeArchive;

@end

NS_ASSUME_NONNULL_END
