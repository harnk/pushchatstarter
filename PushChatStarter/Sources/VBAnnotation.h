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

@property (nonatomic, assign) CLLocationCoordinate2D coordinate; // MKAnnotation property
@property (nonatomic, copy) NSString *title;  // MKAnnotation property
@property (nonatomic, copy) NSString *subtitle;  // MKAnnotation property
@property (nonatomic, copy) NSDate *loctime;
@property (nonatomic, assign) UIImage *pinImage;
@property (nonatomic, copy) NSString *pinImageFile;


- initWithPosition:(CLLocationCoordinate2D)coords;

-(id)initWithTitle:(NSString *)newTitle newSubTitle:(NSString *)newSubTitle Location:(CLLocationCoordinate2D)location LocTime:loctime PinImageFile:pinImageFile PinImage:pinImage;
-(MKAnnotationView *)annotationView;

@end