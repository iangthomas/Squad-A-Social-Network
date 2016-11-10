//
//  ProfileViewController.h
//  squad
//
//  Created by Ian Thomas on 11/3/16.
//  Copyright © 2016 KKIT Creations. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ProfileViewController : UIViewController
@property (weak, nonatomic) IBOutlet UISegmentedControl *onOffGrid;
@property (weak, nonatomic) IBOutlet UILabel *pinLabel;
@property (weak, nonatomic) IBOutlet UILabel *appVersion;
@property (weak, nonatomic) IBOutlet UILabel *userLocation;

@end
