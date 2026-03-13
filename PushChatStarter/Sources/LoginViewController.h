//
//  LoginViewController.h
//  PushChatStarter
//
//  Created by Kauserali on 28/03/13.
//  Copyright (c) 2013 Ray Wenderlich. All rights reserved.
//

#import "DataModel.h"
#import <AFNetworking/AFNetworking.h>

NS_ASSUME_NONNULL_BEGIN

// The Login screen lets the user register a nickname and chat map group
@interface LoginViewController : UIViewController

@property (nonatomic, strong) DataModel* dataModel;
@property (nonatomic, strong) AFHTTPSessionManager *client;
@property (nonatomic) BOOL isUpdating;

@end

NS_ASSUME_NONNULL_END
