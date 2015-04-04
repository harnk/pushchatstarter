//
//  Room.m
//  PushChatStarter
//
//  Created by Scott Null on 3/6/15.
//  Copyright (c) 2015 Ray Wenderlich. All rights reserved.
//

#import "Room.h"



@implementation Room

-(id)initWithRoomName:(NSString *)rName andMemberNickName:(NSString *)mNickName andMemberLocation:(NSString *)mLocation andMemberLocTime:(NSString *)mLocTime andMemberPinImage:(NSString *)mPinImageString; {

    self = [super init];
    if (self) {
        self.roomName = rName;
        self.memberNickName = mNickName;
        self.memberLocation = mLocation;
        self.memberUpdateTime = mLocTime;
        self.memberPinImage = mPinImageString;
//        _memberUpdateTime = mUpdateTime;
    }
//    NSLog(@"adding to Room self %@ at loc %@ last updated %@ color %@", self.memberNickName, self.memberLocation, self.memberUpdateTime, self.memberPinImage);
    return self;
}

@end
