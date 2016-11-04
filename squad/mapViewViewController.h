//
//  mapViewViewController.h
//  beaconList
//
//  Created by Ian Thomas on 11/3/15.
//  Copyright © 2015 Geodex. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@interface mapViewViewController : UIViewController <MKMapViewDelegate> {
  /* 
   UIActivityIndicatorView *activityView;
    UIView *loadingView;
    UILabel *loadingLabel;
   */
}

@property (nonatomic, retain) UIActivityIndicatorView * activityView;
@property (nonatomic, retain) UIView *loadingView;
@property (nonatomic, retain) UILabel *loadingLabel;

@property (strong, nonatomic) IBOutlet UIButton *centerUserInMap;



@end
