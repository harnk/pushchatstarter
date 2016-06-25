//
//  AppDelegate.h
//  PushChatStarter
//
//  Created by Kauserali on 28/03/13.
//  Copyright (c) 2013 Ray Wenderlich. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import "SingletonClass.h"
#import <StoreKit/StoreKit.h>

#define ApplicationDelegate ((AppDelegate *)[UIApplication sharedApplication].delegate)

@class DataModel;

@interface AppDelegate : UIResponder <UIApplicationDelegate, CLLocationManagerDelegate, SKProductsRequestDelegate, SKPaymentTransactionObserver>{
//    CLLocationManager*      locationManager;
    CLLocation*             locationObject;
    NSTimer *backgroundTimer;
}


@property (strong, nonatomic) UIWindow *window;
@property (strong, readonly) UIStoryboard *storyBoard;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, assign) DataModel* dataModel;
@property (nonatomic) BOOL isUpdating;
@property (nonatomic) BOOL deviceHasMoved;
@property (nonatomic, strong) NSString *currentState;

//In-App purchase stuff
@property (strong, nonatomic) SKProductsRequest* request;
@property (strong, nonatomic) NSArray *products;
@property (nonatomic) BOOL canPurchase;
@property (strong, nonatomic) SKMutablePayment *payment;
@property BOOL purchased, isBackgroundMode;

@end
