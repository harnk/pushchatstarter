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
#import "ServiceConnector.h"
@import GoogleMobileAds;

@class ShowMapViewController;
@class DataModel;
//@class Message;

@interface ShowMapViewController : UIViewController <CLLocationManagerDelegate, MKMapViewDelegate, ComposeDelegate, ServiceConnectorDelegate, UITextFieldDelegate, UIPickerViewDelegate, UIGestureRecognizerDelegate>{
    CLLocation* locationObject;
}

@property (weak, nonatomic) IBOutlet GADBannerView *bannerView;
@property (weak, nonatomic) IBOutlet UITextField *textView;
@property (nonatomic, weak) IBOutlet MKMapView *mapView;
@property (nonatomic, weak) IBOutlet UITableView *tableView;

//Stuff for ServiceConnector //////////////////////////////////
@property (weak, nonatomic) IBOutlet UITextView *output;
@property (weak, nonatomic) IBOutlet UITextField *value1TextField;
@property (weak, nonatomic) IBOutlet UITextField *value2TextField;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *satMapButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *pinPickerButton;

- (IBAction)getDown:(id)sender;
- (IBAction)postDown:(id)sender;
//End Stuff for ServiceConnector //////////////////////////////

@property (nonatomic, assign) id<ComposeDelegate> delegate;
@property (nonatomic, strong, readonly) DataModel* dataModel;
@property (nonatomic, strong) AFHTTPClient *client;
@property (nonatomic) BOOL isUpdating;
@property (nonatomic) BOOL isFromNotification;
@property (nonatomic) BOOL pickerIsUp;
@property (nonatomic) BOOL okToRecenterMap;

@property(nonatomic, copy) NSArray *rightBarButtonItems;
//@property(nonatomic, copy) UIBarButtonItem *btnMapType;
//@property (nonatomic, strong) UIPickerView *myPickerView;

@property (nonatomic, retain) CLLocationManager *locationManager;
@property (nonatomic, retain) CLLocation *mapViewSouthWest;
@property (nonatomic, retain) CLLocation *mapViewNorthEast;

//@property CLLocationDistance distanceFromMeInMeters;

@property (nonatomic, strong) NSMutableArray * roomArray; // Current locations of all in the room
@property (nonatomic, strong) NSMutableArray * roomMessagesArray; // Current messages in the room
@property (nonatomic, strong) NSString *centerOnThisGuy;
@end
