//
// Copyright © 2016 Sage Bionetworks. All rights reserved.
// Copyright (c) 2015, Apple Inc.
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

#import "SBANewsFeedItem.h"

@implementation SBANewsFeedItem

- (instancetype)init
{
    self = [super init];
    if (self) {
        _title = @"";
        _link = @"";
        _content = @"";
        _itemDescription = @"";
        
    }
    return self;
}

- (NSArray *)imageURLsFromItemDescription
{
    NSArray *images = nil;
    
    if (self.itemDescription) {
        images = [self imageURLsFromHTMLString:self.itemDescription];
    }
    
    return images;
}

- (NSArray *)imageURLsFromContent
{
    NSArray *images = nil;
    
    if (self.content) {
        images = [self imageURLsFromHTMLString:self.content];
    }
    
    return images;
}

#pragma mark - retrieve images from html string using regexp

- (NSArray *)imageURLsFromHTMLString:(NSString *)htmlstr
{
    NSMutableArray *imagesURLStringArray = [NSMutableArray new];
    
    NSError *error;
    
    NSRegularExpression *regex = [NSRegularExpression
                                  regularExpressionWithPattern:@"(https?)\\S*(png|jpg|jpeg|gif)"
                                  options:NSRegularExpressionCaseInsensitive
                                  error:&error];
    
    if (!error) {
        [regex enumerateMatchesInString:htmlstr
                                options:0
                                  range:NSMakeRange(0, htmlstr.length)
                             usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags __unused flags, __unused BOOL *stop) {
                                 [imagesURLStringArray addObject:[htmlstr substringWithRange:result.range]];
                             }];
    }
    
    
    return [NSArray arrayWithArray:imagesURLStringArray];
}

@end
