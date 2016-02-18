//
//  BridgeAppSDKDelegate.h
//  BridgeAppSDK
//
//  Created by Shannon Young on 2/18/16.
//  Copyright © 2016 Sage Bionetworks. All rights reserved.
//

#ifndef BridgeAppSDKDelegate_h
#define BridgeAppSDKDelegate_h

#import <UIKit/UIKit.h>

@protocol SBABridgeAppSDKDelegate <NSObject, UIApplicationDelegate>
- (NSBundle*)resourceBundle;
- (NSString*)pathForResource:(NSString*)resourceName ofType:(NSString*)resourceType;
@end

#endif /* BridgeAppSDKDelegate_h */
