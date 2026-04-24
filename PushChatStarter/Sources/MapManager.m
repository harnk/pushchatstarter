//
//  MapManager.m
//  PushChatStarter
//
//  Extracted from ShowMapViewController to manage map annotations and display logic.
//

#import "MapManager.h"
#import "VBAnnotation.h"
#import "Room.h"
#import "SingletonClass.h"

@implementation MapManager

- (instancetype)initWithMapView:(MKMapView *)mapView {
    self = [super init];
    if (self) {
        _mapView = mapView;
        _okToRecenterMap = YES;
    }
    return self;
}

#pragma mark - Annotation Management

- (void)updateAnnotationsFromRoomArray:(NSArray<Room *> *)roomArray {
    CLLocationCoordinate2D location, southWest, northEast;
    MKCoordinateRegion region;
    
    // seed the region values with my current location and to set the span later to include all the pins
    NSString *mLoc = [[SingletonClass singleObject] myLocStr];
    NSArray *strs = [mLoc componentsSeparatedByString:@","];
    southWest.latitude = [strs[0] doubleValue];
    southWest.longitude = [strs[1] doubleValue];
    northEast = southWest;

    NSLog(@"SMVC updatePointsOnMapWithAPIData");
    NSLog(@"SMVC My loc:%@", mLoc);
    
    [self checkPinPickerButton:roomArray];
    
    for (Room *item in roomArray) {
        BOOL whoFound = NO;
        if (![item.memberLocation isEqual:@"0.000000, 0.000000"]) {
            
            NSArray *strings = [item.memberLocation componentsSeparatedByString:@","];
            NSString *who = item.memberNickName;
            NSString *imageString = item.memberPinImage;
            UIImage *useThisPin = [UIImage imageNamed:imageString];
            
            NSString *gmtDateStr = item.memberUpdateTime;
            NSString *dateString = [self localDateStrFromUTCDateStr:gmtDateStr];
            NSDate *date = [self dateFromUTCDateStr:gmtDateStr];
            
            for (VBAnnotation *ann in _mapView.annotations)
            {
                // First see if this ann still has a roomArray match
                // or if the person has left the room kill this ann
                if ([self annTitleHasLeftRoom:ann.title inRoomArray:roomArray]) {
                    if ([ann.title isEqualToString:_centerOnThisGuy]){
                        if ([_delegate respondsToSelector:@selector(mapManagerDidRequestReturnToAllWithMessage:)]){
                            [_delegate mapManagerDidRequestReturnToAllWithMessage:@""];
                        }
                    }
                    if (![ann.title isEqualToString:@"My Location"]){
                        if ([_delegate respondsToSelector:@selector(mapManagerDidRequestToast:detailText:)]){
                            [_delegate mapManagerDidRequestToast:ann.title detailText:@"has left the map group"];
                        }
                        [_mapView removeAnnotation:ann];
                    }
                }
                southWest.latitude = MIN(southWest.latitude, ann.coordinate.latitude);
                southWest.longitude = MIN(southWest.longitude, ann.coordinate.longitude);
                northEast.latitude = MAX(northEast.latitude, ann.coordinate.latitude);
                northEast.longitude = MAX(northEast.longitude, ann.coordinate.longitude);
                
                // Move the updated pin to its new locations
                if ([ann.title isEqualToString:who])
                {
                    long pinAge = (long)[self getPinAgeInMinutes:gmtDateStr];
                    if (pinAge > 10000.0) {
                        if (![ann.pinImageFile isEqualToString:@"inactivepin.png"]) {
                            VBAnnotation *swapAnn = ann;
                            swapAnn.pinImage = [UIImage imageNamed:@"inactivepin.png"];
                            swapAnn.pinImageFile = @"inactivepin.png";
                            [swapAnn setPinImageFile:@"inactivepin.png"];
                            [item setMemberPinImage:@"interactivepin.png"];
                            [_mapView removeAnnotation:ann];
                            [_mapView addAnnotation:swapAnn];
                        }
                    } else {
                        if ([ann.pinImageFile isEqualToString:@"inactivepin.png"]) {
                            VBAnnotation *swapAnn = ann;
                            swapAnn.pinImage = [UIImage imageNamed:imageString];
                            swapAnn.pinImageFile = imageString;
                            [swapAnn setPinImageFile:imageString];
                            [item setMemberPinImage:imageString];
                            [_mapView removeAnnotation:ann];
                            [_mapView addAnnotation:swapAnn];
                        }
                    }

                    whoFound = YES;
                    location.latitude = [strings[0] doubleValue];
                    location.longitude = [strings[1] doubleValue];
                    if (![item.memberLocation isEqual:@"0.000000, 0.000000"]){
                        ann.subtitle = @"date and distance from me";
                        
                        // Format the location to read distance from me now
                        NSString *mLoc = [[SingletonClass singleObject] myLocStr];
                        NSArray *strings1 = [mLoc componentsSeparatedByString:@","];
                        CLLocation *locA = [[CLLocation alloc] initWithLatitude:[strings1[0] doubleValue] longitude:[strings1[1] doubleValue]];
                        
                        NSArray *strings2 = [item.memberLocation componentsSeparatedByString:@","];
                        CLLocation *locB = [[CLLocation alloc] initWithLatitude:[strings2[0] doubleValue] longitude:[strings2[1] doubleValue]];
                        CLLocationDistance distance = [locA distanceFromLocation:locB];
                        
                        double distanceMeters = distance;
                        double distanceInYards = distanceMeters * 1.09361;
                        double distanceInMiles = distanceInYards / 1760;
                        
                        if (distanceInYards > 500) {
                            ann.subtitle = [NSString stringWithFormat:@"%@, %.1f miles", dateString, distanceInMiles];
                        } else {
                            ann.subtitle = [NSString stringWithFormat:@"%@, %.1f y", dateString, distanceInYards];
                        }
                        
                        ann.loctime = date;
                        [ann setCoordinate:location];
                    }
                }
            }
            // new who so add addAnnotation and set coordinate and location time and recenter the map
            if (!whoFound) {
                NSLog(@"SMVC Adding new who %@ with pin %@", who, imageString);

                if (![item.memberLocation isEqual:@"0.000000, 0.000000"]){
                    if ([_delegate respondsToSelector:@selector(mapManagerDidRequestToast:detailText:)]){
                        [_delegate mapManagerDidRequestToast:who detailText:@"is in the map group"];
                    }
                    VBAnnotation *annNew = [[VBAnnotation alloc] initWithTitle:who newSubTitle:dateString Location:location LocTime:date PinImageFile:imageString PinImage:useThisPin];
                    location.latitude = [strings[0] doubleValue];
                    location.longitude = [strings[1] doubleValue];
                    [annNew setCoordinate:location];
                    [_mapView addAnnotation:annNew];
                }
            }
        }
    }
    // Recenter map
    
    if (_okToRecenterMap) {
        if (([self rowForNickname:_centerOnThisGuy inRoomArray:roomArray] >= 0)) {
            CLLocationCoordinate2D loc;
            
            NSArray *strings = [[[roomArray objectAtIndex:[self rowForNickname:_centerOnThisGuy inRoomArray:roomArray]] memberLocation] componentsSeparatedByString:@","];
            loc.latitude = [strings[0] doubleValue];
            loc.longitude = [strings[1] doubleValue];
            
            _mapViewSouthWest = [[CLLocation alloc] initWithLatitude:loc.latitude longitude:loc.longitude];
            _mapViewNorthEast = [[CLLocation alloc] initWithLatitude:loc.latitude longitude:loc.longitude];
            
            CLLocationDistance meters = 1000;
            region = _mapView.region;
            [self reCenterMap:region meters:meters];
        } else {
            _mapViewSouthWest = [[CLLocation alloc] initWithLatitude:southWest.latitude longitude:southWest.longitude];
            _mapViewNorthEast = [[CLLocation alloc] initWithLatitude:northEast.latitude longitude:northEast.longitude];
            
            CLLocationDistance meters = [_mapViewSouthWest distanceFromLocation:_mapViewNorthEast];
            
            region = _mapView.region;
            [self reCenterMap:region meters:meters];
        }
    }
}

- (void)updateAnnotationsWithMQTTData:(NSDictionary *)userInfo {
    CLLocationCoordinate2D location;
    NSArray *strings = [[userInfo valueForKey:@"location"] componentsSeparatedByString:@","];
    location.latitude = [strings[0] doubleValue];
    location.longitude = [strings[1] doubleValue];
    NSLog(@"SCXTT updatePointsOnMapWithMQTTData");
    @try {
        for (VBAnnotation *ann in _mapView.annotations) {
            if ([ann.title isEqualToString:[userInfo valueForKey:@"nickname"]]){
                NSLog(@"I FOUND [dict valueForKey:@nickname]:%@ ... setting its location to:%@", [userInfo valueForKey:@"nickname"], [userInfo valueForKey:@"location"]);
                [ann setCoordinate:location];
            }
        }
    }
    @catch (NSException *exception) {
        NSLog(@"SCXTT notification,userInfo NOT SET yet");
    }
}

- (void)removeAllAnnotations {
    [_mapView removeAnnotations:_mapView.annotations];
}

- (void)openAnnotation:(id<MKAnnotation>)annotation {
    [_mapView selectAnnotation:annotation animated:YES];
}

- (void)closeAnnotation:(id<MKAnnotation>)annotation {
    [_mapView deselectAnnotation:annotation animated:YES];
}

#pragma mark - Helpers

- (NSInteger)rowForNickname:(NSString *)nickname inRoomArray:(NSArray<Room *> *)roomArray {
    NSInteger i = 0;
    for (Room *item in roomArray) {
        if ([nickname isEqualToString:item.memberNickName]) {
            return i;
        }
        i++;
    }
    return -1;
}

- (BOOL)annTitleHasLeftRoom:(NSString *)nickname inRoomArray:(NSArray<Room *> *)roomArray {
    if ([nickname isEqualToString:@"Current Location"]) {
        return NO;
    }
    for (Room *item in roomArray) {
        if ([nickname isEqualToString:item.memberNickName]) {
            return NO;
        }
    }
    return YES;
}

- (void)checkPinPickerButton:(NSArray<Room *> *)roomArray {
    if ([roomArray count] == 0) {
        if ([_delegate respondsToSelector:@selector(mapManagerDidUpdatePinPickerEnabled:)]){
            [_delegate mapManagerDidUpdatePinPickerEnabled:NO];
        }
        [_mapView removeAnnotations:_mapView.annotations];
    } else {
        if ([_delegate respondsToSelector:@selector(mapManagerDidUpdatePinPickerEnabled:)]){
            [_delegate mapManagerDidUpdatePinPickerEnabled:YES];
        }
    }
}

#pragma mark - Map Centering

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

#pragma mark - MKMapViewDelegate

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    
    if([annotation isKindOfClass:[VBAnnotation class]]) {
        VBAnnotation *myAnnotation = (VBAnnotation *)annotation;
        MKAnnotationView *annotationView = [mapView dequeueReusableAnnotationViewWithIdentifier:@"MyCustomAnnotation"];

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
        annView.frame = CGRectOffset(endFrame, 0, -500);
        [UIView animateWithDuration:0.5
                         animations:^{ annView.frame = endFrame; }];
    }
}

#pragma mark - Date String Methods

- (NSString *)localDateStrFromUTCDateStr:(NSString *)utcDateStr {
    NSString *localDateStr;
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"YYYY-MM-dd HH:mm:ss"];
    formatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    NSDate *date = [formatter dateFromString:utcDateStr];
    
    formatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:[NSTimeZone localTimeZone].secondsFromGMT];
    [formatter setDateStyle:NSDateFormatterShortStyle];
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    [formatter setDoesRelativeDateFormatting:YES];
    localDateStr = [formatter stringFromDate:date];
    return localDateStr;
}

- (NSDate *)dateFromUTCDateStr:(NSString *)utcDateStr {
    NSDate *date;
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"YYYY-MM-dd HH:mm:ss"];
    formatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    date = [formatter dateFromString:utcDateStr];
    return date;
}

- (NSInteger)getPinAgeInMinutes:(NSString *)gmtDateStr
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"YYYY-MM-dd HH:mm:ss"];
    [formatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    NSDate *jsonDate = [formatter dateFromString:gmtDateStr];
    NSDate *now = [NSDate date];
    
    NSTimeInterval distanceBetweenDates = [now timeIntervalSinceDate:jsonDate];
    double secondsInAnMinute = 60;
    NSInteger minutesBetweenDates = distanceBetweenDates / secondsInAnMinute;
    return minutesBetweenDates;
}

@end
