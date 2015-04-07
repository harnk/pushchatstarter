//
//  ShowMapViewController.m
//  PushChatStarter
//
//  Created by Scott Null on 12/28/14.
//  Copyright (c) 2014 Ray Wenderlich. All rights reserved.
//

#import "ShowMapViewController.h"
#import "VBAnnotation.h"
#import "DataModel.h"
#import "LoginViewController.h"
#import "Message.h"
#import "MessageTableViewCell.h"
#import "SpeechBubbleView.h"
#import "ServiceConnector.h"
#import "JSONDictionaryExtensions.h"
#import "Room.h"

// Carpinteria
#define CA_LATITUDE 37
#define CA_LONGITUDE -95
// Beach
#define BE_LATITUDE -45
#define BE_LONGITUDE 45
// Reston hotel
//#define BE_LATITUDE 38.960663
//#define BE_LONGITUDE -77.423423
#define BE2_LATITUDE 41.736207
#define BE2_LONGITUDE -86.098724

#define SPAN_VALUE 0.005f

@interface ShowMapViewController () {
    AFHTTPClient *_client;
    NSArray *pinImages;
    NSTimer *getRoomTimer;
}
@end

//RotationIn_IOS6 is a Category for overriding the default orientation
// http://stackoverflow.com/questions/12577879/shouldautorotatetointerfaceorientation-is-not-working-in-ios-6

@implementation UINavigationController (RotationIn_IOS6)

-(BOOL)shouldAutorotate
{
    return [[self.viewControllers lastObject] shouldAutorotate];
}
@end


@implementation ShowMapViewController

- (id) initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        
        _dataModel = [[DataModel alloc] init];
        // Load all the messages for this room
        [_dataModel loadMessages:[[SingletonClass singleObject] myLocStr]];
        
        _client = [AFHTTPClient clientWithBaseURL:[NSURL URLWithString:ServerApiURL]];

//        NSLog(@"myPinImages[1]:%@", myPinImages[0]);
        
    }
    return self;
}

- (void)scrollToNewestMessage
{
    // The newest message is at the bottom of the table
    NSIndexPath* indexPath = [NSIndexPath indexPathForRow:(self.dataModel.messages.count - 1) inSection:0];
    [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1)
    {
        NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
        [[UIApplication sharedApplication] openURL:url];
    }
}

- (void)setUpTimersAndObservers {
    [NSTimer scheduledTimerWithTimeInterval: 7
                                     target: self
                                   selector: @selector(areNotificationsEnabled)
                                   userInfo: nil
                                    repeats: NO];

//    getRoomTimer  = [NSTimer scheduledTimerWithTimeInterval: 5
//                                               target: self
//                                                   selector: @selector(postGetRoom)
//                                             userInfo: nil
//                                              repeats: YES];
    
    //Set up a timer to check for new messages if the user has notifications disabled
    [NSTimer scheduledTimerWithTimeInterval: 30
                                     target: self
                                   selector: @selector(checkForNewMessage:)
                                   userInfo: nil
                                    repeats: YES];
    
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updatePointsOnMapWithNotification:)
                                                 name:@"receivedNewMessage"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(findAction)
                                                 name:@"receivedDeviceToken"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updatePointsOnMapWithAPIData)
                                                 name:@"receivedNewAPIData"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(postGetRoomMessages)
                                                 name:@"userJoinedRoom"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(stopGetRoomTimer)
                                                 name:@"killGetRoomTimer"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(startGetRoomTimer)
                                                 name:@"commenceGetRoomTimer"
                                               object:nil];
    
    
}

- (void)setUpButtonBarItems {
    UIBarButtonItem *btnGet = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(getDown:)];
    UIBarButtonItem *btnPost = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCamera target:self action:@selector(postDown:)];
    UIBarButtonItem *btnRefresh = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(findAction)];
    UIBarButtonItem *btnCompose = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:self action:@selector(composeAction)];
    UIBarButtonItem *btnSignOut = [[UIBarButtonItem alloc] initWithTitle:@"Sign Out" style:UIBarButtonItemStyleBordered target:self action:@selector(exitAction)];
    _btnMapType = [[UIBarButtonItem alloc] initWithTitle:@" Sat" style:UIBarButtonItemStyleBordered target:self action:@selector(chgMapAction)];
    //    [self.navigationItem setLeftBarButtonItem:leftBarButton];
    [self.navigationItem setLeftBarButtonItems:[NSArray arrayWithObjects:btnSignOut, _btnMapType, nil] animated:YES];
    //    [self.navigationItem setRightBarButtonItems:[NSArray arrayWithObjects:btnGet, btnPost, btnCompose, btnRefresh, nil] animated:YES];
    [self.navigationItem setRightBarButtonItems:[NSArray arrayWithObjects:btnCompose, btnRefresh, nil] animated:YES];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _okToRecenterMap = YES;
    
    [self.mapView setDelegate:self];
    self.mapView.layer.borderColor = [[UIColor colorWithRed:200/255.0 green:199/255.0 blue:204/255.0 alpha:1] CGColor];
    self.mapView.layer.borderWidth = 0.5;
    
    MKCoordinateRegion region;
    region.center.latitude = CA_LATITUDE;
    region.center.longitude = CA_LONGITUDE;
    region.span.latitudeDelta = 50.1f;
    region.span.longitudeDelta = 50.1f;
    [self.mapView setRegion:region animated:NO];
    
    CLLocationCoordinate2D location;
    location.latitude = BE_LATITUDE;
    location.longitude = BE_LONGITUDE;
    
    _textView.delegate = self;


    [self setUpTimersAndObservers];
    [self setUpButtonBarItems];
//    [self.navigationItem setLeftBarButtonItems:[NSArray arrayWithObjects:btnExit, nil] animated:YES];
    
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (![_dataModel joinedChat])
    {
        [self showLoginViewController];
    }
    
    //Reset pins on map
    [self.mapView removeAnnotations:_mapView.annotations];
//    [self postFindRequest];
    [self postGetRoom];
    
    [self.tableView reloadData];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.title = [_dataModel secretCode];
    
    // Show a label in the table's footer if there are no messages
    if (self.dataModel.messages.count == 0)
    {
        UILabel* label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 30)];
        label.text = NSLocalizedString(@"You have no messages", nil);
        label.font = [UIFont boldSystemFontOfSize:16.0f];
        label.textAlignment = NSTextAlignmentCenter;
        label.textColor = [UIColor colorWithRed:76.0f/255.0f green:86.0f/255.0f blue:108.0f/255.0f alpha:1.0f];
        label.shadowColor = [UIColor whiteColor];
        label.shadowOffset = CGSizeMake(0.0f, 1.0f);
        label.backgroundColor = [UIColor clearColor];
        label.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        self.tableView.tableFooterView = label;
    }
    else
    {
        [self scrollToNewestMessage];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    NSLog(@"scXtt viewWillDisappear");
}

- (void)stopGetRoomTimer {
    //BEFORE DOING SO CHECK THAT TIMER MUST NOT BE ALREADY INVALIDATED
    //Always nil your timer after invalidating so that
    //it does not cause crash due to duplicate invalidate
    NSLog(@"scXtt stopGetRoomTimer");
    if(getRoomTimer)
    {
        NSLog(@"scXtt [_getRoomTimer invalidate]");
        [getRoomTimer invalidate];
        getRoomTimer = nil;
    } else {
        
        NSLog(@"did nothing");
    }

}

-(void)startGetRoomTimer {
    NSLog(@"scXtt startGetRoomTimer");
    getRoomTimer  = [NSTimer scheduledTimerWithTimeInterval: 5
                                                      target: self
                                                   selector: @selector(postGetRoom)
                                                    userInfo: nil
                                                     repeats: YES];
    
}

-(void) areNotificationsEnabled {
    BOOL notifsDisabled = [[SingletonClass singleObject] notificationsAreDisabled];
    NSLog(@" SCXTT [[SingletonClass singleObject] notificationsAreDisabled] value: %d",notifsDisabled);
    NSLog(@"Move the ALERT HERE for Notifs being off");
    
    NSLog(@"SCXTT setting notificationsAreDisabled to YES by default");
    [[SingletonClass singleObject] setNotificationsAreDisabled:YES];
    // Check if notifications are enabled because this app won't work if they aren't
    //    _notificationsAreDisabled = false;
    BOOL isdisabled = true;
    
    if (IS_OS_8_OR_LATER) {
        if ([[UIApplication sharedApplication] respondsToSelector:@selector(isRegisteredForRemoteNotifications)])
        {
            NSLog(@"IS_OS_8_OR_LATER is YES");
            isdisabled =  ![[UIApplication sharedApplication] isRegisteredForRemoteNotifications];
            NSLog(@"isdisabled value: %d",isdisabled);
        }
        
    } else {
        NSLog(@"IS_OS_8_OR_LATER is NO");
        
        
        UIRemoteNotificationType notifTypes = [[UIApplication sharedApplication] enabledRemoteNotificationTypes];
        //        if (notifTypes & UIRemoteNotificationTypeAlert)
        if (notifTypes != 12)
        {
            isdisabled = false;
            NSLog(@"isdisabled value: %d",isdisabled);
            //            NSLog(@"UIRemoteNotificationType notifTypes: %lu", notifTypes);
        }
    }
    
    
    [[SingletonClass singleObject] setNotificationsAreDisabled:isdisabled];
    //    _notificationsAreDisabled = isdisabled;
    
    //Pop an aler to let the user go to settings and change notifications setting for this app
    if (isdisabled) {
        if (IS_OS_8_OR_LATER){
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Notifications Are Disabled" message:@"This app requires notifications in order to function. You need to enable notifications. Choose Settings to enable them" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Settings", nil];
            [alert show];
        } else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Notifications Are Disabled" message:@"This app requires notifications in order to function. You need to enable notifications in Settings - Notification Center." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil, nil];
            [alert show];
        }
    }
    
}



#pragma mark -
#pragma mark Date String Methods

- (NSString *)localDateStrFromUTCDateStr:(NSString *) utcDateStr {
    NSString * localDateStr;
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"YYYY-MM-dd HH:mm:ss"];
    //Create the date assuming the given string is in GMT
    formatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    NSDate *date = [formatter dateFromString:utcDateStr];
    
    //Create a date string in the local timezone
    formatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:[NSTimeZone localTimeZone].secondsFromGMT];
    [formatter setDateStyle:NSDateFormatterShortStyle];
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    [formatter setDoesRelativeDateFormatting:YES];
    localDateStr = [formatter stringFromDate:date];
    return localDateStr;
}

- (NSDate *)dateFromUTCDateStr:(NSString *) utcDateStr {
    NSDate * date;
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"YYYY-MM-dd HH:mm:ss"];
    //Create the date assuming the given string is in GMT
    formatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    date = [formatter dateFromString:utcDateStr];
    return date;
}

- (NSInteger)getPinAgeInMinutes:(NSString *)gmtDateStr
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"YYYY-MM-dd HH:mm:ss"];
    [formatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    //Create the date assuming the given string is in GMT
    NSDate *jsonDate = [formatter dateFromString:gmtDateStr];
    NSDate *now = [NSDate date];
    
    NSTimeInterval distanceBetweenDates = [now timeIntervalSinceDate:jsonDate];
    double secondsInAnMinute = 60;
    NSInteger minutesBetweenDates = distanceBetweenDates / secondsInAnMinute;
    return minutesBetweenDates;
}



#pragma mark - UITableViewDataSource

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
//    NSLog(@"SCXTT willDisplayCell CELL WIDTH %f", cell.contentView.frame.size.width);
}

- (int)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    return (int)self.dataModel.messages.count;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    static NSString* CellIdentifier = @"MessageCellIdentifier";
    
    MessageTableViewCell* cell = (MessageTableViewCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[MessageTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    Message* message = (self.dataModel.messages)[indexPath.row];
//    NSLog(@"message.text:%@", message.text);
//    NSLog(@"message.location:%@", message.location);

//    NSLog(@"SCXTT What is the CELL WIDTH here???");
//    NSLog(@"%f", cell.contentView.frame.size.width);
    
    
    [cell setMessage:message];
    
    //Do orientation specific stuff here
    if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation)) {
        //Make labels smaller
    }
    else {
        //Make them bigger
    }
    
    
    return cell;
}

#pragma mark -
#pragma mark UITableView Delegate

//- (CGFloat)tableView:(UITableView*)tableView widthForRowAtIndexPath:(NSIndexPath*)indexPath
//{
//    // This function is called before cellForRowAtIndexPath, once for each cell.
//
//}


- (CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
    // This function is called before cellForRowAtIndexPath, once for each cell.
    // We calculate the size of the speech bubble here and then cache it in the
    // Message object, so we don't have to repeat those calculations every time
    // we draw the cell. We add 16px for the label that sits under the bubble.
    Message* message = (self.dataModel.messages)[indexPath.row];
    message.bubbleSize = [SpeechBubbleView sizeForText:message.text];
    return message.bubbleSize.height + 9;
}


#pragma mark -
#pragma mark ComposeDelegate

- (void)didSaveMessage:(Message*)message atIndex:(int)index
{
    // This method is called when the user presses Save in the Compose screen,
    // but also when a push notification is received. We remove the "There are
    // no messages" label from the table view's footer if it is present, and
    // add a new row to the table view with a nice animation.
    if ([self isViewLoaded])
    {
        self.tableView.tableFooterView = nil;
        [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
        [self scrollToNewestMessage];
    }
}

#pragma mark - 
#pragma mark ServiceConnector stuff
- (IBAction)getDown:(id)sender { //perform get request
    ServiceConnector *serviceConnector = [[ServiceConnector alloc] init];
    serviceConnector.delegate = self;
    [serviceConnector getTest];
}
- (IBAction)postDown:(id)sender { //perform post request
    ServiceConnector *serviceConnector = [[ServiceConnector alloc] init];
    serviceConnector.delegate = self;
    [serviceConnector postTest];
}
#pragma mark - ServiceConnectorDelegate -
-(void)requestReturnedData:(NSData *)data{ //activated when data is returned
    
    NSDictionary *dictionary = [NSDictionary dictionaryWithJSONData:data];
    _output.text = dictionary.JSONString; // set the textview to the raw string value of the data recieved
    
    _value1TextField.text = [NSString stringWithFormat:@"%d",[[dictionary objectForKey:@"value1"] intValue]];
    _value2TextField.text = [dictionary objectForKey:@"value2"];
    NSLog(@"requestReturnedData: %@",dictionary);
    NSLog(@"_output.text JSON RECEIVED: %@", _output.text);
    NSLog(@"_value1TextField.text: %@", _value1TextField.text);
    NSLog(@"_value2TextField.text: %@", _value2TextField.text);
}

#pragma mark -
#pragma mark Actions

- (void) showLoginViewController {
    LoginViewController* loginController = (LoginViewController*) [ApplicationDelegate.storyBoard instantiateViewControllerWithIdentifier:@"LoginViewController"];
    loginController.dataModel = _dataModel;
    
    loginController.client = _client;
    
    [self presentViewController:loginController animated:YES completion:nil];
}

- (void) willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
                                 duration:(NSTimeInterval)duration {
    
    NSLog(@"SCXTT ROTATING - current location is: %@", [[SingletonClass singleObject] myLocStr]);

    [self.tableView reloadData];
//    [self scrollToNewestMessage];
}

- (void)userDidLeave
{
    [self.dataModel setJoinedChat:NO];
    
    // Show the Login screen. This requires the user to join a new
    // chat map group before he can return to the chat screen.
    [self showLoginViewController];
}

- (void)postLeaveRequest {
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
    hud.labelText = NSLocalizedString(@"Signing Out", nil);
    
    NSDictionary *params = @{@"cmd":@"leave",
                             @"user_id":[_dataModel userId]};
    //    [ApplicationDelegate.client
    [_client
     postPath:@"/whereru/api/api.php"
     parameters:params
     success:^(AFHTTPRequestOperation *operation, id responseObject) {
         if ([self isViewLoaded]) {
             [MBProgressHUD hideHUDForView:self.navigationController.view animated:YES];
             if (operation.response.statusCode != 200) {
                 ShowErrorAlert(NSLocalizedString(@"There was an error communicating with the server", nil));
             } else {
                 [self userDidLeave];
             }
         }
     } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
         if ([self isViewLoaded]) {
             [MBProgressHUD hideHUDForView:self.navigationController.view animated:YES];
             ShowErrorAlert([error localizedDescription]);
         }
     }];
    
}

- (IBAction)exitAction
{
    //	[self userDidLeave];
    [self postLeaveRequest];
}

- (IBAction)chgMapAction
{
    //	Toggle the map betweem Satellite Hybrid and Standard
    if (self.mapView.mapType == 0) {
        self.mapView.mapType = MKMapTypeHybrid;
        _btnMapType.title =@" Map";
    } else {
        self.mapView.mapType = MKMapTypeStandard;
//        UIBarButtonItem *btnMapType = [[UIBarButtonItem alloc] initWithTitle:@"Map" style:UIBarButtonItemStyleBordered target:self action:@selector(chgMapAction)];
        _btnMapType.title =@" Sat";
    }
    

}

- (IBAction)composeAction
{
    // Show the Compose screen
    ComposeViewController* composeController = (ComposeViewController*) [ApplicationDelegate.storyBoard instantiateViewControllerWithIdentifier:@"ComposeViewController"];
    composeController.dataModel = _dataModel;
    composeController.delegate = self;
    composeController.client = _client;
    [self presentViewController:composeController animated:YES completion:nil];
}

- (void)findAction {
    NSLog(@"SCXTT findAction");
//    [self postGetRoom];
    [self postFindRequest];
}

- (void)getRoomAction {
//    [self postFindRequest];
    [self postGetRoom];
}


- (void)getAPI:(NSDictionary *)params
{
    [_client
     postPath:@"/whereru/api/api.php"
     parameters:params
     success:^(AFHTTPRequestOperation *operation, id responseObject) {
         [MBProgressHUD hideHUDForView:self.view animated:YES];
         _isUpdating = NO;
         if (operation.response.statusCode != 200) {
             ShowErrorAlert(NSLocalizedString(@"Could not send the message to the server", nil));
         } else {
             NSLog(@"getAPI cmd request sent");
             NSString* responseString = [NSString stringWithUTF8String:[responseObject bytes]];
             NSLog(@"responseString: %@", responseString);
             NSLog(@"operation: %@", operation);
             
             NSError *e = nil;
             NSArray *jsonArray = [NSJSONSerialization JSONObjectWithData: responseObject options: NSJSONReadingMutableContainers error: &e];
             
             if (!jsonArray) {
                 NSLog(@"Error parsing JSON: %@", e);
             } else {
                 
                 //                     Blank out and reload _roomArray
                 if (!_roomArray) {
                     _roomArray = [[NSMutableArray alloc] init];
                 } else {
                     [_roomArray removeAllObjects];
//                     [self.mapView removeAnnotations:_mapView.annotations];
                 }
                 NSString *myPinImages[11] = {@"blue.png",
                     @"cyan.png",
                     @"darkgreen.png",
                     @"gold.png",
                     @"green.png",
                     @"orange.png",
                     @"pink.png",
                     @"purple.png",
                     @"red.png",
                     @"yellow.png",
                     @"cyangray.png"};
                 
                 int i = 0;
                 UIImage *mPinImage;
                 for(NSDictionary *item in jsonArray) {
                     NSString *mNickName = [item objectForKey:@"nickname"];
                     NSString *mLocation = [item objectForKey:@"location"];
                     
                     NSString *gmtDateStr = [item objectForKey:@"loc_time"];
                     NSInteger minutesBetweenDates;
                     minutesBetweenDates = [self getPinAgeInMinutes:gmtDateStr];
                     
                     
                     NSLog(@"%ld minutes ago %@ updated - assigning image# %d - %@", (long)minutesBetweenDates, mNickName, i, myPinImages[i]);
                     
                     //                        SCXTT need to test if date is old and use a gray pin if so
                     
                     
                     //                         UIImage *mPinImage = [UIImage imageNamed:@"green.png"];
//                     UIImage *mPinImage;
                     
                     
//                     
//                     if (minutesBetweenDates > 500) {
//                         mPinImage = [UIImage imageNamed:@"cyangray.png"];
//                     } else {
////                         NSLog(@"scxtt using pin %@", myPinImages[i]);
//                         mPinImage = [UIImage imageNamed:myPinImages[i]];
//                     }
                     
                     
                     mPinImage = [UIImage imageNamed:myPinImages[i]];
                     
                     
                     
                     if (![mLocation isEqual: @"0.000000, 0.000000"]) {
                         Room *roomObj = [[Room alloc] initWithRoomName:[_dataModel secretCode] andMemberNickName:mNickName andMemberLocation:mLocation andMemberLocTime:gmtDateStr andMemberPinImage:myPinImages[i]];
                         if (!_roomArray) {
                             _roomArray = [[NSMutableArray alloc] init];
                         }
                         [_roomArray addObject:roomObj];
                     }
                     if (i > 10) {
                         i = 0;
                     } else {
                         i++;
                     }
                 }
                 NSLog(@" before updatePointsOnMapWithAPIData _roomAray.count: %lu", (unsigned long)_roomArray.count);
                 [[NSNotificationCenter defaultCenter] postNotificationName:@"receivedNewAPIData" object:nil userInfo:nil];
             }
         }
     } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
         if ([self isViewLoaded]) {
             _isUpdating = NO;
             [MBProgressHUD hideHUDForView:self.view animated:YES];
//             ShowErrorAlert([error localizedDescription]);
             [self toastMsg:[error localizedDescription]];
         }
     }];
}


- (void)postGetRoom
{
    if (!_isUpdating)
    {
        _isUpdating = YES;
        
        //    [_messageTextView resignFirstResponder];
        
        //    NSString *text = self.messageTextView.text;
        NSString *text = @"Hey WhereRU?";
        
        NSDictionary *params = @{@"cmd":@"getroom",
                                 @"user_id":[_dataModel userId],
                                 @"location":[[SingletonClass singleObject] myLocStr],
                                 @"text":text};
        
        [self getAPI:params];
        
    } else {
        NSLog(@"Worse yet Aint nobody got time for that");
        _isUpdating = NO;
    }
}


- (void)postFindRequest
{
    if (!_isUpdating)
    {
        _isUpdating = YES;
        
        //    [_messageTextView resignFirstResponder];
        
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.labelText = NSLocalizedString(@"whereru", nil);
        
        //    NSString *text = self.messageTextView.text;
        NSString *text = @"Hey WhereRU?";
        
        NSDictionary *params = @{@"cmd":@"find",
                                 @"user_id":[_dataModel userId],
                                 @"location":[[SingletonClass singleObject] myLocStr],
                                 @"text":text};
        
        
        [self getAPI:params];
    } else {
        NSLog(@"Aint nobody got time for that");
        _isUpdating = NO;
    }
}


- (void)postGetRoomMessages
{
    if (!_isUpdating)
    {
        _isUpdating = YES;
        NSString *toast = [NSString stringWithFormat:@"Getting map group messages"];
        [self longToastMsg:toast];

        NSString *secret_code = [_dataModel secretCode];
        NSDictionary *params = @{@"cmd":@"getroommessages",
                                 @"user_id":[_dataModel userId],
                                 @"location":[[SingletonClass singleObject] myLocStr],
                                 @"secret_code":secret_code};
        
        [_client
         postPath:@"/whereru/api/api.php"
         parameters:params
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
             _isUpdating = NO;
             if (operation.response.statusCode != 200) {
                 ShowErrorAlert(NSLocalizedString(@"Could not send the message to the server", nil));
             } else {
                 NSLog(@"SMVC Get all messages for this room");
                 NSString* responseString = [NSString stringWithUTF8String:[responseObject bytes]];
                 NSLog(@"getroommessages responseString: %@", responseString);
                 
                 NSError *e = nil;
                 NSArray *jsonArray = [NSJSONSerialization JSONObjectWithData: responseObject options: NSJSONReadingMutableContainers error: &e];
                 
                 if (!jsonArray) {
                     NSLog(@"Error parsing JSON: %@", e);
                 } else {
                     
                     //                   Blank out and reload _roomArray
                     if (!_roomMessagesArray) {
                         _roomMessagesArray = [[NSMutableArray alloc] init];
                     } else {
//                         [_roomMessagesArray removeAllObjects];
                     }
                     for(NSDictionary *item in jsonArray) {
                         Message *message = [[Message alloc] init];
                         
                         //If message user_id == my userID then senderName = nil
//                         NSLog(@"[_dataModel userId] == [item objectForKey:@user_id]: %@ == %@",[_dataModel userId], [item objectForKey:@"user_id"]);
                         
                         if ([[_dataModel userId] isEqualToString:[item objectForKey:@"user_id"]]) {
                             message.senderName = nil;
                         } else {
                             message.senderName = [item objectForKey:@"nickname"];
                         }
                         
                         message.date = [self dateFromUTCDateStr:[item objectForKey:@"time_posted"]];
                         message.location = [item objectForKey:@"location"];
                         message.text = [item objectForKey:@"message"];
//                         NSLog(@"addMessage message_id:%@, nickname: %@, message: %@", [item objectForKey:@"message_id"], [item objectForKey:@"nickname"], [item objectForKey:@"message"]);
                         int index = [self.dataModel addMessage:message];
                         [self didSaveMessage:message atIndex:index];
                         
                     }
                 }
             }
         } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             if ([self isViewLoaded]) {
                 _isUpdating = NO;
                 //                 Since this is running like every 10 seconds we DONT want to throw an alert everytime we lose the network connection
                 //                 ShowErrorAlert([error localizedDescription]);
             }
         }];
    } else {
        NSLog(@"Aint nobody got time for that");
        _isUpdating = NO;
    }
}

- (void)checkForNewMessage:(NSNotification *)notification
{
    //NSLog(@"loadConversation userInfo: %@ ", notification.userInfo);
    //NSDictionary *notificationPayload = notification.userInfo[@"aps"];
    
//    _isFromNotification = YES;
    
    //    NSString *conversationGuid = notification.userInfo[@"conversationGuid"];
    
    NSLog(@"newMessage polling check for new messages");
    
//    [self loadConversation:_conversationGuid];
    
//  don't think i need this next line unless to updateScrollBar
//    [[NSNotificationCenter defaultCenter] postNotificationName:@"messageDataChanged" object:self];
}


#pragma mark -
#pragma mark Map

- (void)openAnnotation:(id)annotation;
{
    //mv is the mapView
    _okToRecenterMap = NO;
    [_mapView selectAnnotation:annotation animated:YES];
    
}

- (void)closeAnnotation:(id)annotation;
{
    //mv is the mapView
    _okToRecenterMap = YES;
    [_mapView deselectAnnotation:annotation animated:YES];
    
}

-(BOOL)annTitleHasLeftRoom:(NSString *)nickname {
//    NSLog(@"Has %@ left yet?", nickname);
    if ([nickname isEqualToString:@"Current Location"]) {
        return NO;
    }
    // Search _roomArray for nickname
    for (Room *item in _roomArray) {
        if ([nickname isEqualToString:item.memberNickName]) {
            return NO;
            break; //this break may not be necessary
        }
    }
    return YES;
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    
    if([annotation isKindOfClass:[VBAnnotation class]]) {
        VBAnnotation *myAnnotation = (VBAnnotation *)annotation;
//      NSLog(@"SCXTT mapView viewForAnnotation myAnnotation.title:%@ myAnnotation.pinImageFile:%@", myAnnotation.title, myAnnotation.pinImageFile);
        MKAnnotationView *annotationView = [mapView dequeueReusableAnnotationViewWithIdentifier:@"MyCustomAnnotation"];
        
//      Need to add code to test for old pins and use gray ones here
        if (annotationView == nil) {
            annotationView = myAnnotation.annotationView;
            annotationView.image = myAnnotation.pinImage;
        } else {
            annotationView.annotation = annotation;
            annotationView.image = [UIImage imageNamed:myAnnotation.pinImageFile];
//            annotationView.highlighted = YES;
        }
        return annotationView;
    } else {
        return nil;
    }
    
}

-(void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view
{
    
    NSLog(@"didSelectAnnotationView");
    //    [mapView selectAnnotation:view.annotation animated:NO];
    _okToRecenterMap = NO;
}

-(void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view
{
    
    NSLog(@"didDeselectAnnotationView");
    //    [mapView selectAnnotation:view.annotation animated:NO];
    _okToRecenterMap = YES;
}

// This goes through all of the objects currently in the _roomArray
// Seeds the region with this devices current location and sets the span
// to include all the pins. This will not plot pins that are located at 0.00,0.00
// this currently gets the first item (room object) then cycles through all map
// annotations until the ann.title = who. MAY WANT TO change it to use key value pairs
// instead to immediately grab the annotation that needs updating

-(void) updatePointsOnMapWithAPIData {
    CLLocationCoordinate2D location, southWest, northEast;
    MKCoordinateRegion region;
    
    // seed the region values with my current location and to set the span later to include all the pins
    NSString *mLoc = [[SingletonClass singleObject] myLocStr];
    NSArray *strs = [mLoc componentsSeparatedByString:@","];
    southWest.latitude = [strs[0] doubleValue];
    southWest.longitude = [strs[1] doubleValue];
    northEast = southWest;

    NSLog(@"updatePointsOnMapWithAPIData");
    // Loop thru all _roomArray[Room objects]
    // Pull from _roomArray where who matches memberNickName
    // each item is a Room object with memberNickName memberLocation & roomName
//    NSLog(@"_roomArray count is:%lu",(unsigned long)[_roomArray count]);
    if ([_roomArray count] == 0) {
        [_mapView removeAnnotations:_mapView.annotations];
    }
//    NSLog(@"_mapView.annotations count is:%lu",(unsigned long)[_mapView.annotations count]);
    for (Room *item in _roomArray) {
        BOOL whoFound = NO;
//        NSLog(@"updatePointsOnMapWithAPIData:memberNickName %@", item.memberNickName);
//        NSLog(@"----------------------------:memberLocation %@", item.memberLocation);
//        NSLog(@"----------------------------:memberUpdateTime %@", item.memberUpdateTime);
//        NSLog(@"----------------------------:roomName %@", item.roomName);
//        NSLog(@"----------------------------:memberPinImage %@", item.memberPinImage);
        
        if (![item.memberLocation  isEqual: @"0.000000, 0.000000"]) {
            
            NSArray *strings = [item.memberLocation componentsSeparatedByString:@","];
            NSString *who = item.memberNickName;
            NSString *imageString = item.memberPinImage;
            UIImage *useThisPin = [UIImage imageNamed:imageString];
            
            NSString *gmtDateStr = item.memberUpdateTime; //UTC needs to be converted to currentLocale
            NSString* dateString = [self localDateStrFromUTCDateStr:gmtDateStr];
            NSDate* date = [self dateFromUTCDateStr:gmtDateStr];
            
//            for (id<MKAnnotation> ann in _mapView.annotations)
            for (VBAnnotation *ann in _mapView.annotations)
            {
//                whoFound = NO;
                //First see if this ann still has a _roomArray match
                //or if the person has left the room kill this ann
                if ([self annTitleHasLeftRoom:ann.title]) {
                    //toast it
//                    NSString *toast = [NSString stringWithFormat:@"%@ has left the map group", ann.title];
//                    [self toastMsg:toast];
                    [self multiLineToastMsg:ann.title detailText:@"has left the map group"];
                    
                    //kill it
                    [self.mapView removeAnnotation:ann];
                }
//                NSLog(@"updatePointsOnMapWithAPIData looking thru ann.title:%@ compared to who:%@", ann.title, who);
//                [self openAnnotation:ann];
                southWest.latitude = MIN(southWest.latitude, ann.coordinate.latitude);
                southWest.longitude = MIN(southWest.longitude, ann.coordinate.longitude);
                northEast.latitude = MAX(northEast.latitude, ann.coordinate.latitude);
                northEast.longitude = MAX(northEast.longitude, ann.coordinate.longitude);
                
                // Move the updated pin to its new locations
                if ([ann.title isEqualToString:who])
                {
                    NSLog(@"grooving %@ at loc %@ at %@", who, item.memberLocation, item.memberUpdateTime);
                    whoFound = YES;
                    location.latitude = [strings[0] doubleValue];
                    location.longitude = [strings[1] doubleValue];
                    if (![item.memberLocation  isEqual: @"0.000000, 0.000000"]){
                        //Scxtt need to find a cool way to animate sliding points
//                        ann.coordinate = location; // this line doesnt work
                        ann.subtitle = dateString; // i dont think this line works either
                        ann.loctime = date; // this prob isnt working either
                        [ann setCoordinate:location];
                    }
//                    break;
                }
            }
            // new who so add addAnnotation and set coordinate and location time
            if (!whoFound) {
                NSLog(@"SCXTT Adding new who %@ with pin %@", who, imageString);
                if (![item.memberLocation  isEqual: @"0.000000, 0.000000"]){
                    //toast it
//                    NSString *toast = [NSString stringWithFormat:@"%@ has entered the map group", who];
//                    [self toastMsg:toast];
                    [self multiLineToastMsg:who detailText:@"has entered the map group"];

                    VBAnnotation *annNew = [[VBAnnotation alloc] initWithTitle:who newSubTitle:dateString Location:location LocTime:date PinImageFile:imageString PinImage:useThisPin];
                    location.latitude = [strings[0] doubleValue];
                    location.longitude = [strings[1] doubleValue];
                    [annNew setCoordinate:location];

                    [self.mapView addAnnotation:annNew];
//                    [self openAnnotation:annNew];
                    
                }
            }
            
            _mapViewSouthWest = [[CLLocation alloc] initWithLatitude:southWest.latitude longitude:southWest.longitude];
            _mapViewNorthEast = [[CLLocation alloc] initWithLatitude:northEast.latitude longitude:northEast.longitude];
            
            // This is a diag distance (if you wanted tighter you could do NE-NW or NE-SE)
            CLLocationDistance meters = [_mapViewSouthWest distanceFromLocation:_mapViewNorthEast];
            
            if (_okToRecenterMap) {
                [self reCenterMap:region meters:meters];
            }
        }
    }
}

-(void) updatePointsOnMapWithNotification:(NSNotification *)notification {

    BOOL whoFound = NO;
    NSDictionary *dict = [notification userInfo];
    
    if (![[dict valueForKey:@"loc"]  isEqual: @"0.000000, 0.000000"]) {

        NSString *who = [dict valueForKey:@"who"];
        NSString *toast = [NSString stringWithFormat:@" Found: %@", who];
        [self toastMsg:toast];
        NSLog(@"who=%@",who);
        
        CLLocationCoordinate2D location, southWest, northEast;
        MKCoordinateRegion region;
        
        // seed the region values to set the span later to include all the pins
        NSArray *strings = [[dict valueForKey:@"loc"] componentsSeparatedByString:@","];
        southWest.latitude = [strings[0] doubleValue];
        southWest.longitude = [strings[1] doubleValue];
        northEast = southWest;
        
        //Scxtt may need to move this to mapView delegate
        // Format the message date
        NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
        [formatter setDateStyle:NSDateFormatterShortStyle];
        [formatter setTimeStyle:NSDateFormatterShortStyle];
        [formatter setDoesRelativeDateFormatting:YES];
        NSString* dateString = [formatter stringFromDate:[NSDate date]];
        
//        for (id<MKAnnotation> ann in _mapView.annotations)
        for (VBAnnotation *ann in _mapView.annotations){
            NSLog(@"moving points checking ann.title is %@",ann.title);
            
            // reset the span to include each and every pin as you go thru the list
            //ignore the 0,0 uninitialize annotations
            if (ann.coordinate.latitude != 0) {
                southWest.latitude = MIN(southWest.latitude, ann.coordinate.latitude);
                southWest.longitude = MIN(southWest.longitude, ann.coordinate.longitude);
                northEast.latitude = MAX(northEast.latitude, ann.coordinate.latitude);
                northEast.longitude = MAX(northEast.longitude, ann.coordinate.longitude);
            }
            // Move the updated pin to its new locations
            if ([ann.title isEqualToString:who])
            {
                NSLog(@"found %@ moving %@", who, who);
//                [self openAnnotation:ann];
                whoFound = YES;
                location.latitude = [strings[0] doubleValue];
                location.longitude = [strings[1] doubleValue];
                NSLog(@"loc = %@",[dict valueForKey:@"loc"]);
//                ann.coordinate = location;
                [ann setCoordinate:location];
                ann.subtitle = dateString;
                break;
            }
        }
        // new who so add addAnnotation and set coordinate
        if (!whoFound) {
            NSLog(@"Adding new who %@", who);
            VBAnnotation *annNew = [[VBAnnotation alloc] initWithTitle:who newSubTitle:dateString Location:location LocTime:[NSDate date] PinImageFile:@"blue.png" PinImage:[UIImage imageNamed:@"blue.png"]];
            
            location.latitude = [strings[0] doubleValue];
            location.longitude = [strings[1] doubleValue];
            if (![[dict valueForKey:@"loc"]  isEqual: @"0.000000, 0.000000"]){
                [annNew setCoordinate:location];
                [self.mapView addAnnotation:annNew];
            }
        }
        
        _mapViewSouthWest = [[CLLocation alloc] initWithLatitude:southWest.latitude longitude:southWest.longitude];
        _mapViewNorthEast = [[CLLocation alloc] initWithLatitude:northEast.latitude longitude:northEast.longitude];
        
        // This is a diag distance (if you wanted tighter you could do NE-NW or NE-SE)
        CLLocationDistance meters = [_mapViewSouthWest distanceFromLocation:_mapViewNorthEast];

        if (_okToRecenterMap) {
            [self reCenterMap:region meters:meters];
        }
    }
}


- (void)reCenterMap:(MKCoordinateRegion)region meters:(CLLocationDistance)meters {
    region.center.latitude = (_mapViewSouthWest.coordinate.latitude + _mapViewNorthEast.coordinate.latitude) / 2.0;
    region.center.longitude = (_mapViewSouthWest.coordinate.longitude + _mapViewNorthEast.coordinate.longitude) / 2.0;
    region.span.latitudeDelta = meters / 111319.5;
    region.span.longitudeDelta = 0.0;
    
    MKCoordinateRegion savedRegion = [_mapView regionThatFits:region];
    [_mapView setRegion:savedRegion animated:YES];
}

-(void)toastMsg:(NSString *)toastStr {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
    
    // Configure for text only and offset down
    hud.mode = MBProgressHUDModeText;
    hud.labelText = toastStr;
    //    hud.margin = 10.f;
    //    hud.yOffset = 50.f;
    hud.removeFromSuperViewOnHide = YES;
    
    [hud hide:YES afterDelay:1];
}

-(void)longToastMsg:(NSString *)toastStr {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
    
    // Configure for text only and offset down
    hud.mode = MBProgressHUDModeText;
    hud.labelText = toastStr;
    //    hud.margin = 10.f;
    //    hud.yOffset = 50.f;
    hud.removeFromSuperViewOnHide = YES;
    
    [hud hide:YES afterDelay:3];
}

-(void)multiLineToastMsg:(NSString *)toastStr detailText:(NSString *)detailsText {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
    
    // Configure for text only and offset down
    hud.frame = CGRectMake(0, 0, 120, 143);
//    hud.mode = MBProgressHUDModeAnnularDeterminate;
    hud.mode = MBProgressHUDModeText;
    hud.labelText = toastStr;
    hud.detailsLabelText = detailsText;
    hud.removeFromSuperViewOnHide = YES;
    [hud hide:YES afterDelay:2];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)cancelAction
{
    //	[self.parentViewController dismissViewControllerAnimated:YES completion:nil];
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Managing Orientation

- (BOOL)shouldAutorotate
{
    //returns true to allow orientation change in IOS 8 devices
    if (IS_OS_8_OR_LATER) {
        return YES;
    } else {
        return NO;
    }
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)  interfaceOrientation duration:(NSTimeInterval)duration
{
    NSLog(@"SCxTT rotating now");
//    update the table view now
//    [self scrollToNewestMessage];

    
}

-(void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    NSLog(@"SCxTT did rotate");
    [self.tableView reloadData];
    [self scrollToNewestMessage];
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
