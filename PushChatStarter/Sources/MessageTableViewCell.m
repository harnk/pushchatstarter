//
//  MessageTableViewCell.m
//  PushChatStarter
//
//  Created by Kauserali on 28/03/13.
//  Copyright (c) 2013 Ray Wenderlich. All rights reserved.
//

#import "MessageTableViewCell.h"
#import "Message.h"
#import "SpeechBubbleView.h"
#import "SingletonClass.h"

static UIColor* color = nil;

@interface MessageTableViewCell() {
    SpeechBubbleView *_bubbleView;
	UILabel *_label;
}
@end

@implementation MessageTableViewCell

+ (void)initialize
{
	if (self == [MessageTableViewCell class])
	{
//        color = [UIColor colorWithRed:219/255.0 green:226/255.0 blue:237/255.0 alpha:1.0];
        color = [UIColor colorWithRed:255/255.0 green:255/255.0 blue:255/255.0 alpha:1.0];
	}
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString*)reuseIdentifier
{
	if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]))
	{
		self.selectionStyle = UITableViewCellSelectionStyleNone;

		// Create the speech bubble view
		_bubbleView = [[SpeechBubbleView alloc] initWithFrame:CGRectZero];
		_bubbleView.backgroundColor = color;
		_bubbleView.opaque = YES;
		_bubbleView.clearsContextBeforeDrawing = NO;
		_bubbleView.contentMode = UIViewContentModeRedraw;
		_bubbleView.autoresizingMask = 0;
		[self.contentView addSubview:_bubbleView];

		// Create the label
		_label = [[UILabel alloc] initWithFrame:CGRectZero];
		_label.backgroundColor = color;
		_label.opaque = YES;
		_label.clearsContextBeforeDrawing = NO;
		_label.contentMode = UIViewContentModeRedraw;
		_label.autoresizingMask = 0;
		_label.font = [UIFont systemFontOfSize:11];
        // Use WhereRU orange
		_label.textColor = [UIColor colorWithRed:242/255.0 green:149/255.0 blue:0/255.0 alpha:1.0];
		[self.contentView addSubview:_label];
	}
	return self;
}

- (void)layoutSubviews
{
	// This is a little trick to set the background color of a table view cell.
	[super layoutSubviews];
	self.backgroundColor = color;
}

-(CGRect)currentScreenBoundsDependOnOrientation
{
    
    CGRect screenBounds = [UIScreen mainScreen].bounds ;
    CGFloat width = CGRectGetWidth(screenBounds)  ;
    CGFloat height = CGRectGetHeight(screenBounds) ;
    UIInterfaceOrientation interfaceOrientation = [UIApplication sharedApplication].statusBarOrientation;
    
    if(UIInterfaceOrientationIsPortrait(interfaceOrientation)){
        screenBounds.size = CGSizeMake(width, height);
    }else if(UIInterfaceOrientationIsLandscape(interfaceOrientation)){
        screenBounds.size = CGSizeMake(height, width);
    }
    return screenBounds ;
}

- (void)setMessage:(Message*)message
{
//    CGPoint point = CGPointZero;
    CGPoint point = CGPointMake(0, 9);
    CGRect myrect;

	// We display messages that are sent by the user on the right-hand side of
	// the screen. Incoming messages are displayed on the left-hand side.
    NSString* senderName;
	BubbleType bubbleType;
	if ([message isSentByUser])
	{
		bubbleType = BubbleTypeRighthand;
		senderName = NSLocalizedString(@"You", nil);
        
        myrect = [self currentScreenBoundsDependOnOrientation];
        
        point.x = myrect.size.width  - message.bubbleSize.width;
//        point.x = self.bounds.size.width - message.bubbleSize.width;
        NSLog(@"SCXTT myrect.size.width: %f",myrect.size.width);
        
		_label.textAlignment = NSTextAlignmentRight;
	}
	else
	{
		bubbleType = BubbleTypeLefthand;
		senderName = message.senderName;
		_label.textAlignment = NSTextAlignmentLeft;
	}

	// Resize the bubble view and tell it to display the message text
	CGRect rect;
	rect.origin = point;
    rect.size = message.bubbleSize;
	_bubbleView.frame = rect;
	[_bubbleView setText:message.text bubbleType:bubbleType];

	// Format the message date
	NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
	[formatter setDateStyle:NSDateFormatterShortStyle];
	[formatter setTimeStyle:NSDateFormatterShortStyle];
	[formatter setDoesRelativeDateFormatting:YES];
	NSString* dateString = [formatter stringFromDate:message.date];
    

    //Format the location to read distance from me now
    //get location from message.location
    NSString *mLoc = [[SingletonClass singleObject] myLocation];
    NSArray *strings1 = [mLoc componentsSeparatedByString:@","];
    CLLocation *locA = [[CLLocation alloc] initWithLatitude:[strings1[0] doubleValue] longitude:[strings1[1] doubleValue]];

    
    // Handle the location of the remote devices from the saved messages
    NSArray *strings = [message.location componentsSeparatedByString:@","];
    CLLocation *locB = [[CLLocation alloc] initWithLatitude:[strings[0] doubleValue] longitude:[strings[1] doubleValue]];
    CLLocationDistance distance = [locA distanceFromLocation:locB];
    message.distanceFromMeInMeters = distance;
    
//  SCXTT This is in two places, fix that, put it in one place
    double distanceMeters = message.distanceFromMeInMeters;
    double distanceInYards = distanceMeters * 1.09361;
    double distanceInMiles = distanceInYards / 1760;
    
    if (distanceInYards > 500) {
        _label.text = [NSString stringWithFormat:@"%@ %@, %.1f miles", senderName, dateString, distanceInMiles];
    } else if (([message isSentByUser]) || (distanceMeters < 0.00001)) {
        _label.text = [NSString stringWithFormat:@"%@ %@", senderName, dateString];
    } else {
        _label.text = [NSString stringWithFormat:@"%@ %@, %.1f y", senderName, dateString, distanceInYards];
    }
    
	// Set the sender's name and date on the label
//    _label.text = [NSString stringWithFormat:@"%@ @ %@ %@", senderName, dateString, message.location];
//    _label.text = [NSString stringWithFormat:@"%@ %@ %.1f y", senderName, dateString, message.distanceFromMeInMeters];
    
	[_label sizeToFit];
//    _label.frame = CGRectMake(8, message.bubbleSize.height, self.contentView.bounds.size.width - 16, 16);
    _label.frame = CGRectMake(8, 0, self.contentView.bounds.size.width - 16, 16);
}

@end
