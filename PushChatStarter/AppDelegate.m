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
    NSLog(@"SCXTT locA is:%@", locA);
    
    // Handle the location of the remote device
    NSArray *strings = [message.location componentsSeparatedByString:@","];
    CLLocation *locB = [[CLLocation alloc] initWithLatitude:[strings[0] doubleValue] longitude:[strings[1] doubleValue]];
    
    //    NSLog(@"locB is:%@", locB);
    
    CLLocationDistance distance = [locA distanceFromLocation:locB];
    NSLog(@"SCXTT The distance from me to it is:%f meters", distance);
    
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
//        NSString *asker = [[userInfo valueForKey:@"aps"] valueForKey:@"asker"];
        NSString *asker = [userInfo valueForKey:@"asker"];
        [self postImhere:asker];
        
    } else {
        if ([extra isEqualToString:@"imhere"]) {
            NSLog(@"Found someone - dont put into the message bubble");
        } else {
            [self addMessageFromRemoteNotification:userInfo updateUI:YES];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:@"receivedNewMessage" object:nil userInfo:userInfo];
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

//- (void)application:(UIApplication*)application didReceiveRemoteNotification:(NSDictionary*)userInfo
//{
//    NSLog(@"Received notification: %@", userInfo);
//    [self addMessageFromRemoteNotification:userInfo updateUI:YES];
//}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    
    _storyBoard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
    
    //-- Set Notification
    if ([application respondsToSelector:@selector(isRegisteredForRemoteNotifications)])
    {
        NSLog(@"SCXTT responds to isRegistered...");
        // iOS 8 Notifications
        [application registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge) categories:nil]];
        
        [application registerForRemoteNotifications];
    }
    else
    {
        NSLog(@"SCXTT DOES NOT respond to to isRegistered...");
        // iOS < 8 Notifications
        [application registerForRemoteNotificationTypes:
         (UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound)];
    }
    
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

    
    //--- your custom code
    
    if (launchOptions != nil)
    {
        NSDictionary *dictionary = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
        if (dictionary != nil)
        {
            NSLog(@"Launched from push notification: %@", dictionary);
            [self addMessageFromRemoteNotification:dictionary updateUI:NO];
        }
    }
    
    _isUpdating = NO;
    
    //SCXTT Need to review this and see if it is still necesary
    [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
    // register for types of remote notifications
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:
     (UIRemoteNotificationTypeNewsstandContentAvailability|
      UIRemoteNotificationTypeBadge |
      UIRemoteNotificationTypeSound |
      UIRemoteNotificationTypeAlert)];
    
    // Start updating my own location
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    _deviceHasMoved = YES;

    if(IS_OS_8_OR_LATER) {
        // Use one or the other, not both. Depending on what you put in info.plist
        //        [self.locationManager requestWhenInUseAuthorization];
        [self.locationManager requestAlwaysAuthorization];
    }
    self.locationManager.pausesLocationUpdatesAutomatically = YES;
    [self.locationManager startMonitoringSignificantLocationChanges];
    self.locationManager.activityType = CLActivityTypeFitness;
    [self.locationManager startUpdatingLocation];
    
    return YES;
}

// This is a delegate method that should get called in the background
-(void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    NSLog(@"########### Received Background Fetch ###########");
    //Download  the Content .
    
    //Cleanup
    completionHandler(UIBackgroundFetchResultNewData);
    
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     NSLog(@"applicationWillResignActive");
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    NSLog(@"applicationDidEnterBackground");
    [self.locationManager startMonitoringSignificantLocationChanges];
    [self.locationManager startUpdatingLocation];
    
    backgroundTimer = [NSTimer scheduledTimerWithTimeInterval: 60
                                               target: self
                                             selector: @selector(postMyLoc)
                                             userInfo: nil
                                              repeats: YES];
    //Kill the getRoomTimer
    [[NSNotificationCenter defaultCenter] postNotificationName:@"killGetRoomTimer" object:nil userInfo:nil];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    NSLog(@"applicationWillEnterForeground");
    [[Harpy sharedInstance] checkVersion];
    
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    NSLog(@"applicationDidBecomeActive");
    application.applicationIconBadgeNumber = 0;
    //Start the getRoomTimer going again
    [[NSNotificationCenter defaultCenter] postNotificationName:@"commenceGetRoomTimer" object:nil userInfo:nil];
    [backgroundTimer invalidate];
    backgroundTimer = nil;
    
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        NSLog(@"applicationWillTerminate");
}

-(void)application:(UIApplication *)application didRegisterUserNotificationSettings:   (UIUserNotificationSettings *)notificationSettings
{
    if (notificationSettings.types) {
        NSLog(@"user allowed notifications");
//        [[UIApplication sharedApplication] registerForRemoteNotifications];
    }else{
        NSLog(@"user did not allow notifications");
        // show alert here
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Notifications Are Disabled" message:@"This app requires notifications in order to function. You need to enable notifications. Choose Settings to enable them" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Settings", nil];
        [alert show];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1)
    {
        NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
        [[UIApplication sharedApplication] openURL:url];
    }
}

-(void)postImhere:(NSString *)asker
{
    NSLog(@"Respond to WhereRU with Im Here back to asker");
    NSLog(@"postImhere %@", [[SingletonClass singleObject] myLocStr]);
    NSString *text = @"Im Here";
    
    NSDictionary *params = @{@"cmd":@"imhere",
                             @"user_id":[[NSUserDefaults standardUserDefaults] stringForKey:@"UserId"],
                             @"asker":asker,
                             @"location":[[SingletonClass singleObject] myLocStr],
                             @"text":text};
    
    //    NSLog(@"Doing API Call with %@", params);
    
    AFHTTPClient *client = [AFHTTPClient clientWithBaseURL:[NSURL URLWithString:ServerApiURL]];
    [client
     postPath:@"/whereru/api/api.php"
     parameters:params
     success:nil failure:nil];
    
}

-(void)resetIsUpdating {
    _isUpdating = NO;
}

-(void)postLiveUpdate
{
    NSLog(@"This is called whenever the device location changes, should not do more than once every 5 seconds");
    NSLog(@"postLiveUpdate %@", [[SingletonClass singleObject] myLocStr]);

    NSDictionary *params = @{@"cmd":@"liveupdate",
                             @"user_id":[[NSUserDefaults standardUserDefaults] stringForKey:@"UserId"],
                             @"location":[[SingletonClass singleObject] myLocStr]};
    
    //    NSLog(@"Doing API Call with %@", params);
    
    AFHTTPClient *client = [AFHTTPClient clientWithBaseURL:[NSURL URLWithString:ServerApiURL]];
    [client
     postPath:@"/whereru/api/api.php"
     parameters:params
     success:^(AFHTTPRequestOperation *operation, id responseObject) {
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
    
    if (!_isUpdating) {
        if (_deviceHasMoved) {
            _isUpdating = YES;
            NSLog(@" bkgnd posting my loc %@", [[SingletonClass singleObject] myLocStr]);
            [self postLiveUpdate];
            _deviceHasMoved = NO;
        }
    } else {
        NSLog(@"no API call since _isUpdating is already YES = Busy");
    }
}


//Ref: http://stackoverflow.com/questions/12602463/didupdatelocations-instead-of-didupdatetolocation
//
- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray *)locations {
    
    [[SingletonClass singleObject] setMyNewLocation:[locations lastObject]];
    
    CLLocation *newLoc = [locations lastObject];
    
// If the stored loc string is the same as this new one do not print to the console
    if ([[[SingletonClass singleObject] myLocStr] isEqualToString: [NSString stringWithFormat:@"%f, %f", newLoc.coordinate.latitude, newLoc.coordinate.longitude]] ) {
        //do nothing
//        NSLog(@"same");
    } else {
        //log it, save it
        [[SingletonClass singleObject] setMyLocStr: [NSString stringWithFormat:@"%f, %f", newLoc.coordinate.latitude, newLoc.coordinate.longitude]];
//        NSLog(@"didUpdateLocations Move to: %@", [locations lastObject]);
        NSLog(@"API postMyLoc didUpdateLocations I moved to: %@", [[SingletonClass singleObject] myLocStr]);
        // If moved farther than 20 yards do an API call scxtt
        _deviceHasMoved = YES;
        [self postMyLoc];
    }
}

- (void)locationManagerDidPauseLocationUpdates:(CLLocationManager *)manager {
    NSLog(@"pausing location updates");
}

- (void)locationManagerDidResumeLocationUpdates:(CLLocationManager *)manager {
    NSLog(@"resuming location updates");
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
     postPath:@"/whereru/api/api.php"
     parameters:params
     success:nil failure:nil];
}

- (void)application:(UIApplication*)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken
{
    
    NSLog(@"My location is: %@", [[SingletonClass singleObject] myLocStr]);
    
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
    
    NSLog(@"SCXTT got a token so notificationsAreDisabled to NO");
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

@end
