//
//  SBAPDFPrintPageRenderer.m
//  BridgeAppSDK
//
//  Created by Shannon Young on 3/1/16.
//  Copyright © 2016 Sage Bionetworks. All rights reserved.
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
