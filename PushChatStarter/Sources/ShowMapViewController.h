//
//  ShowMapViewController.h
//  PushChatStarter
//
//  Created by Scott Null on 12/28/14.
//  Copyright (c) 2014 Ray Wenderlich. All rights reserved.
//

#import "ComposeViewController.h"
#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <MapKit/MKAnnotation.h>
#import <CoreLocation/CoreLocation.h>

#define IS_OS_8_OR_LATER ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)

@class ShowMapViewController;
@class DataModel;
//@class Message;

@interface ShowMapViewController : UIViewController <CLLocationManagerDelegate, MKMapViewDelegate, ComposeDelegate>{
    CLLocationManager*      locationManager;
    CLLocation*             locationObject;
}

@property (nonatomic, weak) IBOutlet MKMapView *mapView;
@property (nonatomic, weak) IBOutlet UITableView *tableView;


@property (nonatomic, assign) id<ComposeDelegate> delegate;
@property (nonatomic, strong, readonly) DataModel* dataModel;
//@property (nonatomic, strong) DataModel* dataModel;
@property (nonatomic, strong) AFHTTPClient *client;
@property (nonatomic) BOOL isUpdating;
@property(nonatomic, copy) NSArray *rightBarButtonItems;
@property(nonatomic, copy) UIBarButtonItem *btnMapType;

@property (nonatomic, retain) CLLocationManager *locationManager;
@property (nonatomic, retain) CLLocation *mapViewSouthWest;
@property (nonatomic, retain) CLLocation *mapViewNorthEast;
@property CLLocationDistance distanceFromMeInMeters;

- (NSString *)deviceLocation;

@end
