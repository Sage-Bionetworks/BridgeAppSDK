//
//  BridgeAppSDK.h
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

#import <UIKit/UIKit.h>

//! Project version number for BridgeAppSDK.
FOUNDATION_EXPORT double BridgeAppSDKVersionNumber;

//! Project version string for BridgeAppSDK.
FOUNDATION_EXPORT const unsigned char BridgeAppSDKVersionString[];

#import <BridgeAppSDK/SBAActivityResult.h>
#import <BridgeAppSDK/SBABridgeManager.h>
#import <BridgeAppSDK/SBADataArchive.h>
#import <BridgeAppSDK/SBADataObject.h>
#import <BridgeAppSDK/SBADefines.h>
#import <BridgeAppSDK/SBADemographicDataObjectType.h>
#import <BridgeAppSDK/SBAJSONObject.h>
#import <BridgeAppSDK/SBAKeychainWrapper.h>
#import <BridgeAppSDK/SBALog.h>
#import <BridgeAppSDK/SBAMedication.h>
#import <BridgeAppSDK/SBANewsFeedItem.h>
#import <BridgeAppSDK/SBANewsFeedManager.h>
#import <BridgeAppSDK/SBAPDFPrintPageRenderer.h>
#import <BridgeAppSDK/SBAPermissionsManager.h>
#import <BridgeAppSDK/SBATrackedDataStore.h>
#import <BridgeAppSDK/ORKCollectionResult+SBAExtensions.h>
#import <BridgeAppSDK/ORKOrderedTask+SBAExtension.h>
