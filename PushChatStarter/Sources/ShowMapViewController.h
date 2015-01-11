//
//  ShowMapViewController.h
//  PushChatStarter
//
//  Created by Scott Null on 12/28/14.
//  Copyright (c) 2014 Ray Wenderlich. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <MapKit/MKAnnotation.h>
#import <CoreLocation/CoreLocation.h>
#import "ComposeViewController.h"

#define IS_OS_8_OR_LATER ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)

@class ShowMapViewController;
@class DataModel;
@class Message;

// The delegate protocol for the Compose screen
@protocol ComposeDelegate <NSObject>
- (void)didSaveMessage:(Message*)message atIndex:(int)index;
@end

@interface ShowMapViewController : UIViewController <CLLocationManagerDelegate, MKMapViewDelegate>{
    CLLocationManager*      locationManager;
    CLLocation*             locationObject;
}

@property (nonatomic, weak) IBOutlet MKMapView *mapView;
@property (nonatomic, assign) id<ComposeDelegate> delegate;
@property (nonatomic, assign) DataModel* dataModel;
@property (nonatomic, strong) AFHTTPClient *client;
@property (nonatomic, retain) CLLocationManager *locationManager;


- (NSString *)deviceLocation;

@end
