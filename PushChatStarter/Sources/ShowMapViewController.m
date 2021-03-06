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

#define SPAN_VALUE 0.005f

@interface ShowMapViewController () {
    AFHTTPClient *_client;
    NSArray *pinImages;
    NSTimer *getRoomTimer;
    NSTimer *getMessagesTimer;
    UIPickerView *myPickerView;
    CGPoint touchStart;
}

@end

//RotationIn_IOS6 is a Category for overriding the default orientation
// http://stackoverflow.com/questions/12577879/shouldautorotatetointerfaceorientation-is-not-working-in-ios-6

@implementation UINavigationController (RotationIn_IOS6)

//int badResponseRetry = 0;

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
    if (!(self.dataModel.messages.count == 0)) {
        NSIndexPath* indexPath = [NSIndexPath indexPathForRow:(self.dataModel.messages.count - 1) inSection:0];
        [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(alertView.tag == kAlertViewNotifications) {
        if (buttonIndex == 1)
        {
            NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
            [[UIApplication sharedApplication] openURL:url];
        }
    } else if(alertView.tag == kAlertViewSignOut) {
        if (buttonIndex == 1)
        {
            [self postLeaveRequest];
        }
    }

}

- (void)setUpTimersAndObservers {
    [NSTimer scheduledTimerWithTimeInterval: 7
                                     target: self
                                   selector: @selector(areNotificationsEnabled)
                                   userInfo: nil
                                    repeats: NO];
    
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
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(checkForNewMessage)
                                                 name:@"notificationReceivedSoGetRoomMessages"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(tellUserLocationUpdatesReceived)
                                                 name:@"receivedLocationUpdate"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(hideAds)
                                                 name:@"removeThoseAds"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(stopGetRoomTimer)
                                                 name:@"killGetRoomTimer"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(startGetRoomTimer)
                                                 name:@"commenceGetRoomTimer"
                                               object:nil];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updatePointsOnMapWithMQTTData:)
                                                 name:@"receivedNewMQTTData"
                                               object:nil];
    

}

- (void)setUpButtonBarItems {
    UIBarButtonItem *btnRefresh = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(findAction)];
    UIBarButtonItem *btnSignOut = [[UIBarButtonItem alloc] initWithTitle:@"Sign Out" style:UIBarButtonItemStylePlain target:self action:@selector(exitAction)];
    [self.navigationItem setLeftBarButtonItems:[NSArray arrayWithObjects:btnSignOut, nil] animated:YES];
    [self.navigationItem setRightBarButtonItems:[NSArray arrayWithObjects:btnRefresh, nil] animated:YES];
}

-(void) returnToAllWithMessage:(NSString *)toastMsg {
    _centerOnThisGuy = @"";
    if (toastMsg.length > 0) {
//        [self multiLineToastMsg:[_dataModel secretCode] detailText:@"returning to view of entire map group"];
        [self multiLineToastMsg:[_dataModel secretCode] detailText:toastMsg];
    }
    if ([_dataModel joinedChat]) {
        _okToRecenterMap = YES;
    }
    self.title = [NSString stringWithFormat:@"[%@]", [_dataModel secretCode]];
    UIBarButtonItem *btnSignOut = [[UIBarButtonItem alloc] initWithTitle:@"Sign Out" style:UIBarButtonItemStylePlain target:self action:@selector(exitAction)];
    [self.navigationItem setLeftBarButtonItems:[NSArray arrayWithObjects:btnSignOut, nil] animated:YES];
}

-(void) returnToAll {
     [self returnToAllWithMessage:@"returning to view of entire map group"];
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
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(applicationWillResign)
     name:UIApplicationWillResignActiveNotification
     object:nil];
    
    NSLog(@"SMVC viewDidLoad Google Mobile Ads SDK version: %@", [GADRequest sdkVersion]);
    //test ad
    // self.bannerView.adUnitID = @"ca-app-pub-3940256099942544/2934735716";
    // real adUnitId
    self.bannerView.adUnitID = @"ca-app-pub-2521098318893673/7870628745";
    self.bannerView.rootViewController = self;
//    _bannerView = [[GADBannerView alloc] initWithAdSize:kGADAdSizeLargeBanner];
    [self.bannerView loadRequest:[GADRequest request]];
    
    _okToRecenterMap = YES;
    _pickerIsUp = NO;
    _isFromNotification = NO;
    [self.mapView setDelegate:self];
    self.mapView.layer.borderColor = [[UIColor colorWithRed:200/255.0 green:199/255.0 blue:204/255.0 alpha:1] CGColor];
    self.mapView.layer.borderWidth = 1.0f;
    
    MKCoordinateRegion region;
    region.center.latitude = 0;
    region.center.longitude = 0;
    region.span.latitudeDelta = 50.1f;
    region.span.longitudeDelta = 50.1f;
    [self.mapView setRegion:region animated:NO];
    
    _textView.delegate = self;
    myPickerView.delegate = self;
    _centerOnThisGuy = @"";

    // Add this to detect user swiping map
    _pullHandle.userInteractionEnabled = YES;
    UIPanGestureRecognizer* panHandle = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(didPanHandle:)];
    UIPanGestureRecognizer* panRec = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(didDragMap:)];
    UIPanGestureRecognizer* tableSwipe = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(didDragTable:)];
    [panRec setDelegate:self];
    [tableSwipe setDelegate:self];
    [self.mapView addGestureRecognizer:panRec];
    [self.tableView addGestureRecognizer:tableSwipe];
    
    panHandle.delegate = self;
    [_pullHandle addGestureRecognizer:panHandle];
    
    
    
    // Add this to detect user swiping down map to full screen
    UISwipeGestureRecognizer *swipeRec = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(didSwipeMap:)];
    [swipeRec setDelegate:self];
    [self.tableView addGestureRecognizer:swipeRec];

    
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];

    [self setUpTimersAndObservers];
    [self setUpButtonBarItems];
    
//    [self.navigationItem setLeftBarButtonItems:[NSArray arrayWithObjects:btnExit, nil] animated:YES];
    
    [self checkAdStatus];
    
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    NSLog(@"SMVC viewDidAppear");
    if (![_dataModel joinedChat])
    {
        [[SingletonClass singleObject] setImInARoom:NO];
        [self showLoginViewController];
    } else {
        [[SingletonClass singleObject] setImInARoom:YES];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"fireUpTheGPS" object:nil userInfo:nil];
        
        // calling findAction to wake up devices but if isUpdating this might get skipped i think so force isUpdating to false
        self.isUpdating = NO;
        [self toastMsg:@"Updating locations"];
//        [self findAction];
        [self postGetRoomMessages];
        [self postGetRoom];
        [self.tableView reloadData];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"commenceGetRoomTimer" object:nil userInfo:nil];
    }
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    NSLog(@"SMVC viewWillAppear");
    self.badResponseRetry = 0;
    if (_centerOnThisGuy.length == 0) {
        self.title = [NSString stringWithFormat:@"[%@]", [_dataModel secretCode]];
    }

//    NSLog(@"viewWillAppear");
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
    NSLog(@"SMVC viewWillDisappear");
//    [self postDoneLookingLiveUpdate];
}

- (void)viewDidDisappear:(BOOL)animated {
    NSLog(@"SMVC viewDidDisappear");
    [self postDoneLookingLiveUpdate];
}

- (void)viewDidUnload:(BOOL)animated {
    NSLog(@"SMVC viewDidUnload");
//    [self postDoneLookingLiveUpdate];
}

- (void) applicationWillResign{
    NSLog(@"SMVC applicationWillResign About to lose focus so stopGetRoomTimer COMMENTED OUT FOR NOW");
//    [self stopGetRoomTimer];
//    NSLog(@"SCXTT We have stopped timers in ShowMap but we need them to start in AppDelegate");
}

- (void)stopGetRoomTimer {
    //BEFORE DOING SO CHECK THAT TIMER MUST NOT BE ALREADY INVALIDATED
    //Always nil your timer after invalidating so that
    //it does not cause crash due to duplicate invalidate
    
    //Tell AD to stop postMyLoc
    [[NSNotificationCenter defaultCenter] postNotificationName:@"allowBackgroundUpdates" object:nil userInfo:nil];
    
    NSLog(@"SMVC stopGetRoomTimer and GetRoomMessagesTimer");
    if(getRoomTimer)
    {
        NSLog(@"SMVC [getRoomTimer invalidate]");
        [getRoomTimer invalidate];
        getRoomTimer = nil;
    } else {
        
        NSLog(@"did nothing");
    }
    
    if(getMessagesTimer)
    {
        NSLog(@"SMVC [getMessagesTimer invalidate]");
        [getMessagesTimer invalidate];
        getMessagesTimer = nil;
    } else {
        
        NSLog(@"SMVC did nothing");
    }
    
}

-(void)startGetRoomTimer {
    [self stopGetRoomTimer];
    // Also need to wake up other devices in the room now
    [self findAction];
    
    //Tell AD to stop postMyLoc
    [[NSNotificationCenter defaultCenter] postNotificationName:@"haltBackgroundUpdates" object:nil userInfo:nil];

    NSLog(@"SMVC findAction WAKE UP DEVICES & startGetRoomTimer should kickoff postGetRoom every 5s");
    _isFromNotification = YES;
    getRoomTimer  = [NSTimer scheduledTimerWithTimeInterval: 5
                                                     target: self
                                                   selector: @selector(postGetRoom)
                                                   userInfo: nil
                                                    repeats: YES];
    
    getMessagesTimer  = [NSTimer scheduledTimerWithTimeInterval: 62
                                                     target: self
                                                   selector: @selector(getRoomMessageViaTimer)
                                                   userInfo: nil
                                                    repeats: YES];
    
}

-(void) areNotificationsEnabled {

    // Check if notifications are enabled because this app won't work if they aren't
    BOOL isdisabled =  ![[UIApplication sharedApplication] isRegisteredForRemoteNotifications];
    [[SingletonClass singleObject] setNotificationsAreDisabled:isdisabled];
    
    //Pop an aler to let the user go to settings and change notifications setting for this app
    if (isdisabled) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Notifications Are Disabled" message:@"This app requires notifications in order to function. You need to enable notifications. Choose Settings to enable them" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Settings", nil];
        alert.tag = kAlertViewNotifications;
        [alert show];
    }
}


#pragma mark -
#pragma mark In-App Purchases Methods

- (void)hideAds {
    // Hide the banner and removeAds button since they have paid
    _bannerView.hidden = YES;
    _removeAdsButton.hidden = YES;
}

-(void) checkAdStatus {
//    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"com.harnk.whereru.removeads"]) {  //SCXTT Temporarily removed this check until I have time to finish in-app ads
    if (YES) {
//        [self toastMsg:@"Remove Ads is enabled - Thank You for your support!"];
        [self hideAds];
    } else {
//        [self toastMsg:@"Remove Ads is disabled or uninitialized so let the banner and Remove Ads button show"];
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

#pragma mark - UITableViewDataSource

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
//    NSLog(@"willDisplayCell CELL WIDTH %f", cell.contentView.frame.size.width);
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

//    NSLog(@"What is the CELL WIDTH here???");
//    NSLog(@"%f", cell.contentView.frame.size.width);
    
    
    [cell setMessage:message];
    
    //Do orientation specific stuff here
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    if ((orientation == UIInterfaceOrientationLandscapeLeft)
        ||  (orientation == UIInterfaceOrientationLandscapeRight) )
    {
        //Landscape so make labels bigger
    }
    else
    {
        //Portrait so make labels smaller
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
    
    //SCXTT RELEASE
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
        NSLog(@"!pickerCustomView");
        pickerCustomView= [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f,
                                                                   [pickerView rowSizeForComponent:component].width - 10.0f, [pickerView rowSizeForComponent:component].height)];
        pickerImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 55.0f, 30.0f)];
        pickerViewLabel= [[UILabel alloc] initWithFrame:CGRectMake(55.0f, 0.0f,
                                                                   [pickerView rowSizeForComponent:component].width - 10.0f, [pickerView rowSizeForComponent:component].height)];

        // the values for x and y are specific for my example
        [pickerCustomView addSubview:pickerImageView];
        [pickerCustomView addSubview:pickerViewLabel];
    }
    
    
//    NSLog(@"picker row is:%ld", (long)row);
    
    
    
    NSString *pickerPin = [[_roomArray objectAtIndex:row] memberPinImage];
    NSString *dateString = [[_roomArray objectAtIndex:row] memberUpdateTime];
    
    
        
    if ([self getPinAgeInMinutes:dateString ] > 10000.0) {
        pickerPin = @"inactivepin.png";
    }

    
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
    [self multiLineToastMsg:@"Locating" detailText:[[_roomArray objectAtIndex:row] memberNickName]];
    [myPickerView removeFromSuperview];
    _pickerIsUp = NO;
    _centerOnThisGuy = [[_roomArray objectAtIndex:row] memberNickName];
    _okToRecenterMap = YES;
//    NSLog(@"Centering on this guy: %@", _centerOnThisGuy);
    
//    self.title = [[_roomArray objectAtIndex:row] memberNickName];
// SCXTT TO BE ADDED
//    self.title = [NSString stringWithFormat:@" %@ (xx mph)", [[_roomArray objectAtIndex:row] memberNickName]];
    self.title = [NSString stringWithFormat:@"%@", [[_roomArray objectAtIndex:row] memberNickName]];
    
    
//    UIButton *button =  [UIButton buttonWithType:UIButtonTypeCustom];
//    [button setImage:[UIImage imageNamed:@"back-button.jpg"] forState:UIControlStateNormal];
//    [button setImage:[UIImage imageNamed:@"back-button-pressed.jpg"] forState:UIControlStateHighlighted];
//    [button addTarget:self action:@selector(returnToAll)forControlEvents:UIControlEventTouchUpInside];
//    [button setFrame:CGRectMake(0, 0, 42, 22)];
//    UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithCustomView:button];
//    self.navigationItem.leftBarButtonItem = barButton;
    
    
    UIBarButtonItem *btnDone = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(returnToAll)];
    [self.navigationItem setLeftBarButtonItems:[NSArray arrayWithObjects:btnDone, nil] animated:YES];

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
    
    region = self.mapView.region;
    [self reCenterMap:region meters:meters];
}



#pragma mark -
#pragma mark Actions

- (void) createPaymentRequestForProduct:(SKProduct *) product {
    SKMutablePayment * payment = [SKMutablePayment paymentWithProduct:product];
    payment.quantity = 1;
    [[SKPaymentQueue defaultQueue]addPayment:payment];
}

- (IBAction)removeAds:(id)sender {
    NSLog(@"Remove Ads pressed");
    SKProduct *thisProduct = (SKProduct *)[[SingletonClass singleObject] myProducts][0];
    [self createPaymentRequestForProduct:thisProduct];
    
}

- (void) showLoginViewController {
    LoginViewController* loginController = (LoginViewController*) [ApplicationDelegate.storyBoard instantiateViewControllerWithIdentifier:@"LoginViewController"];
    loginController.dataModel = _dataModel;
    
    loginController.client = _client;
    
    [self presentViewController:loginController animated:YES completion:nil];
}

- (void) willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
                                 duration:(NSTimeInterval)duration {
    
//    NSLog(@"ROTATING - current location is: %@", [[SingletonClass singleObject] myLocStr]);
    [myPickerView removeFromSuperview];
    _pickerIsUp = NO;
    [self.tableView reloadData];
    if(UIInterfaceOrientationIsPortrait(toInterfaceOrientation)){
        _pullHandle.hidden = NO;
    }else if(UIInterfaceOrientationIsLandscape(toInterfaceOrientation)){
        _pullHandle.hidden = YES;
    }

}

- (IBAction)showPinPicker:(id)sender {

    if (_pickerIsUp) {
        // do nothing
        [myPickerView removeFromSuperview];
        _pickerIsUp = NO;
    } else {
        _pickerIsUp = YES;
        [self setUpPickerView];
        //scxtt remove next line??
//        _okToRecenterMap = NO;
    }
    
}



- (void)userDidLeave
{
    [self.dataModel setJoinedChat:NO];
    [[SingletonClass singleObject] setImInARoom:NO];
    
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
     postPath:ServerPostPathURL
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
    // SCXTT make this next part coexist with the alertview that launches the app settings TBD
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Sign Out of This Map Group" message:@"Are you sure your wish to sign out of this map group? You friends here will miss you!" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"I'm Sure", nil];
    alert.tag = kAlertViewSignOut;
    [alert show];

//    [self postLeaveRequest];
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
    NSLog(@"findAction");
    if ([_dataModel joinedChat]) {
//        [self returnToAllWithMessage:@"refresh request sent"];
        [self returnToAllWithMessage:@""];
        [self postFindRequest];
    }
}


-(NSString *)setPinImageBasedOnNickName {
    
    return @"";
}

- (void)getAPI:(NSDictionary *)params
{
    [_client
     postPath:ServerPostPathURL
     parameters:params
     success:^(AFHTTPRequestOperation *operation, id responseObject) {
         [MBProgressHUD hideHUDForView:self.view animated:YES];
         _isUpdating = NO;
         if (operation.response.statusCode != 200) {
             ShowErrorAlert(NSLocalizedString(@"Could not send the message to the server", nil));
         } else {
             //SCXTT RELEASE
             NSLog(@"getAPI cmd request sent");
             NSString* responseString = [NSString stringWithUTF8String:[responseObject bytes]];
             
             //SCXTT RELEASE
             NSLog(@"responseString: %@ length equals %lu", responseString, (unsigned long)responseString.length);
             
             // if responseString is null then go back to the login screen - your user may have been deleted
             
             if (responseString.length == 0) {
                 self.badResponseRetry = self.badResponseRetry + 1;
                 if (self.badResponseRetry > 9) {
                     NSString *toastStr = [NSString stringWithFormat:@"SCXTT BRR:%d", self.badResponseRetry];
                     [self toastMsg:toastStr];
                     // kill timers
                     [[SingletonClass singleObject] setImInARoom:NO];
                     [self stopGetRoomTimer];
                     [self showLoginViewController];
                     return;
                 }
             } else {
                 self.badResponseRetry = 0;
                 NSLog(@"operation: %@", operation);
                 
                 NSError *e = nil;
                 NSArray *jsonArray = [NSJSONSerialization JSONObjectWithData: responseObject options: NSJSONReadingMutableContainers error: &e];
                 
                 if (!jsonArray) {
                     NSLog(@"1 Error parsing JSON: %@", e);
                     NSLog(@"JSON Array:%@", jsonArray);
//                     [[SingletonClass singleObject] setImInARoom:NO];
                 } else {
                     
                     //                     Blank out and reload _roomArray
                     if (!_roomArray) {
                         _roomArray = [[NSMutableArray alloc] init];
                     } else {
                         [_roomArray removeAllObjects];
                     }
                     NSString *myPinImages[11] = {@"blue.png",@"cyan.png",@"darkgreen.png",@"gold.png",
                         @"green.png",@"orange.png",@"pink.png",@"purple.png",@"red.png",@"yellow.png",
                         @"cyangray.png"};
                     
                     int i = 0;
                     // Add Return to All first then the room
                     
                     for(NSDictionary *item in jsonArray) {
                         if (i > 10) {
                             i = 0;
                         }
                         NSString *mNickName = [item objectForKey:@"nickname"];
                         NSString *mLocation = [item objectForKey:@"location"];
                         NSString *gmtDateStr = [item objectForKey:@"loc_time"];
                         NSString *useThisPinImage = myPinImages[i];

                         NSInteger minutesBetweenDates;
                         minutesBetweenDates = [self getPinAgeInMinutes:gmtDateStr];
//
//                         NSLog(@"SCXTT WIP minutesBetweenDates:%ld", (long)minutesBetweenDates);
//                         if (minutesBetweenDates > 10000) {
//                             useThisPinImage = @"inactivepin.png";
//                         }
                         
                         if (![mLocation isEqual: @"0.000000, 0.000000"]) {
                             
                             Room *roomObj = [[Room alloc] initWithRoomName:[_dataModel secretCode] andMemberNickName:mNickName andMemberLocation:mLocation andMemberLocTime:gmtDateStr andMemberPinImage:useThisPinImage];
                             if (!_roomArray) {
                                 _roomArray = [[NSMutableArray alloc] init];
                             }
                             [_roomArray addObject:roomObj];
                         }
                         i++;
                         
                     }
                     //                 NSLog(@" before updatePointsOnMapWithAPIData _roomAray.count: %lu", (unsigned long)_roomArray.count);
                     //SCXTT this next line calls updatePoinsOnMapWithAPIData, do we want that every time?
                     if ((_roomArray.count == 0) && (_centerOnThisGuy.length > 0)) {
                         [self returnToAllWithMessage:@"Everyone has left the map group"];
                     }
                     [[NSNotificationCenter defaultCenter] postNotificationName:@"receivedNewAPIData" object:nil userInfo:nil];
                 }
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

- (NSInteger)getPinAgeInMinutesDate:(NSDate*)gmtDate {
    NSDate *now = [NSDate date];
    
    NSTimeInterval distanceBetweenDates = [now timeIntervalSinceDate:gmtDate];
    double secondsInAnMinute = 60;
    NSInteger minutesBetweenDates = distanceBetweenDates / secondsInAnMinute;
    return minutesBetweenDates;
    
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


- (void)postGetRoom
{
    NSLog(@"SMVC postGetRoom should happene every 5 secs");
    if ([_dataModel joinedChat]) {
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
                    NSLog(@"SMVC getting room cmd:getroom");
                    NSDictionary *params = @{@"cmd":@"getroom",
                                             @"user_id":[_dataModel userId],
                                             @"location":[[SingletonClass singleObject] myLocStr],
                                             @"text":text};
                    
                    [self getAPI:params];
                    
                } else {
                    NSLog(@"SMVC busy, skipping getroom");
                    _isUpdating = NO;
                }
            }
        }
    }
}

- (void)postDoneLookingLiveUpdate {
    //    NSLog(@"This is called whenever we leave the ShowMapVC");
    
    //SCXTT RELEASE
    NSLog(@"SMVC postDoneLookingLiveUpdate cmd:liveupdate set looking = 0");
    
    NSDictionary *params = @{@"cmd":@"liveupdate",
                             @"user_id":[[NSUserDefaults standardUserDefaults] stringForKey:@"UserId"],
                             @"location":[[SingletonClass singleObject] myLocStr]};
    
    AFHTTPClient *client = [AFHTTPClient clientWithBaseURL:[NSURL URLWithString:ServerApiURL]];
    [client
     postPath:ServerPostPathURL
     parameters:params
     success:^(AFHTTPRequestOperation *operation, id responseObject) {
         NSString* responseString = [NSString stringWithUTF8String:[responseObject bytes]];
         //SCXTT RELEASE
         NSLog(@"SMVC responseString: %@", responseString);
         NSLog(@"SMVC operation: %@", operation);
         
         // SCXTT WIP Loop thru the response and check key "looking"
         NSError *e = nil;
         NSArray *jsonArray = [NSJSONSerialization JSONObjectWithData: responseObject options: NSJSONReadingMutableContainers error: &e];
         if (!jsonArray) {
             NSLog(@"2 Error parsing JSON: %@", e);
         } else {
             BOOL foundALooker = NO;
             for(NSDictionary *item in jsonArray) {
                 NSString *mLooking = [item objectForKey:@"looking"];
                 if ([mLooking isEqual:@"1"]) {
                     NSString *mNickName = [item objectForKey:@"nickname"];
                     NSLog(@"SMVC ShowMapViewController %@ is looking", mNickName );
                     foundALooker = YES;
                     NSLog(@"SMVC ShowMapViewController Toggle singleton BOOL someoneIsLooking to foundALooker=YES and exit the loop");
                 }
             }
             NSLog(@"SMVC set singleton someoneIsLooking = foundALooker which equals %d", foundALooker);
             if (foundALooker) {
                 NSLog(@"SMVC since someoneIsLooking keep updating my loc in the background");
             } else {
                 NSLog(@"SMVC NO ONE is looking so why am I wasting my battery with these background API calls?!?");
             }
         }
         
     } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
     }];
    
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
        NSLog(@"SMVC busy, skipping find");
        _isUpdating = NO;
    }
}

-(void)getRoomMessageViaTimer {
    NSLog(@"SMVC getRoomMessageViaTimer");
    [self postGetRoomMessages];
}

- (void)postGetRoomMessages
{
   
    if (!_isUpdating)
    {
        _isUpdating = YES;
        NSLog(@"SMVC Getting map group messages");

        NSString *secret_code = [_dataModel secretCode];
        NSDictionary *params = @{@"cmd":@"getroommessages",
                                 @"user_id":[_dataModel userId],
                                 @"location":[[SingletonClass singleObject] myLocStr],
                                 @"secret_code":secret_code};
        [_client
         postPath:ServerPostPathURL
         parameters:params
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
             NSLog(@"SMVC in callback - success");
             _isUpdating = NO;
             if (operation.response.statusCode != 200) {
                 ShowErrorAlert(NSLocalizedString(@"Could not send the message to the server", nil));
             } else {
                 NSLog(@"SMVC Get all messages for this room");
//                 NSString* responseString = [NSString stringWithUTF8String:[responseObject bytes]];
                 NSError *e = nil;
                 NSArray *jsonArray = [NSJSONSerialization JSONObjectWithData: responseObject options: NSJSONReadingMutableContainers error: &e];
                 
                 if (!jsonArray) {
                     NSLog(@"3 Error parsing JSON: %@", e);
                     [self.dataModel.messages removeAllObjects];
                 } else {
                     if (!_roomMessagesArray) {
                         _roomMessagesArray = [[NSMutableArray alloc] init];
                     } else {
                         [_roomMessagesArray removeAllObjects];
                     }
                     [self.dataModel.messages removeAllObjects];
                     
                     // Process all messages from JSON array //////////////////////////////////////////
                     for(NSDictionary *item in jsonArray) {
                         Message *message = [[Message alloc] init];
                         if ([[_dataModel userId] isEqualToString:[item objectForKey:@"user_id"]]) {
                             message.senderName = nil;
                         } else {
                             message.senderName = [item objectForKey:@"nickname"];
                         }
                         message.date = [self dateFromUTCDateStr:[item objectForKey:@"time_posted"]];
                         message.location = [item objectForKey:@"location"];
                         message.text = [item objectForKey:@"message"];
                         int index = [self.dataModel addMessage:message];
//                         NSLog(@"SMVC Message added at index:%d" ,index);
                     }
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
        NSLog(@"SMVC busy, skipping getting room messages");
//        _isUpdating = NO;
    }
}

- (void)checkForNewMessage
{
    
    _isFromNotification = YES;
    
    // Need to keep trying until we successfully execute postGetRoomMessages
    
    [self postGetRoomMessages];
    
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
    [_mapView selectAnnotation:annotation animated:YES];
}

- (void)closeAnnotation:(id)annotation;
{
    [_mapView deselectAnnotation:annotation animated:YES];
}

- (NSInteger) getThisGuysRow:(NSString *)thisGuy {
    
    NSInteger i = 0;
    
    for (Room *item in _roomArray) {
        if ([thisGuy isEqualToString:item.memberNickName]) {
            return i;
        }
        i++;
    }
    return -1;
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
        MKAnnotationView *annotationView = [mapView dequeueReusableAnnotationViewWithIdentifier:@"MyCustomAnnotation"];
        
//      Need to add code to test for old pins and use gray ones here
//        NSLog(@"viewForAnnotation loctime:%@", myAnnotation.loctime);

        if (annotationView == nil) {
            annotationView = myAnnotation.annotationView;
            annotationView.image = myAnnotation.pinImage;
        } else {
            annotationView.annotation = annotation;
            annotationView.image = [UIImage imageNamed:myAnnotation.pinImageFile];
        }
        return annotationView;
    } else {
        return nil;
    }
    
}

-(void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view
{
    NSLog(@"didSelectAnnotationView");
}

-(void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view
{
    NSLog(@"didDeselectAnnotationView");
}


- (void)mapView:(MKMapView *)mapView
didAddAnnotationViews:(NSArray *)annotationViews
{
    for (MKAnnotationView *annView in annotationViews)
    {
        CGRect endFrame = annView.frame;
        ////SCXTT can we make the -500 instead be the last location of this annotation?
        annView.frame = CGRectOffset(endFrame, 0, -500);
        [UIView animateWithDuration:0.5
                         animations:^{ annView.frame = endFrame; }];
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

-(void)didDragTable:(UIGestureRecognizer*)gestureRecognizer {
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan){
        CGFloat y = [gestureRecognizer locationInView:self.view].y;
        NSLog(@"TABLE drag starting point at y:%f",y);
    }
    if (gestureRecognizer.state == UIGestureRecognizerStateChanged){
        CGPoint touchPoint = [gestureRecognizer locationInView:self.view];
        CGFloat topY = CGRectGetMinY(self.tableView.frame);
        NSLog(@"tableView.topY:%f", topY);
        NSLog(@"dragging at locationInView point y:%f", touchPoint.y);
        if (touchPoint.y < topY) {
            NSLog(@"SWIPE UP Table - change constraints");
            [self.view layoutIfNeeded];
            self.mapHeight.constant = 196;
            [UIView animateWithDuration:0.5
                             animations:^{
                                 [self.view layoutIfNeeded]; // Called on parent view
                             }];
        }
    }
    if (gestureRecognizer.state == UIGestureRecognizerStateEnded){
        NSLog(@"drag ended");
        CGFloat topY = CGRectGetMinY(self.tableView.frame);
        NSLog(@"top y:%f", topY);
    }
}

- (void)didPanHandle:(UIPanGestureRecognizer *)panGestureRecognizer {
    if (panGestureRecognizer.state == UIGestureRecognizerStateBegan){
        _saveMapHeight = _mapView.bounds.size.height;
    }
    if (panGestureRecognizer.state == UIGestureRecognizerStateChanged){
        CGFloat y = [panGestureRecognizer locationInView:self.mapView].y;
        CGFloat ttopY = CGRectGetMinY(self.tableView.frame);
        CGPoint touchPoint = [panGestureRecognizer locationInView:self.view];
        NSLog(@"is y:%f > _saveMapHeight:%f (down) || tp.y:%f < ttopY:%f (up)", y, _saveMapHeight, touchPoint.y, ttopY);
        if ((y > _saveMapHeight)) {
            [self.view layoutIfNeeded];
            self.mapHeight.constant = 15;
            [UIView animateWithDuration:0.5
                             animations:^{
                                 [self.view layoutIfNeeded]; // Called on parent view
                             }];
        } else if (touchPoint.y < ttopY) {
            [self.view layoutIfNeeded];
            self.mapHeight.constant = 196;
            [UIView animateWithDuration:0.5
                             animations:^{
                                 [self.view layoutIfNeeded]; // Called on parent view
                             }];
        }
    }
}

- (void)didDragMap:(UIGestureRecognizer*)gestureRecognizer {
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan){
        _saveMapHeight = _mapView.bounds.size.height;
        CGFloat y = [gestureRecognizer locationInView:self.view].y;
        NSLog(@"drag starting point at y:%f",y);
    }
    if (gestureRecognizer.state == UIGestureRecognizerStateChanged){
        CGFloat y = [gestureRecognizer locationInView:self.mapView].y;
        NSLog(@"_saveMapHeight:%f y(in view):%f _mapView.bounds.size.height:%f", _saveMapHeight, y, _mapView.bounds.size.height);
        if ((y > _saveMapHeight)) {
            NSLog(@"animate change constraints");
            [self.view layoutIfNeeded];
            self.mapHeight.constant = 15;
            [UIView animateWithDuration:0.5
                             animations:^{
                                 [self.view layoutIfNeeded]; // Called on parent view
                             }];
        }
    }
    if (gestureRecognizer.state == UIGestureRecognizerStateEnded){
        NSLog(@"drag ended");
//        CGFloat botY = CGRectGetMaxY(self.view.frame);
//        NSLog(@"bottom y:%f", botY);
//        if (self.mapHeight.constant < 196){
//            self.mapHeight.constant = 15;
//        }
        _okToRecenterMap = NO;
    }
}

- (void)didSwipeMap:(UIGestureRecognizer*)gestureRecognizer {
    if (gestureRecognizer.state == UIGestureRecognizerStateEnded){
        NSLog(@"Swipe ended");
        _okToRecenterMap = NO;
    }
}

- (void)checkPinPickerButton {
    if ([_roomArray count] == 0) {
        _pinPickerButton.enabled = NO;
        [_mapView removeAnnotations:_mapView.annotations];
    } else {
        _pinPickerButton.enabled = YES;
    }
}

-(void) updatePointsOnMapWithMQTTData:(NSNotification *)notification {
    CLLocationCoordinate2D location;
    NSDictionary *dict = notification.userInfo;
    NSArray *strings = [[dict valueForKey:@"location"] componentsSeparatedByString:@","];
    location.latitude = [strings[0] doubleValue];
    location.longitude = [strings[1] doubleValue];
    NSLog(@"SCXTT updatePointsOnMapWithMQTTData");
    @try {
//        NSLog(@"notification nickname:%@", [dict valueForKey:@"nickname"]);
//        NSLog(@"notification location:%@", [dict valueForKey:@"location"]);
        for (Room *item in _roomArray) {
            NSString *who = item.memberNickName;
            for (VBAnnotation *ann in _mapView.annotations) {
                if ([ann.title isEqualToString:who]) {
//                    NSLog(@"I FOUND who:%@",who);
                    if ([who isEqualToString:[dict valueForKey:@"nickname"]]){
                        NSLog(@"I FOUND [dict valueForKey:@nickname]:%@ ... setting its location to:%@",who,[dict valueForKey:@"location"]);
                        [ann setCoordinate:location];
                    }
                }
            }
        }
        
    }
    @catch (NSException *exception) {
            NSLog(@"SCXTT notification,userInfo NOT SET yet");
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

    //SCXTT RELEASE
    NSLog(@"SMVC updatePointsOnMapWithAPIData");
    NSLog(@"SMVC My loc:%@", mLoc);
    
    // Loop thru all _roomArray[Room objects]
    // Pull from _roomArray where who matches memberNickName
    // each item is a Room object with memberNickName memberLocation & roomName
//    NSLog(@"_roomArray count is:%lu",(unsigned long)[_roomArray count]);
    [self checkPinPickerButton];
    for (Room *item in _roomArray) {
        BOOL whoFound = NO;
        if (![item.memberLocation  isEqual: @"0.000000, 0.000000"]) {
            
            NSArray *strings = [item.memberLocation componentsSeparatedByString:@","];
            NSString *who = item.memberNickName;
            NSString *imageString = item.memberPinImage;
            UIImage *useThisPin = [UIImage imageNamed:imageString];
            
            NSString *gmtDateStr = item.memberUpdateTime; //UTC needs to be converted to currentLocale
            NSString* dateString = [self localDateStrFromUTCDateStr:gmtDateStr];
            NSDate* date = [self dateFromUTCDateStr:gmtDateStr];
            
            for (VBAnnotation *ann in _mapView.annotations)
            {
                //First see if this ann still has a _roomArray match
                //or if the person has left the room kill this ann
                if ([self annTitleHasLeftRoom:ann.title]) {
                    if ([ann.title isEqualToString:_centerOnThisGuy]){
                        [self returnToAllWithMessage:@""];
                    }
                    if (![ann.title isEqualToString:@"My Location"]){
                        [self multiLineToastMsg:ann.title detailText:@"has left the map group"];
                        [self.mapView removeAnnotation:ann];
                    }
                }
                southWest.latitude = MIN(southWest.latitude, ann.coordinate.latitude);
                southWest.longitude = MIN(southWest.longitude, ann.coordinate.longitude);
                northEast.latitude = MAX(northEast.latitude, ann.coordinate.latitude);
                northEast.longitude = MAX(northEast.longitude, ann.coordinate.longitude);
                
                // Move the updated pin to its new locations
                if ([ann.title isEqualToString:who])
                {
                    long pinAge = (long)[self getPinAgeInMinutes:gmtDateStr ];
//                    NSLog(@"ann.title:%@ age:%ld imageString:%@", ann.title, pinAge, imageString);
                    if (pinAge > 10000.0) {
//                        NSLog(@"OLD PIN and ann.pinImageFile:%@", ann.pinImageFile);
                        if (![ann.pinImageFile isEqualToString:@"inactivepin.png"]) {
                            VBAnnotation *swapAnn = ann;
                            swapAnn.pinImage = [UIImage imageNamed:@"inactivepin.png"];
                            swapAnn.pinImageFile = @"inactivepin.png";
                            [swapAnn setPinImageFile:@"inactivepin.png"];
                            [item setMemberPinImage:@"interactivepin.png"];
                            [self.mapView removeAnnotation:ann];
                            [self.mapView addAnnotation:swapAnn];
                        }
//                        useThisPin = [UIImage imageNamed:@"inactivepin.png"];
                    } else {
//                        NSLog(@"NEW PIN and ann.pinImageFile:%@", ann.pinImageFile);
                        if ([ann.pinImageFile isEqualToString:@"inactivepin.png"]) {
                            VBAnnotation *swapAnn = ann;
                            swapAnn.pinImage = [UIImage imageNamed:imageString];
                            swapAnn.pinImageFile = imageString;
                            [swapAnn setPinImageFile:imageString];
                            [item setMemberPinImage:imageString];
                            [self.mapView removeAnnotation:ann];
                            [self.mapView addAnnotation:swapAnn];
                            
                        }
                    }

                    //SCXTT RELEASE
//                    NSLog(@"grooving %@ at loc %@ at %@", who, item.memberLocation, item.memberUpdateTime);
                    whoFound = YES;
                    location.latitude = [strings[0] doubleValue];
                    location.longitude = [strings[1] doubleValue];
                    if (![item.memberLocation  isEqual: @"0.000000, 0.000000"]){
                        //Scxtt need to find a cool way to animate sliding points
//                        ann.coordinate = location; // this line doesnt work
                        
                        
//                        ann.subtitle = dateString; // i dont think this line works either
                        ann.subtitle = @"date and distance from me"; // i dont think this line works either
                        
                        //Format the location to read distance from me now
                        //get location from message.location
                        NSString *mLoc = [[SingletonClass singleObject] myLocStr];
                        NSArray *strings1 = [mLoc componentsSeparatedByString:@","];
                        CLLocation *locA = [[CLLocation alloc] initWithLatitude:[strings1[0] doubleValue] longitude:[strings1[1] doubleValue]];
                        
                        
                        // Handle the location of the remote devices from the saved messages
                        NSArray *strings = [item.memberLocation componentsSeparatedByString:@","];
                        CLLocation *locB = [[CLLocation alloc] initWithLatitude:[strings[0] doubleValue] longitude:[strings[1] doubleValue]];
                        CLLocationDistance distance = [locA distanceFromLocation:locB];
                        
                        CLLocationDistance distanceFromMeInMeters;
                        
                        
                        distanceFromMeInMeters = distance;
                        
                        //  SCXTT This is in two places, fix that, put it in one place
                        double distanceMeters = distanceFromMeInMeters;
                        double distanceInYards = distanceMeters * 1.09361;
                        double distanceInMiles = distanceInYards / 1760;
                        
                        if (distanceInYards > 500) {
                            ann.subtitle = [NSString stringWithFormat:@"%@, %.1f miles", dateString, distanceInMiles];
                        } else {
                            ann.subtitle = [NSString stringWithFormat:@"%@, %.1f y", dateString, distanceInYards];
                        }
                        
                        
                        ann.loctime = date; // this prob isnt working either
                        [ann setCoordinate:location];
                    } // 0.000, 0.000
                } // ann title = who
            } // for marker in markers
            // new who so add addAnnotation and set coordinate and location time and recenter the map
            if (!whoFound) {
                //SCXTT RELEASE
                NSLog(@"SMVC Adding new who %@ with pin %@", who, imageString);

                if (![item.memberLocation  isEqual: @"0.000000, 0.000000"]){
                    [self multiLineToastMsg:who detailText:@"is in the map group"];
                    VBAnnotation *annNew = [[VBAnnotation alloc] initWithTitle:who newSubTitle:dateString Location:location LocTime:date PinImageFile:imageString PinImage:useThisPin];
                    location.latitude = [strings[0] doubleValue];
                    location.longitude = [strings[1] doubleValue];
                    [annNew setCoordinate:location];

                    [self.mapView addAnnotation:annNew];
                } //0,0
            } // !whoFound
        } // 0.000, 0.000
    } // end for (Room *item in _roomArray)
    // Recenter map
    
    if (_okToRecenterMap) {
        if (([self getThisGuysRow:_centerOnThisGuy] >= 0)) {
            CLLocationCoordinate2D location;
            MKCoordinateRegion region;
            
            NSArray *strings = [[[_roomArray objectAtIndex:[self getThisGuysRow:_centerOnThisGuy]] memberLocation] componentsSeparatedByString:@","];
            location.latitude = [strings[0] doubleValue];
            location.longitude = [strings[1] doubleValue];
            
            _mapViewSouthWest = [[CLLocation alloc] initWithLatitude:location.latitude longitude:location.longitude];
            _mapViewNorthEast = [[CLLocation alloc] initWithLatitude:location.latitude longitude:location.longitude];
            
            // This is a diag distance (if you wanted tighter you could do NE-NW or NE-SE)
            //    CLLocationDistance meters = [_mapViewSouthWest distanceFromLocation:_mapViewNorthEast];
            CLLocationDistance meters = 1000;
            region = self.mapView.region;
            [self reCenterMap:region meters:meters];
        } else {
            _mapViewSouthWest = [[CLLocation alloc] initWithLatitude:southWest.latitude longitude:southWest.longitude];
            _mapViewNorthEast = [[CLLocation alloc] initWithLatitude:northEast.latitude longitude:northEast.longitude];
            
            // This is a diag distance (if you wanted tighter you could do NE-NW or NE-SE)
            CLLocationDistance meters = [_mapViewSouthWest distanceFromLocation:_mapViewNorthEast];
            
            region = self.mapView.region;
            [self reCenterMap:region meters:meters];
            
        }
    }
}

//SCXTT this whole method can go
-(void) updatePointsOnMapWithNotification:(NSNotification *)notification {

    BOOL whoFound = NO;
    NSDictionary *dict = [notification userInfo];
    
    if (![[dict valueForKey:@"loc"]  isEqual: @"0.000000, 0.000000"]) {

        NSString *who = [dict valueForKey:@"who"];
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
            //SCXTT RELEASE
//            NSLog(@"moving points checking ann.title is %@",ann.title);
            
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
            
            region = self.mapView.region;
            [self reCenterMap:region meters:meters];
        }
    }
}


- (void)reCenterMap:(MKCoordinateRegion)region meters:(CLLocationDistance)meters {
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenHeight = screenRect.size.height;
    
    region.center.latitude = (_mapViewSouthWest.coordinate.latitude + _mapViewNorthEast.coordinate.latitude) / 2.0;
    region.center.longitude = (_mapViewSouthWest.coordinate.longitude + _mapViewNorthEast.coordinate.longitude) / 2.0;
    region.span.latitudeDelta = meters / 95319.5;
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

- (BOOL)shouldAutorotate {
        return YES;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)  interfaceOrientation duration:(NSTimeInterval)duration
{
    NSLog(@"rotating now");
//    update the table view now
}

-(void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    NSLog(@"did rotate");
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
