//
//  MapManager.h
//  PushChatStarter
//
//  Extracted from ShowMapViewController to manage map annotations and display logic.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@class Room;

NS_ASSUME_NONNULL_BEGIN

@protocol MapManagerDelegate <NSObject>
@optional
- (void)mapManagerDidRequestReturnToAllWithMessage:(NSString *)message;
- (void)mapManagerDidRequestToast:(NSString *)toastStr detailText:(NSString *)detailText;
- (void)mapManagerDidUpdatePinPickerEnabled:(BOOL)enabled;
- (void)mapManagerDidRequestBlockUser:(NSString *)nickname;
@end

@interface MapManager : NSObject <MKMapViewDelegate>

@property (nonatomic, weak) MKMapView *mapView;
@property (nonatomic, weak) id<MapManagerDelegate> delegate;

@property (nonatomic, copy) NSString *centerOnThisGuy;
@property (nonatomic) BOOL okToRecenterMap;
@property (nonatomic, strong) CLLocation *mapViewSouthWest;
@property (nonatomic, strong) CLLocation *mapViewNorthEast;

- (instancetype)initWithMapView:(MKMapView *)mapView;

// Annotation management
- (void)updateAnnotationsFromRoomArray:(NSArray<Room *> *)roomArray;
- (void)updateAnnotationsWithMQTTData:(NSDictionary *)userInfo;
- (void)removeAllAnnotations;
- (void)openAnnotation:(id<MKAnnotation>)annotation;
- (void)closeAnnotation:(id<MKAnnotation>)annotation;

// Helpers
- (NSInteger)rowForNickname:(NSString *)nickname inRoomArray:(NSArray<Room *> *)roomArray;
- (BOOL)annTitleHasLeftRoom:(NSString *)nickname inRoomArray:(NSArray<Room *> *)roomArray;

// Date utilities
- (NSInteger)getPinAgeInMinutes:(NSString *)gmtDateStr;

// Map centering
- (void)reCenterMap:(MKCoordinateRegion)region meters:(CLLocationDistance)meters;

@end

NS_ASSUME_NONNULL_END
