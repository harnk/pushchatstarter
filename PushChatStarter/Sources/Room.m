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
    
    NSString *myPinImages[11] = {@"blue.png",@"cyan.png",@"darkgreen.png",@"gold.png",
        @"green.png",@"orange.png",@"pink.png",@"purple.png",@"red.png",@"yellow.png",
        @"cyangray.png"};
    
    self = [super init];
    if (self) {
        self.roomName = rName;
        self.memberNickName = mNickName;
        self.memberLocation = mLocation;
        self.memberUpdateTime = mLocTime;
        self.memberPinImage = mPinImageString;

        // NSString to ASCII
        int asciiCode = [[mNickName substringToIndex:1] characterAtIndex:0]; // 65
        int n = 0; // from somewhere
        int digit = asciiCode % 10; n /= 10;
//        NSLog(@"mPinImageString:%@ mNickName:%@ first char:%@ ASCII:%d digit:%d",mPinImageString, mNickName,[mNickName substringToIndex:1], asciiCode, digit);
        

//        NSInteger minutesBetweenDates;
//        minutesBetweenDates = [self getPinAgeInMinutes:self.memberUpdateTime];
//        NSLog(@"minutesBetweenDates:%ld", (long)minutesBetweenDates);
        
//        if (minutesBetweenDates > 10000) {
//            self.memberPinImage = @"inactivepin.png";
//        } else {
//            self.memberPinImage = myPinImages[digit];
//        }

        
//        _memberUpdateTime = mUpdateTime;
    }
//    NSLog(@"adding to Room self %@ at loc %@ last updated %@ color %@", self.memberNickName, self.memberLocation, self.memberUpdateTime, self.memberPinImage);
    return self;
}

- (NSInteger)getPinAgeInMinutes:(NSString *)gmtDateStr
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"YYYY-MM-dd HH:mm:ss"];
    [formatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    //Create the date assuming the given string is in GMT
    NSDate *jsonDate = [formatter dateFromString:gmtDateStr];
    NSDate *now = [NSDate date];
    
    NSTimeInterval distanceBetweenDates = [now timeIntervalSinceDate:jsonDate];
    double secondsInAnMinute = 60;
    NSInteger minutesBetweenDates = distanceBetweenDates / secondsInAnMinute;
    return minutesBetweenDates;
}

@end

