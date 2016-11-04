//
//  mapViewViewController.m
//  beaconList
//
//  Created by Ian Thomas on 11/3/15.
//  Copyright © 2015 Geodex. All rights reserved.
//


#import "PVAttractionAnnotation.h"
#import "PVAttractionAnnotationView.h"
//#import "PVCharacter.h"
#import "mapViewViewController.h"

#import "Constants.h"

#import "QuartzCore/QuartzCore.h"
#import "Reachability.h"

#import "TutViewController.h"

#import <Crashlytics/Crashlytics.h>


@interface mapViewViewController ()

//@property (nonatomic, strong) PVPark *park;
@property (nonatomic, strong) NSMutableArray *selectedOptions;
@property (weak, nonatomic) IBOutlet MKMapView *theMapView;


@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@property (nonatomic, assign) BOOL addedPinsToMap;

@property (assign, nonatomic) BOOL modifyingMap;

@property (nonatomic, assign) BOOL updateInProgress;

@property (nonatomic, strong) NSMutableArray* theGeofencesBeingAdded;


@property (strong, nonatomic) IBOutlet UIView *showBeaconView;
@property (weak, nonatomic) IBOutlet UILabel *peoplePresentLabel;
@property (weak, nonatomic) IBOutlet UILabel *geofenceTitleLabel;
@property (strong, nonatomic) NSString* showBeaconViewUniqueId;
@property (weak, nonatomic) IBOutlet UILabel *lineOneLabel;
@property (weak, nonatomic) IBOutlet UILabel *expiresLabel;

@property (nonatomic, assign) BOOL switchingDirectly;
@property (weak, nonatomic) IBOutlet UIImageView *pieChartPicture;



@property (nonatomic, strong) NSNumber* numberOfPeoplePresent;
@property (nonatomic, strong) NSNumber* targetNumber;


@property (nonatomic, assign) BOOL targetNumberReady;
@property (nonatomic, assign) BOOL currentNumberReady;


@property (nonatomic, assign) BOOL updatingAPreexistingAnnotation;

@property (nonatomic, strong) NSTimer *dealEndsTimer;
@property (weak, nonatomic) IBOutlet UIImageView *arrowImageView;

@property (nonatomic, strong) NSTimer *calledInitialGeofencesTimer;


@property (nonatomic, strong) NSDateFormatter *theExpiresDateFormatter;
@property (nonatomic, strong) NSDateComponentsFormatter *theExpiresComponentsFormatter;


@end


@implementation mapViewViewController

@synthesize activityIndicator, showBeaconView;


-(void) viewWillDisappear:(BOOL)animated {
    [Constants debug:@2 withContent:@"mapViewViewController Disappearing"];
    [super viewWillDisappear:animated];
}

-(void) viewWillAppear:(BOOL)animated {
    [Constants debug:@2 withContent:@"mapViewViewController Appearing"];
    [super viewWillAppear:animated];
}


- (void)viewDidLoad {
    [super viewDidLoad];
        
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addAttractionsPinsNotification:) name:@"currentGeofenceList" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(zoomMap:) name:@"zoomMap" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showSlideUpView:) name:@"showSlideUpView" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hideSlideUpView:) name:@"hideSlideUpView" object:nil];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showTheUserLocation:) name:@"showTheUserLocation" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hideTheUserLocation:) name:@"hideTheUserLocation" object:nil];

    
    
    [Constants debug:@1 withContent:@"mapViewViewController"];
    
    [self setupDateFromatters];
    
    [self initialMapSetup];
    
    [self getInitialLocationAuthStatus];

    [self setupMapGeofences];
   
    [self initialyHideTheDisplayBeaconView];
    
    
    UIBarButtonItem *add = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addNewFriend:)];
    add.tintColor = [UIColor whiteColor];
    
    self.navigationItem.rightBarButtonItem = add;
    
    
    _theGeofencesBeingAdded = [[NSMutableArray alloc] init];
    _updateInProgress = NO;
    _addedPinsToMap = NO;
    _updatingAPreexistingAnnotation = NO;
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showNearishLocationsAlert:) name:@"showNearishLocationsMapView" object:nil];
}


-(IBAction)addNewFriend:(id)sender {

    [self performSegueWithIdentifier:@"addNewFriend" sender:self];
}


-(IBAction)showGeofenceEditor:(id)sender {

    [self performSegueWithIdentifier:@"geofences" sender:self];
}


-(IBAction)showListView:(id)sender {
    [self performSegueWithIdentifier:@"listView" sender:self];
}


-(void) initialMapSetup {

    self.selectedOptions = [NSMutableArray array];
    
    
    [_theMapView setMapType:MKMapTypeStandard];

    
    [_theMapView setRotateEnabled:NO];
    [_theMapView setPitchEnabled:NO];
    
    
    _modifyingMap = NO;
    
    [self loadSelectedOptions];
    
   // self.navigationItem.title = @"Map";
    
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    [self.navigationController.navigationBar
     setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor whiteColor]}];

    self.navigationItem.title = @"Squad";
    
    // displays a logo
    //self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"title"]];
}


-(void)zoomMapNonNotif {

/*
    MKCoordinateRegion mapRegion;
    mapRegion.center = CLLocationCoordinate2DMake(41.828794, -71.400701);
    
    mapRegion.span.latitudeDelta = 0.003;
    mapRegion.span.longitudeDelta = 0.003;
    
    
    [_theMapView setRegion:mapRegion animated:YES];
    */
    
    // old way, when the app was actauly in use, we zoomed to the users locaitons, now we zoom to the sight to show it off
    
     
    if (_theMapView.userLocation.location) {
        
        [Constants debug:@1 withContent:@"Found user locaiton"];

        MKCoordinateRegion mapRegion;
        mapRegion.center = _theMapView.userLocation.coordinate;
        mapRegion.span.latitudeDelta = 0.003;
        mapRegion.span.longitudeDelta = 0.003;
        
        
        [_theMapView setRegion:mapRegion animated:YES];
        
    } else {
        [Constants debug:@1 withContent:@"Trying to find user locaiton, waiting another second to try again"];
        [NSTimer scheduledTimerWithTimeInterval:0.7 target:self selector:@selector(zoomMap:) userInfo:nil repeats:NO];
    }
    
}


-(void) zoomMap:(NSNotification*) notification {
    
    [self zoomMapNonNotif];
}

#warning rename me to a new method

-(void) setupMapGeofences {
    
    Reachability *networkReachability = [Reachability reachabilityForInternetConnection];
    NetworkStatus networkStatus = [networkReachability currentReachabilityStatus];

    switch (networkStatus)
    {
        case NotReachable:        {
            [Constants debug:@3 withContent:@"No internet Connection"];
            
            [self showNoInternetAlert];
            break;
        }
        case ReachableViaWWAN:        {
            [Constants debug:@1 withContent:@"There IS internet via WAN (cell) connection"];
#warning change me to a new method

            //[self callForGeofecnes];
            break;
        }
        case ReachableViaWiFi:        {
            [Constants debug:@1 withContent:@"There IS internet via Wifi connection"];
#warning change me to a new method
            //[self callForGeofecnes];
            break;
        }
    }
}


-(void) showNoInternetAlert {
    
    [Constants debug:@1 withContent:@"Showing No Internet Alert View - Map View"];

    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"No Internet"
                                                                   message:@"Please connect to the internet to view the map."
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* tryAgainAction = [UIAlertAction actionWithTitle:@"Try Again" style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction * action) {
                                                               
                                                                [NSTimer scheduledTimerWithTimeInterval:3.0 target:self selector:@selector(setupMapGeofences) userInfo:nil repeats:NO];

                                                           }];
    [alert addAction:tryAgainAction];

    [alert.view setNeedsLayout];
    [alert.view layoutIfNeeded];
    
    
    [self presentViewController:alert animated:YES completion:nil];
}


-(void)setupLoadingView {
    
    if (_activityView.isAnimating == NO) {
    // else, this method has been called before. lets not double call it
    
    
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    _loadingView = [[UIView alloc] initWithFrame:CGRectMake(screenRect.size.width/2 - 85, screenRect.size.height/2 - 85, 170, 170)];
        _loadingView.backgroundColor = [UIColor colorWithRed:0.19 green:0.68 blue:0.59 alpha:0.9];
        
        
    _loadingView.clipsToBounds = YES;
    _loadingView.layer.cornerRadius = 10.0;
    
    _activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    _activityView.frame = CGRectMake(65, 40, _activityView.bounds.size.width, _activityView.bounds.size.height);
    [_loadingView addSubview:_activityView];
    
    _loadingLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 115, 130, 22)];
    _loadingLabel.backgroundColor = [UIColor clearColor];
    _loadingLabel.textColor = [UIColor whiteColor];
    _loadingLabel.adjustsFontSizeToFitWidth = YES;
    _loadingLabel.textAlignment = NSTextAlignmentCenter;
    [_lineOneLabel setFont: [UIFont fontWithName:@"System" size:13.0f]];
    _loadingLabel.text = @"Loading Map";
    [_loadingView addSubview:_loadingLabel];
    
    [self.view addSubview:_loadingView];
    [_activityView startAnimating];
    
    }
}


-(NSString*) stringAboutNumberOfFlockers:(NSNumber*)currentNumberOfPeople :(NSNumber*)currentTargetValue {
    
    return [NSString stringWithFormat:@"%@ of %@ people", currentNumberOfPeople.stringValue, currentTargetValue.stringValue];
}


-(void) removeGeofenceOverlay:(NSString*) uniqueId {

    for (id <MKOverlay> theOverlay  in _theMapView.overlays) {
        if ([theOverlay.subtitle isEqualToString:uniqueId]) {
            [_theMapView removeOverlay:theOverlay];
        }
    }
}


-(BOOL) isThisGeofenceDisplayedAsAnAnnotation:(NSString*) uniqueId {
    
    if ([self getAnnotationViaUniqueId:uniqueId] == nil) {
        return NO;
    } else {
        return YES;
    }
}


-(PVAttractionAnnotation*) getAnnotationViaUniqueId:(NSString*) uniqueId{

    for (PVAttractionAnnotation* theAnnotation in _theMapView.annotations) {
        if ([theAnnotation isKindOfClass:[MKUserLocation class]] == NO) {
            if ([theAnnotation.uniqueId isEqualToString:uniqueId]) {
                return theAnnotation;
            }
        }
    }
    return nil;
}

/*
- (MKOverlayRenderer *)mapView:(MKMapView *)map viewForOverlay:(id <MKOverlay>)overlay {
    MKCircleRenderer *circleView = [[MKCircleRenderer alloc] initWithCircle:overlay];
    circleView.strokeColor = [UIColor whiteColor];
    circleView.lineWidth = 0.6;
    circleView.fillColor = [[self flockGreen]colorWithAlphaComponent:1.0];
    
    return circleView;
}*/


- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay {
  
     if ([overlay isKindOfClass:[MKCircle class]]) {
    
         MKCircleRenderer *circleView = [[MKCircleRenderer alloc] initWithCircle:overlay];
         circleView.strokeColor = [UIColor whiteColor];
         circleView.lineWidth = 0.8;
         circleView.fillColor = [[Constants flockGreen]colorWithAlphaComponent:0.4];
         
         return circleView;
     }
    
    return nil;
}


- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    
   // [Constants debug:@1 withContent:@"viewForAnnotation"];

    if (annotation != nil) {
        
    if ([annotation isKindOfClass:[MKUserLocation class]]) {
        // this appears to alwasy be called last of all the annotations
        
            return nil;
        } else if ([annotation isKindOfClass:[PVAttractionAnnotation class]]){
        
            PVAttractionAnnotationView *annotationView = [[PVAttractionAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"Attraction"];
            annotationView.canShowCallout = NO;

            return annotationView;
            
        } else {
            return nil;
        }
    } else {
        return nil;
    }
}


- (void)mapViewDidFinishRenderingMap:(MKMapView *)mapView fullyRendered:(BOOL)fullyRendered {

    [_activityView stopAnimating];

    [_loadingView setHidden:YES];
}
/*
-(void)myFunctWrapper:(NSArray *)myArgs {
    [self mapView:[myArgs objectAtIndex:0]annotationView:[myArgs objectAtIndex:1] calloutAccessoryControlTapped:[myArgs objectAtIndex:2]];
    
   // [self myFunct:[myArgs objectAtIndex:0] andArg:[myArgs objectAtIndex:1] andYetAnotherArg:[myArgs objectAtIndex:2]];
}
*/


-(void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(nonnull MKAnnotationView *)view {
    
    if (showBeaconView.hidden == NO) {
        
        if (_updatingAPreexistingAnnotation == NO) {
            _switchingDirectly = NO;
            [self performSelector:@selector(handleHidingTheAnnotation) withObject:nil afterDelay:0.05];
        } else {
        // dont hide the geofecne detail slide up view
        }
    }
}

-(void)handleHidingTheAnnotation {
    
    if (_switchingDirectly) {
        // do nothing
    } else  {
        [self hideDetailedAnnotation:[NSNumber numberWithFloat:0.75]];
        
    }
}


// stupid way of preventin callouts for user locaitons
// #warning make this more effiecint later
/*
- (void)mapView:(MKMapView *)mapView didAddAnnotationViews:(NSArray *)views {
    MKAnnotationView *aV;
    for (aV in views) {
        if ([aV.annotation isKindOfClass:[MKUserLocation class]]) {
            MKAnnotationView* annotationView = aV;
            annotationView.canShowCallout = NO;
//#warning check on 64 bit devices

        }
    }
}*/


-(void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view {

    PVAttractionAnnotation *annotation = view.annotation;
    
    if ([annotation isKindOfClass:[MKUserLocation class]]) {
        
        [Constants debug:@1 withContent:@"Callout Tapped an MK user locaiton class annotation."];
        
        _switchingDirectly = NO;
        
        [self hideDetailedAnnotation:[NSNumber numberWithFloat:0.0]];
        
    } else {

        if (_showBeaconViewUniqueId == NULL) {
            [self showDetailedAnnotation: annotation.uniqueId];
            _switchingDirectly = NO;

        } else {
        
            // switching from one view to another
            if ([annotation.uniqueId isEqualToString:_showBeaconViewUniqueId] == NO) {

                _switchingDirectly = YES;
                
                [self hideDetailedAnnotation:[NSNumber numberWithFloat:0.0]];
                [self performSelector:@selector(showDetailedAnnotation:) withObject:annotation.uniqueId afterDelay:0.05];

            } else {
                _switchingDirectly = NO;

                [self showDetailedAnnotation: annotation.uniqueId];
            }
        }
    }
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    [Constants debug:@1 withContent:@"mapView prepareForSegue"];
    
    if ([[segue identifier] isEqualToString:@"details"]) {
        
        NSString* uniqueId = sender;
        
        UINavigationController *navController = [segue destinationViewController];
        /*
        ProgressViewController *progressView = (ProgressViewController *)([navController viewControllers][0]);
        progressView.geofenceUniqueId = uniqueId;
        */
        if (uniqueId != nil) {
          //  [self viewedDeal: uniqueId];
        }
        
    }  else if ([[segue identifier] isEqualToString:@"geofences"]) {
    
     //   UINavigationController *navController = [segue destinationViewController];
     //   FlockListTableViewController *nextVC = (FlockListTableViewController *)([navController viewControllers][0]);
    } else if ([[segue identifier] isEqualToString: @"addNewFriend"]) {
    
    }
}


- (void)addAttractionsPinsNotification: (NSNotification*) notification {

    // when this called explicitly its for a good reason. for eaxmple the app deleage detected that the master geofence list has changed
    
    
    if (_theMapView.annotations.count > 0) {
        [self.theMapView removeAnnotations:self.theMapView.annotations];
        [self.theMapView removeOverlays:self.theMapView.overlays];
    }
    
    [self addAttractionsPinsMutableArray:notification.object];

}


- (void)addAttractionsPinsMutableArray: (NSMutableDictionary*) geofenceDictionary {
    
    _addedPinsToMap = YES;
    
    NSEnumerator *geofenceEnumerator = [geofenceDictionary keyEnumerator];
    for (NSString *theKey in geofenceEnumerator) {
        
        [self addAttractionPin:[geofenceDictionary objectForKey:theKey]];
    }
    
    if (_loadingView.hidden == NO) {
        [_activityView stopAnimating];
        [_loadingView setHidden:YES];
    }
}


-(void) addAttractionPin: (NSMutableDictionary*) attraction  {

    PVAttractionAnnotation *annotation = [[PVAttractionAnnotation alloc] init];
    
    [self makeAnnotationFromAttraction: attraction withAnnotation:annotation];
}



-(void) makeAnnotationFromAttraction:(NSMutableDictionary*)attraction withAnnotation:(PVAttractionAnnotation*)annotation {

    if ([Constants shouldDisplayGeofence:attraction]) {
    
        NSNumber *lon = attraction[@"lon"];
        NSNumber *lat = attraction[@"lat"];
        annotation.coordinate = CLLocationCoordinate2DMake(lat.floatValue, lon.floatValue);
        
        annotation.uniqueId = attraction[@"uniqueId"];
        annotation.title = attraction[@"title"];
        
        annotation.enabled = [attraction[@"enabled"] boolValue];
        annotation.publiclyVisible = [attraction[@"publiclyVisible"] boolValue];
        
        
        [self.theMapView addAnnotation:annotation];
        [self addCircleOverlaywithGeofence:attraction];
        
        if ([_theGeofencesBeingAdded containsObject:attraction[@"uniqueId"]]) {
            [_theGeofencesBeingAdded removeObject:attraction[@"uniqueId"]];
        }
    }
}


-(void) addCircleOverlaywithGeofence:(NSMutableDictionary*) geofence {

      if ([Constants shouldDisplayGeofence:geofence]) {
          
          NSNumber *lon = geofence[@"lon"];
          NSNumber *lat = geofence[@"lat"];
          NSNumber *radius = geofence[@"radius"];
          CLLocationCoordinate2D geofecneLoc = CLLocationCoordinate2DMake(lat.floatValue, lon.floatValue);
          
          MKCircle *circle = [MKCircle circleWithCenterCoordinate:geofecneLoc radius:[radius doubleValue]];
          circle.subtitle = geofence[@"uniqueId"];
          [self.theMapView addOverlay:circle];
    }
}


-(IBAction)centerUserLocation:(id)sender {
    
    // this checks to see it there is a user location
    if (_theMapView.userLocation.location) {
        [_theMapView setCenterCoordinate:_theMapView.userLocation.coordinate animated:YES];
    } else {
        [self checkLocationAuthStatus];
    }
}


-(void)checkLocationAuthStatus {
    
    switch ([CLLocationManager authorizationStatus]) {
        case kCLAuthorizationStatusAuthorizedAlways:
            [Constants debug:@1 withContent:@"Location Detection is Authorized Always"];
            
            break;
        case kCLAuthorizationStatusAuthorizedWhenInUse:
            [Constants debug:@3 withContent:@"Location Detection Authorized when in use"];
            
            break;
        case kCLAuthorizationStatusDenied:
            [Constants debug:@3 withContent:@"Location Detection Denied"];
            
            [self requestAuthStatus];
            break;
        case kCLAuthorizationStatusNotDetermined:
            [Constants debug:@3 withContent:@"Location Detection Not determined"];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"requestLocationAlways" object:nil];
            
            break;
        case kCLAuthorizationStatusRestricted:
            [Constants debug:@3 withContent:@"Location Detection Restricted"];
            
            [self requestAuthStatus];
            break;
        default:
            break;
    }
}


- (void) requestAuthStatus {
    
    [Constants debug:@1 withContent:@"Showing Request Locaiton status backup Alert View"];
    
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Please Enable Location Services"
                                                                   message:@"To do so:\n1. Tap Settings\n2. Tap Location\n3. Tap Always"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* settings = [UIAlertAction actionWithTitle:@"Open Settings" style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction * action) {
                                                         [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
                                                     }];
    
    UIAlertAction* badAction = [UIAlertAction actionWithTitle:@"Disable this App" style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction * action) {
                                                          
                                                          [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(showBackupAlert) userInfo:nil repeats:NO];
                                                      }];
    [alert addAction:settings];
    [alert addAction:badAction];
    
    [self presentViewController:alert animated:YES completion:nil];
}

// duplicate of the in the app delegate
-(void)showBackupAlert {
    
    [Constants debug:@1 withContent:@"Showing Request Locaiton status backup Alert View - map view backup"];

    UIAlertController* alert2 = [UIAlertController alertControllerWithTitle:@"Are you sure? Without Location Services the App will not function"
                                                                    message:@"Please Enable Location Services.\n1. Tap Settings\n2. Tap Location\n3. Tap Always"
                                                             preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* settings = [UIAlertAction actionWithTitle:@"Open Settings" style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction * action) {
                                                         [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
                                                     }];
    
    UIAlertAction* reallyBadAction = [UIAlertAction actionWithTitle:@"Disable this App" style:UIAlertActionStyleDefault
                                                            handler:^(UIAlertAction * action) {
                                                                
                                                                
                                                                
                                                            }];
    
    [alert2 addAction:settings];
    [alert2 addAction:reallyBadAction];
    
    [self presentViewController:alert2 animated:YES completion:nil];
}


- (void)loadSelectedOptions {
    [self.theMapView removeAnnotations:self.theMapView.annotations];
    [self.theMapView removeOverlays:self.theMapView.overlays];
}




-(void) showNearishLocationsAlert:(NSNotification*) theNotificaiton {
    
    if (self.isViewLoaded && self.view.window) {
        UIAlertController* theAlert = theNotificaiton.object;
        [self presentViewController:theAlert animated:YES completion:nil];
    }
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(void)getInitialLocationAuthStatus {
    
    switch ([CLLocationManager authorizationStatus]) {
        case kCLAuthorizationStatusAuthorizedAlways:
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"zoomMap" object:nil];
            break;
            
        case kCLAuthorizationStatusAuthorizedWhenInUse:
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"zoomMap" object:nil];

            break;
        default:
            break;
    }
}


-(void) showSlideUpView:(NSNotification*) notif {

    // this is pretty slick!
    [_theMapView selectAnnotation:[self getAnnotationViaUniqueId:notif.object] animated:YES];
}


-(void) hideSlideUpView:(NSNotification*) notif {
    
    [_theMapView deselectAnnotation:[self getAnnotationViaUniqueId:notif.object] animated:YES];
}


-(void) initialyHideTheDisplayBeaconView {
    
    showBeaconView.hidden = YES;
}


-(void) hideDetailedAnnotation:(NSNumber*)time {
    
    _showBeaconViewUniqueId = NULL;
    // this next line prevents the old expiraiton text from appearing when switching between geofence detailed views
    _expiresLabel.text = @"";
    
    [UIView animateWithDuration:time.floatValue
                          delay:0.0f
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         _centerUserInMap.hidden = NO;
                         [showBeaconView setAlpha:0.0f];
                     }
     
                     completion:^(BOOL finished){
                         [self.view sendSubviewToBack:showBeaconView];
                         showBeaconView.hidden = YES;
                         //  [self.view layoutIfNeeded];
                     }];
}



-(void) showDetailedAnnotation:(NSString*) theUniqueId {
    
   // if (showBeaconView.hidden == YES) {
        
    showBeaconView.hidden = NO;
    [self.view bringSubviewToFront:showBeaconView];
    [showBeaconView setAlpha:1.0f];
    
    
    
    _targetNumberReady = NO;
    _currentNumberReady = NO;
    
    _showBeaconViewUniqueId = theUniqueId;

   
    
    
    _expiresLabel.text = @"During normal hours";
    
  
    
    [UIView animateWithDuration:0.75f
                          delay:0.0f
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         _centerUserInMap.hidden = YES;
                         showBeaconView.frame = CGRectMake(0, 0, showBeaconView.bounds.size.width, showBeaconView.bounds.size.height);
                     }
                     completion:^(BOOL finished){
                     }];
    
    _switchingDirectly = NO;
}



- (IBAction)detailsButtonPressed:(id)sender {
    
    [self performSegueWithIdentifier:@"details" sender:_showBeaconViewUniqueId];
}



-(void) setupDateFromatters {

    _theExpiresDateFormatter = [Constants internetTimeDateFormatter];
    
    _theExpiresComponentsFormatter = [[NSDateComponentsFormatter alloc] init];
    _theExpiresComponentsFormatter.unitsStyle = NSDateComponentsFormatterUnitsStyleShort;
    _theExpiresComponentsFormatter.allowedUnits = NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond;
    _theExpiresComponentsFormatter.maximumUnitCount = 2;
    _theExpiresComponentsFormatter.zeroFormattingBehavior = NSDateComponentsFormatterZeroFormattingBehaviorDropAll;
}


-(void) showTheUserLocation:(NSNotification*)notif {
    self.theMapView.showsUserLocation = YES;
}

-(void) hideTheUserLocation:(NSNotification*)notif {
    self.theMapView.showsUserLocation = NO;
}



@end
