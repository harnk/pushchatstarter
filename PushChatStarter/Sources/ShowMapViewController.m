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
#import "JSONDictionaryExtensions.h"
#import "Room.h"
#import "NetworkService.h"
#import "MapManager.h"

#define SPAN_VALUE 0.005f

@interface ShowMapViewController () {
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
                                             selector:@selector(handleReceivedNewAPIData)
                                                 name:@"receivedNewMessage"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(findAction)
                                                 name:@"receivedDeviceToken"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleReceivedNewAPIData)
                                                 name:@"receivedNewAPIData"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(checkForNewMessage)
                                                 name:@"notificationReceivedSoGetRoomMessages"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(tellUserLocationUpdatesReceived:)
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
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleReceivedNewMQTTData:)
                                                 name:@"receivedNewMQTTData"
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleUserJoinedRoom)
                                                 name:@"userJoinedRoom"
                                               object:nil];

}

- (void)setUpButtonBarItems {
    UIBarButtonItem *btnRefresh = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(findAction)];
    UIBarButtonItem *btnSignOut = [[UIBarButtonItem alloc] initWithTitle:@"Sign Out" style:UIBarButtonItemStylePlain target:self action:@selector(exitAction)];
    [self.navigationItem setLeftBarButtonItems:[NSArray arrayWithObjects:btnSignOut, nil] animated:YES];
    [self.navigationItem setRightBarButtonItems:[NSArray arrayWithObjects:btnRefresh, nil] animated:YES];
    
    // Disable the problematic bluemenuitem button to fix layout constraints
    if (self.pinPickerButton) {
        self.pinPickerButton.enabled = NO;
        // Hide it or replace with proper sized button
        self.pinPickerButton.title = @"Pins";
        self.pinPickerButton.enabled = YES;
    }
}

-(void) returnToAllWithMessage:(NSString *)toastMsg {
    _mapManager.centerOnThisGuy = @"";
    if (toastMsg.length > 0) {
//        [self multiLineToastMsg:[_dataModel secretCode] detailText:@"returning to view of entire map group"];
        [self multiLineToastMsg:[_dataModel secretCode] detailText:toastMsg];
    }
    if ([_dataModel joinedChat]) {
        _mapManager.okToRecenterMap = YES;
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
    
    _pickerIsUp = NO;
    _isFromNotification = NO;
    
    // Initialize MapManager
    _mapManager = [[MapManager alloc] initWithMapView:self.mapView];
    _mapManager.delegate = self;
    [self.mapView setDelegate:_mapManager];
    
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
    _mapManager.centerOnThisGuy = @"";

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
    
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    NSLog(@"SMVC viewDidAppear");
    if (![_dataModel joinedChat])
    {
        [[SingletonClass singleObject] setImInARoom:NO];
        [self showLoginViewController];
    } else {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Share Location"
                                                                       message:@"Do you want to share your location with others in this room?"
                                                                preferredStyle:UIAlertControllerStyleAlert];

        UIAlertAction *shareAction = [UIAlertAction actionWithTitle:@"Share My Location"
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction * _Nonnull action) {
            [[SingletonClass singleObject] setImInARoom:YES];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"fireUpTheGPS" object:nil userInfo:nil];

            // calling findAction to wake up devices but if isUpdating this might get skipped i think so force isUpdating to false
            self.isUpdating = NO;
            [self toastMsg:@"Updating locations"];
//            [self findAction];
            [self postGetRoomMessages];
            [self postGetRoom];
            [self.tableView reloadData];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"commenceGetRoomTimer" object:nil userInfo:nil];
        }];

        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel"
                                                               style:UIAlertActionStyleCancel
                                                             handler:^(UIAlertAction * _Nonnull action) {
            // [[SingletonClass singleObject] setImInARoom:NO];
            // [self showLoginViewController];
            [self postLeaveRequest];
        }];

        [alert addAction:shareAction];
        [alert addAction:cancelAction];
        [self presentViewController:alert animated:YES completion:nil];
    }
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    NSLog(@"SMVC viewWillAppear");
    self.badResponseRetry = 0;
    if (_mapManager.centerOnThisGuy.length == 0) {
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
    NSLog(@"SMVC startGetRoomTimer (stop old timers first) findAction WAKE UP DEVICES & postGetRoom every 50s");
    
    [self stopGetRoomTimer];
    // Also need to wake up other devices in the room now
    [self findAction];
    
    //Tell AD to stop postMyLoc
    [[NSNotificationCenter defaultCenter] postNotificationName:@"haltBackgroundUpdates" object:nil userInfo:nil];

    _isFromNotification = YES;
    getRoomTimer  = [NSTimer scheduledTimerWithTimeInterval: 50
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
//        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Notifications Are Disabled" message:@"This app requires notifications in order to function. You need to enable notifications. Choose Settings to enable them" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Settings", nil];
//        alert.tag = kAlertViewNotifications;
//        [alert show];
//
        UIAlertController *alert =
        [UIAlertController alertControllerWithTitle:@"Notifications Are Disabled"
                                            message:@"This app requires notifications in order to function. You need to enable notifications. Choose Settings to enable them"
                                     preferredStyle:UIAlertControllerStyleAlert];

        UIAlertAction *cancel =
        [UIAlertAction actionWithTitle:@"Cancel"
                                 style:UIAlertActionStyleCancel
                               handler:^(UIAlertAction *action) {
                                   // Cancel tapped
                               }];

        UIAlertAction *settings =
        [UIAlertAction actionWithTitle:@"Settings"
                                 style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction *action) {
                                   NSURL *settingsURL = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                                   if ([[UIApplication sharedApplication] canOpenURL:settingsURL]) {
                                       [[UIApplication sharedApplication] openURL:settingsURL options:@{} completionHandler:nil];
                                   }
                               }];

        [alert addAction:cancel];
        [alert addAction:settings];

        [self presentViewController:alert animated:YES completion:nil];
    }
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
    
    
        
    if ([_mapManager getPinAgeInMinutes:dateString ] > 10000.0) {
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
    _mapManager.centerOnThisGuy = [[_roomArray objectAtIndex:row] memberNickName];
    _mapManager.okToRecenterMap = YES;
//    NSLog(@"Centering on this guy: %@", _mapManager.centerOnThisGuy);
    
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
    
    _mapManager.mapViewSouthWest = [[CLLocation alloc] initWithLatitude:location.latitude longitude:location.longitude];
    _mapManager.mapViewNorthEast = [[CLLocation alloc] initWithLatitude:location.latitude longitude:location.longitude];
    
    // This is a diag distance (if you wanted tighter you could do NE-NW or NE-SE)
//    CLLocationDistance meters = [_mapManager.mapViewSouthWest distanceFromLocation:_mapManager.mapViewNorthEast];
    CLLocationDistance meters = 1000;
    
    region = self.mapView.region;
    [_mapManager reCenterMap:region meters:meters];
}



#pragma mark -
#pragma mark Actions

- (void) showLoginViewController {
    LoginViewController* loginController = (LoginViewController*) [ApplicationDelegate.storyBoard instantiateViewControllerWithIdentifier:@"LoginViewController"];
    loginController.dataModel = _dataModel;
    
    
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
//        _mapManager.okToRecenterMap = NO;
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
    hud.label.text = NSLocalizedString(@"Signing Out", nil);

    [[NetworkService sharedService] leaveWithUserId:[_dataModel userId]
        completion:^(BOOL success, NSError *error) {
            if ([self isViewLoaded]) {
                [MBProgressHUD hideHUDForView:self.navigationController.view animated:YES];
                if (!success) {
                    ShowErrorAlert(error.localizedDescription ?: @"There was an error communicating with the server");
                } else {
                    [self userDidLeave];
                }
            }
        }];
}

- (IBAction)exitAction
{
    // old comment SCXTT make this next part coexist with the alertview that launches the app settings TBD
    UIAlertController *alert =
    [UIAlertController alertControllerWithTitle:@"Sign Out of This Map Group"
                                        message:@"Are you sure you wish to sign out of this map group? Your friends here will miss you!"
                                 preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *cancel =
    [UIAlertAction actionWithTitle:@"Cancel"
                             style:UIAlertActionStyleCancel
                           handler:^(UIAlertAction *action) {
                               // Do nothing
                           }];

    UIAlertAction *confirm =
    [UIAlertAction actionWithTitle:@"I'm Sure"
                             style:UIAlertActionStyleDestructive
                           handler:^(UIAlertAction *action) {
                               [self postLeaveRequest];
                           }];

    [alert addAction:cancel];
    [alert addAction:confirm];

    [self presentViewController:alert animated:YES completion:nil];
    


//    [self postLeaveRequest];
}

- (IBAction)chgMapAction
{
    //    Toggle the map betweem Satellite Hybrid and Standard
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


- (void)fetchRoomsWithCompletion:(NetworkServiceRoomsCompletion)originalCompletion {
    NSString *userId = [_dataModel userId];
    NSString *location = [[SingletonClass singleObject] myLocStr];
    NSString *roomName = [_dataModel secretCode];
    
    NetworkServiceRoomsCompletion wrappedCompletion = ^(NSArray<Room *> *rooms, NSError *error) {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        _isUpdating = NO;
        
        if (error) {
            // Check for empty response (user may have been deleted)
            if (error.code == NetworkServiceErrorEmptyResponse) {
                self.badResponseRetry = self.badResponseRetry + 1;
                if (self.badResponseRetry > 9) {
                    NSString *toastStr = [NSString stringWithFormat:@"SCXTT BRR:%d", self.badResponseRetry];
                    [self toastMsg:toastStr];
                    [[SingletonClass singleObject] setImInARoom:NO];
                    [self stopGetRoomTimer];
                    [self showLoginViewController];
                    if (originalCompletion) originalCompletion(nil, error);
                    return;
                }
            } else {
                [self toastMsg:[error localizedDescription]];
            }
            if (originalCompletion) originalCompletion(nil, error);
            return;
        }
        
        self.badResponseRetry = 0;
        
        // Update _roomArray with the parsed rooms
        if (!_roomArray) {
            _roomArray = [[NSMutableArray alloc] init];
        } else {
            [_roomArray removeAllObjects];
        }
        [_roomArray addObjectsFromArray:rooms];
        
        if ((_roomArray.count == 0) && (_mapManager.centerOnThisGuy.length > 0)) {
            [self returnToAllWithMessage:@"Everyone has left the map group"];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:@"receivedNewAPIData" object:nil userInfo:nil];
        
        if (originalCompletion) originalCompletion(rooms, nil);
    };
    
    // Determine which API call based on caller context
    // This method is called from postFindRequest and postGetRoom
    // The caller should use the specific NetworkService methods directly
    if (originalCompletion) {
        [[NetworkService sharedService] findRoomWithUserId:userId location:location roomName:roomName completion:wrappedCompletion];
    }
}


- (void)postGetRoom
{
    NSLog(@"SMVC postGetRoom should happene every 50 secs");
    if ([_dataModel joinedChat]) {
        if (_isFromNotification) {
            [self postGetRoomMessages];
        } else {
            
            if ([_dataModel joinedChat]) {
                if (!_isUpdating)
                {
                    _isUpdating = YES;
                    NSLog(@"SMVC getting room cmd:getroom");
                    
                    NSString *userId = [_dataModel userId];
                    NSString *location = [[SingletonClass singleObject] myLocStr];
                    NSString *roomName = [_dataModel secretCode];
                    
                    NetworkServiceRoomsCompletion completion = ^(NSArray<Room *> *rooms, NSError *error) {
                        [MBProgressHUD hideHUDForView:self.view animated:YES];
                        _isUpdating = NO;
                        
                        if (error) {
                            if (error.code == NetworkServiceErrorEmptyResponse) {
                                self.badResponseRetry = self.badResponseRetry + 1;
                                if (self.badResponseRetry > 9) {
                                    [[SingletonClass singleObject] setImInARoom:NO];
                                    [self stopGetRoomTimer];
                                    [self showLoginViewController];
                                    return;
                                }
                            } else {
                                [self toastMsg:[error localizedDescription]];
                            }
                            return;
                        }
                        
                        self.badResponseRetry = 0;
                        if (!_roomArray) {
                            _roomArray = [[NSMutableArray alloc] init];
                        } else {
                            [_roomArray removeAllObjects];
                        }
                        [_roomArray addObjectsFromArray:rooms];
                        
                        if ((_roomArray.count == 0) && (_mapManager.centerOnThisGuy.length > 0)) {
                            [self returnToAllWithMessage:@"Everyone has left the map group"];
                        }
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"receivedNewAPIData" object:nil userInfo:nil];
                    };
                    
                    [[NetworkService sharedService] getRoomWithUserId:userId location:location roomName:roomName completion:completion];
                    
                } else {
                    NSLog(@"SMVC busy, skipping getroom");
                    _isUpdating = NO;
                }
            }
        }
    }
}

- (void)postDoneLookingLiveUpdate {
    NSLog(@"SMVC postDoneLookingLiveUpdate cmd:liveupdate set looking = 0");

    NSString *userId = [[NSUserDefaults standardUserDefaults] stringForKey:@"UserId"];
    NSString *location = [[SingletonClass singleObject] myLocStr];

    [[NetworkService sharedService] liveUpdateWithUserId:userId
                                                location:location
                                              completion:^(NSArray *jsonArray, NSError *error) {
         if (error) {
             NSLog(@"Error posting liveupdate: %@", error.localizedDescription);
             return;
         }
         if (!jsonArray) { return; }
         
         BOOL foundALooker = NO;
         for(NSDictionary *item in jsonArray) {
             NSString *mLooking = [item objectForKey:@"looking"];
             if ([mLooking isEqual:@"1"]) {
                 NSString *mNickName = [item objectForKey:@"nickname"];
                 NSLog(@"SMVC ShowMapViewController %@ is looking", mNickName);
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
     }];
}

- (void)postFindRequest
{
    if (!_isUpdating)
    {
        _isUpdating = YES;
        
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.label.text = NSLocalizedString(@"whereru loading ...", nil);
        
        NSString *userId = [_dataModel userId];
        NSString *location = [[SingletonClass singleObject] myLocStr];
        NSString *roomName = [_dataModel secretCode];
        
        NetworkServiceRoomsCompletion completion = ^(NSArray<Room *> *rooms, NSError *error) {
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            _isUpdating = NO;
            
            if (error) {
                if (error.code == NetworkServiceErrorEmptyResponse) {
                    self.badResponseRetry = self.badResponseRetry + 1;
                    if (self.badResponseRetry > 9) {
                        NSString *toastStr = [NSString stringWithFormat:@"SCXTT BRR:%d", self.badResponseRetry];
                        [self toastMsg:toastStr];
                        [[SingletonClass singleObject] setImInARoom:NO];
                        [self stopGetRoomTimer];
                        [self showLoginViewController];
                        return;
                    }
                } else {
                    [self toastMsg:[error localizedDescription]];
                }
                return;
            }
            
            self.badResponseRetry = 0;
            if (!_roomArray) {
                _roomArray = [[NSMutableArray alloc] init];
            } else {
                [_roomArray removeAllObjects];
            }
            [_roomArray addObjectsFromArray:rooms];
            
            if ((_roomArray.count == 0) && (_mapManager.centerOnThisGuy.length > 0)) {
                [self returnToAllWithMessage:@"Everyone has left the map group"];
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:@"receivedNewAPIData" object:nil userInfo:nil];
        };
        
        [[NetworkService sharedService] findRoomWithUserId:userId location:location roomName:roomName completion:completion];
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

        NSString *userId = [_dataModel userId];
        NSString *secretCode = [_dataModel secretCode];
        
        [[NetworkService sharedService] getRoomMessagesWithUserId:userId
                                                       secretCode:secretCode
                                                        completion:^(NSArray<Message *> *messages, NSError *error) {
            _isUpdating = NO;
            
            if (error) {
                if ([self isViewLoaded]) {
                    _isFromNotification = NO;
                }
                return;
            }
            
            if (!_roomMessagesArray) {
                _roomMessagesArray = [[NSMutableArray alloc] init];
            } else {
                [_roomMessagesArray removeAllObjects];
            }
            [self.dataModel.messages removeAllObjects];

            for (Message *message in messages) {
                [self.dataModel addMessage:message];
            }
            [self.tableView reloadData];
            [self scrollToNewestMessage];
            _isFromNotification = NO;
        }];
    } else {
        NSLog(@"SMVC busy, skipping getting room messages");
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

-(void)tellUserLocationUpdatesReceived:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    NSLog(@"📍 tellUserLocationUpdatesReceived - userInfo: %@", userInfo);

    // [self toastMsg:@"Receiving Updates"];

    // Extract location and user info from payload
    NSString *loc = [userInfo valueForKey:@"loc"];
    NSString *who = [userInfo valueForKey:@"who"];

    if (loc && who) {
        NSLog(@"📍 Updating location for %@: %@", who, loc); 
        [self toastMsg:[NSString stringWithFormat:@"📍 Updating %@", who]];

        // Create dictionary with correct key format for updateAnnotationsWithMQTTData
        NSDictionary *userLocation = @{
            @"nickname": who,
            @"location": loc,  // Must be "location" key with "lat, lng" string format
            @"timestamp": [NSDate date]  // Include current timestamp
        };

        // Update map with this user's location (will also update timestamp)
        [_mapManager updateAnnotationsWithMQTTData:userLocation];
    }
}

#pragma mark -
#pragma mark Map Notification Handlers

- (void)handleReceivedNewAPIData {
    [_mapManager updateAnnotationsFromRoomArray:_roomArray];
}

- (void)handleUserJoinedRoom {
    [self toastMsg:@"Joining room..."];
    [self postGetRoomMessages];
    [self postGetRoom];
    [self.tableView reloadData];
    [_mapManager updateAnnotationsFromRoomArray:_roomArray];
}

- (void)handleReceivedNewMQTTData:(NSNotification *)notification {
    [_mapManager updateAnnotationsWithMQTTData:notification.userInfo];
}

#pragma mark - MapManagerDelegate

- (void)mapManagerDidRequestReturnToAllWithMessage:(NSString *)message {
    [self returnToAllWithMessage:message];
}

- (void)mapManagerDidRequestToast:(NSString *)toastStr detailText:(NSString *)detailText {
    [self multiLineToastMsg:toastStr detailText:detailText];
}

- (void)mapManagerDidUpdatePinPickerEnabled:(BOOL)enabled {
    _pinPickerButton.enabled = enabled;
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
        _mapManager.okToRecenterMap = NO;
    }
}

- (void)didSwipeMap:(UIGestureRecognizer*)gestureRecognizer {
    if (gestureRecognizer.state == UIGestureRecognizerStateEnded){
        NSLog(@"Swipe ended");
        _mapManager.okToRecenterMap = NO;
    }
}

-(void)toastMsg:(NSString *)toastStr {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
    
    // Configure for text only and offset down
    hud.mode = MBProgressHUDModeText;
    hud.label.text = toastStr;
    //    hud.margin = 10.f;
    //    hud.yOffset = 50.f;
    hud.removeFromSuperViewOnHide = YES;
    
    [hud hideAnimated:YES afterDelay:1];
}

-(void)longToastMsg:(NSString *)toastStr {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
    
    // Configure for text only and offset down
    hud.mode = MBProgressHUDModeText;
    hud.label.text = toastStr;
    //    hud.margin = 10.f;
    //    hud.yOffset = 50.f;
    hud.removeFromSuperViewOnHide = YES;
    
    [hud hideAnimated:YES afterDelay:3];
}

-(void)multiLineToastMsg:(NSString *)toastStr detailText:(NSString *)detailsText {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
    
    // Configure for text only and offset down
    hud.frame = CGRectMake(0, 0, 120, 143);
//    hud.mode = MBProgressHUDModeAnnularDeterminate;
    hud.mode = MBProgressHUDModeText;
    hud.label.text = toastStr;
    hud.detailsLabel.text = detailsText;
    hud.removeFromSuperViewOnHide = YES;
    [hud hideAnimated:YES afterDelay:2];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)cancelAction
{
    //    [self.parentViewController dismissViewControllerAnimated:YES completion:nil];
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
