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
//#import <FBSDKCoreKit/FBSDKCoreKit.h>
//#import <FBSDKLoginKit/FBSDKLoginKit.h>
#import "SystemStatusViewController.h"
#import <AudioToolbox/AudioToolbox.h>
#import "TutViewController.h"

#import <squad-Swift.h>

@interface AppDelegate ()
@property (nonatomic, assign) BOOL sendCheckInTimes;
//@property (nonatomic, assign) BOOL hasRunDoubleCheck;

@property (nonatomic, assign) BOOL deviceIsInGeofenceViaManual;
@property (nonatomic, assign) BOOL showingNearbyAlertview;


@property (nonatomic, strong) NSNumber *lowishAccuracyThreshold;
@property (nonatomic, strong) NSNumber *geofenceCutoffDistanceForAlert;
//@property (nonatomic, strong) NSNumber *maxDistanceFromGeofence;

@property (nonatomic, strong) NSDate *dateLowAccuracyAlertWasShown;

@property (nonatomic, strong) NSMutableArray *colA;
@property (nonatomic, strong) NSMutableArray *colB;
@property (nonatomic, strong) NSMutableArray *colC;

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
    
   // [self updateNumLaunches];
    

    
#warning for the beta this has been disabled
  //  if ([defaults boolForKey:kauto_crash_reporting]) {
        [Fabric with:@[[Crashlytics class]]];
    
 //   [[Fabric sharedSDK] setDebug: YES];

    
  //  }
    

    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sendCurrentLocation:) name:@"getCurrentLocation" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(requestLocation:) name:@"requestLocation" object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(makeProfileAndGoOnDuty:) name:@"makeProfile" object:nil];

    
    
    
    
    
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
    
    [self setupFirebaseVars];
    
    [self setupTabBar];
    
//  [FBSDKLoginButton class];
    
    [self generateCityList];
    
    [self setupSwiftAppDelegate];
    
    [Constants debug:@1 withContent:@"Starting App Done"];

    return YES;
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

    if ([self docentProfileEmpty] == NO) {
    
    FIRDatabaseReference *friendRequests= [[[[[FIRDatabase database] reference] child:@"users"]child:[[NSUserDefaults standardUserDefaults] objectForKey:kDocentUserId]] child:@"friendRequests"];
    
        [friendRequests observeEventType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
            [self updateBadgeIcon:snapshot];
        }];
    }
}


-(void)updateBadgeIcon:(FIRDataSnapshot*) snapshot {

    UITabBarController *tabBarController = (UITabBarController *)self.window.rootViewController;
    UITabBarItem * friendRequestTabBarItem = [tabBarController.tabBar.items objectAtIndex:3];
    
    if (snapshot.value != [NSNull null]) {
        NSDictionary *friendRequestsDict = snapshot.value;
        
        if (friendRequestsDict.count > 0) {
            friendRequestTabBarItem.badgeValue = [NSString stringWithFormat:@"%lu", (unsigned long)friendRequestsDict.count];
        } else if (friendRequestsDict.count == 0) {
            friendRequestTabBarItem.badgeValue = nil;
        }
    } else if (friendRequestTabBarItem.badgeValue != nil) {
        friendRequestTabBarItem.badgeValue = nil;
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

            
            // we now only show the map view first, reguardless of the users possition
            //[self decideWhatTabToShow:_currentLocation];
            
        } else {
            
            _currentLocation = [locations objectAtIndex:0];
        
            if ([self isAccuracyUnacceptablyLow:_currentLocation]) {
                [self showLowAccuracyAlert];
                
            } else {
                [self postUserLocation:_currentLocation];
            }
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
    
    [coorRef setValue: locDic withCompletionBlock: ^(NSError *error, FIRDatabaseReference *ref) {
        if (error) {
            [Constants debug:@3 withContent:@"ERROR: Firebase telling the internet that the user is there."];
            [Constants makeErrorReportWithDescription:error.localizedDescription];
        } else {
            [Constants debug:@2 withContent:@"Successfully added user to the firebase geofence."];

            
           // [self postInitialFirebaseAnalyticsWithAutomatic:automatic];
        }
     }];
}


-(BOOL) shouldShowLowAccuracyAlert {
    if (_showingNearbyAlertview == YES) {
        return NO;
    } else {
        
        /*
        if ([self isDeviceInGeofence]) {
            return NO;
            
        } else {
         */
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





-(void) showLowAccuracyAlert {
    [Constants debug:@1 withContent:@"Showing Very Poor Accuracy Alert View"];

    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Poor Accuracy"
                                                                   message:@"Your location could not be determined with sufficient accuracy. Please re-launch the App and try again."
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {}];
    
    [alert addAction:defaultAction];
    
    [self.window.rootViewController presentViewController:alert animated:YES completion:nil];
    
    [Constants debug:@3 withContent:@"horizontal accuracy too low!"];
}


-(BOOL) isAccuracyUnacceptablyLow:(CLLocation*)theLocation {
    
    if (_currentLocation.horizontalAccuracy > 100000 ||
        theLocation.verticalAccuracy > 100000) {
        return YES;
        
    } else {
        return NO;
    }
}


-(BOOL) isAccuracyLowish:(CLLocation*)theLocation {
    
    // these make all the comparisons in "long format"
    NSNumber * horizAcc = [NSNumber numberWithDouble:theLocation.horizontalAccuracy];
    NSNumber * verticAcc = [NSNumber numberWithDouble:theLocation.verticalAccuracy];

    [Constants debug:@1 withContent:[NSString stringWithFormat:@"Current Horizontal Accuracy: %ld, with Threshold: %ld", horizAcc.longValue, _lowishAccuracyThreshold.longValue]];
    
    if (horizAcc.longValue > _lowishAccuracyThreshold.longValue ||
        verticAcc.longValue > _lowishAccuracyThreshold.longValue) {
        return YES;
    } else {
        return NO;
    }
}


-(BOOL) isGeofenceNew:(NSString*)theGeofenceUniqueId {
   
    if ([_currentGeofenceList objectForKey:theGeofenceUniqueId] == NULL) {
        // then the geofence is new
        return YES;
    } else {
        return NO;
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


-(CLCircularRegion*)getTheRegionById:(NSString*) theId {

    NSSet *setOfRegions = [self.locationManager monitoredRegions];
    
    for (CLCircularRegion *theRegion in setOfRegions) {
        
        if([theId isEqualToString:theRegion.identifier]) {
            return theRegion;
        }
    }
    return nil;
}


-(NSDictionary*) getGeofenceById:(NSString*) theId {
    
    NSEnumerator *geofenceEnumerator = [_currentGeofenceList keyEnumerator];
    for (NSString *theKey in geofenceEnumerator) {
        NSMutableDictionary *theGeofence = [_currentGeofenceList objectForKey:theKey];
     
        if([theId isEqualToString:theGeofence[@"uniqueId"]]) {
            return theGeofence;
        }
    }
    return nil;
}


/*
-(void) tellInternetDocentIsThereFirebase:(NSString*) uniqueId wasAutomatic:(BOOL) automatic {
    
    [Constants debug:@3 withContent:[NSString stringWithFormat:@"FIREBASE: Calling the Internet with an updated location, the person is in a new geofence, in mode: %@", automatic ? @"YES" : @"NO" ]];
    
    
    Firebase *geofecneRef = [[Constants firebasePath] childByAppendingPath: @"geofences"];
    Firebase *uniqueIdRef = [geofecneRef childByAppendingPath:uniqueId];
    Firebase *peoplePresent = [uniqueIdRef childByAppendingPath:@"peoplePresent"];
    Firebase *thePerson = [peoplePresent childByAppendingPath: [[NSUserDefaults standardUserDefaults] objectForKey:kDocentUserId]];
    
    
    [thePerson setValue:@YES  withCompletionBlock:^(NSError *error, Firebase *ref) {
        if (error) {
            [Constants debug:@3 withContent:@"ERROR: Firebase telling the internet that the user is there."];
            [Constants makeErrorReportWithDescription:error.localizedDescription];
        } else {
            [Constants debug:@2 withContent:@"Successfully added user to the firebase geofence."];

            _withinAGeofence = YES;
            
            if ([[NSUserDefaults standardUserDefaults] boolForKey:kVibration_enabled]) {
                AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
            }
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"showSlideUpView" object:uniqueId];
    
            [self postInitialFirebaseAnalyticsWithAutomatic:automatic];
            
            if (uniqueId != nil) {
                [self postAnswersAnalytics:uniqueId wasAutomatic:automatic];
            }
        }
    }];
}
*/

/*
-(void) postInitialFirebaseAnalyticsWithAutomatic:(BOOL)automatic {
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kauto_anonymous_stats]) {
        

        [Constants debug:@3 withContent:[NSString stringWithFormat:@"FIREBASE: posting initial firebase analytics, in mode: %@", automatic ? @"YES" : @"NO"]];
        
        Firebase *geofenceVisitDirectory = [[Constants firebasePath] childByAppendingPath:@"geofenceVisit"];
        
        Firebase *postDirectory = [geofenceVisitDirectory childByAutoId];
        
        NSMutableDictionary *geofenceVisit = [[NSMutableDictionary alloc] init];
        
        Firebase *geofenceDirectory = [Constants firebasePathGeofences];
        Firebase *theGeofence = [geofenceDirectory childByAppendingPath:[[NSUserDefaults standardUserDefaults] objectForKey:kidOfGenfenceDeviceIsIn]];
        Firebase *geofenceTitle = [theGeofence childByAppendingPath:@"title"];

        [geofenceTitle observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *title) {
            geofenceVisit[@"geofenceTitle"] = title.value;
            
            
            Firebase *usersDirectory = [[Constants firebasePath] childByAppendingPath:@"users"];
            Firebase *theUserPath = [usersDirectory childByAppendingPath:[[NSUserDefaults standardUserDefaults] objectForKey:kDocentUserId]];
            Firebase *personName = [theUserPath childByAppendingPath:@"name"];
            
#warning this above line is straenge, does it work??
            
            [personName observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *name) {
            
                geofenceVisit[@"personName"] = name.value;
                                
                geofenceVisit[@"checkInTime"] = [[Constants internetTimeDateFormatter] stringFromDate:[NSDate date]];
                
                UIDevice *myDevice = [UIDevice currentDevice];
                [[UIDevice currentDevice] setBatteryMonitoringEnabled:YES];
                //double batLeft = (float)[myDevice batteryLevel];
                NSNumber *batteryLevel = [NSNumber numberWithFloat: [myDevice batteryLevel]];
                geofenceVisit[@"batteryLevelUponCheckIn"] = batteryLevel;
                
                
                geofenceVisit[@"App_Version"] = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
                geofenceVisit[@"Build_Number"] = [[[NSBundle mainBundle] infoDictionary] valueForKey:@"CFBuildNumber"];
                geofenceVisit[@"Device_Type"] = [myDevice model];
                geofenceVisit[@"System_Version"] = [myDevice systemVersion];
                geofenceVisit[@"Country"] = [[NSLocale currentLocale] localeIdentifier];
                geofenceVisit[@"Num_Launches"] = [NSString stringWithFormat:@"%ld", (long)[[NSUserDefaults standardUserDefaults] integerForKey:kNumLaunchesKey]];
                geofenceVisit[@"DeviceName"] = [Constants platform];
                
                
            #if DEBUG == 1
                geofenceVisit[@"is_DeveloperViaDebug"] = @YES;
            #else
                geofenceVisit[@"is_DeveloperViaDebug"] = @NO;
            #endif
                
                
                UIApplicationState state = [[UIApplication sharedApplication] applicationState];
                if (state == UIApplicationStateBackground) {
                    geofenceVisit[@"UIApplicationStateUponEntrance"] = @"UIApplicationStateBackground";
                } else if (state == UIApplicationStateInactive) {
                    geofenceVisit[@"UIApplicationStateUponEntrance"] = @"UIApplicationStateInactive";
                } else if (state == UIApplicationStateActive) {
                    geofenceVisit[@"UIApplicationStateUponEntrance"] = @"UIApplicationStateActive";
                }
                
                
                geofenceVisit[@"idOfGenfenceDeviceIsIn"] = [[NSUserDefaults standardUserDefaults] objectForKey:kidOfGenfenceDeviceIsIn];
                
                if ([[NSUserDefaults standardUserDefaults] boolForKey:kOnDuty]) {
                    geofenceVisit[@"onDuty"] = @YES;
                } else {
                    geofenceVisit[@"onDuty"] = @NO;
                }
                
                geofenceVisit[@"personUserId"] = [[NSUserDefaults standardUserDefaults] objectForKey:kDocentUserId];
                
                geofenceVisit[@"appIDNumber"] = [[NSUserDefaults standardUserDefaults] objectForKey:kAppIDNumber];
                

                
                if (automatic) {
                    geofenceVisit[@"wasAutomatic"] = @YES;
                } else {
                    geofenceVisit[@"wasAutomatic"] = @NO;
                }
                
                
                geofenceVisit[@"inProgress"] = @YES;
                
                
                [postDirectory setValue:geofenceVisit  withCompletionBlock:^(NSError *error, Firebase *ref) {
                    if (error) {
                        [Constants debug:@3 withContent:@"ERROR: Firebase posting of initial visit analytics."];
                        [Constants makeErrorReportWithDescription:error.localizedDescription];
                    } else {
                        [Constants debug:@3 withContent:@"Successfully firebase posted initial visit analytics."];

                        _geofenceVisitChildId = postDirectory.key;
                    }
                }];
            }];
        }];
    }
}
*/


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
    /*
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {
                                                          
                                                              
                                                          
                                                          }];
    
     */
    
    
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
    
  //  [self updateGeofencesFirebase];

//#warning remove me from shipping verison
  //  [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(countParseCalls) userInfo:nil repeats:YES];
    
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


#warning facebook needed this before...
/*
- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
    return [[FBSDKApplicationDelegate sharedInstance] application:application
                                                          openURL:url
                                                sourceApplication:sourceApplication
                                                       annotation:annotation];
}*/

-(void) makeProfileAndGoOnDuty:(NSNotification*) theNotification {
    
    [[NSUserDefaults standardUserDefaults] setObject:theNotification.object forKey:kDocentUserId];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kOnDuty];
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



/*
- (void)application:(UIApplication *)application
didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
        // Store the deviceToken in the current installation and save it to Parse.
        
        // this is why the notificaont thigns needs to be last. to send a push notificaiotn we need the device token, and a user acount, but we didn;t make the user account until after we ask for a notifcaiton!
        
        PFInstallation *currentInstallation = [PFInstallation currentInstallation];
        if ([PFUser currentUser] != nil)
        {
            currentInstallation[@"currentUser"]=[PFUser currentUser];
        }
        else {
            [currentInstallation removeObjectForKey:@"currentUser"];
        }
        
        [currentInstallation setDeviceTokenFromData:deviceToken];
        [currentInstallation saveInBackground];
}
*/


-(void) generateCityList {
    
    _colA = [NSMutableArray array];
    _colB = [NSMutableArray array];
    _colC = [NSMutableArray array];
    NSString *fileContents = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"cities15000" ofType:@"csv"] encoding:NSUTF8StringEncoding error:nil];

    
   // NSString* fileContents = [NSString stringWithContentsOfURL:@"cities150000.csv"];
    NSArray* rows = [fileContents componentsSeparatedByString:@"\n"];
    for (NSString *row in rows){
        NSArray* columns = [row componentsSeparatedByString:@","];
        [_colA addObject:columns[0]];
        [_colB addObject:columns[1]];
        [_colC addObject:columns[2]];
    }

}


-(NSString*)findNearestLargeCity:(CLLocation*) theGoalLocation {
    
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
    return _colA[index];
}





@end
