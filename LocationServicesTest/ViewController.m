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
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didChangeAuthorizationStatusOn) name:@"didChangeAuthorizationStatusOn" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didChangeAuthorizationStatusOff) name:@"didChangeAuthorizationStatusOff" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didUpdateLocations:) name:@"didUpdateLocations" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didFailWithError:) name:@"didFailWithError" object:nil];
    
    //self.mapview.showsUserLocation = YES;
    [self.mapview setMapType:MKMapTypeStandard];
    [self.mapview setZoomEnabled:YES];
    [self.mapview setScrollEnabled:YES];
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)askPermissionInUse:(id)sender {
    [self gpsStartLocating:FALSE];
}

- (IBAction)askPermissionAlways:(id)sender {
    [self gpsStartLocating:TRUE];
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

- (void)solicitarServicioBackground {
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
        
        self.locationTracker = [[LocationTracker alloc]init];
        [self.locationTracker startLocationTracking];
        
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
    
    [self solicitarServicioBackground];
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
        [self solicitarServicioBackground]; // TODO: ATENCION este metodo se llama multiples veces
    }else if (status == kCLAuthorizationStatusAuthorizedWhenInUse ) {
        [prefs removeObjectForKey:@"activaGpsSiempre"];
    }
    
    if (status == kCLAuthorizationStatusAuthorizedAlways || status == kCLAuthorizationStatusAuthorizedWhenInUse || status == kCLAuthorizationStatusAuthorized) {
        [manager startUpdatingLocation];
        [prefs setObject:@"activo" forKey:@"activaGps"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"didChangeAuthorizationStatusOn" object:nil];
    }else if (status == kCLAuthorizationStatusDenied){
        [manager stopUpdatingLocation];
        [prefs setObject:@"rechazo" forKey:@"activaGpsSiempre"];
        [prefs setObject:@"rechazo" forKey:@"activaGps"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"didChangeAuthorizationStatusOff" object:nil];
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
                                            //Handel your yes please button action here
                                        }];
            [alert addAction:yesButton];
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
                                            //Handel your yes please button action here
                                        }];
            [alert addAction:yesButton];
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
                                                //Handel your yes please button action here
                                            }];
                [servicesDisabledAlert addAction:yesButton];
                [self presentViewController:servicesDisabledAlert animated:YES completion:nil];
        }
            break;
    }
}
- (void) didUpdateLocations : (NSNotification *) notification {
    CLLocation *location =  (CLLocation *)[notification object];
    NSLog(@"%@",location);
    MKCoordinateRegion region = { { 0.0, 0.0 }, { 0.0, 0.0 } };
    region.center.latitude = location.coordinate.latitude;
    region.center.longitude = location.coordinate.longitude;
    region.span.longitudeDelta = 0.005f;
    region.span.longitudeDelta = 0.005f;
    [self.mapview setRegion:region animated:YES];
}

/*
// This Method will be called as soon as the app goes into the background
// (Which is done through the "[NSNotificationCenter defaultCenter] addObserver" method with the key
// "UIApplicationDidEnterBackgroundNotification
//" in the "name" parameter, should be implemented in the init method).
-(void)applicationEnterBackground
{
    CLLocationManager *locationManager = [ViewController locationManager];//[LocationTracker sharedLocationManager];
    //revisar si user esta en modo viaje o no!
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSNumber* modoViaje = [prefs objectForKey:@"modoViaje"];
    if(!modoViaje || [modoViaje intValue]<=0){
        //frenar timers
        if (self.shareModel.timer)
        {
            [self.shareModel.timer invalidate];
            self.shareModel.timer = nil;
        }
        if (self.timer)
        {
            [self.timer invalidate];
            self.timer = nil;
        }
        [locationManager stopUpdatingLocation];
        return;
    }
    
    if(pedirBackground){ //para que no entre multiples veces
        return;
    }
    pedirBackground=true;
    
    locationManager.delegate = self;
    // Any other initializations you see fit
    locationManager.distanceFilter = kCLDistanceFilterNone; //whenever we move
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    locationManager.headingFilter = kCLHeadingFilterNone;
    
    // check for iOS 8
    if(IS_OS_8_OR_LATER)
    {
        [locationManager requestAlwaysAuthorization];
    }
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 9) {
        locationManager.allowsBackgroundLocationUpdates = YES;
    }
    
    [locationManager startUpdatingLocation];
    
    //Use the BackgroundTaskManager to manage all the background Task
    self.shareModel.bgTask = [BackgroundTaskManager sharedBackgroundTaskManager];
    // Begin a new background task.
    [self.shareModel.bgTask beginNewBackgroundTask];
}


*/
-(void)didChangeAuthorizationStatusOn{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    [prefs setObject:@"activo" forKey:@"activaGps"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(void)didChangeAuthorizationStatusOff{
    [self gpsStopLocating];
}



@end
