//
//  AppDelegate.h
//  beaconList
//
//  Created by Ian Thomas on 11/2/15.
//  Copyright © 2015 Geodex. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
//#import <Parse/Parse.h>
#import "Reachability.h"
//#import <Firebase/Firebase.h>

@import Firebase;

@class SwiftAppDelegate;
@class individualFriend;


@interface AppDelegate : UIResponder <UIApplicationDelegate, CLLocationManagerDelegate>

@property (strong, nonatomic) UIWindow *window;
//@property (strong, nonatomic) NSArray* theSourcesArray;
//@property (strong, nonatomic) NSString* theDateInfoWasPulledFromServer;
//@property (nonatomic) BOOL requestInProgress;


@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) CLLocation *currentLocation;
//@property (nonatomic, strong) NSMutableDictionary *currentGeofenceList;
@property (nonatomic) NSDate* userLocaitonLastUpdated;

//@property (nonatomic, assign) BOOL withinAGeofence;
//@property (nonatomic, strong) NSString* idOfGenfenceDeviceIsIn;

//@property (nonatomic, assign) BOOL isDeveloperManual;

@property (nonatomic, assign) UIBackgroundTaskIdentifier backgroundTaskFirebase;


//@property (nonatomic, assign) BOOL geofencesSucessfulyCalledFromNet;

//@property (nonatomic, strong) NSString* geofenceVisitChildId;


@property (nonatomic, strong) NSArray<individualFriend *> *friendList;
//@property (nonatomic, strong) NSArray *friendList2;

//@property (nonatomic, strong) SwiftAppDelegate *swiftAppDelegate;



-(NSString*)findNearestLargeCity:(CLLocation*) theGoalLocation;


@end

