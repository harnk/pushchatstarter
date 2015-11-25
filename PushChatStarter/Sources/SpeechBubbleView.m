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
                         resizableImageWithCapInsets:UIEdgeInsetsMake(19, 19, 20, 20)];

		righthandImage = [[UIImage imageNamed:@"BubbleRighthand"]
                          resizableImageWithCapInsets:UIEdgeInsetsMake(19, 21, 20, 22)];
	}
}

+(CGSize)frameForText:(NSString*)text sizeWithFont:(UIFont*)font constrainedToSize:(CGSize)size lineBreakMode:(NSLineBreakMode)lineBreakMode  {
    
    NSMutableParagraphStyle * paragraphStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
    paragraphStyle.lineBreakMode = lineBreakMode;
    
    NSDictionary * attributes = @{NSFontAttributeName:font,
                                  NSParagraphStyleAttributeName:paragraphStyle
                                  };
    
    
    CGRect textRect = [text boundingRectWithSize:size
                                         options:NSStringDrawingUsesLineFragmentOrigin
                                      attributes:attributes
                                         context:nil];
    
    //Contains both width & height ... Needed: The height
    return textRect.size;
}

+ (CGSize)sizeForText:(NSString*)text
{
    CGSize textSize = [self frameForText:text sizeWithFont:font constrainedToSize:CGSizeMake(WrapWidth, 9999) lineBreakMode:NSLineBreakByWordWrapping];

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

    [[UIColor whiteColor] set];
    NSMutableParagraphStyle *textStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
    textStyle.lineBreakMode = NSLineBreakByWordWrapping;
    textStyle.alignment = NSTextAlignmentLeft;
    
    NSDictionary *attributes = @{ NSFontAttributeName: font,
                                  NSForegroundColorAttributeName: [UIColor whiteColor],
                                  NSParagraphStyleAttributeName: textStyle };
    
    [_text drawInRect:textRect withAttributes:attributes];
    
}

- (void)setText:(NSString*)newText bubbleType:(BubbleType)newBubbleType
{
	_text = [newText copy];
	_bubbleType = newBubbleType;
	[self setNeedsDisplay];
}
@end
