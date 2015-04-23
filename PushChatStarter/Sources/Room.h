//
//  Room.h
//  PushChatStarter
//
//  Created by Scott Null on 3/6/15.
//  Copyright (c) 2015 Ray Wenderlich. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Room : NSObject

@property (strong, nonatomic) NSString *roomName; // db active_users secret_code
@property (strong, nonatomic) NSString *memberNickName;
@property (strong, nonatomic) NSString *memberLocation;
@property (strong, nonatomic) NSString *memberUpdateTime;
@property (strong, nonatomic) NSString *memberPinImage;
//@property (strong, nonatomic) NSDate *memberUpdateTime;

#pragma mark - 
#pragma mark Class Methods

-(id)initWithRoomName:(NSString *)rName andMemberNickName:(NSString *)mNickName andMemberLocation:(NSString *)mLocation andMemberLocTime:(NSString *)mLocTime andMemberPinImage:(NSString *)mPinImageString;


@end
