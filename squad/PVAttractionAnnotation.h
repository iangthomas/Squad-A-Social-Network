#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

//  Copyright © 2017 Geodex Systems
//  All Rights Reserved.


#warning remove these old pireces of code

@interface PVAttractionAnnotation : NSObject <MKAnnotation>

@property (nonatomic) CLLocationCoordinate2D coordinate;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subtitle;
//@property (nonatomic, copy) NSString *imageName;


@property (nonatomic) BOOL isGreenDotColor;


@property (nonatomic, copy) NSString* uniqueId;
@property (nonatomic) BOOL publiclyVisible;
@property (nonatomic) BOOL enabled;

@property (nonatomic, copy) NSNumber *radius;


@end
