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
    //*******************************************************************
    VBAnnotation *ann = [[VBAnnotation alloc] initWithPosition:location];
    [ann setCoordinate:location];
    ann.title = @"Harnk";
    ann.subtitle = @"Today, 11:19 AM";
    ann.pinColor = MKPinAnnotationColorRed;

    [self.mapView addAnnotation:ann];
    
    //*******************************************************************
    VBAnnotation *ann2 = [[VBAnnotation alloc] initWithPosition:location];
    [ann2 setCoordinate:location];
    ann2.title = @"steve";
    ann2.subtitle = @"Today, 11:19 AM";
    ann2.pinColor = MKPinAnnotationColorGreen;

    [self.mapView addAnnotation:ann2];
    
    //*******************************************************************
    VBAnnotation *ann3 = [[VBAnnotation alloc] initWithPosition:location];
    [ann3 setCoordinate:location];
    ann3.title = @"SN6Plus";
    ann3.subtitle = @"Today, 11:19 AM";
    ann3.pinColor = MKPinAnnotationColorPurple;

    [self.mapView addAnnotation:ann3];
    
    //*******************************************************************
    VBAnnotation *ann4 = [[VBAnnotation alloc] initWithPosition:location];
    [ann4 setCoordinate:location];
    ann4.title = @"Patty";
    ann4.subtitle = @"Today, 11:19 AM";
    ann4.pinColor = MKPinAnnotationColorRed;
    [self.mapView addAnnotation:ann4];
    
    //*******************************************************************
    VBAnnotation *ann5 = [[VBAnnotation alloc] initWithPosition:location];
    [ann5 setCoordinate:location];
    ann5.title = @"jackie";
    ann5.subtitle = @"Today, 11:19 AM";
    ann5.pinColor = MKPinAnnotationColorPurple;
    [self.mapView addAnnotation:ann5];
    
    //*******************************************************************
    VBAnnotation *ann6 = [[VBAnnotation alloc] initWithPosition:location];
    [ann6 setCoordinate:location];
    ann6.title = @"ED";
    ann6.subtitle = @"Today, 11:19 AM";
    ann6.pinColor = MKPinAnnotationColorGreen;
    [self.mapView addAnnotation:ann6];
    
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
    view.pinColor = MKPinAnnotationColorGreen;
    view.enabled = YES;
    view.animatesDrop = YES;
    view.canShowCallout = YES;
    
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"palmTree.png"]];
    view.leftCalloutAccessoryView = imageView;
    view.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
    return view;
}

-(void) updatePointsOnMap:(NSNotification *)notification {
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
        
        // Move the updated pin to its new locations
        if ([ann.title isEqualToString:who])
        {
            NSLog(@"found %@ moving %@", who, who);
            location.latitude = [strings[0] doubleValue];
            location.longitude = [strings[1] doubleValue];
            ann.coordinate = location;
            break;
        }
        // reset the span to include each and every pin as you go thru the list
        //ignore the 0,0 uninitialize annotations
        if (ann.coordinate.latitude != 0) {
            southWest.latitude = MIN(southWest.latitude, ann.coordinate.latitude);
            southWest.longitude = MIN(southWest.longitude, ann.coordinate.longitude);
            northEast.latitude = MAX(northEast.latitude, ann.coordinate.latitude);
            northEast.longitude = MAX(northEast.longitude, ann.coordinate.longitude);
        }
    }

    CLLocation *locSouthWest = [[CLLocation alloc] initWithLatitude:southWest.latitude longitude:southWest.longitude];
    CLLocation *locNorthEast = [[CLLocation alloc] initWithLatitude:northEast.latitude longitude:northEast.longitude];
    
    // This is a diag distance (if you wanted tighter you could do NE-NW or NE-SE)
    CLLocationDistance meters = [locSouthWest getDistanceFrom:locNorthEast];

    region.center.latitude = (southWest.latitude + northEast.latitude) / 2.0;
    region.center.longitude = (southWest.longitude + northEast.longitude) / 2.0;
    region.span.latitudeDelta = meters / 111319.5;
    region.span.longitudeDelta = 0.0;
    
    MKCoordinateRegion savedRegion = [_mapView regionThatFits:region];
    [_mapView setRegion:savedRegion animated:YES];
    
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


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
