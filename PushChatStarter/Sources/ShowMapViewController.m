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

// DAD 41.723240, -86.184829
#define CA_LATITUDE 41.723240
#define CA_LONGITUDE -86.184829
// Beach
#define BE_LATITUDE 41.723240
#define BE_LONGITUDE -86.184829
// Reston hotel
//#define BE_LATITUDE 38.960663
//#define BE_LONGITUDE -77.423423
#define BE2_LATITUDE 41.723240
#define BE2_LONGITUDE -86.184829

#define SPAN_VALUE 0.005f

@interface ShowMapViewController () {
    AFHTTPClient *_client;
    NSArray *pinImages;
    NSTimer *getRoomTimer;
    UIPickerView *myPickerView;
//    NSInteger *centerOnThisRoomArrayRow;
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
    if (!self.dataModel.messages.count == 0) {
        NSIndexPath* indexPath = [NSIndexPath indexPathForRow:(self.dataModel.messages.count - 1) inSection:0];
        [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
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
//    [NSTimer scheduledTimerWithTimeInterval: 10
//                                     target: self
//                                   selector: @selector(checkForNewMessage:)
//                                   userInfo: nil
//                                    repeats: NO];
    
    
    
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(updatePointsOnMapWithNotification:) //SCXTT TIME TO RETIRE THIS ONE COMPLETELY
//                                                 name:@"receivedNewMessage"
//                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updatePointsOnMapWithAPIData)
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
    
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(postGetRoomMessages)
//                                                 name:@"userJoinedRoom"
//                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(checkForNewMessage)
                                                 name:@"notificationReceivedSoGetRoomMessages"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(tellUserLocationUpdatesReceived)
                                                 name:@"receivedLocationUpdate"
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
//    UIBarButtonItem *btnGet = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(getDown:)];
//    UIBarButtonItem *btnPost = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCamera target:self action:@selector(postDown:)];
    UIBarButtonItem *btnRefresh = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(findAction)];
//    UIBarButtonItem *btnCompose = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:self action:@selector(composeAction)];
    UIBarButtonItem *btnSignOut = [[UIBarButtonItem alloc] initWithTitle:@"Sign Out" style:UIBarButtonItemStyleBordered target:self action:@selector(exitAction)];
//    _btnMapType = [[UIBarButtonItem alloc] initWithTitle:@" Sat" style:UIBarButtonItemStyleBordered target:self action:@selector(chgMapAction)];
    //    [self.navigationItem setLeftBarButtonItem:leftBarButton];
    [self.navigationItem setLeftBarButtonItems:[NSArray arrayWithObjects:btnSignOut, nil] animated:YES];
    [self.navigationItem setRightBarButtonItems:[NSArray arrayWithObjects:btnRefresh, nil] animated:YES];
}

- (void) setUpPickerView {
    CGFloat w, h, x, y;
    w = 300;
    h = 200;
    x = (self.view.frame.size.width / 2) - w / 2;
    y = ((self.view.frame.size.height) - h) - 25;
    myPickerView = [[UIPickerView alloc] initWithFrame:CGRectMake(x, y, w, h)];
    myPickerView.delegate = self;
    myPickerView.showsSelectionIndicator = YES;
    myPickerView.layer.backgroundColor = (__bridge CGColorRef)([UIColor clearColor]);
    myPickerView.backgroundColor = [UIColor colorWithRed:249.0f/255.0f green:244.0f/255.0f blue:238.0f/255.0f alpha:1.0f];
    myPickerView.opaque = NO;
    
    
    myPickerView.layer.cornerRadius = 12;
    myPickerView.layer.masksToBounds = YES;
    
    //    scxtt
    //    myPickerView.translatesAutoresizingMaskIntoConstraints = YES;
    [self.view addSubview:myPickerView];
    
    [self.view addConstraints:[NSLayoutConstraint
                               constraintsWithVisualFormat:@"V:|-[myPickerView(>=200)]-|"
                               options:NSLayoutFormatDirectionLeadingToTrailing
                               metrics:nil
                               views:NSDictionaryOfVariableBindings(myPickerView)]];
    
    [self.view addConstraints:[NSLayoutConstraint
                               constraintsWithVisualFormat:@"H:[myPickerView(==200)]-|"
                               options:NSLayoutFormatDirectionLeadingToTrailing
                               metrics:nil
                               views:NSDictionaryOfVariableBindings(myPickerView)]];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _okToRecenterMap = YES;
    _pickerIsUp = NO;
    _isFromNotification = NO;
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
    myPickerView.delegate = self;
    _centerOnThisRoomArrayRow = -1;

    // Add this to detect user dragging map
    UIPanGestureRecognizer* panRec = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(didDragMap:)];
    [panRec setDelegate:self];
    [self.mapView addGestureRecognizer:panRec];
    
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];

    [self setUpTimersAndObservers];
    [self setUpButtonBarItems];
    
//    [self.navigationItem setLeftBarButtonItems:[NSArray arrayWithObjects:btnExit, nil] animated:YES];
    
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    NSLog(@"scXtt viewDidAppear");
    if (![_dataModel joinedChat])
    {
        [self showLoginViewController];
    } else {
        //Reset pins on map
        [self.mapView removeAnnotations:_mapView.annotations];
        //    [self postFindRequest];
        [self postGetRoomMessages];
        [self postGetRoom];
        [self.tableView reloadData];
    }
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.title = [_dataModel secretCode];
    NSLog(@"scXtt viewWillAppear");
    // Show a label in the table's footer if there are no messages
    if (self.dataModel.messages.count == 0)
    {
        UILabel* label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 30)];
//        label.text = NSLocalizedString(@"You have no messages", nil);
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
    _isFromNotification = YES;
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
#pragma mark Picker View Delegates

//- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view
//{
//    UIView *myColorView = [UIView new]; //Set desired frame
//    myColorView.backgroundColor = [UIColor redColor]; //Set desired color or add a UIImageView if you want...
//    UIImageView *myImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"cyan.png"]];
//    [view addSubview:myImageView];
//    [view addSubview:myColorView];
//    
//    return view;
//}
//

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view
{
    UIView *pickerCustomView = (id)view;
    UILabel *pickerViewLabel;
    UIImageView *pickerImageView;
    
    if (!pickerCustomView) {
        pickerCustomView= [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f,
                                                                   [pickerView rowSizeForComponent:component].width - 10.0f, [pickerView rowSizeForComponent:component].height)];
        pickerImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 55.0f, 30.0f)];
        pickerViewLabel= [[UILabel alloc] initWithFrame:CGRectMake(55.0f, 0.0f,
                                                                   [pickerView rowSizeForComponent:component].width - 10.0f, [pickerView rowSizeForComponent:component].height)];

        // the values for x and y are specific for my example
        [pickerCustomView addSubview:pickerImageView];
        [pickerCustomView addSubview:pickerViewLabel];
    }
    
    NSString *pickerPin = [[_roomArray objectAtIndex:row] memberPinImage];
    
    pickerImageView.image = [UIImage imageNamed:[NSString stringWithFormat:@"pk%@",pickerPin]];
//    pickerImageView.image = [UIImage imageNamed:[[_roomArray objectAtIndex:row] memberPinImage]];
    pickerViewLabel.backgroundColor = [UIColor clearColor];
    pickerViewLabel.text = [[_roomArray objectAtIndex:row] memberNickName];
//    pickerViewLabel.font = [UIFont fontWithName:@"ChalkboardSE-Regular" size:20];
    
    return pickerCustomView;
}

// tell the picker how many rows are available for a given component
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    NSUInteger numRows = [_roomArray count];
    return numRows;
}

// tell the picker how many components it will have
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

// tell the picker the title for a given component
- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    NSString *title;
//    title = [@"pin nickname " stringByAppendingFormat:@"%d",row];
    title = [[_roomArray objectAtIndex:row] memberNickName];
    return title;
}

// tell the picker the width of each row for a given component
- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component {
    int sectionWidth = 300;
    
    return sectionWidth;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow: (NSInteger)row inComponent:(NSInteger)component {
    // Handle the selection
    [self toastMsg:[[_roomArray objectAtIndex:row] memberNickName]];
    // need to remove the subview
    // see: http://stackoverflow.com/questions/9820113/iphone-remove-sub-view
    [myPickerView removeFromSuperview];
    _pickerIsUp = NO;
    
    _centerOnThisRoomArrayRow = row;

    //    _okToRecenterMap = YES;
    //    set center point and zoom level
    
    CLLocationCoordinate2D location;
    MKCoordinateRegion region;
    
    
    NSArray *strings = [[[_roomArray objectAtIndex:row] memberLocation] componentsSeparatedByString:@","];
    location.latitude = [strings[0] doubleValue];
    location.longitude = [strings[1] doubleValue];
    
    _mapViewSouthWest = [[CLLocation alloc] initWithLatitude:location.latitude longitude:location.longitude];
    _mapViewNorthEast = [[CLLocation alloc] initWithLatitude:location.latitude longitude:location.longitude];
    
    // This is a diag distance (if you wanted tighter you could do NE-NW or NE-SE)
//    CLLocationDistance meters = [_mapViewSouthWest distanceFromLocation:_mapViewNorthEast];
    CLLocationDistance meters = 1000;
    
    
    [self reCenterMap:region meters:meters];
}



#pragma mark -
#pragma mark Actions

- (void) showLoginViewController {
    LoginViewController* loginController = (LoginViewController*) [ApplicationDelegate.storyBoard instantiateViewControllerWithIdentifier:@"LoginViewController"];
    loginController.dataModel = _dataModel;
    
    loginController.client = _client;
    
    [self presentViewController:loginController animated:YES completion:nil];
//    scxtt
    
}

- (void) willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
                                 duration:(NSTimeInterval)duration {
    
    NSLog(@"SCXTT ROTATING - current location is: %@", [[SingletonClass singleObject] myLocStr]);
    [myPickerView removeFromSuperview];
    _pickerIsUp = NO;
    [self.tableView reloadData];
}

- (IBAction)showPinPicker:(id)sender {

    if (_pickerIsUp) {
        // do nothing
    } else {
        _pickerIsUp = YES;
        [self setUpPickerView];
        _okToRecenterMap = NO;
    }
    
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
//        _btnMapType.title =@" Map";
        _satMapButton.title =@"Map";
        
    } else {
        self.mapView.mapType = MKMapTypeStandard;
//        UIBarButtonItem *btnMapType = [[UIBarButtonItem alloc] initWithTitle:@"Map" style:UIBarButtonItemStyleBordered target:self action:@selector(chgMapAction)];
//        _btnMapType.title =@" Sat";
        _satMapButton.title =@"Sat";
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
    _okToRecenterMap = YES;
    [self postFindRequest];
}

- (void)getRoomAction {
//    [self postFindRequest];
    [self postGetRoom];
}

-(NSString *)setPinImageBasedOnNickName {
    
    return @"";
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
                 NSString *myPinImages[11] = {@"blue.png",@"cyan.png",@"darkgreen.png",@"gold.png",
                     @"green.png",@"orange.png",@"pink.png",@"purple.png",@"red.png",@"yellow.png",
                     @"cyangray.png"};
                 
                 int i = 0;
                 UIImage *mPinImage;
                 for(NSDictionary *item in jsonArray) {
                     if (i > 10) {
                         i = 0;
                     }
                     NSString *mNickName = [item objectForKey:@"nickname"];
                     NSString *mLocation = [item objectForKey:@"location"];
                     
                     NSString *gmtDateStr = [item objectForKey:@"loc_time"];
                     NSInteger minutesBetweenDates;
                     minutesBetweenDates = [self getPinAgeInMinutes:gmtDateStr];
                     
//                     NSLog(@"%ld minutes ago %@ updated - assigning image# %d - %@", (long)minutesBetweenDates, mNickName, i, myPinImages[i]);
                     
//                     SCXTT need to test if date is old and use a gray pin if so
//                         if (minutesBetweenDates > 500) {
//                             mPinImage = [UIImage imageNamed:@"cyangray.png"];
//                         } else {
//                             //                         NSLog(@"scxtt using pin %@", myPinImages[i]);
//                             mPinImage = [UIImage imageNamed:myPinImages[i]];
//                         }
                     
                     mPinImage = [UIImage imageNamed:myPinImages[i]];
                     
                     if (![mLocation isEqual: @"0.000000, 0.000000"]) {
                         Room *roomObj = [[Room alloc] initWithRoomName:[_dataModel secretCode] andMemberNickName:mNickName andMemberLocation:mLocation andMemberLocTime:gmtDateStr andMemberPinImage:myPinImages[i]];
                         if (!_roomArray) {
                             _roomArray = [[NSMutableArray alloc] init];
                         }
                         [_roomArray addObject:roomObj];
                     }
                     i++;
                     
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
    if (_isFromNotification) {
        [self postGetRoomMessages];
    } else {
        
        if ([_dataModel joinedChat]) {
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
        //Prod comment these next 2 lines out scxtt
//        NSString *toast = [NSString stringWithFormat:@"Getting map group messages"];
//        [self toastMsg:toast];
        NSLog(@"Getting map group messages");

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
                     [self.dataModel.messages removeAllObjects];
                     // SCXTT these next three lines dont do what I wanted, I want one table cell to say No one is here
//                     Message *message = [[Message alloc] init];
//                     message.text = @"No one is here";
//                     int index = [self.dataModel addMessage:message];
                 } else {
                     
                     //                   Blank out and reload _roomArray
                     if (!_roomMessagesArray) {
                         _roomMessagesArray = [[NSMutableArray alloc] init];
                     } else {
                         NSLog(@"SCXTT reset roomMessagesArray");
                         [_roomMessagesArray removeAllObjects];
                     }
                     [self.dataModel.messages removeAllObjects];
                     
                     // Process all messages from JSON array ///////////////////////////////////////////////////////////////////////////////////////
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
                         NSLog(@"Message added at index:%d" ,index);
                     }
//                     [[NSNotificationCenter defaultCenter] postNotificationName:@"receivedNewAPIData" object:nil userInfo:nil];
                     NSLog(@"SCXTT RELOAD TABLE DATA");
                     [self.tableView reloadData];
                     [self scrollToNewestMessage];
                     // We got it so reset below
                     _isFromNotification = NO;
                 }
             }
         } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             if ([self isViewLoaded]) {
                 _isUpdating = NO;
                 _isFromNotification = NO;
                 //                 Since this is running like every 10 seconds we DONT want to throw an alert everytime we lose the network connection
                 //                 ShowErrorAlert([error localizedDescription]);
             }
         }];
    } else {
        NSLog(@"Aint nobody got time for that");
//        _isUpdating = NO;
    }
}

- (void)checkForNewMessage
{

    _isFromNotification = YES;
    
    // Need to keep trying until we successfully execute postGetRoomMessages
    
    
    [self postGetRoomMessages];
    
    NSLog(@"newMessage polling check for new messages COMMENTED OUT");
    
    
//  don't think i need this next line unless to updateScrollBar
//    [[NSNotificationCenter defaultCenter] postNotificationName:@"messageDataChanged" object:self];
}

-(void)tellUserLocationUpdatesReceived {
    [self toastMsg:@"Receiving Updates"];
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
    _centerOnThisRoomArrayRow = -1;
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


- (void)mapView:(MKMapView *)mapView
didAddAnnotationViews:(NSArray *)annotationViews
{
    for (MKAnnotationView *annView in annotationViews)
    {
        CGRect endFrame = annView.frame;
        annView.frame = CGRectOffset(endFrame, 0, -500);
        [UIView animateWithDuration:0.5
                         animations:^{ annView.frame = endFrame; }];
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

- (void)didDragMap:(UIGestureRecognizer*)gestureRecognizer {
    if (gestureRecognizer.state == UIGestureRecognizerStateEnded){
        NSLog(@"YOU DRAGGGGGED ME YOU DRAGGGGGGGED ME drag ended");
        _centerOnThisRoomArrayRow = -1;
        _okToRecenterMap = NO;
    }
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
    NSLog(@"We will center on this if its not -1 centerOnThisRoomArrayRow:%ld", _centerOnThisRoomArrayRow);
    // Loop thru all _roomArray[Room objects]
    // Pull from _roomArray where who matches memberNickName
    // each item is a Room object with memberNickName memberLocation & roomName
//    NSLog(@"_roomArray count is:%lu",(unsigned long)[_roomArray count]);
    if ([_roomArray count] == 0) {
        _pinPickerButton.enabled = NO;
        [_mapView removeAnnotations:_mapView.annotations];
    } else {
        _pinPickerButton.enabled = YES;
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
                    _centerOnThisRoomArrayRow = -1;
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
            // new who so add addAnnotation and set coordinate and location time and recenter the map
            if (!whoFound) {
                NSLog(@"SCXTT Adding new who %@ with pin %@", who, imageString);
                if (![item.memberLocation  isEqual: @"0.000000, 0.000000"]){
                    //toast it
//                    NSString *toast = [NSString stringWithFormat:@"%@ is in the map group", who];
//                    [self toastMsg:toast];
                    [self multiLineToastMsg:who detailText:@"is in the map group"];
                    _okToRecenterMap = YES;

                    VBAnnotation *annNew = [[VBAnnotation alloc] initWithTitle:who newSubTitle:dateString Location:location LocTime:date PinImageFile:imageString PinImage:useThisPin];
                    location.latitude = [strings[0] doubleValue];
                    location.longitude = [strings[1] doubleValue];
                    [annNew setCoordinate:location];

                    [self.mapView addAnnotation:annNew];
//                    [self openAnnotation:annNew];
                    
                }
            }
            if (_okToRecenterMap) {
                _mapViewSouthWest = [[CLLocation alloc] initWithLatitude:southWest.latitude longitude:southWest.longitude];
                _mapViewNorthEast = [[CLLocation alloc] initWithLatitude:northEast.latitude longitude:northEast.longitude];
                
                // This is a diag distance (if you wanted tighter you could do NE-NW or NE-SE)
                CLLocationDistance meters = [_mapViewSouthWest distanceFromLocation:_mapViewNorthEast];
                
                
                [self reCenterMap:region meters:meters];
            } else if ((_centerOnThisRoomArrayRow >= 0) && ([_roomArray count] >_centerOnThisRoomArrayRow)) {
//                NSLog(@"SCXTT we have selected a pin to center on so do it centerOnThisRoomArrayRow:%ld", _centerOnThisRoomArrayRow);
                CLLocationCoordinate2D location;
                MKCoordinateRegion region;
                
                
                NSArray *strings = [[[_roomArray objectAtIndex:_centerOnThisRoomArrayRow] memberLocation] componentsSeparatedByString:@","];
                location.latitude = [strings[0] doubleValue];
                location.longitude = [strings[1] doubleValue];
                
                _mapViewSouthWest = [[CLLocation alloc] initWithLatitude:location.latitude longitude:location.longitude];
                _mapViewNorthEast = [[CLLocation alloc] initWithLatitude:location.latitude longitude:location.longitude];
                
                // This is a diag distance (if you wanted tighter you could do NE-NW or NE-SE)
                //    CLLocationDistance meters = [_mapViewSouthWest distanceFromLocation:_mapViewNorthEast];
                CLLocationDistance meters = 1000;
                
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
        //Prod remove this toast scxtt
//        NSString *toast = [NSString stringWithFormat:@" Found: %@", who];
//        [self toastMsg:toast];
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
        if (_okToRecenterMap) {
            _mapViewSouthWest = [[CLLocation alloc] initWithLatitude:southWest.latitude longitude:southWest.longitude];
            _mapViewNorthEast = [[CLLocation alloc] initWithLatitude:northEast.latitude longitude:northEast.longitude];
            
            // This is a diag distance (if you wanted tighter you could do NE-NW or NE-SE)
            CLLocationDistance meters = [_mapViewSouthWest distanceFromLocation:_mapViewNorthEast];
            
            
            [self reCenterMap:region meters:meters];
        }
    }
}


- (void)reCenterMap:(MKCoordinateRegion)region meters:(CLLocationDistance)meters {
//    NSLog(@"recentering map");
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenHeight = screenRect.size.height;
    
    region.center.latitude = (_mapViewSouthWest.coordinate.latitude + _mapViewNorthEast.coordinate.latitude) / 2.0;
    region.center.longitude = (_mapViewSouthWest.coordinate.longitude + _mapViewNorthEast.coordinate.longitude) / 2.0;
    region.span.latitudeDelta = meters / 111319.5;
//    region.span.latitudeDelta = meters / 100319.5;
//    region.span.longitudeDelta = 0.0;
    if (screenHeight == 320) {
        region.span.longitudeDelta = meters / 80319.5;
    } else {
        region.span.longitudeDelta = 0;
    }
    
    
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
