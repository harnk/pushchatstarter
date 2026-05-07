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
#import "APIClient.h"
#import "ServerURLManager.h"
#import <UserNotifications/UserNotifications.h>

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
#pragma mark Notifications

- (NSString *)hexStringFromDeviceToken:(NSData *)deviceToken
{
    const unsigned char *dataBuffer = (const unsigned char *)[deviceToken bytes];
    NSUInteger dataLength = [deviceToken length];
    NSMutableString *hexString = [NSMutableString stringWithCapacity:(dataLength * 2)];

    for (int i = 0; i < dataLength; ++i) {
        [hexString appendFormat:@"%02x", (unsigned int)dataBuffer[i]];
    }
    return [hexString copy];
}

- (void)application:(UIApplication*)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken
{
    NSLog(@"My RAW Device Token: %@", deviceToken);
    NSString *hexString = [self hexStringFromDeviceToken:deviceToken];
    NSLog(@"My Device Token: %@", hexString);
    NSLog(@"%@ My location is: %@", _currentState, [[SingletonClass singleObject] myLocStr]);
    
    UINavigationController *navigationController = (UINavigationController*)_window.rootViewController;
    
    //    ChatViewController *chatViewController = (ChatViewController*)[navigationController.viewControllers objectAtIndex:0];
    ShowMapViewController *showMapViewController = (ShowMapViewController*)[navigationController.viewControllers  objectAtIndex:0];
    
    //    DataModel *dataModel = chatViewController.dataModel;
    DataModel *dataModel = showMapViewController.dataModel;
    
    NSString *oldToken = [dataModel deviceToken];
    
    NSLog(@"My oldToken is: %@", oldToken);
    NSLog(@"My newToken is: %@", hexString);

    //    NSLog(@"Got a token so notificationsAreDisabled to NO");
    [[SingletonClass singleObject] setNotificationsAreDisabled:NO];
    
    //Tell the app the good news
    [[NSNotificationCenter defaultCenter] postNotificationName:@"receivedDeviceToken" object:nil userInfo:nil];
    
    [dataModel setDeviceToken:hexString];
    NSString *newToken = [dataModel deviceToken];

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
    // FIRST: Initialize the server URL from the gist before making any API calls
    [ServerURLManager initializeServerURL:^(BOOL success) {
        if (success) {
            NSLog(@"✅ App ready - Server URL is: %@", [ServerURLManager serverURL]);
        } else {
            NSLog(@"⚠️ Failed to initialize server URL, using fallback");
        }
    }];
    
    // ...existing code...
    _storyBoard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
    
    // Check the keychain for the userID
    UICKeyChainStore *keychain = [UICKeyChainStore keyChainStoreWithService:@"com.harnk.WhereRU.storedid"];
    NSString *userId = [keychain stringForKey:@"mysaveduserid"];
    NSLog(@"SCXTT ====================================== READ KEYCHAIN BEFORE: %@", userId);
    
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
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];

    [center requestAuthorizationWithOptions:(UNAuthorizationOptionAlert |
                                             UNAuthorizationOptionSound |
                                             UNAuthorizationOptionBadge)
                          completionHandler:^(BOOL granted, NSError * _Nullable error) {
    }];

    [[UIApplication sharedApplication] registerForRemoteNotifications];
    
//    we should only do this next line if we are already imInARoom and also move this to start updating when we are notified of leave ShowMapViewController and not right here
    [self startMyLocationUpdates];
    
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
    NSLog(@"%@ postImhere %@", _currentState, [[SingletonClass singleObject] myLocStr]);
    NSString *text = @"Im Here";
    
    NSDictionary *params = @{@"cmd":@"imhere",
                             @"user_id":[[NSUserDefaults standardUserDefaults] stringForKey:@"UserId"],
                             @"asker":asker,
                             @"location":[[SingletonClass singleObject] myLocStr],
                             @"text":text};
    
    [[APIClient sharedClient] postToEndpoint:ServerPostPathURL
                                  parameters:params
                                     success:nil
                                     failure:nil];
}

-(void)resetIsUpdating {
    _isUpdating = NO;
}

// next needs work has issues 4/26 SCXTT
static void checkForLookers(AppDelegate *object, NSArray *jsonArray) {
    BOOL foundALooker = NO;
    for(NSDictionary *item in jsonArray) {
        NSString *mLooking = [item objectForKey:@"looking"];
        if ([mLooking isEqual:@"1"]) {
            NSString *mNickName = [item objectForKey:@"nickname"];
            NSLog(@"%@  %@ is looking", object->_currentState, mNickName);
            foundALooker = YES;
            NSLog(@"%@ Toggle singleton BOOL someoneIsLooking to foundALooker=YES and exit the loop", object->_currentState);
        }
    }
    NSLog(@"%@ set singleton someoneIsLooking = foundALooker which equals %d", object->_currentState, foundALooker);
    if (foundALooker) {
        NSLog(@"%@ since someoneIsLooking keep updating my loc in the background", object->_currentState);
        retryCounter = 0;
    } else {
        if (object->_isBackgroundMode){
            retryCounter += 1;
            NSLog(@"NO ONE is looking so why am I wasting my battery with these background API calls?!? Retry:%d", retryCounter);
            if (retryCounter > 10) {
                NSLog(@"IM DONE with AppDelegate LocationManager so setDistanceFilter:99999");
                NSLog(@"SCXTT CANT STOP LOCATIONMANAGER HERE so setDesiredAccuracy:kCLLocationAccuracyThreeKilometers");
                
                
                object.locationManager.pausesLocationUpdatesAutomatically = YES;
                object.locationManager.activityType = CLActivityTypeAutomotiveNavigation;
                [object.locationManager setDesiredAccuracy:kCLLocationAccuracyThreeKilometers];
                [object.locationManager setDistanceFilter:99999];
                
            }
        }
    }
}

-(void)postLiveUpdate
{
    NSLog(@"%@ postLiveUpdate %@", _currentState, [[SingletonClass singleObject] myLocStr]);

    NSDictionary *params = @{@"cmd":@"liveupdate",
                             @"user_id":[[NSUserDefaults standardUserDefaults] stringForKey:@"UserId"],
                             @"location":[[SingletonClass singleObject] myLocStr]};
    
    [[APIClient sharedClient] postToEndpoint:ServerPostPathURL
                                  parameters:params
                                     success:^(id responseObject, NSHTTPURLResponse *httpResponse) {
                                         NSString* responseString = [NSString stringWithUTF8String:[responseObject bytes]];
                                         
                                         // Deal with me if I have been deleted from the active_users table in the DB
                                         if (responseString.length == 0) {
                                             badResponseCounter += 1;
                                             if (badResponseCounter > 5) {
                                                 [[SingletonClass singleObject] setImInARoom:NO];
                                             }
                                         } else {
                                             badResponseCounter = 0;
                                         }
                                         
                                         [NSTimer scheduledTimerWithTimeInterval: 5 target: self selector: @selector(resetIsUpdating) userInfo: nil repeats: NO];
                                     }
                                     failure:^(NSError *error) {
                                         [NSTimer scheduledTimerWithTimeInterval: 10 target: self selector: @selector(resetIsUpdating) userInfo: nil repeats: NO];
                                     }];
}

-(void) postMyLoc {
    if ([[SingletonClass singleObject] imInARoom]) {
        NSLog(@"%@ imInARoom is true", _currentState);
        if (!_isUpdating) {
            NSLog(@"%@ were not _isUpdating", _currentState);
            if (_deviceHasMoved) {
                _isUpdating = YES;
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
    
    [[APIClient sharedClient] postToEndpoint:ServerPostPathURL
                                  parameters:params
                                     success:nil
                                     failure:nil];
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
    
    CLLocation *oldLoc = [[SingletonClass singleObject] myNewLocation];
    CLLocation *newLoc = [locations lastObject];
    CLLocationDistance distanceMoved = [oldLoc distanceFromLocation:newLoc];
//    NSLog(@"SCXTT SCXTT newLoc: %@ ", [NSString stringWithFormat:@"%f, %f", newLoc.coordinate.latitude, newLoc.coordinate.longitude]);
//    NSLog(@"SCXTT distanceMoved: %f ", distanceMoved);
    if (distanceMoved < 0.01) {
        fprintf(stderr, ".");
        return;
    } else {
        NSLog(@"%@ AppDelegate-didUpdateLocations device moved %f yards", _currentState, distanceMoved);
    }
//    NSLog(@"%@ AppDelegate-didUpdateLocations background delegate device moved %f yards", _currentState, distanceMoved);
    [[SingletonClass singleObject] setMyNewLocation:newLoc];
    [[SingletonClass singleObject] setMyLocStr: [NSString stringWithFormat:@"%f, %f", newLoc.coordinate.latitude, newLoc.coordinate.longitude]];
    //SCXTT RELEASE
    // If moved farther than 20 yards do an API call SCXTT - add logic
    _deviceHasMoved = YES;
    
    
    // Do NOT do this next line if SMVC is still active and looking
    [self postLiveUpdate]; //DEBUG - do this alot FOR NOW UNTIL I GET THIS ALL WORKING AGAIN
    
    
    if (_isBackgroundMode) {
        [self postMyLoc]; // API
//        [self publishIMoved]; // MQTT
    }
}

- (void)locationManagerDidPauseLocationUpdates:(CLLocationManager *)manager {
    NSLog(@"%@ pausing location updates", _currentState);
}

- (void)locationManagerDidResumeLocationUpdates:(CLLocationManager *)manager {
    NSLog(@"%@ resuming location updates", _currentState);
}


#pragma mark - JSON <==> Dictionary Methods

-(NSDictionary *) dictionaryFromJSON:(NSString *)json
{
    NSError *jsonError;
    NSData *myRequestData = [json dataUsingEncoding:NSUTF8StringEncoding];
    
    NSDictionary *returnDict = [NSJSONSerialization JSONObjectWithData:myRequestData
                                                               options: NSJSONReadingMutableContainers
                                                                 error: &jsonError];
    
    return returnDict;
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
        NSString *statusAsString = [[NSString alloc] initWithData:statusData encoding:NSUTF8StringEncoding];
        NSLog(@"stringSuccess: %@", statusAsString);
        return statusAsString;
    }
}

@end
