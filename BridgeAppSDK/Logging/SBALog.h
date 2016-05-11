// 
//  SBALog.h
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
 
#import <Foundation/Foundation.h>



@interface SBALog : NSObject

// ---------------------------------------------------------
#pragma mark - Logging wrappers:  almost generic
// ---------------------------------------------------------

/*
 These macros wrap NSLog.
 
 You can also just call the Objective-C versions yourself.
 The reasons to use the macros are:

 -	Conceptual compatibility with NSLog().  It feels familiar.

 -	The macros automatically include the current file name,
	line number, and Objective-C class and method name.
	You can also provide that stuff to the Obj-C methods
	yourself, by calling the macro SBALogMethodInfo(),
	defined at the bottom of this file.
 */

#define SBALogError( ... )                              [SBALog methodInfo: SBALogMethodInfo ()  errorMessage: __VA_ARGS__]
#define SBALogError2( nsErrorObject )                   [SBALog methodInfo: SBALogMethodInfo ()  error: nsErrorObject]
#define SBALogException( nsException )                  [SBALog methodInfo: SBALogMethodInfo ()  exception: nsException]
#if DEBUG
#define SBALogDebug( ... )                              [SBALog methodInfo: SBALogMethodInfo ()  debug: __VA_ARGS__]
#define SBALogEvent( ... )                              [SBALog methodInfo: SBALogMethodInfo ()  event: __VA_ARGS__]
#define SBALogEventWithData( name, dictionary )         [SBALog methodInfo: SBALogMethodInfo ()  eventName: name  data: dictionary]
#define SBALogViewControllerAppeared()                  [SBALog methodInfo: SBALogMethodInfo ()  viewControllerAppeared: self]
#define SBALogFilenameBeingArchived( filenameOrPath )   [SBALog methodInfo: SBALogMethodInfo ()  filenameBeingArchived: filenameOrPath]
#define SBALogFilenameBeingUploaded( filenameOrPath )   [SBALog methodInfo: SBALogMethodInfo ()  filenameBeingUploaded: filenameOrPath]
#else
#define SBALogDebug( ... )
#define SBALogEvent( ... )
#define SBALogEventWithData( name, dictionary )
#define SBALogViewControllerAppeared()
#define SBALogFilenameBeingArchived( filenameOrPath )
#define SBALogFilenameBeingUploaded( filenameOrPath )
#endif



// ---------------------------------------------------------
#pragma mark - Objective-C versions of Dhanush's API
// ---------------------------------------------------------

/*
 These methods are called by the macros above.
 
 A key feature of these methods is that they take,
 as the first parameter, a nicely-formatted string
 representing the current file, line number, class
 name, and method name.  The macros above provide that
 info for you.  You can also provide it yourself, by
 calling SBALogMethodInfo(), defined at the bottom of
 this file.  (For that matter, you can pass any
 string you like as that first parameter.)

 As with everything else, this is evolving.
 */

/** Please consider calling SBALogError() instead. */
+ (void) methodInfo: (NSString *) SBALogMethodInfo
	   errorMessage: (NSString *) formatString, ... ;

/** Please consider calling SBALogError2() instead. */
+ (void) methodInfo: (NSString *) SBALogMethodInfo
			  error: (NSError *) error;

/** Please consider calling SBALogException() instead. */
+ (void) methodInfo: (NSString *) SBALogMethodInfo
          exception: (NSException *) exception;

/** Please consider calling SBALogDebug() instead. */
+ (void) methodInfo: (NSString *) SBALogMethodInfo
              debug: (NSString *) formatString, ... ;

/** Please consider calling SBALogFilenameBeingArchived() instead. */
+ (void)       methodInfo: (NSString *) SBALogMethodInfo
    filenameBeingArchived: (NSString *) filenameOrPath;

/** Please consider calling SBALogFilenameBeingUploaded() instead. */
+ (void)       methodInfo: (NSString *) SBALogMethodInfo
    filenameBeingUploaded: (NSString *) filenameOrPath;

/** Please consider calling SBALogEvent() instead. */
+ (void) methodInfo: (NSString *) SBALogMethodInfo
			  event: (NSString *) formatString, ... ;

/** Please consider calling SBALogEventWithData() instead. */
+ (void) methodInfo: (NSString *) SBALogMethodInfo
		  eventName: (NSString *) name
			   data: (NSDictionary *) eventDictionary;

/** Please consider calling SBALogViewControllerAppeared() instead. */
+ (void)        methodInfo: (NSString *) SBALogMethodInfo
	viewControllerAppeared: (NSObject *) viewController;



// ---------------------------------------------------------
#pragma mark - Utility Macro
// ---------------------------------------------------------

/**
 Generates an NSString with the current filename,
 line number, class name, and method name.  You can
 use this by itself.  All our logging macros also
 use it.
 
 This macro requires parentheses just for readability,
 so we realize it's doing work (allocating an NSString).
 */
#define SBALogMethodInfo()								\
	([NSString stringWithFormat: @"in %s at %@:%d",		\
		(__PRETTY_FUNCTION__),							\
		@(__FILE__).lastPathComponent,					\
		(int) (__LINE__)								\
	])


@end

// ---------------------------------------------------------
#pragma mark - Macro:  converting varArgs into a string
// ---------------------------------------------------------

/**
 This macro converts a bunch of "..." arguments into an NSString.
 
 (Other keywords to find this chunk of code:  va_args,
 varargs, vaargs, variadic arguments, variadic macro,
 dotdotdot, ellipsis, three dots)
 
 Note that this macro requires ARC.  (To use it without ARC,
 edit the macro to call "autorelease" on formattedMessage before
 returning it.)
 
 
 To use it:
 
 First, create a method that ENDS with a "...", like this:
 
 - (void) printMyStuff: (NSString *) messageFormat, ...
 {
 }
 
 Inside that method, call this macro, passing it the string
 you want to use as a formatting string.  Using the above
 example, it might be:
 
 - (void) printMyStuff: (NSString *) messageFormat, ...
 {
 NSString extractedString = NSStringFromVariadicArgumentsAndFormat ( messageFormat );
 
 //
 // now use the extractedString.  For example:
 //
 NSLog (@"That string was: %@", extractedString);
 }
 
 Behind the scenes, this macro extracts the parameters from
 that "...", takes your formatting string, and passes them
 all to +[NSString stringWithFormat], giving you a normally-
 formatted string as a result.
 
 This macro is identical to typing the following mess into
 the same method:
 
	va_list arguments;
	va_start (arguments, format);
	NSString *formattedMessage = [[NSString alloc] initWithFormat: format
 arguments: arguments];
	va_end (arguments);
 
 ...and then using the string "formattedMessage" somewhere.
 
 If you're interested:  this macro "returns" a value by wrapping
 the whole thing in a ({ ... }) and them simply putting the value
 on a line by itself at the end.
 
 References:
 
 -	Extracting the variadic arguments (the "..." parameter) into an array we pass to NSString:
	http://stackoverflow.com/questions/1420421/how-to-pass-on-a-variable-number-of-arguments-to-nsstrings-stringwithformat
 
 -	"Returning" a value from a macro:
	http://stackoverflow.com/questions/2679182/have-macro-return-a-value
 
 -	More ways to get to the variadic arguments:
	https://developer.apple.com/library/mac/qa/qa1405/_index.html
 
 -	Well-written, general-purpose documentation about writing macros,
	which talks about the rules for defining macro "functions," using
	the trailing "\", and many cool tricks and rules:
	https://gcc.gnu.org/onlinedocs/cpp/Macros.html
 */
#define NSStringFromVariadicArgumentsAndFormat( formatString )				\
    ({																		\
        NSString *formattedMessage = nil;									\
        va_list arguments;													\
        va_start (arguments, formatString);									\
        formattedMessage = [[NSString alloc] initWithFormat: formatString	\
                                                    arguments: arguments];	\
        va_end (arguments);													\
        formattedMessage;													\
    })















