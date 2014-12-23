//
//  Message.m
//  PushChatStarter
//
//  Created by Kauserali on 28/03/13.
//  Copyright (c) 2013 Ray Wenderlich. All rights reserved.
//

#import "Message.h"

static NSString* const SenderNameKey = @"SenderName";
static NSString* const DateKey = @"Date";
static NSString* const TextKey = @"Text";
static NSString* const LocKey = @"Location";

@implementation Message

- (id)initWithCoder:(NSCoder*)decoder
{
	if ((self = [super init]))
	{
		self.senderName = [decoder decodeObjectForKey:SenderNameKey];
		self.date = [decoder decodeObjectForKey:DateKey];
        self.text = [decoder decodeObjectForKey:TextKey];
        self.location = [decoder decodeObjectForKey:LocKey];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
	[encoder encodeObject:self.senderName forKey:SenderNameKey];
	[encoder encodeObject:self.date forKey:DateKey];
    [encoder encodeObject:self.text forKey:TextKey];
    [encoder encodeObject:self.location forKey:LocKey];
}

- (BOOL)isSentByUser
{
	return self.senderName == nil;
}
@end
