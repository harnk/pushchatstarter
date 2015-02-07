//
//  SingletonClass.h
//  PushChatStarter
//
//  Created by Scott Null on 2/6/15.
//  Copyright (c) 2015 Ray Wenderlich. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SingletonClass : NSObject
+(SingletonClass *)singleObject;

@property(nonatomic, strong)NSString *myLocation;

@end