//
//  ComposeViewController.h
//  PushChatStarter
//
//  Created by Kauserali on 28/03/13.
//  Copyright (c) 2013 Ray Wenderlich. All rights reserved.
//
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>

#define IS_OS_8_OR_LATER ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)

@class ComposeViewController;
@class DataModel;
@class Message;

// The delegate protocol for the Compose screen
@protocol ComposeDelegate <NSObject>
- (void)didSaveMessage:(Message*)message atIndex:(int)index;
@end

@interface ComposeViewController : UIViewController <UITextViewDelegate, CLLocationManagerDelegate, MKMapViewDelegate>{
    CLLocationManager*      locationManager;
    CLLocation*             locationObject;
}

@property (nonatomic, assign) id<ComposeDelegate> delegate;
@property (nonatomic, assign) DataModel* dataModel;
@property (nonatomic, strong) AFHTTPClient *client;
@property (nonatomic, retain) CLLocationManager *locationManager;


- (NSString *)deviceLocation;

@end

