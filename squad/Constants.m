//
//  Constants.m
//
//  Created by Ian Thomas on 7/15/15.
//
//

//  Copyright © 2017 Geodex Systems
//  All Rights Reserved.

#import <Foundation/Foundation.h>
#import <Crashlytics/Crashlytics.h>
//#import "AppDelegate.h"

#import "Constants.h"
//#import <Parse.h>
#include <sys/types.h>
#include <sys/sysctl.h>

static int methodCallCount = 0;
static NSString* theLog;
static NSString* idInfo;


@implementation Constants


+(void) debug: (NSNumber*) level withContent:(NSString*) content {
    
    NSInteger temp = debugLvl;
    if (level.integerValue >= temp) {
        CLS_LOG(@"%@", content);
        // Level 3 Very Litte (Warnings Only)
        // Level 2 Some (Debug)
        // Level 1 Everything (Verbose)
    }
    
    if (theLog == nil) {
        theLog = content;
    } else {
        theLog = [theLog stringByAppendingString:[NSString stringWithFormat:@"%@\n", content]];
    }
    
    idInfo = [[NSUserDefaults standardUserDefaults] objectForKey:kAppIDNumber];
    if ([idInfo isEqualToString:@""]) {
        
        NSNumber * randNumber = [NSNumber numberWithFloat: (arc4random()%10000000)+1];
        idInfo = [NSString stringWithFormat:@"%i", randNumber.intValue];
        
        [[NSUserDefaults standardUserDefaults] setObject:idInfo forKey:kAppIDNumber];
    }
}


+(NSString *) platform {
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *machine = malloc(size);
    sysctlbyname("hw.machine", machine, &size, NULL, 0);
    NSString *platform = [NSString stringWithUTF8String:machine];
    free(machine);
    return platform;
}


+(void)makeErrorReportWithDescription:(NSString*) theDescription {

   // FIRDatabaseReference *usersRef= [[[FIRDatabase database] reference] child:@"users"];

    FIRDatabaseReference *errorDir = [[[FIRDatabase database] reference] child:@"errorReports"];
    
    NSMutableDictionary *theError = [[NSMutableDictionary alloc] init];
        
    UIDevice *currentDevice = [UIDevice currentDevice];
    theError[@"description"] = theDescription;
    theError[@"AppVersion"] = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    theError[@"BuildNumber"] = [[[NSBundle mainBundle] infoDictionary] valueForKey:@"CFBuildNumber"];
    theError[@"Device_Type"] = [currentDevice model];
    theError[@"System_Version"] = [currentDevice systemVersion];
    theError[@"platform"] = [self platform];

   // AppDelegate *theAppDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
#if DEBUG == 1
    theError[@"is_DeveloperViaDebug"] = @YES;
#else
    theError[@"is_DeveloperViaDebug"] = @NO;
#endif

    theError [@"callsToServer"] = [NSNumber numberWithInt:[self getMethodCallCount]];
    
    theError[@"debugLog"] = theLog;

    theError[@"idInfo"] = [[NSUserDefaults standardUserDefaults] objectForKey:kAppIDNumber];
    
    theError[@"idOfGenfenceDeviceIsIn"] = [[NSUserDefaults standardUserDefaults] objectForKey:kidOfGenfenceDeviceIsIn];
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kOnDuty]) {
        theError[@"onDuty"] = @YES;
    } else {
        theError[@"onDuty"] = @NO;
    }
    
    
    theError[@"docentUserId"] = [[NSUserDefaults standardUserDefaults] objectForKey:kDocentUserId];
    theError[@"numTimesAppLaunched"] = [[NSUserDefaults standardUserDefaults] objectForKey:kNumLaunchesKey];
    
    
    UIApplicationState state = [[UIApplication sharedApplication] applicationState];
    if (state == UIApplicationStateBackground) {
        theError[@"UIApplicationStateCurrently"] = @"UIApplicationStateBackground";
    } else if (state == UIApplicationStateInactive) {
        theError[@"UIApplicationStateCurrently"] = @"UIApplicationStateInactive";
    } else if (state == UIApplicationStateActive) {
        theError[@"UIApplicationStateCurrently"] = @"UIApplicationStateActive";
    }
    
    [Constants debug:@3 withContent:@"Attempting to Send Error Report"];

    [[errorDir childByAutoId] setValue:theError withCompletionBlock:^(NSError * error, FIRDatabaseReference * ref) {
        
        if (!error) {
            [Constants debug:@2 withContent:@"Error Report Successfully Sent"];
        } else {
            [Constants debug:@3 withContent:@"ERROR: Failed to send Error Report"];
            [Constants makeErrorReportWithDescription:error.localizedDescription];
        }
    }];
}


+(void)incrementMethodCallCount {
    methodCallCount ++;
}

+(int)getMethodCallCount {
    return methodCallCount;
}
/*
+(NSMutableDictionary*)storeMessageLocally:(PFObject*)message {
    NSArray * allKeys = [message allKeys];
    NSMutableDictionary * retDict = [[NSMutableDictionary alloc] init];
    
    for (NSString * key in allKeys) {
        // store only the parts we need
        if ([key isEqualToString:@"title"] == YES ||
            [key isEqualToString:@"lat"] == YES ||
            [key isEqualToString:@"lon"] == YES ||
            [key isEqualToString:@"radius"] == YES ||
            [key isEqualToString:@"uniqueId"] == YES ||
            [key isEqualToString:@"name"] == YES || // used the profile viewer
            [key isEqualToString:@"targetNumber"] == YES ||
            [key isEqualToString:@"enabled"] == YES ||
            [key isEqualToString:@"websiteText"] == YES ||
            [key isEqualToString:@"publiclyVisible"] == YES ||
            [key isEqualToString:@"ownedBy"] == YES ||
            [key isEqualToString:@"theDescription"] == YES ||
            [key isEqualToString:@"dateCreated"] == YES ||
            [key isEqualToString:@"dateUpdated"] == YES ||
            [key isEqualToString:@"addEdit"] == YES ||
            [key isEqualToString:@"ownedByUserID"] == YES ||
            [key isEqualToString:@"bannerImage"] == YES ||
            [key isEqualToString:@"lineOne"] == YES ||
            [key isEqualToString:@"lineTwo"] == YES ||
            [key isEqualToString:@"lineThree"] == YES
            )
        {
            [retDict setObject:[message objectForKey:key] forKey:key];
        }
    }
    return retDict;
}
*/

/*
+(Firebase*) firebasePath {
    return [[Firebase alloc] initWithUrl:@"https://flock-to-unlock.firebaseio.com"];
}


+(Firebase*) firebasePathGeofences {
    return [[Constants firebasePath] childByAppendingPath:@"geofences"];
}
*/

+(UIColor*)flockGreen {
    return [UIColor colorWithRed:0.29 green:0.78 blue:0.69 alpha:1.0];
}


+(UIColor*)flockOrange {
    return [UIColor colorWithRed:0.93 green:0.51 blue:0.23 alpha:1.0];
}


+(NSDateFormatter*) internetTimeDateFormatter {

    NSDateFormatter* formatter  = [[NSDateFormatter alloc] init];
    
    // these two lines solve an insane bug: one that causee the all the dates and times to fail if the date is in 24 hour time while the device is in 12 hour time
    [formatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]];
    [formatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"];

    return formatter;
}


// coppied from the app delegate
+(BOOL) shouldDisplayGeofence:(NSMutableDictionary*)attraction {
    
    NSString* userId = [[NSUserDefaults standardUserDefaults] objectForKey:kDocentUserId];
    
  //  NSString* ownedbyuserId = attraction[@"ownedByUserId"];
    
    if ([attraction[@"enabled"] boolValue] == YES && [attraction[@"publiclyVisible"] boolValue] == YES) {
        return YES;
    } else if ([attraction[@"ownedByUserID"] isEqualToString:userId] && [attraction[@"enabled"] boolValue] == YES) {
        return YES;
    } else {
        return NO;
    }
}


@end


