//
//  AppDelegate.m
//  PushChatStarter
//
//  Created by Kauserali on 28/03/13.
//  Copyright (c) 2013 Ray Wenderlich. All rights reserved.
//

#import "AppDelegate.h"
#import "ComposeViewController.h"
#import "ShowMapViewController.h"
#import "DataModel.h"
#import "Message.h"
#import "Harpy.h"

void ShowErrorAlert(NSString* text)
{
	UIAlertView* alertView = [[UIAlertView alloc]
                              initWithTitle:text
                              message:nil
                              delegate:nil
                              cancelButtonTitle:NSLocalizedString(@"OK", nil)
                              otherButtonTitles:nil];
    
	[alertView show];
}

@implementation AppDelegate

int retryCounter = 0;
int badResponseCounter = 0;

#pragma mark - 
#pragma mark In-App Purchase Stuff

-(NSArray *)getProductIdentifiersFromMainBundle{
    NSArray *identifiers;
    // do the following swift equivalent
    // if let url =  NSBundle.mainBundle().URLForResource("iap_product_ids", withExtension: "plist") { identifiers = NSArray(contentsOfURL: url)! }
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"iap_product_ids"
                                         withExtension:@"plist"];
    identifiers = [NSArray arrayWithContentsOfURL:url];

    return identifiers;
    
}

- (void)validateProductIdentifiers:(NSArray *)productIdentifiers
{
    NSLog(@"SCXTT validateProductIdentifiers");
    SKProductsRequest *productsRequest = [[SKProductsRequest alloc]
                                          initWithProductIdentifiers:[NSSet setWithArray:productIdentifiers]];
    
    // Keep a strong reference to the request.
    self.request = productsRequest;
    productsRequest.delegate = self;
    [productsRequest start];
}

// SKProductsRequestDelegate protocol method
- (void)productsRequest:(SKProductsRequest *)request
     didReceiveResponse:(SKProductsResponse *)response
{
    self.products = response.products;
    NSLog(@"SCXTT productsRequest:didReceiveResponse Delegate fired with response: %@", response.products[0].localizedDescription);
    NSLog(@"SCXTT now put these into the singleton NOW");
    [[SingletonClass singleObject] setMyProducts:self.products];
    
    for (NSString *invalidIdentifier in response.invalidProductIdentifiers) {
        // Handle any invalid product identifiers.
        NSLog(@"invalidIdentifier %@", invalidIdentifier);
    }
    
//    [self displayStoreUI]; // Custom method
}

-(void) paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray<SKPaymentTransaction *> *)transactions {
    //flesh this out
    NSLog(@"SCXTT paymentQueue:updatedTransactions delegate");
    for (SKPaymentTransaction *transaction in transactions) {
        
        switch (transaction.transactionState) {
                
            case SKPaymentTransactionStatePurchasing:
                
//                [self initPurchase];
                NSLog(@"PURCH 1 Purchasing");
                [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
                break;
                
            case SKPaymentTransactionStatePurchased:
                
                // this is successfully purchased!
                _purchased = YES;
                NSLog(@"PURCH 2 Purchased");
                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"com.harnk.whereru.removeads"];
                [[NSUserDefaults standardUserDefaults] synchronize];
                [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                // finish the transaction
                [queue finishTransaction:transaction];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"removeThoseAds" object:nil userInfo:nil];

                //  and return the transaction data
                
//                if ([delegate respondsToSelector:@selector(successfulPurchase:restored:identifier:receipt:)])
//                    [delegate successfulPurchase:self restored:NO identifier:transaction.payment.productIdentifier receipt:transaction.transactionReceipt];
                
                // and more code bla bla bla
                
                break;
                
            case SKPaymentTransactionStateRestored:
                
                // and more code bla bla bla
                
                //                [self restorePurchase];
                NSLog(@"PURCH 3 Restored");
                
                break;
                
            case SKPaymentTransactionStateDeferred:
                
                // and more code bla bla bla
                
                //                [self ??];
                NSLog(@"PURCH 4 Deferred");
                [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                
                break;
                
            case SKPaymentTransactionStateFailed:
                
                // and more code bla bla bla
                
//                [self failedNotification];
                NSLog(@"PURCH 5 Failed: %@", [[transaction error] localizedDescription]);
                [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                
                break;
        }
    }
}


#pragma mark -
#pragma mark Notifications

- (void)application:(UIApplication*)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken
{
    
    NSLog(@"%@ My location is: %@", _currentState, [[SingletonClass singleObject] myLocStr]);
    
    UINavigationController *navigationController = (UINavigationController*)_window.rootViewController;
    
    //    ChatViewController *chatViewController = (ChatViewController*)[navigationController.viewControllers objectAtIndex:0];
    ShowMapViewController *showMapViewController = (ShowMapViewController*)[navigationController.viewControllers  objectAtIndex:0];
    
    //    DataModel *dataModel = chatViewController.dataModel;
    DataModel *dataModel = showMapViewController.dataModel;
    
    NSString *oldToken = [dataModel deviceToken];
    
    NSString *newToken = [deviceToken description];
    newToken = [newToken stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
    newToken = [newToken stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSLog(@"My token is: %@", newToken);
    
    //    NSLog(@"Got a token so notificationsAreDisabled to NO");
    [[SingletonClass singleObject] setNotificationsAreDisabled:NO];
    
    //Tell the app the good news
    [[NSNotificationCenter defaultCenter] postNotificationName:@"receivedDeviceToken" object:nil userInfo:nil];
    
    [dataModel setDeviceToken:newToken];
    
    if ([dataModel joinedChat] && ![newToken isEqualToString:oldToken])
    {
        [self postUpdateRequest];
    }
}

- (void)application:(UIApplication*)application didFailToRegisterForRemoteNotificationsWithError:(NSError*)error
{
    NSLog(@"Failed to get token, error: %@", error);
}


- (void)addMessageFromRemoteNotification:(NSDictionary*)userInfo updateUI:(BOOL)updateUI
{
    UINavigationController *navigationController = (UINavigationController*)_window.rootViewController;
    ShowMapViewController *showMapViewController = (ShowMapViewController*)[navigationController.viewControllers  objectAtIndex:0];
    DataModel *dataModel = showMapViewController.dataModel;
    
    Message *message = [[Message alloc] init];
    message.date = [NSDate date];
    //    message.location = [[userInfo valueForKey:@"aps"] valueForKey:@"loc"];
    message.location = [userInfo valueForKey:@"loc"];
    
    // Handle my location
    //    CLLocation *locA = [[CLLocation alloc] initWithLatitude:self.locationManager.location.coordinate.latitude longitude:self.locationManager.location.coordinate.longitude];
    CLLocation *locA = [[SingletonClass singleObject] myNewLocation];
    
    // Handle the location of the remote device
    NSArray *strings = [message.location componentsSeparatedByString:@","];
    CLLocation *locB = [[CLLocation alloc] initWithLatitude:[strings[0] doubleValue] longitude:[strings[1] doubleValue]];
    
    //    NSLog(@"locB is:%@", locB);
    
    CLLocationDistance distance = [locA distanceFromLocation:locB];
    message.distanceFromMeInMeters = distance;
    
    NSString *alertValue = [[userInfo valueForKey:@"aps"] valueForKey:@"alert"];
    //    NSString *alertValue = [[userInfo valueForKey:@"aps"] valueForKey:@"extra"];
    
    NSMutableArray *parts = [NSMutableArray arrayWithArray:[alertValue componentsSeparatedByString:@": "]];
    
    message.senderName = [parts objectAtIndex:0];
    [parts removeObjectAtIndex:0];
    message.text = [parts componentsJoinedByString:@": "];
    
    //    message.text = alertValue;
    
    int index = [dataModel addMessage:message];
    
    if (updateUI) {
        //        [chatViewController didSaveMessage:message atIndex:index];
        [showMapViewController didSaveMessage:message atIndex:index];
    }
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler {
    
    NSLog(@"Received notification: %@", userInfo);
    
//    NSString *extra = [[userInfo valueForKey:@"aps"] valueForKey:@"extra"];
    NSString *extra = [userInfo valueForKey:@"extra"];

    if([extra isEqualToString:@"whereru"]) {
        NSLog(@"whereru - in ^completionHandlerSilent push received");
        NSLog(@"SCXTT NEED TO WAKE UP LOCATIONMANAGER HERE");
        retryCounter = 0;
        NSString *asker = [userInfo valueForKey:@"asker"];
//        [self.locationManager startMonitoringSignificantLocationChanges];
        
        // If battery is above 90 percent do a CLActivityTypeFitness else do CLActivityTypeAutomotiveNavigation?? maybe later
        
        [[UIDevice currentDevice] setBatteryMonitoringEnabled:YES];
        float batteryLevel = [[UIDevice currentDevice] batteryLevel];
        batteryLevel *= 100;
        NSLog(@"SCXTT batteryLevel is %f", batteryLevel);
        
        self.locationManager.pausesLocationUpdatesAutomatically = NO;
        self.locationManager.activityType = CLActivityTypeFitness;
        [self.locationManager setDesiredAccuracy:kCLLocationAccuracyBest];
        [self.locationManager setDistanceFilter:kCLDistanceFilterNone];
//        [self.locationManager startUpdatingLocation];
        [self postImhere:asker];
    } else {
        if ([extra isEqualToString:@"imhere"]) {
//            NSLog(@"Found someone - dont put into the message bubble but do a toast that receiving updates is working");
            [[NSNotificationCenter defaultCenter] postNotificationName:@"receivedLocationUpdate" object:nil userInfo:userInfo];
        } else {
            //Prod doing away with the next line because API calls should get the new message
//            [self addMessageFromRemoteNotification:userInfo updateUI:YES];
            //Prod I think I may no longer need this next line either
//            [[NSNotificationCenter defaultCenter] postNotificationName:@"receivedNewMessage" object:nil userInfo:userInfo];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"notificationReceivedSoGetRoomMessages" object:nil userInfo:nil];
        }
    }
    
    if(application.applicationState == UIApplicationStateInactive) {
        
        NSLog(@"Inactive: application.applicationState == UIApplicationStateInactive");
        
        //Show the view with the content of the push
        
        completionHandler(UIBackgroundFetchResultNewData);
        
    } else if (application.applicationState == UIApplicationStateBackground) {
        
        NSLog(@"Background: application.applicationState == UIApplicationStateBackground");
        
        //Refresh the local model
        
        completionHandler(UIBackgroundFetchResultNewData);
        
    } else {
        
        NSLog(@"Active");
        
        //Show an in-app banner
        
        
        completionHandler(UIBackgroundFetchResultNewData);
        
    }
}

-(void)application:(UIApplication *)application didRegisterUserNotificationSettings:   (UIUserNotificationSettings *)notificationSettings
{
    if (notificationSettings.types) {
        NSLog(@"%@ user allowed notifications", _currentState);
        //        [[UIApplication sharedApplication] registerForRemoteNotifications];
    }else{
        NSLog(@"%@ user did not allow notifications", _currentState);
        // show alert here
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Notifications Are Disabled" message:@"This app requires notifications in order to function. You need to enable notifications. Choose Settings to enable them" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Settings", nil];
        [alert show];
    }
}

#pragma mark -
#pragma mark AppDelegate methods

//- (void)application:(UIApplication*)application didReceiveRemoteNotification:(NSDictionary*)userInfo
//{
//    NSLog(@"Received notification: %@", userInfo);
//    [self addMessageFromRemoteNotification:userInfo updateUI:YES];
//}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [self initializeAWS];
    
    self.mqttTopic = @"Whereru/test";
    
    // Connect to MQTT
    [self connectToMqtt];
    
    // Override point for customization after application launch.
    _currentState = @"AD_DFLWO";
    _purchased = NO;
    _storyBoard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
    
    // HARPY BEGIN
    // Check to see if a newer version of this app is available
    // Present Window before calling Harpy
    [self.window makeKeyAndVisible];
    
    // Set the App ID for your app
    [[Harpy sharedInstance] setAppID:@"976774720"];
    
    // Set the UIViewController that will present an instance of UIAlertController
    [[Harpy sharedInstance] setPresentingViewController:_window.rootViewController];
    
    // (Optional) Set the App Name for your app
    [[Harpy sharedInstance] setAppName:@"WhereRU - Locator and Chat"];
    
    /* (Optional) Set the Alert Type for your app
     By default, Harpy is configured to use HarpyAlertTypeOption */
    //    [[Harpy sharedInstance] setAlertType:HarpyAlertTypeForce];
    
    // Perform check for new version of your app
    [[Harpy sharedInstance] checkVersion];

    
    // Check the keychain for the userID
    UICKeyChainStore *keychain = [UICKeyChainStore keyChainStoreWithService:@"com.harnk.WhereRU.storedid"];
    NSString *userId = [keychain stringForKey:@"mysaveduserid"];
    NSLog(@"SCXTT READ KEYCHAIN BEFORE: %@", userId);
    
    if (!userId) {
        NSLog(@"SCXTT USERID FALSE: %@", userId);
        userId = [[[NSUUID UUID] UUIDString] stringByReplacingOccurrencesOfString:@"-" withString:@""];
        keychain[@"mysaveduserid"] = userId;
        [keychain setString:userId forKey:@"mysaveduserid"];
    }

    userId = [keychain stringForKey:@"mysaveduserid"];
    NSLog(@"SCXTT READ KEYCHAIN AFTER: %@", userId);
    
    // Init my location since it may not have gotten a read on me yet
    // All points start at the statue of liberty: 40.689124, -74.044611
    NSString *checkStartingLoc = [[SingletonClass singleObject] myLocStr];
    if (nil == checkStartingLoc) {
        CLLocation *startingPoint = [[CLLocation alloc] initWithLatitude:40.689124 longitude:-74.044611];
        [[SingletonClass singleObject] setMyNewLocation:startingPoint];
        NSLog(@"%@ AppDelegate myLoc: %@", _currentState, [[SingletonClass singleObject] myLocStr]);
    }
    
    if (launchOptions != nil)
    {
        NSDictionary *dictionary = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
        if (dictionary != nil)
        {
            NSLog(@"%@ Launched from push notification: %@", _currentState, dictionary);
            [self addMessageFromRemoteNotification:dictionary updateUI:NO];
        }
    }
    
    _isUpdating = NO;
    [[SingletonClass singleObject] setImInARoom:NO];
    
    //SCXTT Need to review this and see if it is still necesary
    [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];

    // register for types of remote notifications
    [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge) categories:nil]];
    [[UIApplication sharedApplication] registerForRemoteNotifications];
    
//    we should only do this next line if we are already imInARoom and also move this to start updating when we are notified of leave ShowMapViewController and not right here
//    [self startMyLocationUpdates];
    
    // Deal with In-App purchase
    _canPurchase = NO;
//    if ([SKPaymentQueue canMakePayments]) {
//        NSArray *productsArray = [self getProductIdentifiersFromMainBundle];
//        NSLog(@"SCXTT getProductIdentifiersFromMainBundle:%@", productsArray);
//        [self validateProductIdentifiers:productsArray];
//        _canPurchase = YES;
//        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
//        
//    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(startMyLocationUpdates)
                                                 name:@"fireUpTheGPS"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(smvcIsActive)
                                                 name:@"haltBackgroundUpdates"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(smvcIsInactive)
                                                 name:@"allowBackgroundUpdates"
                                               object:nil];
    

    //REMOVE this next bit later - its for testing while sitting in one place
//    backgroundTimer = [NSTimer scheduledTimerWithTimeInterval: 20
//                                                       target: self
//                                                     selector: @selector(fakeMove)
//                                                     userInfo: nil
//                                                      repeats: YES];

    return YES;
}

// This is a delegate method that should get called in the background
-(void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    NSLog(@"%@ ########### Received Background Fetch ###########", _currentState);
    //Download  the Content .
    // Do NOT do this next line if SMVC is still active and looking
    if (_isBackgroundMode) {
        [self postMyLoc];
    }
    //Cleanup
    completionHandler(UIBackgroundFetchResultNewData);
    
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    _currentState = @"AD_RESIGN";
    NSLog(@"%@ applicationWillResignActive", _currentState);

    //stop looking here
    [self postLiveUpdate];
    _isBackgroundMode = YES;
    
//    we should only do this next line if we are already imInARoom and also move this to start updating when we are notified of leave ShowMapViewController and not right here
    if ([[SingletonClass singleObject] imInARoom]) {
        [self startMyLocationUpdates];
    }
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    _currentState = @"AD_BKGND";
    NSLog(@"%@ applicationDidEnterBackground", _currentState);
//    [self.locationManager startMonitoringSignificantLocationChanges];
//    self.locationManager.pausesLocationUpdatesAutomatically = NO;
//    self.locationManager.activityType = CLActivityTypeFitness;
//    [self.locationManager startUpdatingLocation];

    //Kill the getRoomTimer
    [[NSNotificationCenter defaultCenter] postNotificationName:@"killGetRoomTimer" object:nil userInfo:nil];
    
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    _currentState = @"AD_FOREGROUND";
    NSLog(@"%@ applicationWillEnterForeground", _currentState);
    [[Harpy sharedInstance] checkVersion];
    
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    _currentState = @"AD_ACTIVE";
    NSLog(@"%@ applicationDidBecomeActive", _currentState);
    application.applicationIconBadgeNumber = 0;
    //Start the getRoomTimer going again
    [[NSNotificationCenter defaultCenter] postNotificationName:@"commenceGetRoomTimer" object:nil userInfo:nil];
    retryCounter = 0;
//    [backgroundTimer invalidate];
//    backgroundTimer = nil;
    
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    _currentState = @"AD_TERMINATE";
    NSLog(@"%@ applicationWillTerminate", _currentState);
}

#pragma mark - AWS IoT MQTT Methods

-(void)initializeAWS {
//    NSString *identityId;
//    AWSIoTManager *iotManager;
    
    //SCXTT THESE NEXT TWO LINES HARD CODED FOR NOW
    AWSRegionType const CognitoRegionType = AWSRegionUSWest2;
    NSString *const CognitoIdentityPoolId = @"us-west-2:98ec2e25-2767-4bb9-b2f3-1c0bea5c3184";
    
    
    //awsRegionName and awsCognitoPoolId should have already been set in the singleton from login return values
    NSString *cognitoRegionString = [[SingletonClass singleObject] awsRegionName];
    NSString *cognitoId = [[SingletonClass singleObject] awsCognitoPoolId];
    
    if (([cognitoRegionString length] == 0) || ([cognitoRegionString isEqualToString:@"null"])){
        cognitoRegionString = @"us-west-2";
    }
    AWSRegionType cognitoRegion = [cognitoRegionString aws_regionTypeValue];
    
    // Initialize the Amazon Cognito credentials provider
    AWSCognitoCredentialsProvider *credentialsProvider = [[AWSCognitoCredentialsProvider alloc] initWithRegionType:cognitoRegion
                                                                                                    identityPoolId:CognitoIdentityPoolId];
    AWSServiceConfiguration *configuration = [[AWSServiceConfiguration alloc] initWithRegion:cognitoRegion
                                                                         credentialsProvider:credentialsProvider];
    AWSServiceManager.defaultServiceManager.defaultServiceConfiguration = configuration;
    
    // Keep a reference to the provider
//    self.credentialsProvider = credentialsProvider;
//    self.serviceConfiguration = configuration;
    
    [[credentialsProvider getIdentityId] continueWithSuccessBlock:^id _Nullable(AWSTask<NSString *> * _Nonnull task) {
        NSLog(@"SCXTT Cognito identityId = [%@]", credentialsProvider.identityId);
        self.identityId = credentialsProvider.identityId;
        return nil;
    }];
    
    // do IoT
    self.iotManager = [AWSIoTManager defaultIoTManager];
    AWSIoT *iot = [AWSIoT defaultIoT];
}


#pragma mark -
#pragma mark custom methods

-(void) smvcIsActive {
    _isBackgroundMode = NO;
}

-(void) smvcIsInactive {
    _isBackgroundMode = YES;
}


- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1)
    {
        NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
        [[UIApplication sharedApplication] openURL:url];
    }
}

- (void)startMyLocationUpdates
{
    NSLog(@"Fire Up The GPS: self.locationManager startUpdatingLocation");
    // Start updating my own location
    _deviceHasMoved = YES;
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    
    [self.locationManager requestAlwaysAuthorization];
    //  self.locationManager.pausesLocationUpdatesAutomatically = YES;
    // [self.locationManager startMonitoringSignificantLocationChanges];
    self.locationManager.pausesLocationUpdatesAutomatically = NO;
    
    // iOS 9 now requires that you ALSO set allowsBackgroundLocationUpdates = YES
    [_locationManager setDesiredAccuracy:kCLLocationAccuracyBest];
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8) {
        [_locationManager requestAlwaysAuthorization];
    }
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 9) {
        _locationManager.allowsBackgroundLocationUpdates = YES;
    }
    
    [self.locationManager startUpdatingLocation];
}

-(void)postImhere:(NSString *)asker
{
//    NSLog(@"Respond to WhereRU with Im Here back to asker");
    NSLog(@"%@ postImhere %@", _currentState, [[SingletonClass singleObject] myLocStr]);
    NSString *text = @"Im Here";
    
    NSDictionary *params = @{@"cmd":@"imhere",
                             @"user_id":[[NSUserDefaults standardUserDefaults] stringForKey:@"UserId"],
                             @"asker":asker,
                             @"location":[[SingletonClass singleObject] myLocStr],
                             @"text":text};
    
    //    NSLog(@"Doing API Call with %@", params);
    
    AFHTTPClient *client = [AFHTTPClient clientWithBaseURL:[NSURL URLWithString:ServerApiURL]];
    [client
     postPath:ServerPostPathURL
     parameters:params
     success:nil failure:nil];
    
}

-(void)resetIsUpdating {
    _isUpdating = NO;
}

-(void)postLiveUpdate
{
//    NSLog(@"This is called whenever the device location changes, should not do more than once every 5 seconds");
    
    //SCXTT RELEASE
    NSLog(@"%@ postLiveUpdate %@", _currentState, [[SingletonClass singleObject] myLocStr]);

    NSDictionary *params = @{@"cmd":@"liveupdate",
                             @"user_id":[[NSUserDefaults standardUserDefaults] stringForKey:@"UserId"],
                             @"location":[[SingletonClass singleObject] myLocStr]};
    
    //    NSLog(@"Doing API Call with %@", params);
    
    AFHTTPClient *client = [AFHTTPClient clientWithBaseURL:[NSURL URLWithString:ServerApiURL]];
    [client
     postPath:ServerPostPathURL
     parameters:params
     success:^(AFHTTPRequestOperation *operation, id responseObject) {
         NSString* responseString = [NSString stringWithUTF8String:[responseObject bytes]];
         //SCXTT RELEASE
         NSLog(@"%@ responseString: %@", _currentState, responseString);
         NSLog(@"%@ operation: %@", _currentState, operation);
         NSLog(@"%@ need to check repsonse to see if looking is 1 yet for anyone", _currentState);
         
         // Deal with me if I have been deleted from the active_users table in the DB
         if (responseString.length == 0) {
             badResponseCounter += 1;
             if (badResponseCounter > 5) {
                 [[SingletonClass singleObject] setImInARoom:NO];
             }
         } else {
             badResponseCounter = 0;
         }
         
         // SCXTT WIP Loop thru the response and check key "looking"
         NSError *e = nil;
         NSArray *jsonArray = [NSJSONSerialization JSONObjectWithData: responseObject options: NSJSONReadingMutableContainers error: &e];
         if (!jsonArray) {
             NSLog(@"4 Error parsing JSON: %@", e);
         } else {
             BOOL foundALooker = NO;
             for(NSDictionary *item in jsonArray) {
                 NSString *mLooking = [item objectForKey:@"looking"];
                 if ([mLooking isEqual:@"1"]) {
                     NSString *mNickName = [item objectForKey:@"nickname"];
                     NSLog(@"%@  %@ is looking", _currentState, mNickName);
                     foundALooker = YES;
                     NSLog(@"%@ Toggle singleton BOOL someoneIsLooking to foundALooker=YES and exit the loop", _currentState);
                 }
             }
             NSLog(@"%@ set singleton someoneIsLooking = foundALooker which equals %d", _currentState, foundALooker);
             if (foundALooker) {
                 NSLog(@"%@ since someoneIsLooking keep updating my loc in the background", _currentState);
                 retryCounter = 0;
             } else {
                 if (_isBackgroundMode){
                     retryCounter += 1;
                     NSLog(@"NO ONE is looking so why am I wasting my battery with these background API calls?!? Retry:%d", retryCounter);
                     if (retryCounter > 10) {
                         NSLog(@"IM DONE with AppDelegate LocationManager so setDistanceFilter:99999");
                         NSLog(@"SCXTT CANT STOP LOCATIONMANAGER HERE so setDesiredAccuracy:kCLLocationAccuracyThreeKilometers");

                         
                         self.locationManager.pausesLocationUpdatesAutomatically = YES;
                         self.locationManager.activityType = CLActivityTypeAutomotiveNavigation;
                         [self.locationManager setDesiredAccuracy:kCLLocationAccuracyThreeKilometers];
                         [self.locationManager setDistanceFilter:99999];
                         
                         
                         
                         
                     }
                 }
             }
         }

         
         [NSTimer scheduledTimerWithTimeInterval: 5
                                          target: self
                                        selector: @selector(resetIsUpdating)
                                        userInfo: nil
                                         repeats: NO];
     } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
         [NSTimer scheduledTimerWithTimeInterval: 10
                                          target: self
                                        selector: @selector(resetIsUpdating)
                                        userInfo: nil
                                         repeats: NO];
     }];
    
}

-(void) postMyLoc {
    if ([[SingletonClass singleObject] imInARoom]) {
        NSLog(@"%@ imInARoom is true", _currentState);
        if (!_isUpdating) {
            NSLog(@"%@ were not _isUpdating", _currentState);
            if (_deviceHasMoved) {
                _isUpdating = YES;
                NSLog(@"%@ POSTLIVEUPDATE %@", _currentState, [[SingletonClass singleObject] myLocStr]);
                [self postLiveUpdate];
                _deviceHasMoved = NO;

                // Need to check response for anyone still looking and set _isAnyoneStillLooking
                
            }
        } else {
            NSLog(@"%@ no API call since _isUpdating is already YES = Busy", _currentState);
        }
    } else {
        NSLog(@"%@ imInARoom is false - no update", _currentState);
    }
}


- (void)postUpdateRequest
{
    //The update cmd will update the user's device token on the server because sometimes these change
    NSDictionary *params = @{@"cmd":@"update",
                             @"user_id":[[NSUserDefaults standardUserDefaults] stringForKey:@"UserId"],
                             @"location":[[SingletonClass singleObject] myLocStr],
                             @"token":[[NSUserDefaults standardUserDefaults] stringForKey:@"DeviceToken"]};
    AFHTTPClient *client = [AFHTTPClient clientWithBaseURL:[NSURL URLWithString:ServerApiURL]];
    [client
     postPath:ServerPostPathURL
     parameters:params
     success:nil failure:nil];
}

#pragma mark - locationManager delegate methods

//Ref: http://stackoverflow.com/questions/12602463/didupdatelocations-instead-of-didupdatetolocation
//

//-(void) fakeMove {
//    
//    NSLog(@"SCXTT FAKEMOVE - TAKE OUT LATER - calling postMyLoc");
//    _deviceHasMoved = YES;
//    [self postMyLoc];
//    
//}

- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray *)locations {
    // This is the battery burner right here ... must optimize this
    
    CLLocation * oldLocation = [[SingletonClass singleObject] myNewLocation];
    CLLocation * newLocation = [locations lastObject];
    CLLocationDistance distanceMoved = [oldLocation distanceFromLocation:newLocation];
    NSLog(@"%@ AppDelegate background delegate device moved %f yards - DIDUPDATELOCATIONS", _currentState, distanceMoved);
    
    [[SingletonClass singleObject] setMyNewLocation:[locations lastObject]];
    
    CLLocation *newLoc = [locations lastObject];
    
    // If the stored loc string is the same as this new one do not print to the console
    //    if ([[[SingletonClass singleObject] myLocStr] isEqualToString: [NSString stringWithFormat:@"%f, %f", newLoc.coordinate.latitude, newLoc.coordinate.longitude]] ) {
    //        //do nothing
    //        NSLog(@"same");
    //    } else {
    
    //log it, save it
    [[SingletonClass singleObject] setMyLocStr: [NSString stringWithFormat:@"%f, %f", newLoc.coordinate.latitude, newLoc.coordinate.longitude]];
    //SCXTT RELEASE
    NSLog(@"%@ API postMyLoc didUpdateLocations I moved to: %@", _currentState, [[SingletonClass singleObject] myLocStr]);
    // If moved farther than 20 yards do an API call SCXTT - add logic
    _deviceHasMoved = YES;
    
    // Do NOT do this next line if SMVC is still active and looking
    if (_isBackgroundMode) {
        [self postMyLoc];
    }
    //    }
}

- (void)locationManagerDidPauseLocationUpdates:(CLLocationManager *)manager {
    NSLog(@"%@ pausing location updates", _currentState);
}

- (void)locationManagerDidResumeLocationUpdates:(CLLocationManager *)manager {
    NSLog(@"%@ resuming location updates", _currentState);
}

#pragma mark - JSON to Dictionary Method

-(NSDictionary *) dictionaryFromJSON:(NSString *)json
{
    NSError *jsonError;
    NSData *myRequestData = [json dataUsingEncoding:NSUTF8StringEncoding];
    
    NSDictionary *returnDict = [NSJSONSerialization JSONObjectWithData:myRequestData
                                                               options: NSJSONReadingMutableContainers
                                                                 error: &jsonError];
    
    return returnDict;
}

#pragma mark -
#pragma mark custom methods

-(void)connectToMqtt {
    NSLog(@"connectToMqtt");
    // setup handleMqttConnect method with AWSIoTMQTTStatus *status and set value for connected there
    self.iotDataManager = [AWSIoTDataManager defaultIoTDataManager];
    
    if (self.connected == NO) {
        NSString *lastWillJSON = [self createLastWillJSON:@"unavailable" withShow:@"dead"];
        //        self.iotDataManager.mqttConfiguration.keepAliveTimeInterval = 75.0;
        self.iotDataManager.mqttConfiguration.lastWillAndTestament.topic = self.mqttTopic;
        self.iotDataManager.mqttConfiguration.lastWillAndTestament.message = lastWillJSON;
        self.iotDataManager.mqttConfiguration.lastWillAndTestament.qos = AWSIoTMQTTQoSMessageDeliveryAttemptedAtMostOnce;
        NSLog(@"connectUsingWebSocketWithClientId, setting last will message to: %@", lastWillJSON);
        //
        // Need a unique device ID because two devices logged onto the same conversation cannot share the same websocket
        //
        NSString *deviceId = [[NSUUID UUID] UUIDString] ;
        NSLog(@"connectUsingWebSocketWithClientId with deviceId: %@", deviceId);
        //
        // Connect to IoT using websocket
        //
        [self.iotDataManager connectUsingWebSocketWithClientId:deviceId cleanSession:true statusCallback:^(AWSIoTMQTTStatus status) {
            
            NSLog(@"in connectToMqtt callback with status:%ld", (long)status);
            
            switch (status) {
                case AWSIoTMQTTStatusConnecting:
                    NSLog(@"AWSIoTMQTTStatusConnecting");
                    break;
                    
                case AWSIoTMQTTStatusConnected:
                    NSLog(@"AWSIoTMQTTStatusConnected");
                    self.connected = YES;
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"mqttConnected" object:self];
                    break;
                    
                case AWSIoTMQTTStatusDisconnected:
                    NSLog(@"AWSIoTMQTTStatusDisconnected");
                    self.connected = NO;
                    break;
                    
                case AWSIoTMQTTStatusConnectionRefused:
                    NSLog(@"AWSIoTMQTTStatusConnectionRefused");
                    break;
                    
                case AWSIoTMQTTStatusConnectionError:
                    NSLog(@"AWSIoTMQTTStatusConnectionError");
                    break;
                    
                case AWSIoTMQTTStatusProtocolError:
                    NSLog(@"AWSIoTMQTTStatusProtocolError");
                    break;
                    
                case AWSIoTMQTTStatusUnknown:
                    NSLog(@"AWSIoTMQTTStatusUnknown");
                    break;
                    
                default:
                    break;
            }
        }];
    } else {
        // you are already connected
        NSLog(@"already connected to MQTT");
    }
}

-(void)disconnectFromMqtt {
    if (self.connected) {
        // disconnect now
        NSLog(@"disconnectFromMqtt");
        [self.iotDataManager disconnect];
    }
}

- (void) configureMqttReceivedMessageBlock {
    // You can't refer to self or properties on self from within a block that will be strongly retained by self
    // Create a weak reference to self to avoid a retain cycle
    __weak typeof(self) weakSelf = self;
    self.mqttReceivedMessageBlock = ^(NSData *data) {
        NSString *receivedString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@"subscribeAndReceiveMqtt ^mqttReceivedMessage callback from subscribed topic with data: %@", receivedString);
        NSDictionary *bodyDict = [self dictionaryFromJSON:receivedString];
        
        // Don't do anything unless actor = agent
        if ([[bodyDict objectForKey:@"actor"] isEqualToString:@"agent"]) {
            if ([[bodyDict objectForKey:@"type"] isEqualToString:@"indicator"]) {
                if ([[bodyDict objectForKey:@"show"] isEqualToString:@"composing"]) {
                    // composing
                    if (![weakSelf.mqttAgentIndicatorState isEqualToString:@"composing"]) {
//                        [weakSelf createTypingIndicator];
                    }
                    weakSelf.mqttAgentIndicatorState = @"composing";
                }
                else if ([[bodyDict objectForKey:@"show"] isEqualToString:@"paused"]) {
                    // paused
                    if ([weakSelf.mqttAgentIndicatorState isEqualToString:@"composing"]) {
//                        [weakSelf removeTypingIndicator];
                    }
                    weakSelf.mqttAgentIndicatorState = @"paused";
                }
            }
            else if ([[bodyDict objectForKey:@"type"] isEqualToString:@"message"]) {
                // message
                if (weakSelf.isUpdating) {
//                    weakSelf.runJob = @"loadConv";
                } else {
                    // Load the conversation
//                    [weakSelf loadConversation:weakSelf.conversationGuid];
                    weakSelf.mqttAgentIndicatorState = @"paused";
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"mytimeDataChanged" object:weakSelf];
                }
            }
        } else {
            NSLog(@"message arrived but was not from an agent");
        }
        NSLog(@"--------------- END callback method --------------");
    };
}

-(void)subscribeAndReceiveMqtt {
    NSLog(@"subscribeAndReceiveMqtt");
    [self configureMqttReceivedMessageBlock];
    [self.iotDataManager subscribeToTopic:self.mqttTopic QoS:AWSIoTMQTTQoSMessageDeliveryAttemptedAtLeastOnce messageCallback:self.mqttReceivedMessageBlock];
    [self publishConnectPresence];
}

- (void)publishIndicator:(NSString *)show {
    NSString *bodyJson = [self createIndicatorJSON:show]; // simple JSON contains type, actor and show
    NSLog(@"sendIndicator bodyJson:%@", bodyJson);
    if (![bodyJson isEqualToString:@"error"]) {
        [self.iotDataManager publishString:bodyJson onTopic:self.mqttTopic QoS:AWSIoTMQTTQoSMessageDeliveryAttemptedAtMostOnce];
    }
}

- (void)publishMessageNotification {
    NSString *bodyJson = [self createMessageNotificationJSON]; // simple JSON contains type, actor and show
    NSLog(@"sendMessageNotification bodyJson:%@", bodyJson);
    if (![bodyJson isEqualToString:@"error"]) {
        [self.iotDataManager publishString:bodyJson onTopic:self.mqttTopic QoS:AWSIoTMQTTQoSMessageDeliveryAttemptedAtMostOnce];
    }
}

- (void)publishPresence:(NSString *)presenceState withShow:(NSString *)showString {
    NSLog(@"publishPresence called with presenceState: %@ show: %@", presenceState, showString);
    
    NSString *jsonString = [self createPresenceJSON:presenceState withShow:showString];
    
    if ([jsonString isEqualToString:@"error"]) {
        NSLog(@"do not send presence, there was a prepare json error: %@", jsonString);
    } else {
        // send presence
        NSLog(@"publishPresence publishString:jsonString:%@ ", jsonString);
        [self.iotDataManager publishString:jsonString onTopic:self.mqttTopic QoS:AWSIoTMQTTQoSMessageDeliveryAttemptedAtMostOnce];
    }
}

- (void)publishConnectPresence {
    [self publishPresence:@"available" withShow:@"chat"];
//    [self.connectTimer invalidate];
//    self.connectTimer = nil;
}

- (NSString *)createPresenceJSON:(NSString *)presenceState withShow:(NSString *)showString {
    NSMutableDictionary *statusDict = [[NSMutableDictionary alloc] init];
    
//    [statusDict setObject:[[[CSSingletonClass singleObject] companyGuid] uppercaseString] forKey:kCScompanyGuid];
//    [statusDict setObject:[self.conversationGuid uppercaseString] forKey:kCSconversationGuid];
//    [statusDict setObject:[[[CSSingletonClass singleObject] userGuidString] uppercaseString] forKey:kCSuserGuid];
    [statusDict setObject:@"ios" forKey:@"resource"];
    [statusDict setObject:@"user" forKey:@"actor"];
    [statusDict setObject:@"presence" forKey:@"type"];
    [statusDict setObject:presenceState forKey:@"presenceState"];
    [statusDict setObject:showString forKey:@"show"];
    
    NSLog(@"statusDic ready for jsonConversion: %@", statusDict);
    return [self serializeDictToJSON:statusDict];
}

- (NSString *)createLastWillJSON:(NSString *)presenceState withShow:(NSString *)showString {
    NSMutableDictionary *statusDict = [[NSMutableDictionary alloc] init];
    
//    [statusDict setObject:[[[CSSingletonClass singleObject] companyGuid] uppercaseString] forKey:kCScompanyGuid];
//    [statusDict setObject:[self.conversationGuid uppercaseString] forKey:kCSconversationGuid];
//    [statusDict setObject:[[[CSSingletonClass singleObject] userGuidString] uppercaseString] forKey:kCSuserGuid];
//    [statusDict setObject:@"ios" forKey:kCSresource];
//    [statusDict setObject:@"user" forKey:kCSactor];
//    [statusDict setObject:@"presence" forKey:kCStype];
//    [statusDict setObject:presenceState forKey:kCSpresenceState];
//    [statusDict setObject:showString forKey:kCSshow];
    
    NSLog(@"statusDic ready for jsonConversion: %@", statusDict);
    return [self serializeDictToJSON:statusDict];
}

-(NSString *)createIndicatorJSON:(NSString *)show {
    NSMutableDictionary *bodyDict = [[NSMutableDictionary alloc] init];
    [bodyDict setObject:@"abcd1234" forKey:@"companyGuid"];
    [bodyDict setObject:@"wxyz9876" forKey:@"conversationGuid"];
    [bodyDict setObject:@"indicator" forKey:@"type"];
    [bodyDict setObject:@"user" forKey:@"actor"];
    return [self serializeDictToJSON:bodyDict];
}

-(NSString *)createMessageNotificationJSON {
    NSMutableDictionary *bodyDict = [[NSMutableDictionary alloc] init];
//    [bodyDict setObject:[[[CSSingletonClass singleObject] companyGuid] uppercaseString] forKey:kCScompanyGuid];
//    [bodyDict setObject:[self.conversationGuid uppercaseString] forKey:kCSconversationGuid];
//    [bodyDict setObject:[[[CSSingletonClass singleObject] userGuidString] uppercaseString] forKey:kCSuserGuid];
    [bodyDict setObject:@"message" forKey:@"type"];
    [bodyDict setObject:@"user" forKey:@"actor"];
    return [self serializeDictToJSON:bodyDict];
}

-(NSString *)serializeDictToJSON:(NSMutableDictionary *)inputDict {
    NSError *serializeError;
    NSData *statusData;
    
    if ([NSJSONSerialization isValidJSONObject:inputDict])
    {
        statusData = [NSJSONSerialization dataWithJSONObject:inputDict options:NSJSONWritingPrettyPrinted error:&serializeError];
    }
    if (serializeError)
    {
        NSLog(@"jsonError: %@", serializeError);
        return @"error";
    }
    else
    {
        NSLog(@"jsonSuccess: %@", statusData);
        NSString *statusAsString = [[NSString alloc] initWithData:statusData encoding:NSUTF8StringEncoding];
        NSLog(@"stringSuccess: %@", statusAsString);
        return statusAsString;
    }
}

@end
