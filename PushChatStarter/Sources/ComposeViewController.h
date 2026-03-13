//
//  ComposeViewController.h
//  PushChatStarter
//
//  Created by Kauserali on 28/03/13.
//  Copyright (c) 2013 Ray Wenderlich. All rights reserved.
//
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>
#import "SingletonClass.h"
#import <AFNetworking/AFNetworking.h>

@class ComposeViewController;
@class DataModel;
@class Message;

// The delegate protocol for the Compose screen
@protocol ComposeDelegate <NSObject>
- (void)didSaveMessage:(Message*)message atIndex:(int)index;
@end

NS_ASSUME_NONNULL_BEGIN

@interface ComposeViewController : UIViewController <UITextViewDelegate, CLLocationManagerDelegate, MKMapViewDelegate>{
    CLLocation*             locationObject;
}

@property (nonatomic, assign) id<ComposeDelegate> delegate;
@property (nonatomic, assign) DataModel* dataModel;
@property (nonatomic, strong) AFHTTPSessionManager *client;
@property (nonatomic, retain) CLLocationManager *locationManager;
@property (nonatomic) BOOL isUpdating;


@end

NS_ASSUME_NONNULL_END
