//
//  VBAnnotation.m
//  PushChatStarter
//
//  Created by Scott Null on 1/6/15.
//  Copyright (c) 2015 Ray Wenderlich. All rights reserved.
//

#import "VBAnnotation.h"

@implementation VBAnnotation

- initWithPosition:(CLLocationCoordinate2D)coords {
    if (self = [super init]) {
        self.coordinate = coords;
    }
    return self;
}

-(id)initWithTitle:(NSString *)newTitle newSubTitle:(NSString *)newSubTitle Location:(CLLocationCoordinate2D)location LocTime:(NSDate *)loctime PinImageFile:pinImageFile PinImage:pinImage; {
    self = [super init];
    if(self) {
        _title = newTitle;
        _coordinate = location;
        _subtitle = newSubTitle;
        _loctime = loctime;
        _pinImage = pinImage;
        _pinImageFile = pinImageFile;
    }
    return self;
}

- (MKAnnotationView *)annotationView {
    MKAnnotationView *annotationView = [[MKAnnotationView alloc] initWithAnnotation:self reuseIdentifier:@"MyCustomAnnotation"];
    annotationView.enabled = YES;
    annotationView.canShowCallout = YES;
    annotationView.image = _pinImage;
//    annotationView.image = [UIImage imageNamed:@"cyangray.png"];
    annotationView.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
    return annotationView;
}

@end

