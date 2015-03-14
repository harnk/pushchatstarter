//
//  AppDelegate.h
//  PushChatStarter
//
//  Created by Kauserali on 28/03/13.
//  Copyright (c) 2013 Ray Wenderlich. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import "SingletonClass.h"

#define ApplicationDelegate ((AppDelegate *)[UIApplication sharedApplication].delegate)

@class DataModel;

@interface AppDelegate : UIResponder <UIApplicationDelegate, CLLocationManagerDelegate>{
//    CLLocationManager*      locationManager;
    CLLocation*             locationObject;
}


@property (strong, nonatomic) UIWindow *window;
@property (strong, readonly) UIStoryboard *storyBoard;
@property (nonatomic, retain) CLLocationManager *locationManager;
@property (nonatomic, assign) DataModel* dataModel;
@property (nonatomic) BOOL isUpdating;

@end
