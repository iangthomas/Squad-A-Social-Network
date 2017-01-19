//  Copyright © 2017 Geodex Systems
//  All Rights Reserved.

#import "PVAttractionAnnotationView.h"
#import "PVAttractionAnnotation.h"

@implementation PVAttractionAnnotationView

- (id)initWithAnnotation:(id<MKAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier];
    if (self) {
        PVAttractionAnnotation *attractionAnnotation = self.annotation;

        /*
        if ([attractionAnnotation.imageName isEqualToString:@"green"]) {
            self.image = [UIImage imageNamed:@"greenDot"];

        } else if ([attractionAnnotation.imageName isEqualToString:@"orange"]) {
            self.image = [UIImage imageNamed:@"orangeDot"];

        } else { //if ([attractionAnnotation.imageName isEqualToString:@"grey"]) {
            self.image = [UIImage imageNamed:@"greyDot"];
        }
       */

        
        if (attractionAnnotation.isGreenDotColor) {
            self.image = [UIImage imageNamed:@"greenDot"];
        } else {
            self.image = [UIImage imageNamed:@"greyDot"];
        }
         
    }
    
    return self;
}

/*
-(void) updateAnnotation {
    self.image = [UIImage imageNamed:@"orangeDot"];
}*/

@end
