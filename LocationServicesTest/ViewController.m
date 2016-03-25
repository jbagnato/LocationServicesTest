//
//  ViewController.m
//  LocationServicesTest
//
//  Created by Juan Bagnato on 20/3/16.
//  Copyright © 2016 Juan Bagnato. All rights reserved.
// 

#import "ViewController.h"

#define IS_OS_8_OR_LATER ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)

@interface ViewController ()

@end

@implementation ViewController


- (id)initWithCoder:(NSCoder *)aDecoder {
    
    self = [super initWithCoder:aDecoder];
    if(self){
        self.locationTracker = [[LocationTracker alloc]init];
        self.point = [[MKPointAnnotation alloc] init];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didUpdateLocations:) name:@"didUpdateLocations" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didFailWithError:) name:@"didFailWithError" object:nil];
    
    //self.mapview.showsUserLocation = YES;
    [self.mapview setMapType:MKMapTypeStandard];
    [self.mapview setZoomEnabled:YES];
    [self.mapview setScrollEnabled:YES];
    
    if([self.locationTracker areServicesAvailable]){
        self.lblServiceAvailable.text=@"SI";
    }else{
        self.lblServiceAvailable.text=@"NO";
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)localizeOnce:(id)sender {
    [self gpsStartLocating:FALSE];
}

- (IBAction)localizeAllTime:(id)sender {
    [self gpsStartLocating:TRUE];
}
- (IBAction)gotoWeb:(id)sender {
    //TODO
}

- (IBAction)stopLocalize:(id)sender {
    [self gpsStopLocating];
}

- (void)askService {
    UIAlertController * alert;
    //We have to make sure that the Background App Refresh is enable for the Location updates to work in the background.
    if([[UIApplication sharedApplication] backgroundRefreshStatus] == UIBackgroundRefreshStatusDenied){
        
        alert = [UIAlertController
                 alertControllerWithTitle:@"Localización"
                                          message:@"La app no funcionará bien si no habilitas Actualizar en segundo Plano. Activalos en Ajustes > General > Actualizar en segundo Plano"
                 preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* yesButton = [UIAlertAction
                                    actionWithTitle:@"Ok"
                                    style:UIAlertActionStyleDefault
                                    handler:^(UIAlertAction * action)
                                    {
                                        //Handle your yes please button action here
                                    }];
        [alert addAction:yesButton];
        [self presentViewController:alert animated:YES completion:nil];
        
    }else if([[UIApplication sharedApplication] backgroundRefreshStatus] == UIBackgroundRefreshStatusRestricted){
        
        alert = [UIAlertController
                 alertControllerWithTitle:@"Localización"
                                          message:@"Las funciones de la App están limitados por tener Actualizar en segundo Plano deshabilitado."
                 preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* yesButton = [UIAlertAction
                                    actionWithTitle:@"OK"
                                    style:UIAlertActionStyleDefault
                                    handler:^(UIAlertAction * action)
                                    {
                                        //Handle your yes please button action here
                                    }];
        [alert addAction:yesButton];
        [self presentViewController:alert animated:YES completion:nil];
        
    } else{
        
        [self.locationTracker startLocationTrackingAndAllowInBackground:self.switchBackground.isOn];
        
    }
}

-(int) aumentaAlwaysAuth{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSNumber * cant = [prefs objectForKey:@"solicitaAlwaysAuth"];
    if(cant){
        int suma = [cant intValue]+1;
        [prefs setObject:[NSNumber numberWithInt:suma] forKey:@"solicitaAlwaysAuth"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        return suma;
    }else{
        return 0;
    }
}

-(void) gpsStartLocating:(BOOL) alwaysUse {
    
    if(![CLLocationManager locationServicesEnabled] || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied){
        UIAlertController *servicesDisabledAlert = [UIAlertController
                                                    alertControllerWithTitle:@"Error en Localización" message:@"Por favor, dirígete a Ajuste > Privacidad > Localización y habilita los servicios de ubicación."
                                                    preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* yesButton = [UIAlertAction
                                    actionWithTitle:@"Ok"
                                    style:UIAlertActionStyleDefault
                                    handler:^(UIAlertAction * action)
                                    {
                                        //Handel your yes please button action here
                                    }];
        [servicesDisabledAlert addAction:yesButton];
        [self presentViewController:servicesDisabledAlert animated:YES completion:nil];
        return;
    }
    
    if([CLLocationManager locationServicesEnabled] && [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedAlways){
        
    }else if ([[LocationTracker sharedLocationManager] respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        if(alwaysUse){
            //ATENCION aqui se da el caso que el user ya haya solicitado el permiso ALWAYS pero no lo habilito la 1ra vez. Entonces debera ir manualmente
            int veces = [self aumentaAlwaysAuth];
            if(veces<=0){
                [[LocationTracker sharedLocationManager] requestAlwaysAuthorization];
                if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 9) {
                    [LocationTracker sharedLocationManager].allowsBackgroundLocationUpdates = YES;
                }
            }else{
                UIAlertController *servicesDisabledAlert = [UIAlertController
                                                            alertControllerWithTitle:@"Localización" message:@"Por favor, dirígete a Ajustes > App y permite Localización Siempre" preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction* yesButton = [UIAlertAction
                                            actionWithTitle:@"Ok"
                                            style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * action)
                                            {
                                                //Handel your yes please button action here
                                            }];
                [servicesDisabledAlert addAction:yesButton];
                [self presentViewController:servicesDisabledAlert animated:YES completion:nil];
                [self gpsStopLocating];
                return;
            }
            
        }else{
            [[LocationTracker sharedLocationManager] requestWhenInUseAuthorization];
        }
    } else {
        // iOS 7 - We can't use requestWhenInUseAuthorization -- we'll get an unknown selector crash!
        // Instead, you just start updating location, and the OS will take care of prompting the user
        // for permissions.
        
    }
    
    [self askService];
}

-(void) gpsStopLocating{
    [self.locationTracker stopLocationTracking];
}

/*
 ATENCION este método se llama muchas veces! no sólo cuando se muestra el cartelito de autorizacion
 Se muestra en los suguientes casos
 1-Cuando el user ve cartelito y elije
 2-cuando se instancia CLLocationManager
 3-si el user cambia ajustes en Settings de iOs y vuelve a la app
 */
- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    // We only need to start updating location for iOS 8 -- iOS 7 users should have already
    // started getting location updates
    
    if (status == kCLAuthorizationStatusAuthorizedAlways ) {
        [prefs setObject:@"activo" forKey:@"activaGpsSiempre"];
        [self askService]; // ATENCION este metodo se llama multiples veces
    }else if (status == kCLAuthorizationStatusAuthorizedWhenInUse ) {
        [prefs removeObjectForKey:@"activaGpsSiempre"];
    }
    
    if (status == kCLAuthorizationStatusAuthorizedAlways || status == kCLAuthorizationStatusAuthorizedWhenInUse || status == kCLAuthorizationStatusAuthorized) {
        [manager startUpdatingLocation];
        [prefs setObject:@"activo" forKey:@"activaGps"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }else if (status == kCLAuthorizationStatusDenied){
        [prefs setObject:@"rechazo" forKey:@"activaGpsSiempre"];
        [prefs setObject:@"rechazo" forKey:@"activaGps"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [self gpsStopLocating];
    }
}

/*
- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(userLocation.coordinate, 800, 800);
    [self.mapview setRegion:[self.mapview regionThatFits:region] animated:YES];
}
*/

- (void) didFailWithError : (NSNotification *) notification {
    static BOOL alreadyOpen=false;
    
    if(alreadyOpen){
        return;
    }
    
    NSError *error =  (NSError *)[notification object];
    switch([error code])
    {
        case kCLErrorNetwork: // general, network-related error
        {
            UIAlertController *alert = [UIAlertController
                                        alertControllerWithTitle:@"Error en la Red" message:@"Por favor, revisa tu conexión a la red." preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction* yesButton = [UIAlertAction
                                        actionWithTitle:@"Ok"
                                        style:UIAlertActionStyleDefault
                                        handler:^(UIAlertAction * action)
                                        {
                                            alreadyOpen=false;
                                        }];
            [alert addAction:yesButton];
            alreadyOpen=true;
            [self presentViewController:alert animated:YES completion:nil];
        }
            break;
        case kCLErrorDenied:{
            UIAlertController *alert = [UIAlertController
                                        alertControllerWithTitle:@"Habilita Servicios de Ubicación" message:@"Debes habilitar los servicios de Ubicación. Para hacerlo dirigete a Ajustes->Privacidad->Localización" preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction* yesButton = [UIAlertAction
                                        actionWithTitle:@"Ok"
                                        style:UIAlertActionStyleDefault
                                        handler:^(UIAlertAction * action)
                                        {
                                            alreadyOpen=false;
                                        }];
            [alert addAction:yesButton];
            alreadyOpen=true;
            [self presentViewController:alert animated:YES completion:nil];
        }
            break;
        default:
        {
                UIAlertController *servicesDisabledAlert = [UIAlertController
                                                            alertControllerWithTitle:@"Error en Localización" message:@"No se  pudo obtener tu posición." preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction* yesButton = [UIAlertAction
                                            actionWithTitle:@"Ok"
                                            style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * action)
                                            {
                                                alreadyOpen=false;
                                            }];
                [servicesDisabledAlert addAction:yesButton];
            alreadyOpen=true;
                [self presentViewController:servicesDisabledAlert animated:YES completion:nil];
        }
            break;
    }
    [self gpsStopLocating];

}
- (void) didUpdateLocations : (NSNotification *) notification {
    static CLLocation *lastLocation;
    CLLocation *location =  (CLLocation *)[notification object];
    if (location.coordinate.latitude == lastLocation.coordinate.latitude &&
        location.coordinate.longitude == lastLocation.coordinate.longitude) {
        return;
    }
    NSLog(@"%@",location);
    lastLocation=location;
    self.lblPosition.text=[NSString stringWithFormat:@"%.8f %.8f",location.coordinate.latitude,location.coordinate.longitude];
    MKCoordinateRegion region = { { 0.0, 0.0 }, { 0.0, 0.0 } };
    region.center.latitude = location.coordinate.latitude;
    region.center.longitude = location.coordinate.longitude;
    region.span.longitudeDelta = 0.005f;
    region.span.longitudeDelta = 0.005f;
    [self.mapview setRegion:region animated:YES];
    
    // Add an annotation
    self.point.coordinate = location.coordinate;
    self.point.title = @"Posicion";
    self.point.subtitle = @"detectada";
    
    [self.mapview addAnnotation:self.point];
}




@end
