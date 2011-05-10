// AttributedTableViewCell.m
//
// Copyright (c) 2011 Mattt Thompson (http://mattt.me)
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

static CGFloat const kSummaryTextFontSize = 17;

#import <QuartzCore/QuartzCore.h>
#import "AttributedTableViewCell.h"
#import "TTTAttributedLabel.h"

static NSRegularExpression *__nameRegularExpression;
static inline NSRegularExpression * NameRegularExpression() {
    if (!__nameRegularExpression) {
        __nameRegularExpression = [[NSRegularExpression alloc] initWithPattern:@"^\\w+" options:NSRegularExpressionCaseInsensitive error:nil];
    }
    
    return __nameRegularExpression;
}

static NSRegularExpression *__parenthesisRegularExpression;
static inline NSRegularExpression * ParenthesisRegularExpression() {
    if (!__parenthesisRegularExpression) {
        __parenthesisRegularExpression = [[NSRegularExpression alloc] initWithPattern:@"\\([^\\(\\)]+\\)" options:NSRegularExpressionCaseInsensitive error:nil];
    }
    
    return __parenthesisRegularExpression;
}

@implementation AttributedTableViewCell
@synthesize summaryText = _summaryText;
@synthesize summaryLabel = _summaryLabel;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (!self) {
        return nil; 
    }
    
    self.layer.shouldRasterize = YES;
    self.layer.rasterizationScale = [[UIScreen mainScreen] scale];
    
    _summaryLabel = [[TTTAttributedLabel alloc] initWithFrame:CGRectZero];
    self.summaryLabel.font = [UIFont systemFontOfSize:kSummaryTextFontSize];
    self.summaryLabel.textColor = [UIColor darkGrayColor];
    self.summaryLabel.lineBreakMode = UILineBreakModeWordWrap;
    self.summaryLabel.numberOfLines = 0;
    
    NSMutableDictionary *mutableLinkAttributes = [NSMutableDictionary dictionary];
    [mutableLinkAttributes setObject:[NSNumber numberWithBool:YES] forKey:(NSString*)kCTUnderlineStyleAttributeName];
    self.summaryLabel.linkAttributes = mutableLinkAttributes;
    
    self.selectionStyle = UITableViewCellEditingStyleNone;

    [self.contentView addSubview:self.summaryLabel];
    
    return self;
}

- (void)dealloc {
    [_summaryLabel release];
    [super dealloc];
}

- (void)setSummaryText:(NSString *)text {
    [self willChangeValueForKey:@"summaryText"];
    [_summaryText release];
    _summaryText = [text copy];
    [self didChangeValueForKey:@"summaryText"];
    
    __block NSRegularExpression *regexp = nil;    
    [self.summaryLabel setText:self.summaryText afterInheritingLabelAttributesAndConfiguringWithBlock:^NSAttributedString *(NSMutableAttributedString *mutableAttributedString) {
        NSRange stringRange = NSMakeRange(0, [mutableAttributedString length]);
        
        regexp = NameRegularExpression();
        NSRange nameRange = [regexp rangeOfFirstMatchInString:[mutableAttributedString string] options:0 range:stringRange];
        UIFont *boldSystemFont = [UIFont boldSystemFontOfSize:kSummaryTextFontSize]; 
    	CTFontRef boldFont = CTFontCreateWithName((CFStringRef)boldSystemFont.fontName, boldSystemFont.pointSize, NULL);
    	if (boldFont) {
            [mutableAttributedString addAttribute:(NSString *)kCTFontAttributeName value:(id)boldFont range:nameRange];
            CFRelease(boldFont);
    	}
        
        [mutableAttributedString replaceCharactersInRange:nameRange withString:[[[mutableAttributedString string] substringWithRange:nameRange] uppercaseString]];
        
        regexp = ParenthesisRegularExpression();
        [regexp enumerateMatchesInString:[mutableAttributedString string] options:0 range:stringRange usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {            
            UIFont *italicSystemFont = [UIFont italicSystemFontOfSize:kSummaryTextFontSize];
            CTFontRef italicFont = CTFontCreateWithName((CFStringRef)italicSystemFont.fontName, italicSystemFont.pointSize, NULL);
            if (italicFont) {
                [mutableAttributedString addAttribute:(NSString *)kCTFontAttributeName value:(id)italicFont range:result.range];
                CFRelease(italicFont);
                
                [mutableAttributedString addAttribute:(NSString*)kCTForegroundColorAttributeName value:(id)[[UIColor grayColor] CGColor] range:result.range];
            }
        }];
        
        return mutableAttributedString;
    }];
    
    regexp = NameRegularExpression();
    NSRange linkRange = [regexp rangeOfFirstMatchInString:self.summaryText options:0 range:NSMakeRange(0, [self.summaryText length])];
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://wikipedia.org/wiki/%@", [self.summaryText substringWithRange:linkRange]]];
    [self.summaryLabel addLinkToURL:url withRange:linkRange];
}

+ (CGFloat)heightForCellWithText:(NSString *)text {
    CGFloat height = 10.0f;
    height += ceilf([text sizeWithFont:[UIFont systemFontOfSize:kSummaryTextFontSize] constrainedToSize:CGSizeMake(300.0f, CGFLOAT_MAX) lineBreakMode:UILineBreakModeWordWrap].height);
        
    return height;
}

#pragma mark -
#pragma mark UIView

- (void)layoutSubviews {
    self.textLabel.hidden = YES;
    self.detailTextLabel.hidden = YES;
        
    self.summaryLabel.frame = CGRectOffset(CGRectInset(self.bounds, 20.0f, 5.0f), -10.0f, 0.0f);
}

@end