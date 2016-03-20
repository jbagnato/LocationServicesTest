//
//  ViewController.h
//  LocationServicesTest
//
//  Created by Juan Bagnato on 20/3/16.
//  Copyright © 2016 Juan Bagnato. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>
#import <MapKit/MKAnnotation.h>

@interface ViewController : UIViewController<MKMapViewDelegate,  CLLocationManagerDelegate>

@property (weak, nonatomic) IBOutlet UILabel *lblServiceAvailable;
- (IBAction)askPermissionInUse:(id)sender;
- (IBAction)askPermissionAlways:(id)sender;
- (IBAction)localizeOnce:(id)sender;
- (IBAction)localizeAllTime:(id)sender;
@property (weak, nonatomic) IBOutlet MKMapView *mapview;
- (IBAction)gotoWeb:(id)sender;

@end

