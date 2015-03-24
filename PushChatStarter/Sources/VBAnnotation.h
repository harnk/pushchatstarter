//
//  VBAnnotation.h
//  PushChatStarter
//
//  Created by Scott Null on 1/6/15.
//  Copyright (c) 2015 Ray Wenderlich. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface VBAnnotation : NSObject <MKAnnotation>

@property (nonatomic, assign) CLLocationCoordinate2D coordinate;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subtitle;
@property (nonatomic, assign) MKPinAnnotationColor *pinColor;
@property (nonatomic, assign) UIImage *image;

- initWithPosition:(CLLocationCoordinate2D)coords;

-(id)initWithTitle:(NSString *)newTitle newSubTitle:(NSString *)newSubTitle Location:(CLLocationCoordinate2D)location;
-(MKAnnotationView *)annotationView;

@end