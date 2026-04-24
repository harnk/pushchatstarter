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
#import <CoreLocation/CoreLocation.h>
#import "MapManager.h"

@class ShowMapViewController;
@class DataModel;
//@class Message;

NS_ASSUME_NONNULL_BEGIN

@interface ShowMapViewController : UIViewController <CLLocationManagerDelegate, ComposeDelegate, UITextFieldDelegate, UIPickerViewDelegate, UIGestureRecognizerDelegate, MapManagerDelegate>{
    CLLocation* locationObject;
}

@property (weak, nonatomic) IBOutlet UITextField *textView;
@property (nonatomic, weak) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mapHeight;
@property (nonatomic) CGFloat saveMapHeight;
@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet UIScreenEdgePanGestureRecognizer *panDownChat;
@property (weak, nonatomic) IBOutlet UIImageView *pullHandle;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *satMapButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *pinPickerButton;

@property (nonatomic, assign) id<ComposeDelegate> delegate;
@property (nonatomic, strong, readonly) DataModel* dataModel;
@property (nonatomic) BOOL isUpdating;
@property (nonatomic) int badResponseRetry;

@property (nonatomic) BOOL isFromNotification;
@property (nonatomic) BOOL pickerIsUp;
@property (nonatomic, strong) MapManager *mapManager;

@property(nonatomic, copy) NSArray *rightBarButtonItems;

@property (nonatomic, retain) CLLocationManager *locationManager;

@property (nonatomic, strong) NSMutableArray * roomArray; // Current locations of all in the room
@property (nonatomic, strong) NSMutableArray * roomMessagesArray; // Current messages in the room
@end

NS_ASSUME_NONNULL_END
