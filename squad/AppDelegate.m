//
//  AppDelegate.m
//  beaconList
//
//  Created by Ian Thomas on 11/2/15.
//  Copyright © 2015 Geodex. All rights reserved.
//

#import "AppDelegate.h"
#import "Constants.h"
#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>
#import "SystemStatusViewController.h"
#import <AudioToolbox/AudioToolbox.h>
#import "TutViewController.h"
#import <squad-Swift.h>
#import <OneSignal/OneSignal.h>


@interface AppDelegate ()
@property (nonatomic, assign) BOOL sendCheckInTimes;

@property (nonatomic, assign) BOOL deviceIsInGeofenceViaManual;
@property (nonatomic, assign) BOOL showingNearbyAlertview;


@property (nonatomic, strong) NSNumber *lowishAccuracyThreshold;
@property (nonatomic, strong) NSNumber *geofenceCutoffDistanceForAlert;

@property (nonatomic, strong) NSDate *dateLowAccuracyAlertWasShown;

@property (nonatomic, strong) NSMutableArray *colA;
@property (nonatomic, strong) NSMutableArray *colB;
@property (nonatomic, strong) NSMutableArray *colC;
@property (nonatomic, strong) NSMutableArray *colD;
@property (nonatomic, strong) NSMutableArray *countryCode;
@property (nonatomic, strong) NSMutableArray *countryFullName;

@property (nonatomic, strong) NSMutableDictionary *friendNicknames;

@property (nonatomic, strong) SwiftAppDelegateClass *swiftAppDelegate;

@end

@implementation AppDelegate

@synthesize locationManager;
//@synthesize networkReachability;


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    [Constants debug:@1 withContent:@"Starting App"];
    
    [FIRApp configure];
    
    _sendCheckInTimes = NO;
    
    
    _deviceIsInGeofenceViaManual = NO;
    _showingNearbyAlertview = NO;
    
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *appDefaults = [[NSDictionary alloc] initWithObjectsAndKeys:
                                 @"", kidOfGenfenceDeviceIsIn,
                                 @"NO", kOnDuty,
                                 @"", kDocentUserId,
                                 @"", kPin,
                                 @"", kAppIDNumber,
                                 @"YES", kauto_anonymous_stats,
                                 @"YES", kauto_crash_reporting,
                                 @"YES", kVibration_enabled,
                                 @"YES", knearby_flock_alert,
                                 @"NO", kgeofenceEditAccess,
                                 nil];
    
    
    [defaults registerDefaults:appDefaults];
    
    
    NSInteger numLaunches = [defaults integerForKey:kNumLaunchesKey];
    [[NSUserDefaults standardUserDefaults] setInteger:numLaunches+1 forKey:kNumLaunchesKey];
    
 
    
 
#warning for the beta this has been disabled
    //  if ([defaults boolForKey:kauto_crash_reporting]) {
    [[Fabric sharedSDK] setDebug: YES];
    [Fabric with:@[CrashlyticsKit]];
    [Fabric with:@[[Crashlytics class]]];
    
    [self postUpdatedAppVersion];
    
    
    //   [[Fabric sharedSDK] setDebug: YES];
    
    
    //  }
    
    //   [OneSignal initWithLaunchOptions:launchOptions appId:@"d0a67531-fa19-4ccc-a749-4699ce969ddd"];
    //       OneSignal.initWithLaunchOptions(launchOptions, appId: "5eb5a37e-b458-11e3-ac11-000c2940e62c")
    
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber: 0];
    
    
    [OneSignal initWithLaunchOptions:launchOptions appId:@"d0a67531-fa19-4ccc-a749-4699ce969ddd" handleNotificationReceived:^(OSNotification *notification) {
        //   NSLog(@"Received Notification - %@", notification.payload.notificationID);
    } handleNotificationAction:^(OSNotificationOpenedResult *result) {
        
        // This block gets called when the user reacts to a notification received
        /*
         OSNotificationPayload* payload = result.notification.payload;
         
         #warning make this pop the user drienctly into the relovent channel
         
         
         NSString* messageTitle = @"OneSignal Example";
         NSString* fullMessage = [payload.body copy];
         
         if (payload.additionalData) {
         
         if(payload.title)
         messageTitle = payload.title;
         
         NSDictionary* additionalData = payload.additionalData;
         
         if (additionalData[@"actionSelected"])
         fullMessage = [fullMessage stringByAppendingString:[NSString stringWithFormat:@"\nPressed ButtonId:%@", additionalData[@"actionSelected"]]];
         }
         
         UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:messageTitle
         message:fullMessage
         delegate:self
         cancelButtonTitle:@"Close"
         otherButtonTitles:nil, nil];
         [alertView show];
         */
        
    } settings:@{kOSSettingsKeyInFocusDisplayOption : @(OSNotificationDisplayTypeNone), kOSSettingsKeyAutoPrompt : @NO}];
    
    
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sendCurrentLocation:) name:@"getCurrentLocation" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(requestLocation:) name:@"requestLocation" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(makeProfileAndGoOnDuty:) name:@"makeProfile" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(incrementFriendListBadgeIcon:) name:@"incrementFriendListBadgeIcon" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(decrementFriendListBadgeIcon:) name:@"decrementFriendListBadgeIcon" object:nil];
    
    
    
    //#warning this does nor work
    /*
     // Reachability *reachabilityInfo;
     [[NSNotificationCenter defaultCenter] addObserver:self
     selector:@selector(reachabilityChanged)
     name:kReachabilityChangedNotification
     object:_networkReachability];
     [_networkReachability startNotifier];
     */
    
    
    [self makeAppReadyToUse];
    
    [self setupTabBar];
    
    [self generateCityList];
    [self generateCountryList];
    
    if ([self docentProfileEmpty] == NO) {
        [self methodsThatRequireAProfile];
    }
    
    
    [Constants debug:@1 withContent:@"Starting App Done"];
    
    return YES;
}



-(void)methodsThatRequireAProfile {
    [self setupSwiftAppDelegate];
    [self setupFirebaseVars];
    
    // [self updateNumLaunches];
    
}

-(void) setupSwiftAppDelegate {
    SwiftAppDelegateClass *swiftClass = [SwiftAppDelegateClass alloc];
    [swiftClass startObservingChatChannels];
}


-(void)setupTabBar {
    
    UITabBarController *tabBarController = (UITabBarController *)self.window.rootViewController;
    UITabBar *tabBar = tabBarController.tabBar;
    UITabBarItem *tabBarItem1 = [tabBar.items objectAtIndex:1];
    UITabBarItem *tabBarItem2 = [tabBar.items objectAtIndex:0];
    
    tabBarItem2.image = [[UIImage imageNamed:@"mapViewIconDark"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    tabBarItem2.selectedImage = [[UIImage imageNamed:@"mapViewIconWhite"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    
    tabBarItem1.image = [[UIImage imageNamed:@"threeLines"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    tabBarItem1.selectedImage = [[UIImage imageNamed:@"threeLinesWhite"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    
    [[UITabBar appearance] setBarTintColor:[Constants flockGreen]];
    [[UITabBarItem appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                       [UIColor whiteColor],
                                                       NSForegroundColorAttributeName, nil]
                                             forState:UIControlStateSelected];
    
    [[UITabBar appearance] setTintColor:[UIColor whiteColor]];
    
    
    [[UITabBarItem appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                       [UIColor darkGrayColor],
                                                       NSForegroundColorAttributeName, nil]
                                             forState:UIControlStateNormal];
}


/*
 -(void) updateNumLaunches {
 
 #warning chek me
 
 if ([self docentProfileEmpty] == NO) {
 
 
 Firebase *usersDirectory = [[Constants firebasePath] childByAppendingPath:@"users"];
 Firebase *theUserPath = [usersDirectory childByAppendingPath:[[NSUserDefaults standardUserDefaults] objectForKey:kDocentUserId]];
 // Firebase *personName = [theUserPath childByAppendingPath:@"name"];
 
 [theUserPath updateChildValues:@{ @"Num_Launches": [NSString stringWithFormat:@"%ld", (long)[[NSUserDefaults standardUserDefaults] integerForKey:kNumLaunchesKey]]
 } withCompletionBlock:^(NSError *error, Firebase *ref) {
 if (!error) {
 [Constants debug:@2 withContent:@"Successfully updated number of launches to firebase."];
 } else {
 [Constants debug:@3 withContent:@"ERROR: couldn't update number of launchesto firebase."];
 [Constants makeErrorReportWithDescription:error.localizedDescription];
 }
 }];
 }
 }
 */

-(void) setupFirebaseVars {
    
    FIRDatabaseReference *friendRequests= [[[[[FIRDatabase database] reference] child:@"users"]child:[[NSUserDefaults standardUserDefaults] objectForKey:kDocentUserId]] child:@"friendRequests"];
    
    [friendRequests observeEventType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        [self updateFriendRequestBadgeIcon:snapshot];
    }];
}


-(void)updateFriendRequestBadgeIcon:(FIRDataSnapshot*) snapshot {
    
    UITabBarController *tabBarController = (UITabBarController *)self.window.rootViewController;
    UITabBarItem * friendRequestTabBarItem = [tabBarController.tabBar.items objectAtIndex:2];
    
    if (snapshot.value != [NSNull null]) {
        NSArray *friendRequestsDict = snapshot.value;
        
        if (friendRequestsDict.count > 0) {
            int realCount = 0;
            
            for (int i = 0; i < friendRequestsDict.count; i++) {
                //  if (friendRequestsDict[i] != [NSNull null]) {
                realCount ++;
                //  }
            }
            
            if (realCount > 0) {
                friendRequestTabBarItem.badgeValue = [NSString stringWithFormat:@"%lu", (unsigned long)realCount];
            } else {
                friendRequestTabBarItem.badgeValue = nil;
            }
            
            
        } else if (friendRequestsDict.count == 0) {
            friendRequestTabBarItem.badgeValue = nil;
        }
    } else if (friendRequestTabBarItem.badgeValue != nil) {
        friendRequestTabBarItem.badgeValue = nil;
    }
}

#warning refacrtor these, most of code is duplicite
-(void)incrementFriendListBadgeIcon:(NSNotification*) notification {
    
    NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
    f.numberStyle = NSNumberFormatterDecimalStyle;
    
    UITabBarController *tabBarController = (UITabBarController *)self.window.rootViewController;
    UITabBarItem * friendRequestTabBarItem = [tabBarController.tabBar.items objectAtIndex:0];
    NSString * theString = friendRequestTabBarItem.badgeValue;
    NSNumber * num = [f numberFromString:theString];
    
    num = [NSNumber numberWithDouble:num.intValue + 1];
    
    friendRequestTabBarItem.badgeValue = num.stringValue;
}


-(void)decrementFriendListBadgeIcon:(NSNotification*) notification {
    
    NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
    f.numberStyle = NSNumberFormatterDecimalStyle;
    
    UITabBarController *tabBarController = (UITabBarController *)self.window.rootViewController;
    UITabBarItem * friendRequestTabBarItem = [tabBarController.tabBar.items objectAtIndex:0];
    NSString * theString = friendRequestTabBarItem.badgeValue;
    NSNumber * num = [f numberFromString:theString];
    
    num = [NSNumber numberWithDouble:num.intValue - 1];
    
    if (num.intValue == 0) {
        friendRequestTabBarItem.badgeValue = nil;
    } else {
        friendRequestTabBarItem.badgeValue = num.stringValue;
    }
}


// if the user is on duty then force them off duty
-(void)takeDeviceOffDuty {
    [Constants debug:@1 withContent:@"takeDeviceOffDuty"];
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kOnDuty]) {
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"takeTheDeviceOffDuty" object:nil];
        [Constants debug:@1 withContent:@"takeDeviceOffDuty posted"];
        
    }
}

-(BOOL) docentProfileEmpty {
    NSString* theName = [[NSUserDefaults standardUserDefaults] stringForKey:kDocentUserId];
    
    if ([theName isEqualToString:@""] || theName == nil || [theName isEqualToString:@"0"]) {
        return YES;
    } else {
        return NO;
    }
}

-(void) showTutorial {
    
    [Constants debug:@2 withContent:@"showTutorial"];
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UINavigationController *vc = [storyboard instantiateViewControllerWithIdentifier:@"tutorialNav"];
    
    TutViewController *nextVC = (TutViewController *)([vc viewControllers][0]);
    nextVC.showHiddenStuff = NO;
    
    [vc setModalPresentationStyle:UIModalPresentationFullScreen];
    [self.window makeKeyAndVisible];
    [self.window.rootViewController presentViewController:vc animated:YES completion:nil];
}


-(void) showLogin:(NSNotification*) theNotificaiton {
    
    [Constants debug:@2 withContent:@"haveUserLogin"];
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UINavigationController *vc = [storyboard instantiateViewControllerWithIdentifier:@"systemStatusNav"];
    
    SystemStatusViewController *nextVC = (SystemStatusViewController *)([vc viewControllers][0]);
    nextVC.showHiddenStuff = NO;
    
    [vc setModalPresentationStyle:UIModalPresentationFullScreen];
    [self.window makeKeyAndVisible];
    [self.window.rootViewController presentViewController:vc animated:NO completion:nil];
}


-(void) countParseCalls {
    
    [Constants debug:@3 withContent:[NSString stringWithFormat:@"%i", [Constants getMethodCallCount]]];
}


- (void) startDocentLocationStuff {
    
    [Constants debug:@1 withContent:@"startDocentLocationStuff"];
    
    if (locationManager == nil) {
        locationManager = [CLLocationManager new];
        locationManager.delegate = self;
    }
    
    locationManager.distanceFilter = kCLLocationAccuracyThreeKilometers;
    
    
    locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers;
    //[locationManager startMonitoringSignificantLocationChanges];
    locationManager.activityType = CLActivityTypeOther;
    [locationManager startUpdatingLocation];
    [locationManager requestWhenInUseAuthorization];
}


-(void) requestLocation:(NSNotification*) theNotificaiton {
    
    [self startDocentLocationStuff];
}


-(void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    
    [Constants debug:@1 withContent:@"didChangeAuthorizationStatus called"];
    
    if (status == kCLAuthorizationStatusDenied || status == kCLAuthorizationStatusRestricted)
    {
        [Constants debug:@3 withContent:@"Location Services authorization denied, can't range"];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"locationServicesDenied" object:nil];
        
    } else if (status == kCLAuthorizationStatusNotDetermined) {
        
    }
    
    else if (status == kCLAuthorizationStatusAuthorizedAlways) {
        
        [Constants debug:@1 withContent:@"Location Services authorized"];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"locationServicesAllowed" object:nil];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"zoomMap" object:nil];
    }
    
    else if (status == kCLAuthorizationStatusAuthorizedWhenInUse) {
        
        [Constants debug:@3 withContent:@"Location Services when in use"];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"locationServicesAllowedInUse" object:nil];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"zoomMap" object:nil];
    }
}


- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    
    if ([self docentProfileEmpty] == NO && [[NSUserDefaults standardUserDefaults] boolForKey:kOnDuty]) {
        
        // is this the first time this method has been called
        if (_currentLocation == nil) {
            
            _currentLocation = [locations objectAtIndex:0];
            
            
        } else {
            
            _currentLocation = [locations objectAtIndex:0];
            /*
             if ([self isAccuracyUnacceptablyLow:_currentLocation]) {
             [self showLowAccuracyAlert];
             
             } else { */
            [self postUserLocation:_currentLocation];
            //   }
        }
    }
}


-(void)postUserLocation:(CLLocation*)userLoc {
    
    
    [Constants debug:@3 withContent:[NSString stringWithFormat:@"FIREBASE: Calling the Internet with an updated location"]];
    
    FIRDatabaseReference *usersRef= [[[FIRDatabase database] reference] child:@"users"];
    FIRDatabaseReference *userRef= [usersRef child:[[NSUserDefaults standardUserDefaults] objectForKey:kDocentUserId]];
    FIRDatabaseReference *coorRef = [userRef child:@"coor"];
    
    
    
    NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
    f.numberStyle = NSNumberFormatterDecimalStyle;
    
    
    
    NSNumber *lat = [f numberFromString: [NSString stringWithFormat: @"%.1f", [[NSNumber numberWithDouble:userLoc.coordinate.latitude] doubleValue]]];
    NSNumber *lon = [f numberFromString: [NSString stringWithFormat: @"%.1f", [[NSNumber numberWithDouble:userLoc.coordinate.longitude] doubleValue]]];
    
    /*
     NSNumber *lat = [NSNumber numberWithDouble:[NSString stringWithFormat: @"%.1f", [[NSNumber numberWithDouble:userLoc.coordinate.latitude] doubleValue]]];
     NSNumber *lon = [NSNumber numberWithDouble:[NSString stringWithFormat: @"%.1f", [[NSNumber numberWithDouble:userLoc.coordinate.longitude] doubleValue]]];
     */
    
    NSDictionary *locDic = @{
                             @"lon": lon,
                             @"lat": lat,
                             @"Time": [[Constants internetTimeDateFormatter] stringFromDate:[NSDate date]]
                             };
    
    CLLocation* thefuzzyLocation = [[CLLocation alloc] initWithLatitude:lat.doubleValue longitude:lon.doubleValue];
    
    [coorRef setValue: locDic withCompletionBlock: ^(NSError *error, FIRDatabaseReference *ref) {
        if (error) {
            [Constants debug:@3 withContent:@"ERROR: Firebase telling the internet that the user is there."];
            [Constants makeErrorReportWithDescription:error.localizedDescription];
        } else {
            [Constants debug:@2 withContent:@"Successfully added user to the firebase geofence."];
            
            
            // [self postInitialFirebaseAnalyticsWithAutomatic:automatic];
        }
    }];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"currentLocationUpdated" object:[self findNearestLargeCity:thefuzzyLocation]];
}


-(BOOL) shouldShowLowAccuracyAlert {
    if (_showingNearbyAlertview == YES) {
        return NO;
    } else {
        
        if (_dateLowAccuracyAlertWasShown == nil) {
            return YES;
            
        } else {
            NSTimeInterval timeInterval = [[NSDate date] timeIntervalSinceDate:_dateLowAccuracyAlertWasShown];
            
            //#warning discuss w iain what this number should be
            if (timeInterval >= 15.0) {
                return YES;
                
            } else {
                return NO;
            }
        }
        // }
    }
}


-(BOOL) NSNumberCompare:(NSNumber*) one :(NSNumber*) two {
    
    if ([one compare:two] == NSOrderedSame) {
        return YES;
    } else {
        return NO;
    }
}


-(void) toggelDocentStuff:(NSNotification*) notificaiton {
    
    [Constants debug:@3 withContent:[NSString stringWithFormat:@"toggelDocentStuff called, with notification, %@", notificaiton.description]];
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kOnDuty]) {
        
        if (locationManager == nil) {
            [self startDocentLocationStuff];
        }
        [locationManager startUpdatingLocation];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"showTheUserLocation" object:nil];
        
    } else {
        [self disableDocentStuff];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"hideTheUserLocation" object:nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"currentLocationUpdated" object:@"Off Grid"];
    }
}


-(void) disableDocentStuff {
    
    [Constants debug:@1 withContent:@"disableDocentStuff called."];
    [locationManager stopUpdatingLocation];
    [self setFirebaseToOffGrid];
}


-(void) setFirebaseToOffGrid {
    
    [Constants debug:@3 withContent:[NSString stringWithFormat:@"FIREBASE: Calling the Internet to go off grid."]];
    
    FIRDatabaseReference *usersRef= [[[FIRDatabase database] reference] child:@"users"];
    FIRDatabaseReference *userRef= [usersRef child:[[NSUserDefaults standardUserDefaults] objectForKey:kDocentUserId]];
    FIRDatabaseReference *coorRef = [userRef child:@"coor"];
    
    [coorRef setValue:@NO withCompletionBlock:^(NSError * _Nullable error, FIRDatabaseReference * _Nonnull ref) {
        
        if (error) {
            [Constants debug:@3 withContent:@"FIREBASE: Calling the Internet to go off grid."];
            [Constants makeErrorReportWithDescription:error.localizedDescription];
        } else {
            [Constants debug:@3 withContent:[NSString stringWithFormat:@"FIREBASE: sucessfully off grid."]];
        }
    }];
}


- (void) makeAppReadyToUse {
    Reachability *networkReachability = [Reachability reachabilityForInternetConnection];
    NetworkStatus networkStatus = [networkReachability currentReachabilityStatus];
    
    switch (networkStatus)
    {
        case NotReachable:        {
            [Constants debug:@3 withContent:@"No internet Connection"];
            
            [self atemptToDisplayInternetAlert];
            
            break;
        }
        case ReachableViaWWAN:        {
            [Constants debug:@1 withContent:@"There IS internet via WAN (cell) connection"];
            [self initialSetup];
            
            break;
        }
        case ReachableViaWiFi:        {
            [Constants debug:@1 withContent:@"There IS internet via Wifi connection"];
            [self initialSetup];
            
            break;
        }
    }
}


-(void) atemptToDisplayInternetAlert {
    
    if (self.window.rootViewController.isViewLoaded && self.window.rootViewController.view.window) {
        [self showNoInternetAlert];
    } else {
        [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(makeAppReadyToUse) userInfo:nil repeats:NO];
    }
}


-(void) showNoInternetAlert {
    [Constants debug:@1 withContent:@"Showing No Internet Alert View - App Delegate"];
    
    
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"No Internet"
                                                                   message:@"Please connect to the internet."
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* tryAgainAction = [UIAlertAction actionWithTitle:@"Try Again" style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction * action) {
                                                               
                                                               [NSTimer scheduledTimerWithTimeInterval:3.0 target:self selector:@selector(makeAppReadyToUse) userInfo:nil repeats:NO];
                                                           }];
    //[alert addAction:defaultAction];
    [alert addAction:tryAgainAction];
    
    [alert.view setNeedsLayout];
    [alert.view layoutIfNeeded];
    
    [self.window.rootViewController presentViewController:alert animated:YES completion:nil];
}


-(void) initialSetup {
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(toggelDocentStuff:) name:@"onDutySwitchChanged" object:nil];
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kOnDuty]) {
        [Constants debug:@2 withContent:@"Device is on Duty"];
    } else {
        [Constants debug:@2 withContent:@"Device is off Duty"];
    }
    
    if ([self docentProfileEmpty]) {
        
        [self showTutorial];
    } else {
        if ([[NSUserDefaults standardUserDefaults] boolForKey:kOnDuty]) {
            
            [self toggelDocentStuff:nil];
        }
    }
}


-(void)sendCurrentLocation: (NSNotification*) notification {
    
    [Constants debug:@2 withContent:[NSString stringWithFormat:@"Attempting to send current locaiton, userLocationLastUpdated: %@, Current location accuracy: %f", _userLocaitonLastUpdated, _currentLocation.horizontalAccuracy]];
    
    if (_userLocaitonLastUpdated == NULL) {
        [self startDocentLocationStuff];
    }
    if (_currentLocation.horizontalAccuracy < 500 == NO || _currentLocation == nil) {
        [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(sendCurrentLocation:) userInfo:nil repeats:NO];
        
    } else {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"currentLocation" object:_currentLocation];
    }
}


-(void) makeProfileAndGoOnDuty:(NSNotification*) theNotification {
    
    [[NSUserDefaults standardUserDefaults] setObject:theNotification.object forKey:kDocentUserId];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kOnDuty];
    
    [self methodsThatRequireAProfile];
}


- (void)applicationWillResignActive:(UIApplication *)application {
    
    [Constants debug:@1 withContent:@"applicationWillResignActive"];
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    
    [Constants debug:@1 withContent:@"applicationDidEnterBackground"];
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    
    [Constants debug:@1 withContent:@"applicationWillEnterForeground"];
    
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    
    [Constants debug:@1 withContent:@"applicationDidBecomeActive"];
    
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    //#warning this does not work qutie yet
    
    [Constants debug:@1 withContent:@"applicationWillTerminate"];
    
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


-(void) generateCityList {
    
    _colA = [NSMutableArray array];
    _colB = [NSMutableArray array];
    _colC = [NSMutableArray array];
    _colD = [NSMutableArray array];
    NSString *fileContents = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"cities15000" ofType:@"csv"] encoding:NSUTF8StringEncoding error:nil];
    
    // NSString* fileContents = [NSString stringWithContentsOfURL:@"cities150000.csv"];
    NSArray* rows = [fileContents componentsSeparatedByString:@"\n"];
    for (NSString *row in rows){
        NSArray* columns = [row componentsSeparatedByString:@","];
        [_colA addObject:columns[0]];
        [_colB addObject:columns[1]];
        [_colC addObject:columns[2]];
        [_colD addObject:columns[3]];
    }
}


-(void) generateCountryList {
    NSString *fileContents = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"twoLetterCodes" ofType:@"csv"] encoding:NSUTF8StringEncoding error:nil];
    
    _countryFullName = [NSMutableArray array];
    _countryCode = [NSMutableArray array];
    
    NSArray* rows = [fileContents componentsSeparatedByString:@"\n"];
    for (NSString *row in rows){
        NSArray* columns = [row componentsSeparatedByString:@","];
        [_countryFullName addObject:columns[0]];
        [_countryCode addObject:columns[1]];
    }
}


-(NSString*)findNearestLargeCity:(CLLocation*) theGoalLocation {
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kOnDuty]) {
        
        int index = 0;
        double lowestDistanceSoFar = DBL_MAX;
        
        NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
        f.numberStyle = NSNumberFormatterDecimalStyle;
        
        for (int i = 0; i < _colA.count; i++) {
            
            NSNumber * lat = [f numberFromString:_colB[i]];
            NSNumber * lon = [f numberFromString:_colC[i]];
            
            CLLocation* possibleCity = [[CLLocation alloc] initWithLatitude:lat.doubleValue longitude:lon.doubleValue];
            
            NSNumber* theCurrentDistance = [NSNumber numberWithDouble:[theGoalLocation distanceFromLocation:possibleCity]];
            
            if (theCurrentDistance.doubleValue < lowestDistanceSoFar) {
                lowestDistanceSoFar = theCurrentDistance.doubleValue;
                index = i;
            }
        }
        
        NSString* theCity = [NSString stringWithFormat:@"%@", _colA[index]];
        NSString* theCountry = [NSString stringWithFormat:@"%@", [self findTheFullCountryName:_colD[index]]];
        
        if ([theCountry isEqualToString:@""]) {
            // the cuntry coresponding from the countyr code was not found, show nothing
            return theCity;
        } else {
            return [NSString stringWithFormat:@"%@, %@", theCity, theCountry];
        }
        
    } else {
        return @"Off Grid";
    }
}


-(NSString*) findTheFullCountryName:(NSString*) goalCountryCode {
    
    for (int i = 0; i < _countryCode.count; i++) {
        
        if ([_countryCode[i] isEqualToString: goalCountryCode]) {
            return _countryFullName[i];
        }
    }
    return @"";
}


- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo  {
    // NSLog(@"remote notification: %@",[userInfo description]);
    
    if ([[UIApplication sharedApplication] applicationState] != UIApplicationStateActive) {
        NSInteger temp = [[UIApplication sharedApplication] applicationIconBadgeNumber];
        [[UIApplication sharedApplication] setApplicationIconBadgeNumber: temp += 1];
    }
    
    /*
     if (userInfo) {
     NSLog(@"%@",userInfo);
     
     if ([userInfo objectForKey:@"aps"]) {
     if([[userInfo objectForKey:@"aps"] objectForKey:@"badgecount"]) {
     [UIApplication sharedApplication].applicationIconBadgeNumber = [[[userInfo objectForKey:@"aps"] objectForKey: @"badgecount"] intValue];
     }
     }
     }
     */
}

-(void) postUpdatedAppVersion {
    if ([self docentProfileEmpty] == NO) {
        
        FIRDatabaseReference *updateAppVersionPath= [[[[[FIRDatabase database] reference] child:@"users"]child:[[NSUserDefaults standardUserDefaults] objectForKey:kDocentUserId]] child:@"App_Version"];
        
        [updateAppVersionPath setValue:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"] withCompletionBlock:^(NSError * _Nullable error, FIRDatabaseReference * _Nonnull ref) {
            
            if (error) {
                [Constants debug:@2 withContent:@"ERROR updated app verison on firebase."];
            } else {
                [Constants debug:@2 withContent:@"Successfully updated app verison on firebase."];
            }
        }];
    }
}


-(NSString*) nicknameForPin:(NSString*) thePin {

    if (_friendNicknames == NULL) {
    // is the array uninitalized and loaded?
        _friendNicknames = [[NSMutableDictionary alloc] init];
        
        // load the database
        _friendNicknames = [self loadFriendListDatabase];
    }
    return [self searchTheArrayForThePin:thePin];
}


- (NSString*) searchTheArrayForThePin:(NSString*) thePin {
    
    if ( [_friendNicknames count] > 0 ) {
        
        NSArray *allTheKeys = [_friendNicknames allKeys];
        
        if (allTheKeys.count > 0) {
            
            for (int i = 0; i < allTheKeys.count; i++) {
                
                if ([allTheKeys[i] isEqualToString: thePin]) {
                    NSArray* allTheValues = [_friendNicknames allValues];
                    
                    return allTheValues[i];
                }
            }
        }
    }
    return @"";
}


-(void) addNewFriendNicknameWithNickname:(NSString*) theNickname withPin :(NSString*) thePin {
    
    [_friendNicknames setObject:theNickname forKey:thePin];
}


//-(void) saveFriendListDatabase:(NSDictionary*) theFriendListDict {


-(void) saveFriendListDatabase {
    
    [Constants debug:@2 withContent:@"Saving local content"];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:@"fList.dasq"];
    
    BOOL success = [NSKeyedArchiver archiveRootObject:_friendNicknames toFile:filePath];
    if(success == NO) {
        [Constants debug:@3 withContent:[NSString stringWithFormat:@"did not write file to %@", filePath]];
    } else {
        [Constants debug:@2 withContent:@"ListDict Saved"];
    }
}


-(NSMutableDictionary*) loadFriendListDatabase {
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:@"fList.dasq"];
    [Constants debug:@1 withContent:[NSString stringWithFormat:@"Filepath: %@", filePath]];
    
    /*
     //----- LIST ALL FILES -----
     CLS_LOG(@"LISTING ALL FILES FOUND");
     
     int Count;
     NSArray *directoryContent = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentsDirectory error:NULL];
     for (Count = 0; Count < (int)[directoryContent count]; Count++)
     {
     CLS_LOG(@"File %d: %@", (Count + 1), [directoryContent objectAtIndex:Count]);
     }
     */
    
    
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        // if the file exists, then load it
        
        [Constants debug:@1 withContent:[NSString stringWithFormat:@"Filepath: %@", filePath]];
        [Constants debug:@1 withContent:[NSString stringWithFormat:@"file exists at the path!"]];
        
        NSMutableDictionary* fListDict = [NSMutableDictionary alloc];
        
        fListDict = [NSKeyedUnarchiver unarchiveObjectWithFile:filePath];
        NSAssert(fListDict, @"unarchiveObjectWithFile failed");
        
        return fListDict;
        
    } else {
        
        [Constants debug:@1 withContent:@"file path does not exist, nothing to load"];
        
        NSMutableDictionary* empty = [[NSMutableDictionary alloc] init];

        return empty;
    }
}


@end
