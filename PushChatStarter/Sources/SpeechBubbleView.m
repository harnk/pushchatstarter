//
//  SpeechBubbleView.m
//  PushChatStarter
//
//  Created by Kauserali on 28/03/13.
//  Copyright (c) 2013 Ray Wenderlich. All rights reserved.
//

#import "SpeechBubbleView.h"

static UIFont* font = nil;
static UIImage* lefthandImage = nil;
static UIImage* righthandImage = nil;

const CGFloat VertPadding = 4;       // additional padding around the edges
const CGFloat HorzPadding = 4;

const CGFloat TextLeftMargin = 17;   // insets for the text
const CGFloat TextRightMargin = 15;
const CGFloat TextTopMargin = 10;
const CGFloat TextBottomMargin = 10;

const CGFloat MinBubbleWidth = 50;   // minimum width of the bubble
const CGFloat MinBubbleHeight = 40;  // minimum height of the bubble

const CGFloat WrapWidth = 200;       // maximum width of text in the bubble

@interface SpeechBubbleView() {
    NSString *_text;
	BubbleType _bubbleType;
}
@end

@implementation SpeechBubbleView

+ (void)initialize
{
	if (self == [SpeechBubbleView class])
	{
		font = [UIFont systemFontOfSize:[UIFont systemFontSize]];

		lefthandImage = [[UIImage imageNamed:@"BubbleLefthand"]
			stretchableImageWithLeftCapWidth:20 topCapHeight:19];

		righthandImage = [[UIImage imageNamed:@"BubbleRighthand"]
			stretchableImageWithLeftCapWidth:20 topCapHeight:19];
	}
}

+ (CGSize)sizeForText:(NSString*)text
{
//    CGSize textSize = [string sizeWithFont:font
//                         constrainedToSize:constrainSize
//                             lineBreakMode:NSLineBreakByWordWrapping];
//    
//    CGRect textRect = [text boundingRectWithSize:textSize
//                                         options:NSStringDrawingUsesLineFragmentOrigin
//                                      attributes:@{NSFontAttributeName:FONT}
//                                         context:nil];
//    WARNING FIX HERE http://stackoverflow.com/questions/18903304/replacement-for-deprecated-sizewithfontconstrainedtosizelinebreakmode-in-ios
//    CGSize textSize = [text sizeWithFont:font
//                       constrainedToSize:CGSizeMake(WrapWidth, 9999)
//                           lineBreakMode:NSLineBreakByWordWrapping];
    
    CGSize textSize = [text boundingRectWithSize:CGSizeMake(WrapWidth, 9999)
                                         options:NSStringDrawingUsesLineFragmentOrigin
                                      attributes:@{NSFontAttributeName: font}
                                         context:nil].size;
	CGSize bubbleSize;
	bubbleSize.width = textSize.width + TextLeftMargin + TextRightMargin;
    
    // Need to add 4 to this otherwise the bottom line of text gets cut off on iPhone 6+
    bubbleSize.height = textSize.height + TextTopMargin + TextBottomMargin + 4;

	if (bubbleSize.width < MinBubbleWidth)
		bubbleSize.width = MinBubbleWidth;

	if (bubbleSize.height < MinBubbleHeight)
		bubbleSize.height = MinBubbleHeight;

	bubbleSize.width += HorzPadding*2;
	bubbleSize.height += VertPadding*2;

	return bubbleSize;
}

- (void)drawRect:(CGRect)rect
{
	[self.backgroundColor setFill];
	UIRectFill(rect);

	CGRect bubbleRect = CGRectInset(self.bounds, VertPadding, HorzPadding);

	CGRect textRect;
	textRect.origin.y = bubbleRect.origin.y + TextTopMargin;
	textRect.size.width = bubbleRect.size.width - TextLeftMargin - TextRightMargin;
	textRect.size.height = bubbleRect.size.height - TextTopMargin - TextBottomMargin;

	if (_bubbleType == BubbleTypeLefthand)
	{
		[lefthandImage drawInRect:bubbleRect];
		textRect.origin.x = bubbleRect.origin.x + TextLeftMargin;
	}
	else
	{
		[righthandImage drawInRect:bubbleRect];
		textRect.origin.x = bubbleRect.origin.x + TextRightMargin;
	}

//    [[UIColor blackColor] set];
    [[UIColor whiteColor] set];

//	deprecated
//    [_text drawInRect:textRect withFont:font lineBreakMode:NSLineBreakByWordWrapping];
    
    /// Make a copy of the default paragraph style
    NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    /// Set line break mode
    paragraphStyle.lineBreakMode = NSLineBreakByTruncatingTail;
    /// Set text alignment
    paragraphStyle.alignment = NSTextAlignmentRight;
    
    NSDictionary *attributes = @{ NSFontAttributeName: font,
                                  NSParagraphStyleAttributeName: paragraphStyle };
    
    [_text drawInRect:rect withAttributes:attributes];
    
}

- (void)setText:(NSString*)newText bubbleType:(BubbleType)newBubbleType
{
	_text = [newText copy];
	_bubbleType = newBubbleType;
	[self setNeedsDisplay];
}
@end
