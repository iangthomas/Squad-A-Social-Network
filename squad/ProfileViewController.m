//
//  ProfileViewController.m
//  squad
//
//  Created by Ian Thomas on 11/3/16.
//  Copyright © 2016 KKIT Creations. All rights reserved.
//

#import "ProfileViewController.h"
#import "Constants.h"
#import "Reachability.h"

@interface ProfileViewController ()

@end

@implementation ProfileViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self setInitialSwitchPositionAndUi];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(void)setInitialSwitchPositionAndUi {
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kOnDuty]) {
        [_onOffGrid setSelectedSegmentIndex:1];
        [Constants debug:@1 withContent:@"Switch indicates Docent is ON Duty"];
    } else {
        [_onOffGrid setSelectedSegmentIndex:0];
        [Constants debug:@1 withContent:@"Switch indicates Docent is OFF Duty"];
    }
    
    [_onOffGrid addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
}

-(void) updateSwitchToOffDuty:(NSNotification*) notification {
    
    [_onOffGrid setSelectedSegmentIndex:0];
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kOnDuty];
    [Constants debug:@2 withContent:@"Docent was taken OFF Duty because of switching users"];
    
}

-(void)switchChanged:(UISegmentedControl*)theControl {
    
    if (theControl.selectedSegmentIndex == 0) {
        
        if ([self connectedToInternet]) {
            [Constants debug:@1 withContent:@"Docent switched to OFF Duty"];
            [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kOnDuty];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"onDutySwitchChanged" object:nil];
            
        } else {
            [theControl setSelectedSegmentIndex:1];
        }
        
    } else {
        if ([self connectedToInternet]) {
            [Constants debug:@1 withContent:@"Docent switched to ON Duty"];
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kOnDuty];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"onDutySwitchChanged" object:nil];
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
                                                                   message:@"Please connect to the internet to change duty status."
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
