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

@interface ShowMapViewController ()

@end

@implementation ShowMapViewController

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

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.mapView setDelegate:self];
    
    MKCoordinateRegion region;
    region.center.latitude = CA_LATITUDE;
    region.center.longitude = CA_LONGITUDE;
    region.span.latitudeDelta = 50.1f;
    region.span.longitudeDelta = 50.1f;
    [self.mapView setRegion:region animated:NO];
    
    CLLocationCoordinate2D location;
    location.latitude = BE_LATITUDE;
    location.longitude = BE_LONGITUDE;

// SCXTT this below aint worken
    UIBarButtonItem *btnCamera = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCamera target:self action:@selector(share)];
    UIBarButtonItem *btnRefresh = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(findAction)];
    UIBarButtonItem *btnCompose = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:self action:@selector(composeAction)];
    [self.navigationItem setRightBarButtonItems:[NSArray arrayWithObjects:btnCompose, btnRefresh, btnCamera, nil] animated:NO];

//    //*******************************************************************
//    VBAnnotation *ann = [[VBAnnotation alloc] initWithPosition:location];
//    [ann setCoordinate:location];
//    ann.title = @"Harnk";
//    ann.subtitle = @"Today, 11:19 AM";
//    ann.pinColor = MKPinAnnotationColorRed;
//
//    [self.mapView addAnnotation:ann];
//    
//    //*******************************************************************
//    VBAnnotation *ann2 = [[VBAnnotation alloc] initWithPosition:location];
//    [ann2 setCoordinate:location];
//    ann2.title = @"steve";
//    ann2.subtitle = @"Today, 11:19 AM";
//    ann2.pinColor = MKPinAnnotationColorGreen;
//
//    [self.mapView addAnnotation:ann2];
//    
//    //*******************************************************************
//    VBAnnotation *ann3 = [[VBAnnotation alloc] initWithPosition:location];
//    [ann3 setCoordinate:location];
//    ann3.title = @"SN6Plus";
//    ann3.subtitle = @"Today, 11:19 AM";
//    ann3.pinColor = MKPinAnnotationColorPurple;
//
//    [self.mapView addAnnotation:ann3];
//    
//    //*******************************************************************
//    VBAnnotation *ann4 = [[VBAnnotation alloc] initWithPosition:location];
//    [ann4 setCoordinate:location];
//    ann4.title = @"Patty";
//    ann4.subtitle = @"Today, 11:19 AM";
//    ann4.pinColor = MKPinAnnotationColorRed;
//    [self.mapView addAnnotation:ann4];
//    
//    //*******************************************************************
//    VBAnnotation *ann5 = [[VBAnnotation alloc] initWithPosition:location];
//    [ann5 setCoordinate:location];
//    ann5.title = @"jackie";
//    ann5.subtitle = @"Today, 11:19 AM";
//    ann5.pinColor = MKPinAnnotationColorPurple;
//    [self.mapView addAnnotation:ann5];
//    
//    //*******************************************************************
//    VBAnnotation *ann6 = [[VBAnnotation alloc] initWithPosition:location];
//    [ann6 setCoordinate:location];
//    ann6.title = @"ED";
//    ann6.subtitle = @"Today, 11:19 AM";
//    ann6.pinColor = MKPinAnnotationColorGreen;
//    [self.mapView addAnnotation:ann6];
    
    [NSTimer scheduledTimerWithTimeInterval: 0.001
                                     target: self
                                   selector: @selector(changeRegion)
                                   userInfo: nil
                                    repeats: NO];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updatePointsOnMap:)
                                                 name:@"receivedNewMessage"
                                               object:nil];

    
}

- (NSString *)deviceLocation {
    return [NSString stringWithFormat:@"%f, %f", self.locationManager.location.coordinate.latitude, self.locationManager.location.coordinate.longitude];
}


- (IBAction)findAction {
    [self postFindRequest];
//    [self mapAction];
}

- (void)postFindRequest
{
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
             NSLog(@"Find request sent to all devices");
             //             [self dismissViewControllerAnimated:YES completion:nil];
         }
     } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
         if ([self isViewLoaded]) {
             [MBProgressHUD hideHUDForView:self.view animated:YES];
             ShowErrorAlert([error localizedDescription]);
         }
     }];
    
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    MKPinAnnotationView *view = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"pin"];
    view.pinColor = MKPinAnnotationColorPurple;
    view.enabled = YES;
    view.animatesDrop = YES;
    view.canShowCallout = YES;
    
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"palmTree.png"]];
    view.leftCalloutAccessoryView = imageView;
    view.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
    return view;
}

- (void)reCenterMap:(MKCoordinateRegion)region meters:(CLLocationDistance)meters {
    
    region.center.latitude = (_mapViewSouthWest.coordinate.latitude + _mapViewNorthEast.coordinate.latitude) / 2.0;
    region.center.longitude = (_mapViewSouthWest.coordinate.longitude + _mapViewNorthEast.coordinate.longitude) / 2.0;
    region.span.latitudeDelta = meters / 111319.5;
    region.span.longitudeDelta = 0.0;
    
    MKCoordinateRegion savedRegion = [_mapView regionThatFits:region];
    [_mapView setRegion:savedRegion animated:YES];
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
        annNew.subtitle = @"Today, 11:19 AM";
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
    
    //    //region
    //    MKCoordinateRegion region;
    //    //center
    //    CLLocationCoordinate2D center;
    //    center.latitude = CA_LATITUDE;
    //    center.longitude = CA_LONGITUDE;
    //    //span
    //    MKCoordinateSpan span;
    //    span.latitudeDelta = SPAN_VALUE;
    //    span.longitudeDelta = SPAN_VALUE;
    //
    //    region.center = center;
    //    region.span = span;
    //
    //    // assign region to map
    //    [_mapView setRegion:region animated:YES];
    
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
#pragma mark - UITableViewDataSource

- (void)scrollToNewestMessage
{
    // The newest message is at the bottom of the table
    NSIndexPath* indexPath = [NSIndexPath indexPathForRow:(self.dataModel.messages.count - 1) inSection:0];
    [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
}


- (int)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.dataModel.messages.count;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    static NSString* CellIdentifier = @"MessageCellIdentifier";
    
    MessageTableViewCell* cell = (MessageTableViewCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
        cell = [[MessageTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    
    Message* message = (self.dataModel.messages)[indexPath.row];
    [cell setMessage:message];
    return cell;
}

#pragma mark -
#pragma mark UITableView Delegate

- (CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
    // This function is called before cellForRowAtIndexPath, once for each cell.
    // We calculate the size of the speech bubble here and then cache it in the
    // Message object, so we don't have to repeat those calculations every time
    // we draw the cell. We add 16px for the label that sits under the bubble.
    Message* message = (self.dataModel.messages)[indexPath.row];
    message.bubbleSize = [SpeechBubbleView sizeForText:message.text];
    return message.bubbleSize.height + 16;
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
