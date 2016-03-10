//
//  SBAPDFPrintPageRenderer.m
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

#import "SBAPDFPrintPageRenderer.h"

#define kSBA_PPI 72
#define SBAMakeSizeWithPPI(width, height) CGSizeMake(width * kSBA_PPI, height * kSBA_PPI)

static const CGFloat HeaderHeight = 25.0;
static const CGFloat FooterHeight = 25.0;
static const CGFloat PageEdge = (72.0 / 4.0);
static const CGFloat A4Width = 8.27;
static const CGFloat A4Height = 11.69;
static const CGFloat LetterWidth = 8.5f;
static const CGFloat LetterHeight = 11.0f;

@implementation SBAPDFPrintPageRenderer

- (instancetype)init {
    self = [super init];
    if (self) {
        // Setup defaults
        _pageSize = [[self class] defaultPageSize];
        _pageMargins = UIEdgeInsetsMake(PageEdge, PageEdge, PageEdge, PageEdge);
        self.headerHeight = HeaderHeight;
        self.footerHeight = FooterHeight;
    }
    return self;
}

+ (CGSize)defaultPageSize {
    NSLocale *locale = [NSLocale currentLocale];
    BOOL useMetric = [[locale objectForKey:NSLocaleUsesMetricSystem] boolValue];
    CGSize pageSize = (useMetric ? SBAMakeSizeWithPPI(A4Width, A4Height) : SBAMakeSizeWithPPI(LetterWidth, LetterHeight)); // A4 and Letter
    return pageSize;
}

+ (CGRect)defaultBounds {
    UIEdgeInsets pageMargins = UIEdgeInsetsMake(PageEdge, PageEdge, PageEdge, PageEdge);
    CGRect paperRect;
    paperRect.size = [self defaultPageSize];
    CGRect printableRect = UIEdgeInsetsInsetRect(paperRect, pageMargins);
    return CGRectMake(0, 0, printableRect.size.width, printableRect.size.height);
}

- (CGRect)paperRect {
    return CGRectMake(0, 0, self.pageSize.width, self.pageSize.height);
}

- (CGRect)printableRect {
    return UIEdgeInsetsInsetRect([self paperRect], self.pageMargins);
}

- (void)drawFooterForPageAtIndex:(NSInteger)pageIndex
                          inRect:(CGRect)footerRect {
    
    NSBundle *bundle = [NSBundle bundleForClass:[SBAPDFPrintPageRenderer class]];
    
    NSString *footerFormat = NSLocalizedStringWithDefaultValue(@"SBA_PAGE_NUMBER_FORMAT", nil, bundle, @"Page %1$@ of %2$@", @"Footer page number format");
    NSString *pageNum = [NSNumberFormatter localizedStringFromNumber:@(pageIndex + 1) numberStyle:NSNumberFormatterNoStyle];
    NSString *numPages = [NSNumberFormatter localizedStringFromNumber:@([self numberOfPages]) numberStyle:NSNumberFormatterNoStyle];
    NSString *footer  = [NSString stringWithFormat:footerFormat, pageNum, numPages];
    
    UIFont *font = [UIFont fontWithName:@"Helvetica" size:12];
    CGSize size = [footer sizeWithAttributes:@{ NSFontAttributeName: font}];
    
    // Center Text
    CGFloat drawX = (CGRectGetWidth(footerRect) / 2) + footerRect.origin.x - (size.width / 2);
    CGFloat drawY = footerRect.origin.y + (footerRect.size.height / 2) - (size.height / 2);
    CGPoint drawPoint = CGPointMake(drawX, drawY);
    
    [footer drawAtPoint:drawPoint withAttributes:@{ NSFontAttributeName: font}];
}

@end
