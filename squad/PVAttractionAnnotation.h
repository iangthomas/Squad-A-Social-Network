#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
//#import <Parse/Parse.h>

typedef NS_ENUM(NSInteger, PVAttractionType) {
    PVAttractionDefault = 0,
    PVAttractionRide,
    PVAttractionFood,
    PVAttractionFirstAid
};

@interface PVAttractionAnnotation : NSObject <MKAnnotation>

@property (nonatomic) CLLocationCoordinate2D coordinate;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subtitle;
//@property (nonatomic, copy) NSString *imageName;


@property (nonatomic) BOOL isGreenDotColor;

//@property (nonatomic) BOOL isUnlocked;


@property (nonatomic, copy) NSString* uniqueId;
@property (nonatomic) BOOL publiclyVisible;
@property (nonatomic) BOOL enabled;




@property (nonatomic, copy) NSNumber *radius;



@end
