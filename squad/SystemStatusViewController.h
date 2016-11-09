//
//  SystemStatusViewController.h
//  Nimbus
//
//  Created by Ian Thomas on 11/7/15.
//
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>


@interface SystemStatusViewController : UIViewController

@property (nonatomic) CBCentralManager *myCentralManager;
@property (nonatomic, assign) BOOL showHiddenStuff;

@end
