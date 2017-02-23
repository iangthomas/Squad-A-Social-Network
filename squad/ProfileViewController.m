//
//  ProfileViewController.m
//  squad
//
//  Created by Ian Thomas on 11/3/16.
//  Copyright © 2016 Geodex Systems. All rights reserved.
//

#import "ProfileViewController.h"
#import "Constants.h"
#import "Reachability.h"
#import "AppDelegate.h"

@interface ProfileViewController ()

@end

@implementation ProfileViewController

#warning todo make the photos button working in the chat view

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.navigationItem.title = @"Your Profile";
        
    _pinLabel.text = [[NSUserDefaults standardUserDefaults] stringForKey:kPin];
    
    
    NSDictionary* infoDict = [[NSBundle mainBundle] infoDictionary];
    _appVersion.text = [NSString stringWithFormat:@"App Version: %@\nBuild #: %@ \n Build Date: %@", [infoDict objectForKey:@"CFBundleShortVersionString"], [infoDict objectForKey:@"CFBuildNumber"], [infoDict objectForKey:@"CFBuildDate"]];
    
    AppDelegate *theAppDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    // does this inititaly, then delegate notifications take it from here
    _userLocation.text = [NSString stringWithFormat:@"You're Near: %@", [theAppDelegate findNearestLargeCity:theAppDelegate.currentLocation]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateUserLocationText:) name:@"currentLocationUpdated" object:nil];
    
    
    [self setInitialSwitchPositionAndUi];
}


-(void) updateUserLocationText:(NSNotification*) theNotification {
    
    if ([theNotification.object isEqualToString:@"Off Grid"]) {
        _userLocation.text = @"Off Grid";
    } else {
        _userLocation.text = [NSString stringWithFormat:@"You're Near: %@", theNotification.object];
    }
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(void)setInitialSwitchPositionAndUi {
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kUserVisible]) {
        [_onOffGrid setSelectedSegmentIndex:1];
        [Constants debug:@1 withContent:@"Switch indicates user is visible"];
    } else {
        [_onOffGrid setSelectedSegmentIndex:0];
        [Constants debug:@1 withContent:@"Switch indicates user is not visible"];
    }
    
    [_onOffGrid addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
}

-(void) updateSwitchToNotVisible:(NSNotification*) notification {
    
    [_onOffGrid setSelectedSegmentIndex:0];
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kUserVisible];
    [Constants debug:@2 withContent:@"User was taken off visible  because of switching users"];
    
}

-(void)switchChanged:(UISegmentedControl*)theControl {
    
    if (theControl.selectedSegmentIndex == 0) {
        
        if ([self connectedToInternet]) {
            _userLocation.text = @"Loading...";
            [Constants debug:@1 withContent:@"user switched to not visible"];
            [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kUserVisible];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"isVisibleSwitchChanged" object:nil];
            
        } else {
            [theControl setSelectedSegmentIndex:1];
        }
        
    } else {
        if ([self connectedToInternet]) {
            _userLocation.text = @"Loading...";
            [Constants debug:@1 withContent:@"user switched to visible"];
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kUserVisible];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"isVisibleSwitchChanged" object:nil];
        } else {
            [theControl setSelectedSegmentIndex:0];
        }
    }
}

-(BOOL) connectedToInternet {
    
    Reachability *networkReachability = [Reachability reachabilityForInternetConnection];
    NetworkStatus networkStatus = [networkReachability currentReachabilityStatus];
    
    switch (networkStatus)
    {
        case NotReachable:        {
            [Constants debug:@3 withContent:@"No internet Connection"];
            
            [self showNoInternetAlert];
            return NO;
            
            break;
        }
        case ReachableViaWWAN:        {
            [Constants debug:@1 withContent:@"There IS internet via WAN (cell) connection"];
            return  YES;
            
            break;
        }
        case ReachableViaWiFi:        {
            [Constants debug:@1 withContent:@"There IS internet via Wifi connection"];
            return  YES;
            
            break;
        }
    }
}


-(void) showNoInternetAlert {
    
    [Constants debug:@1 withContent:@"Showing no internet alert view - system status"];
    
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"No Internet"
                                                                   message:@"Please connect to the internet to change visible status."
                                                            preferredStyle:UIAlertControllerStyleAlert];
    /*
     UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
     handler:^(UIAlertAction * action) {
     
     [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(makeAppReadyToUse) userInfo:nil repeats:NO];
     
     }];
     */
    
    UIAlertAction* tryAgainAction = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction * action) {
                                                               
                                                               /*
                                                                [NSTimer scheduledTimerWithTimeInterval:3.0 target:self selector:@selector(makeAppReadyToUse) userInfo:nil repeats:NO];
                                                                */
                                                           }];
    
    // [alert addAction:defaultAction];
    [alert addAction:tryAgainAction];
    
    [alert.view setNeedsLayout];
    [alert.view layoutIfNeeded];
    
    [self presentViewController:alert animated:YES completion:nil];
}


@end
