//
//  SBAMedication.h
//  BridgeAppSDK
//
//  Created by Shannon Young on 4/4/16.
//  Copyright © 2016 Sage Bionetworks. All rights reserved.
//

#import "SBATrackedDataObject.h"

@interface SBAMedication : SBATrackedDataObject

@property (nonatomic, copy) NSString * _Nonnull name;

@property (nonatomic, copy) NSString * _Nullable detail;

@property (nonatomic, copy) NSString * _Nullable brand;

@property (nonatomic) BOOL injection;

@end
