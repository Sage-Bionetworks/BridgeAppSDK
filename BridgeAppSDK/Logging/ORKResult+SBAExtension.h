//
//  ORKResult+SBAExtension.h
//  BridgeAppSDK
//
//  Created by Erin Mounts on 5/11/16.
//  Copyright © 2016 Sage Bionetworks. All rights reserved.
//

#import <ResearchKit/ResearchKit.h>

@interface ORKResult (SBAExtension)

- (NSData *)sba_bridgeData;

@end
