//
//  SBATaskViewController.m
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

#import "SBATaskViewController.h"
#import <BridgeAppSDK/BridgeAppSDK-Swift.h>
#import "ORKOrderedTask+SBAExtension.h"

@implementation SBATaskViewController

- (NSURL *)outputDirectory {
    NSURL *outputDirectory = [super outputDirectory];
    if (outputDirectory == nil) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
        NSString * path = [[paths lastObject] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@", self.taskRunUUID.UUIDString]];
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
            NSError* fileError;
            BOOL created = [[NSFileManager defaultManager] createDirectoryAtPath:path
                                                     withIntermediateDirectories:YES
                                                                      attributes:@{ NSFileProtectionKey : NSFileProtectionCompleteUntilFirstUserAuthentication }
                                                                           error:&fileError];
            if (!created) {
                NSLog (@"Error creating file: %@", fileError);
            }
        }
        
        outputDirectory = [NSURL fileURLWithPath:path];
        [super setOutputDirectory: outputDirectory];
    }
    return outputDirectory;
}

- (void)stepViewControllerWillAppear:(ORKStepViewController *)stepViewController {
    [super stepViewControllerWillAppear:stepViewController];
    
    if ([stepViewController.step isKindOfClass:[ORKCompletionStep class]]) {
        // Set timestamp for when the scheduled activity finished
        _finishedOn = [NSDate date];
        // If this is a completion step, then change the tint color for the view
        // to the app green tint color.
        stepViewController.view.tintColor = [UIColor greenTintColor];
    }
    else if ([stepViewController.step isKindOfClass:[ORKAudioStep class]]) {
        // If this is an audio step, then change the tint color for the view
        // to the app blue tint color.
        stepViewController.view.tintColor = [UIColor blueTintColor];
    }
    
    if ([self shouldHideCancelForStep: stepViewController.step]) {
        // If cancel is disabled then hide on all but the first step
        stepViewController.cancelButtonItem = [[UIBarButtonItem alloc] initWithTitle:nil style:0 target:nil action:nil];
    }
}

- (BOOL)shouldHideCancelForStep:(ORKStep *)step {
    // Should hide the cancel button if cancel is disabled AND either there is only one
    // step in the task OR this is NOT the first step
    
    if (!self.cancelDisabled) {
        // If not disabled then exit early with NO answer
        return NO;
    }
    if (![self.task conformsToProtocol:@protocol(SBATaskExtension)]) {
        // If the task does not respond then assume that cancel should be hidden for all steps
        return YES;
    }
    
    // Otherwise, do not disable the first step IF and ONLY IF there are more than 1 steps.
    id <SBATaskExtension> task = (id <SBATaskExtension>)self.task;
    return [task indexOfStep:step] > 0 || [task stepCount] == 1;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        _scheduledActivityGUID = [aDecoder decodeObjectOfClass:[NSString class] forKey:NSStringFromSelector(@selector(scheduledActivityGUID))];
        _cancelDisabled = [aDecoder decodeBoolForKey:NSStringFromSelector(@selector(cancelDisabled))];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    [aCoder setValue:_scheduledActivityGUID forKey:NSStringFromSelector(@selector(scheduledActivityGUID))];
    [aCoder setValue:@(_cancelDisabled) forKey:NSStringFromSelector(@selector(cancelDisabled))];
}

@end
