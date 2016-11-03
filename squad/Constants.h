//
//  Constants.h
//  nimbustest
//
//  Created by Ian Thomas on 7/1/15.
//  Copyright (c) 2015 Geodex. All rights reserved.
//

#import <Firebase.h>

#ifndef nimbustest_Constants_h
#define nimbustest_Constants_h


#define IS_IPAD (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
#define IS_IPHONE (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
#define IS_IPHONE_5 (IS_IPHONE && [[UIScreen mainScreen] bounds].size.height == 568.0f)
#define IS_RETINA ([[UIScreen mainScreen] scale] == 2.0f)

#define kauto_crash_reporting @"auto_crash_reporting"
#define kauto_anonymous_stats @"auto_anonymous_stats"

#define kVibration_enabled @"vibration_enabled"
#define kgeofenceEditAccess @"geofenceEditAccess"

#define knearby_flock_alert @"nearby_flock_alert"

#define kidOfGenfenceDeviceIsIn @"idOfGenfenceDeviceIsIn"
#define kOnDuty @"onDuty"
#define kDocentUserId @"docentUserId"
#define kNumLaunchesKey @"numTimesAppLaunched"

#define kAppIDNumber @"appIDNumber"


#warning change the following before release
#define debugLvl 3
// Level 1 Everything (Verbose)
// Level 2 Some (Debug)
// Level 3 Very Litte (Warnings)

#endif


@interface Constants: NSObject

+(void) debug: (NSNumber*) level withContent:(NSString*) content;
+(void)makeErrorReportWithDescription:(NSString*) theDescription;
+(NSString *) platform;

+(void)incrementMethodCallCount;
+(int)getMethodCallCount;

//+(Firebase*) firebasePath;
//+(Firebase*) firebasePathGeofences;

+(UIColor*)flockGreen;
+(UIColor*)flockOrange;

+(NSDateFormatter*) internetTimeDateFormatter;

+(BOOL) shouldDisplayGeofence:(NSMutableDictionary*)attraction;

@end
