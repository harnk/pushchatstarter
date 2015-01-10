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
#define CA_LATITUDE 41.739414
#define CA_LONGITUDE -86.099170
// Beach
#define BE_LATITUDE 41.739474
#define BE_LONGITUDE -86.098960
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
    region.span.latitudeDelta = SPAN_VALUE;
    region.span.longitudeDelta = SPAN_VALUE;
    [self.mapView setRegion:region animated:NO];
    
    CLLocationCoordinate2D location;
    location.latitude = BE_LATITUDE;
    location.longitude = BE_LONGITUDE;
    //*******************************************************************
    VBAnnotation *ann = [[VBAnnotation alloc] initWithPosition:location];
    [ann setCoordinate:location];
    ann.title = @"Harnk";
    ann.subtitle = @"Today, 11:19 AM";
    [self.mapView addAnnotation:ann];
    
    //*******************************************************************
    VBAnnotation *ann2 = [[VBAnnotation alloc] initWithPosition:location];
    [ann2 setCoordinate:location];
    ann2.title = @"steve";
    ann2.subtitle = @"Today, 11:19 AM";
    [self.mapView addAnnotation:ann2];
    
    //*******************************************************************
    VBAnnotation *ann3 = [[VBAnnotation alloc] initWithPosition:location];
    [ann3 setCoordinate:location];
    ann3.title = @"SN6Plus";
    ann3.subtitle = @"Today, 11:19 AM";
    [self.mapView addAnnotation:ann3];
    
    //*******************************************************************
    VBAnnotation *ann4 = [[VBAnnotation alloc] initWithPosition:location];
    [ann4 setCoordinate:location];
    ann4.title = @"Patty";
    ann4.subtitle = @"Today, 11:19 AM";
    [self.mapView addAnnotation:ann4];
    
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

-(void) updatePointsOnMap:(NSNotification *)notification {
    NSDictionary *dict = [notification userInfo];
    NSLog([[dict valueForKey:@"aps"] valueForKey:@"loc"]);
    NSArray *strings = [[[dict valueForKey:@"aps"] valueForKey:@"loc"] componentsSeparatedByString:@","];
    NSLog(@"lat = %@", strings[0]);
    NSLog(@"lon = %@", strings[1]);
    NSString *who = [[dict valueForKey:@"aps"] valueForKey:@"who"];
    NSLog(@"who=%@",who);
    
    for (id<MKAnnotation> ann in _mapView.annotations)
    {
        if ([ann.title isEqualToString:@"Harnk"])
        {
            NSLog(@"found Harnk");
            CLLocationCoordinate2D location;
            location.latitude = [strings[0] doubleValue];
            location.longitude = [strings[1] doubleValue];
            ann.coordinate = location;
            break;
        }
        
    }
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
