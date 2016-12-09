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

#import "SBANewsFeedParser.h"
#import "SBANewsFeedItem.h"

static NSString * const kAPCDateFormatLocale_EN_US_POSIX = @"en_US_POSIX";
static NSString * const kAPCFeedDateFormat               = @"EEE, dd MMM yyyy HH:mm:ss Z";

@interface SBANewsFeedParser() <NSXMLParserDelegate>

@property (nonatomic, copy) SBANewsFeedParserCompletionBlock completionBlock;

@property (nonatomic, strong) NSMutableArray *results;

@property (nonatomic, strong) NSXMLParser *parser;
@property (nonatomic, strong) NSString *currentElement;
@property (nonatomic, strong) NSDictionary *attributeDict;
@property (nonatomic, strong) NSMutableString *parsedString;

@property (nonatomic, strong) SBANewsFeedItem *feedItem;

@property (nonatomic, strong) NSDateFormatter *dateFormatter;

@end

dispatch_queue_t feedDispatchQueue()
{
    static dispatch_queue_t q;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        q = dispatch_queue_create("org.sagebase.NewsFeedParser", DISPATCH_QUEUE_SERIAL);
    });
    
    return q;
}

@implementation SBANewsFeedParser

- (instancetype)initWithFeedURL:(NSURL *)feedURL
{
    self = [super init];
    if (self) {
        _feedURL = feedURL;
        
        _completionBlock = nil;
        
        _results = [NSMutableArray new];
        
        _dateFormatter = [NSDateFormatter new];
        [_dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:kAPCDateFormatLocale_EN_US_POSIX]];
        _dateFormatter.dateFormat = kAPCFeedDateFormat;
    }
    return self;
}

- (void)setupParser
{
    if (self.parser) {
        self.parser = nil;
    }
    
    self.parser = [[NSXMLParser alloc] initWithContentsOfURL:self.feedURL];
    self.parser.delegate = self;
    self.parser.shouldResolveExternalEntities = NO;
}

- (void)fetchFeedWithCompletion:(SBANewsFeedParserCompletionBlock)completion
{
    dispatch_async(feedDispatchQueue(), ^{

        [self setupParser];
        
        [self.results removeAllObjects];
        
        self.completionBlock = completion;
        
        BOOL success = [self.parser parse];
        
        if (!success) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (self.completionBlock) {
                    self.completionBlock(nil, self.parser.parserError);
                }
            });
        }
    });
}

#pragma mark - NSXMLParserDelegate methods

- (void)parser:(NSXMLParser *)__unused parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)__unused namespaceURI qualifiedName:(NSString *)__unused qName attributes:(NSDictionary *)attributeDict
{
    self.currentElement = elementName;
    self.attributeDict = attributeDict;
    
    if ([elementName isEqualToString:@"item"] || [elementName isEqualToString:@"entry"]) {
        self.feedItem = [SBANewsFeedItem new];
    }
    
    self.parsedString = [NSMutableString new];
}

- (void)parser:(NSXMLParser *)__unused parser foundCharacters:(NSString *)string
{
    [self.parsedString appendString:string];
}

- (void)parser:(NSXMLParser *)__unused parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)__unused namespaceURI qualifiedName:(NSString *)__unused qName
{
    if ([elementName isEqualToString:@"item"] || [elementName isEqualToString:@"entry"]) {
        [self.results addObject:self.feedItem];
    }
    
    if (self.feedItem != nil && self.parsedString != nil) {
        if ([elementName isEqualToString:@"title"]) {
            self.feedItem.title = self.parsedString;
        } else if ([elementName isEqualToString:@"description"]) {
            self.feedItem.itemDescription = self.parsedString;
        } else if ([elementName isEqualToString:@"content:encoded"] || [elementName isEqualToString:@"content"]) {
            self.feedItem.content = self.parsedString;
        } else if ([elementName isEqualToString:@"link"]) {
            self.feedItem.link = self.parsedString;
        } else if ([elementName isEqualToString:@"pubDate"]) {
            _dateFormatter.dateFormat = kAPCFeedDateFormat;
            self.feedItem.pubDate = [self.dateFormatter dateFromString:self.parsedString];
        } else if ([elementName isEqualToString:@"dc:creator"]) {
            self.feedItem.author = self.parsedString;
        } else if ([elementName isEqualToString:@"guid"]) {
            self.feedItem.guid = self.parsedString;
        }
        
        // sometimes the URL is inside enclosure element, not in link. Reference: http://www.w3schools.com/rss/rss_tag_enclosure.asp
        if ([elementName isEqualToString:@"enclosure"] && self.attributeDict != nil) {
            NSString *url = [self.attributeDict objectForKey:@"url"];
            if(url) {
                self.feedItem.link = url;
            }
        }
    }
}

- (void)parserDidEndDocument:(NSXMLParser *)__unused parser
{
    __weak typeof(self) weakSelf = self;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        __strong typeof(self) strongSelf = weakSelf;
        
        if (strongSelf.completionBlock) {
            strongSelf.completionBlock([NSArray arrayWithArray:strongSelf.results], nil);
        }
    });
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError
{
    __weak typeof(self) weakSelf = self;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (weakSelf.completionBlock) {
            weakSelf.completionBlock(nil, parseError);
        }
    });
    
    [parser abortParsing];
}

- (void)parser:(NSXMLParser *)parser validationErrorOccurred:(NSError *)validationError
{
    __weak typeof(self) weakSelf = self;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (weakSelf.completionBlock) {
            weakSelf.completionBlock(nil, validationError);
        }
    });
    
    [parser abortParsing];
}
                         
@end



