// 
//  SBALog.m 
//  BridgeAppSDK 
//
// Copyright © 2016 Sage Bionetworks.
// Copyright (c) 2015, Apple Inc. All rights reserved. 
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
 
#import "SBALog.h"
//#import "SBAConstants.h"
//#import "SBAUtilities.h"
//#import "NSError+SBAAdditions.h"


static NSDateFormatter *dateFormatter = nil;
static NSString * const kErrorIndentationString = @"    ";


/**
 Apple says they use these formatting codes:
 http://www.unicode.org/reports/tr35/tr35-31/tr35-dates.html#Date_Format_Patterns
 */
static NSString *LOG_DATE_FORMAT = @"yyyy-MM-dd HH:mm:ss.SSS ZZZZ";


// ---------------------------------------------------------
#pragma mark - "Tags" - introductory strings in print statements
// ---------------------------------------------------------

/*
 "Tags" that appear at the left edge of the debugging
 statements we print with this logging facility.
 */

static NSString * const SBALogTagError   = @"SBA_ERROR  ";
static NSString * const SBALogTagDebug   = @"SBA_DEBUG  ";
static NSString * const SBALogTagEvent   = @"SBA_EVENT  ";
static NSString * const SBALogTagData    = @"SBA_DATA   ";
static NSString * const SBALogTagView    = @"SBA_VIEW   ";
static NSString * const SBALogTagArchive = @"SBA_ARCHIVE";
static NSString * const SBALogTagUpload  = @"SBA_UPLOAD ";

@interface NSError (SBALog)

- (NSString *)friendlyFormattedString;

@end

@implementation SBALog



// ---------------------------------------------------------
#pragma mark - Setup
// ---------------------------------------------------------

/**
 Set global, static values the first time anyone calls this class.

 By definition, this method is called once per class, in a thread-safe
 way, the first time the class is sent a message -- basically, the first
 time we refer to the class.  That means we can use this to set up stuff
 that applies to all objects (instances) of this class.

 Documentation:  See +initialize in the NSObject Class Reference.  Currently, that's here:
 https://developer.apple.com/library/ios/documentation/Cocoa/Reference/Foundation/Classes/NSObject_Class/index.html#//apple_ref/occ/clm/NSObject/initialize
 */
+ (void) initialize
{
	if (dateFormatter == nil)
	{
		dateFormatter = [NSDateFormatter new];
		dateFormatter.dateFormat = LOG_DATE_FORMAT;
	}
}

// ---------------------------------------------------------
#pragma mark - New Logging Methods.  No, really.
// ---------------------------------------------------------

+ (void) methodInfo: (NSString *) sbaLogMethodInfo
	   errorMessage: (NSString *) formatString, ...
{
	if (formatString == nil)
	{
		formatString = @"(no message)";
	}

	NSString *formattedMessage = NSStringFromVariadicArgumentsAndFormat(formatString);

	[self logInternal_tag: SBALogTagError
				   method: sbaLogMethodInfo
				  message: formattedMessage];
}

+ (void) methodInfo: (NSString *) sbaLogMethodData
			  error: (NSError *) error
{
	if (error != nil)
	{
        // Note:  this is expensive.
        NSString *description = error.friendlyFormattedString;

		[self logInternal_tag: SBALogTagError
					   method: sbaLogMethodData
					  message: description];
	}
}

+ (void) methodInfo: (NSString *) sbaLogMethodData
		  exception: (NSException *) exception
{
	if (exception != nil)
	{
		NSString *printout = [NSString stringWithFormat: @"EXCEPTION: [%@]. Stack trace:\n%@", exception, exception.callStackSymbols];

		[self logInternal_tag: SBALogTagError
					   method: sbaLogMethodData
					  message: printout];
	}
}

+ (void) methodInfo: (NSString *) sbaLogMethodData
			  debug: (NSString *) formatString, ...
{
	if (formatString == nil)
	{
		formatString = @"(no message)";
	}

	NSString *formattedMessage = NSStringFromVariadicArgumentsAndFormat(formatString);

	[self logInternal_tag: SBALogTagDebug
				   method: sbaLogMethodData
				  message: formattedMessage];
}

+ (void)       methodInfo: (NSString *) sbaLogMethodInfo
    filenameBeingArchived: (NSString *) filenameOrPath
{
    NSString *message = [NSString stringWithFormat: @"Adding file to .zip archive for uploading: [%@]", filenameOrPath];

    [self logInternal_tag: SBALogTagArchive
                   method: sbaLogMethodInfo
                  message: message];
}

+ (void)       methodInfo: (NSString *) sbaLogMethodInfo
    filenameBeingUploaded: (NSString *) filenameOrPath
{
    NSString *message = [NSString stringWithFormat: @"Uploading file to Sage: [%@]", filenameOrPath];

    [self logInternal_tag: SBALogTagUpload
                   method: sbaLogMethodInfo
                  message: message];
}

+ (void) methodInfo: (NSString *) sbaLogMethodData
			  event: (NSString *) formatString, ...
{
	if (formatString == nil)
	{
		formatString = @"(no message)";
	}

	NSString *formattedMessage = NSStringFromVariadicArgumentsAndFormat(formatString);

	[self logInternal_tag: SBALogTagEvent
				   method: sbaLogMethodData
				  message: formattedMessage];
}

+ (void) methodInfo: (NSString *) sbaLogMethodData
		  eventName: (NSString *) eventName
			   data: (NSDictionary *) eventDictionary
{
	NSString *message = [NSString stringWithFormat: @"%@: %@", eventName, eventDictionary];

	[self logInternal_tag: SBALogTagData
				   method: sbaLogMethodData
				  message: message];
}

+ (void)        methodInfo: (NSString *) sbaLogMethodData
	viewControllerAppeared: (NSObject *) viewController
{
	NSString *message = [NSString stringWithFormat: @"%@ appeared.", NSStringFromClass (viewController.class)];

	[self logInternal_tag: SBALogTagView
				   method: sbaLogMethodData
				  message: message];
}



// ---------------------------------------------------------
#pragma mark - The centralized, internal logging method
// ---------------------------------------------------------

+ (void) logInternal_tag: (NSString *) tag
				  method: (NSString *) methodInfo
				 message: (NSString *) message
{
	/*
	 Objective-C disables all NSLog() statements in
	 a "release" build, so this is safe to leave as-is.
	 */
    
    // Although the above statement is not in fact true, this wouldn't be the right place
    // to handle it anyway, as error- and exception-level log messages are still useful
    // in release builds.
	NSLog (@"%@ %@ => %@", tag, methodInfo, message);
}

@end

@implementation NSError (SBALog)

static NSString * const oneTab = @"    ";

// ---------------------------------------------------------
#pragma mark - Friendly printouts
// ---------------------------------------------------------

- (NSString *)friendlyFormattedString
{
    return [self friendlyFormattedStringAtLevel: 0];
}

- (NSString *)friendlyFormattedStringAtLevel:(NSUInteger)tabLevel
{
    NSMutableString *output = [NSMutableString new];
    NSString *tab = [@"" stringByPaddingToLength: tabLevel * oneTab.length
                                      withString: oneTab
                                 startingAtIndex: 0];
    
    NSString *tabForNestedObjects = [NSString stringWithFormat: @"\n%@", tab];
    NSString *domain = self.domain.length > 0 ? self.domain : @"(none)";
    
    [output appendFormat: @"%@Code: %@\n", tab, @(self.code)];
    [output appendFormat: @"%@Domain: %@\n", tab, domain];
    
    if (self.userInfo.count > 0) {
        for (NSString *key in [self.userInfo.allKeys sortedArrayUsingSelector: @selector (compare:)]) {
            id value = self.userInfo [key];
            NSString *valueString = nil;
            
            if ([value isKindOfClass: [NSError class]]) {
                valueString = [value friendlyFormattedStringAtLevel: tabLevel + 1];
                [output appendFormat: @"%@%@:\n%@", tab, key, valueString];
            }
            else {
                valueString = [NSString stringWithFormat: @"%@", value];
                valueString = [valueString stringByReplacingOccurrencesOfString: @"\\n" withString: @"\n"];
                valueString = [valueString stringByReplacingOccurrencesOfString: @"\\\"" withString: @"\""];
                valueString = [valueString stringByReplacingOccurrencesOfString: @"\n" withString: tabForNestedObjects];
                [output appendFormat: @"%@%@: %@\n", tab, key, valueString];
            }
        }
    }
    
    if (tabLevel == 0)  {
        [output insertString: @"An error occurred. Available info:\n----- ERROR INFO -----\n" atIndex: 0];
        
        if ([output characterAtIndex: output.length - 1] != '\n') {
            [output appendString: @"\n"];
        }
        
        [output appendString: @"----------------------"];
    }
    
    /*
     Ship it.
     */
    return output;
}

@end










