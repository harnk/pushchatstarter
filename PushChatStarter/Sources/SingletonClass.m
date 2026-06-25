//
//  SingletonClass.m
//  PushChatStarter
//
//  Created by Scott Null on 2/6/15.
//  Copyright (c) 2015 Ray Wenderlich. All rights reserved.
//

#import "SingletonClass.h"

@implementation SingletonClass
+(SingletonClass *)singleObject
{
    static SingletonClass *single = nil;
    @synchronized (self)
    {
        if (!single) {
            single = [[SingletonClass alloc]init];
            single.blockedUserIds = [NSMutableSet set];
        }
    }
    return single;
}

- (void)addBlockedUser:(NSString *)userId {
    [self.blockedUserIds addObject:userId];
}

- (void)removeBlockedUser:(NSString *)userId {
    [self.blockedUserIds removeObject:userId];
}

- (BOOL)isUserBlocked:(NSString *)userId {
    return [self.blockedUserIds containsObject:userId];
}

@end
