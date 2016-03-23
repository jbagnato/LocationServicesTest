//
//  ViewController.h
//  LocationServicesTest
//
//  Created by Juan Bagnato on 20/3/16.
//  Copyright © 2016 Juan Bagnato. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <MapKit/MKAnnotation.h>
#import "LocationTracker.h"


@interface ViewController : UIViewController{
}

@property (strong,nonatomic) LocationTracker * locationTracker;


@property (weak, nonatomic) IBOutlet UILabel *lblServiceAvailable;
- (IBAction)askPermissionInUse:(id)sender;
- (IBAction)askPermissionAlways:(id)sender;
- (IBAction)localizeOnce:(id)sender;
- (IBAction)localizeAllTime:(id)sender;
@property (weak, nonatomic) IBOutlet MKMapView *mapview;
- (IBAction)gotoWeb:(id)sender;

@end

