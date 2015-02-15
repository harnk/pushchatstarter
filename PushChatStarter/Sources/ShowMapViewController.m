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


// Carpinteria
#define CA_LATITUDE 37
#define CA_LONGITUDE -95
// Beach
#define BE_LATITUDE 0
#define BE_LONGITUDE 0
// Reston hotel
//#define BE_LATITUDE 38.960663
//#define BE_LONGITUDE -77.423423
#define BE2_LATITUDE 41.736207
#define BE2_LONGITUDE -86.098724

#define SPAN_VALUE 0.005f

@interface ShowMapViewController () {
    AFHTTPClient *_client;
}
@end

@implementation ShowMapViewController

- (id) initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        
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
        [[SingletonClass singleObject] setMyLocation:[self deviceLocation]];
        
        _dataModel = [[DataModel alloc] init];
        [_dataModel loadMessages:[self deviceLocation]];
        
        _client = [AFHTTPClient clientWithBaseURL:[NSURL URLWithString:ServerApiURL]];
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

- (void)viewDidLoad {
    [super viewDidLoad];
    
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
    
    [NSTimer scheduledTimerWithTimeInterval: 0.001
                                     target: self
                                   selector: @selector(changeRegion)
                                   userInfo: nil
                                    repeats: NO];
    
    [NSTimer scheduledTimerWithTimeInterval: 7
                                     target: self
                                   selector: @selector(areNotificationsEnabled)
                                   userInfo: nil
                                    repeats: NO];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updatePointsOnMap:)
                                                 name:@"receivedNewMessage"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(findAction)
                                                 name:@"receivedDeviceToken"
                                               object:nil];
    
    UIBarButtonItem *btnRefresh = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(findAction)];
    UIBarButtonItem *btnCompose = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:self action:@selector(composeAction)];
    
    UIBarButtonItem *btnSignOut = [[UIBarButtonItem alloc] initWithTitle:@"Sign Out" style:UIBarButtonItemStyleBordered target:self action:@selector(exitAction)];
    _btnMapType = [[UIBarButtonItem alloc] initWithTitle:@" Sat" style:UIBarButtonItemStyleBordered target:self action:@selector(chgMapAction)];
//    [self.navigationItem setLeftBarButtonItem:leftBarButton];
    [self.navigationItem setLeftBarButtonItems:[NSArray arrayWithObjects:btnSignOut, _btnMapType, nil] animated:YES];
    [self.navigationItem setRightBarButtonItems:[NSArray arrayWithObjects:btnCompose, btnRefresh, nil] animated:YES];
//    [self.navigationItem setLeftBarButtonItems:[NSArray arrayWithObjects:btnExit, nil] animated:YES];
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
    
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
    if ([[UIApplication sharedApplication] respondsToSelector:@selector(isRegisteredForRemoteNotifications)])
    {
        NSLog(@"__IPHONE_OS_VERSION_MAX_ALLOWED >= 80000 is YES");
        isdisabled =  ![[UIApplication sharedApplication] isRegisteredForRemoteNotifications];
        NSLog(@"isdisabled value: %d",isdisabled);
    }
#else
    NSLog(@"__IPHONE_OS_VERSION_MAX_ALLOWED >= 80000 is NO");
    UIRemoteNotificationType types = [[UIApplication sharedApplication] enabledRemoteNotificationTypes];
    if (types & UIRemoteNotificationTypeAlert)
    {
        isdisabled = false;
        NSLog(@"isdisabled value: %d",isdisabled);
    }
#endif
    
    [[SingletonClass singleObject] setNotificationsAreDisabled:isdisabled];
    //    _notificationsAreDisabled = isdisabled;
    
    //Pop an aler to let the user go to settings and change notifications setting for this app
    if (isdisabled) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Notifications Are Disabled" message:@"This app requires notifications in order to function. You need to enable notifications. Choose Settings to enable them" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Settings", nil];
        [alert show];
    }
    
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (![_dataModel joinedChat])
    {
        [self showLoginViewController];
    }
    [self.tableView reloadData];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    NSLog(@"SCXTT viewWillAppear");
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

#pragma mark -
#pragma mark - UITableViewDataSource

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"SCXTT willDisplayCell CELL WIDTH %f", cell.contentView.frame.size.width);
}

- (int)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.dataModel.messages.count;
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

    NSLog(@"SCXTT What is the CELL WIDTH here???");
    NSLog(@"%f", cell.contentView.frame.size.width);
    
    
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
#pragma mark Actions

- (void) showLoginViewController {
    LoginViewController* loginController = (LoginViewController*) [ApplicationDelegate.storyBoard instantiateViewControllerWithIdentifier:@"LoginViewController"];
    loginController.dataModel = _dataModel;
    
    loginController.client = _client;
    
    [self presentViewController:loginController animated:YES completion:nil];
}

- (void) willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
                                 duration:(NSTimeInterval)duration {
    NSLog(@"SCXTT ROTATING TO :%ld", toInterfaceOrientation);

    [self.tableView reloadData];
    [self scrollToNewestMessage];
}

- (void)userDidLeave
{
    [self.dataModel setJoinedChat:NO];
    
    // Show the Login screen. This requires the user to join a new
    // chat room before he can return to the chat screen.
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
    [self postFindRequest];
//    [self mapAction];
}

- (NSString *)deviceLocation {
    return [NSString stringWithFormat:@"%f, %f", self.locationManager.location.coordinate.latitude, self.locationManager.location.coordinate.longitude];
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
                                 @"location":[self deviceLocation],
                                 @"text":text};
        
        [_client
         postPath:@"/whereru/api/api.php"
         parameters:params
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
             [MBProgressHUD hideHUDForView:self.view animated:YES];
             if (operation.response.statusCode != 200) {
                 ShowErrorAlert(NSLocalizedString(@"Could not send the message to the server", nil));
             } else {
                 NSLog(@"SMVC Find request sent to all devices");
                 //             [self dismissViewControllerAnimated:YES completion:nil];
             }
         } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             if ([self isViewLoaded]) {
                 _isUpdating = NO;
                 [MBProgressHUD hideHUDForView:self.view animated:YES];
                 ShowErrorAlert([error localizedDescription]);
             }
         }];
    }
}

#pragma mark -
#pragma mark Map
//
//- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
//{
//    MKPinAnnotationView *view = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"pin"];
//    view.pinColor = MKPinAnnotationColorPurple;
//    view.enabled = YES;
//    view.animatesDrop = YES;
//    view.canShowCallout = YES;
//    
//    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"palmTree.png"]];
//    view.leftCalloutAccessoryView = imageView;
//    view.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
//    return view;
//}
//
//



- (MKAnnotationView *)mapView:(MKMapView *)map viewForAnnotation:(id <MKAnnotation>)annotation
{
    
    
    if (annotation == _mapView.userLocation)
        return nil;
    
    MKPinAnnotationView *pin = (MKPinAnnotationView *) [_mapView dequeueReusableAnnotationViewWithIdentifier: @"wrupin"];
    
    if (pin == nil)
        pin = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier: @"wrupin"];
    else
        pin.annotation = annotation;
    
    //  NSLog(@"%@",annotation.title);
    
    NSString *titlename=@"xyz";
    if ([annotation.title isEqualToString:titlename]) {
        pin.pinColor = MKPinAnnotationColorPurple;
        // pin.image=[UIImage imageNamed:@"arrest.png"] ;
    }
    else{
        pin.pinColor= MKPinAnnotationColorGreen;
    }
    
    pin.userInteractionEnabled = YES;
    UIButton *disclosureButton = [UIButton buttonWithType:UIButtonTypeCustom];
    //  //pin.image=[UIImage imageNamed:@"arrest.png"] ;
    
    
    
    //Scxtt may need to move this to mapView delegate
    // Format the message date
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    [formatter setDateStyle:NSDateFormatterShortStyle];
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    [formatter setDoesRelativeDateFormatting:YES];
    NSString* dateString = [formatter stringFromDate:[NSDate date]];
//SCXTT need to set the subtitle to the new date time

//    annotation.subtitle = dateString;
//    [pin se]
    
    
    pin.rightCalloutAccessoryView = disclosureButton;
    //pin.pinColor = MKPinAnnotationColorRed;
    pin.animatesDrop = YES;
    [pin setEnabled:YES];
    [pin setCanShowCallout:YES];
    return pin;
    
    
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

-(void) updatePointsOnMap:(NSNotification *)notification {
//    [self didSaveMessage];
    BOOL whoFound = NO;
    NSDictionary *dict = [notification userInfo];
    NSLog([[dict valueForKey:@"aps"] valueForKey:@"loc"]);
    NSArray *strings = [[[dict valueForKey:@"aps"] valueForKey:@"loc"] componentsSeparatedByString:@","];
    NSLog(@"lat = %@", strings[0]);
    NSLog(@"lon = %@", strings[1]);
    NSString *who = [[dict valueForKey:@"aps"] valueForKey:@"who"];
    NSString *toast = [NSString stringWithFormat:@" Found: %@", who];
    [self toastMsg:toast];
    NSLog(@"who=%@",who);
    
    CLLocationCoordinate2D location, southWest, northEast;
    MKCoordinateRegion region;
    
    // seed the region values to set the span later to include all the pins
    southWest.latitude = [strings[0] doubleValue];
    southWest.longitude = [strings[1] doubleValue];
    northEast = southWest;
    
    for (id<MKAnnotation> ann in _mapView.annotations)
    {
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
            whoFound = YES;
            location.latitude = [strings[0] doubleValue];
            location.longitude = [strings[1] doubleValue];
            ann.coordinate = location;
            break;
        }
    }
    // new who so add addAnnotation and set coordinate
    if (!whoFound) {
        NSLog(@"Adding new who %@", who);
        VBAnnotation *annNew = [[VBAnnotation alloc] initWithPosition:location];
        annNew.title = who;
        
        
        
        //Scxtt may need to move this to mapView delegate
        // Format the message date
        NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
        [formatter setDateStyle:NSDateFormatterShortStyle];
        [formatter setTimeStyle:NSDateFormatterShortStyle];
        [formatter setDoesRelativeDateFormatting:YES];
        NSString* dateString = [formatter stringFromDate:[NSDate date]];

        
        
        annNew.subtitle = dateString;
        annNew.pinColor = MKPinAnnotationColorGreen;
        location.latitude = [strings[0] doubleValue];
        location.longitude = [strings[1] doubleValue];
        [annNew setCoordinate:location];
        [self.mapView addAnnotation:annNew];
    }

    _mapViewSouthWest = [[CLLocation alloc] initWithLatitude:southWest.latitude longitude:southWest.longitude];
    _mapViewNorthEast = [[CLLocation alloc] initWithLatitude:northEast.latitude longitude:northEast.longitude];
    
    // This is a diag distance (if you wanted tighter you could do NE-NW or NE-SE)
    CLLocationDistance meters = [_mapViewSouthWest getDistanceFrom:_mapViewNorthEast];

    [self reCenterMap:region meters:meters];
    
}

-(void) changeRegion {
    NSLog(@"changeRegion is called");
    
    
    for (id<MKAnnotation> ann in _mapView.annotations)
    {
        if ([ann.title isEqualToString:@"User1"])
        {
            NSLog(@"found user1");
            CLLocationCoordinate2D location;
            float rndV1 = (((float)arc4random()/0x100000000)*0.101);
            float rndV2 = (((float)arc4random()/0x100000000)*0.101);
            location.latitude = BE2_LATITUDE + rndV1;
            location.longitude = BE2_LONGITUDE + rndV2;
            ann.coordinate = location;
            break;
        }
    }
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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
