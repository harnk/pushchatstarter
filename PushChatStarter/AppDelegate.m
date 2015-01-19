//
//  AppDelegate.m
//  PushChatStarter
//
//  Created by Kauserali on 28/03/13.
//  Copyright (c) 2013 Ray Wenderlich. All rights reserved.
//

#import "AppDelegate.h"
#import "ChatViewController.h"
#import "ComposeViewController.h"
#import "DataModel.h"
#import "Message.h"


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
    ChatViewController *chatViewController =
    (ChatViewController*)[navigationController.viewControllers  objectAtIndex:0];
    
    DataModel *dataModel = chatViewController.dataModel;
    
    Message *message = [[Message alloc] init];
    message.date = [NSDate date];
    message.location = [[userInfo valueForKey:@"aps"] valueForKey:@"loc"];
    
    NSString *alertValue = [[userInfo valueForKey:@"aps"] valueForKey:@"alert"];
//    NSString *alertValue = [[userInfo valueForKey:@"aps"] valueForKey:@"extra"];
    
    NSMutableArray *parts = [NSMutableArray arrayWithArray:[alertValue componentsSeparatedByString:@": "]];
    message.senderName = [parts objectAtIndex:0];
    [parts removeObjectAtIndex:0];
    message.text = [parts componentsJoinedByString:@": "];
    
    int index = [dataModel addMessage:message];
    
    if (updateUI)
        [chatViewController didSaveMessage:message atIndex:index];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler {
    
    NSLog(@"Received notification: %@", userInfo);
    
    NSString *extra = [[userInfo valueForKey:@"aps"] valueForKey:@"extra"];
    NSString *alert = [[userInfo valueForKey:@"aps"] valueForKey:@"alert"];

    if([extra isEqualToString:@"whereru"]) {
        NSString *asker = [[userInfo valueForKey:@"aps"] valueForKey:@"asker"];
        [self postImhere:asker];
    } else {
        if ([alert rangeOfString:@"Im Here"].location == NSNotFound) {
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
        // iOS 8 Notifications
        [application registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge) categories:nil]];
        
        [application registerForRemoteNotifications];
    }
    else
    {
        // iOS < 8 Notifications
        [application registerForRemoteNotificationTypes:
         (UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound)];
    }
    
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
    
    [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
    // register for types of remote notifications
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:
     (UIRemoteNotificationTypeNewsstandContentAvailability|
      UIRemoteNotificationTypeBadge |
      UIRemoteNotificationTypeSound |
      UIRemoteNotificationTypeAlert)];
    
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
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    NSLog(@"applicationWillEnterForeground");
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

-(void)postImhere:(NSString *)asker
{
    
    NSLog(@"Respond to WhereRU with Im Here back to asker");

    
//    SCXTT clean this crap up
    
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
#ifdef __IPHONE_8_0
    if(IS_OS_8_OR_LATER) {
        // Use one or the other, not both. Depending on what you put in info.plist
        //        [self.locationManager requestWhenInUseAuthorization];
        [self.locationManager requestAlwaysAuthorization];
    }
#endif
    [self.locationManager startUpdatingLocation];

    NSLog(@"Im over here %@", [self deviceLocation]);
        
    
    
    ComposeViewController *getLocationData;
    getLocationData = [[ComposeViewController alloc] init];
//    [getLocationData.locationManager startUpdatingLocation];
//    NSLog(@"Im here: %@",[getLocationData deviceLocation]);
    
    UINavigationController *navigationController = (UINavigationController*)_window.rootViewController;
    ChatViewController *chatViewController = (ChatViewController*)[navigationController.viewControllers objectAtIndex:0];
    
    DataModel *dataModel = chatViewController.dataModel;
    
    NSString *text = @"Im Here";
    
    NSDictionary *params = @{@"cmd":@"imhere",
                             @"user_id":[dataModel userId],
                             @"asker":asker,
                             @"location":[self deviceLocation],
                             @"text":text};
    
    NSLog(@"Doing API Call with %@", params);
    
    AFHTTPClient *client = [AFHTTPClient clientWithBaseURL:[NSURL URLWithString:ServerApiURL]];
    [client
     postPath:@"/whereru/api/api.php"
     parameters:params
     success:nil failure:nil];
    
}

- (NSString *)deviceLocation {
    return [NSString stringWithFormat:@"%f, %f", self.locationManager.location.coordinate.latitude, self.locationManager.location.coordinate.longitude];
}

- (void)postUpdateRequest
{
    UINavigationController *navigationController = (UINavigationController*)_window.rootViewController;
    ChatViewController *chatViewController = (ChatViewController*)[navigationController.viewControllers objectAtIndex:0];
    
    DataModel *dataModel = chatViewController.dataModel;
    
    NSDictionary *params = @{@"cmd":@"update",
                             @"user_id":[dataModel userId],
                             @"token":[dataModel deviceToken]};
    AFHTTPClient *client = [AFHTTPClient clientWithBaseURL:[NSURL URLWithString:ServerApiURL]];
    [client
     postPath:@"/whereru/api/api.php"
     parameters:params
     success:nil failure:nil];
}

- (void)application:(UIApplication*)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken
{
    UINavigationController *navigationController = (UINavigationController*)_window.rootViewController;
    ChatViewController *chatViewController = (ChatViewController*)[navigationController.viewControllers objectAtIndex:0];
    
    DataModel *dataModel = chatViewController.dataModel;
    NSString *oldToken = [dataModel deviceToken];
    
    NSString *newToken = [deviceToken description];
    newToken = [newToken stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
    newToken = [newToken stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    NSLog(@"My token is: %@", newToken);
    
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
