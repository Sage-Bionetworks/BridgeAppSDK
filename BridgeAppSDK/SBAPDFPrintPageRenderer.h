//
//  SBAPDFPrintPageRenderer.h
//  BridgeAppSDK
//
//  Created by Shannon Young on 3/1/16.
//  Copyright © 2016 Sage Bionetworks. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SBAPDFPrintPageRenderer : UIPrintPageRenderer

@property (nonatomic) UIEdgeInsets pageMargins;
@property (nonatomic) CGSize pageSize;

@end
