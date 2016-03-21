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
@synthesize timer;//,lastLocation

static bool pedirBackground =false;

- (id)initWithCoder:(NSCoder *)aDecoder {
    
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        self.shareModel = [LocationShareModel sharedModel];
    }
    
    return self;
}

+ (CLLocationManager *)locationManager {
    static CLLocationManager *fooLocationManager = nil;
    if (fooLocationManager == nil) {
        fooLocationManager = [[CLLocationManager alloc] init];
        fooLocationManager.distanceFilter = kCLDistanceFilterNone; //whenever we move
        fooLocationManager.desiredAccuracy = kCLLocationAccuracyBest;
        fooLocationManager.headingFilter = kCLHeadingFilterNone;
    }
    return fooLocationManager;
}
static CLLocation *foolastLocation = Nil;
+ (CLLocation *)lastLocation {
    if (foolastLocation == Nil) {
        //foolastLocation = ;
    }
    return foolastLocation;
}
+ (void)setLastLocation:(CLLocation *)num {
    if(foolastLocation && !num){
        
    }else{
        foolastLocation = num;
        
    }
}



- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    pedirBackground=false;

    self.mapview.delegate = self;
    
    [ViewController locationManager].delegate = self; //solo este vc sera el delegate del gps
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didChangeAuthorizationStatusOn) name:@"didChangeAuthorizationStatusOn" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didChangeAuthorizationStatusOff) name:@"didChangeAuthorizationStatusOff" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didUpdateLocations:) name:@"didUpdateLocations" object:nil];
    
    /*NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSString * estado = [prefs objectForKey:@"activaGps"];
    if(!estado || ![estado isEqualToString:@"activo"]){
        [self gpsStartLocating:FALSE];
    }*/
    
    self.mapview.showsUserLocation = YES;
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
    UIAlertView * alert;
    //We have to make sure that the Background App Refresh is enable for the Location updates to work in the background.
    if([[UIApplication sharedApplication] backgroundRefreshStatus] == UIBackgroundRefreshStatusDenied){
        
        alert = [[UIAlertView alloc]initWithTitle:@""
                                          message:@"La app no funcionará bien si no habilitas Actualizar en segundo Plano. Activalos en Ajustes > General > Actualizar en segundo Plano"
                                         delegate:nil
                                cancelButtonTitle:@"Ok"
                                otherButtonTitles:nil, nil];
        [alert show];
        
    }else if([[UIApplication sharedApplication] backgroundRefreshStatus] == UIBackgroundRefreshStatusRestricted){
        
        alert = [[UIAlertView alloc]initWithTitle:@""
                                          message:@"Las funciones de la App están limitados por tener Actualizar en segundo Plano deshabilitado."
                                         delegate:nil
                                cancelButtonTitle:@"Ok"
                                otherButtonTitles:nil, nil];
        [alert show];
        
    } else{
        
        /*self.locationTracker = [[LocationTracker alloc]init];
         [self.locationTracker startLocationTracking];
         
         //Send the best location to server every 60 seconds
         //You may adjust the time interval depends on the need of your app.
         NSTimeInterval time = 60.0;
         self.locationUpdateTimer =
         [NSTimer scheduledTimerWithTimeInterval:time
         target:self
         selector:@selector(updateLocation)
         userInfo:nil
         repeats:YES];*/
        @try {
            [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:Nil];
        } @catch (NSException *__unused exception) {}
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
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
        UIAlertView *servicesDisabledAlert = [[UIAlertView alloc] initWithTitle:@"Error en Localización" message:@"Por favor, dirígete a Ajuste > Privacidad > Localización y habilita los servicios de ubicación." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [servicesDisabledAlert show];
        return;
    }
    
    if([CLLocationManager locationServicesEnabled] && [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedAlways){
        //[self solicitarServicioBackground];
    }else if ([[ViewController locationManager] respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        if(alwaysUse){
            //ATENCION aqui se da el caso que el user ya haya solicitado el permiso ALWAYS pero no lo habilito la 1ra vez. Entonces debera ir manualmente
            int veces = [self aumentaAlwaysAuth];
            if(veces<=0){
                [[ViewController locationManager] requestAlwaysAuthorization];
                if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 9) {
                    [ViewController locationManager].allowsBackgroundLocationUpdates = YES;
                }
            }else{
                UIAlertView *servicesDisabledAlert = [[UIAlertView alloc] initWithTitle:@"Localización" message:@"Por favor, dirígete a Ajustes > App y permite Localización Siempre para activar el Modo Viaje" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [servicesDisabledAlert show];
                return;
            }
            
        }else{
            [[ViewController locationManager] requestWhenInUseAuthorization];
        }
    } else {
        // iOS 7 - We can't use requestWhenInUseAuthorization -- we'll get an unknown selector crash!
        // Instead, you just start updating location, and the OS will take care of prompting the user
        // for permissions.
        
    }
    
    [self solicitarServicioBackground];
    
    if(self.timer){
        [self.timer invalidate];
    }
    self.timer = [NSTimer scheduledTimerWithTimeInterval:60 target:self selector:@selector(_turnOnLocationManager)  userInfo:nil repeats:NO];
    //self.shareModel.timer = self.timer;
    [[ViewController locationManager] startUpdatingLocation];
}

-(void) gpsStopLocating{
    [[ViewController locationManager] stopUpdatingLocation];
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
    //NSString * estado = [prefs objectForKey:@"activaGps"];
    //if(!estado || (estado && [estado isEqualToString:@"activo"])){
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
    //[[NSUserDefaults standardUserDefaults] synchronize];
    //}
}

// Location Manager Delegate Methods
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    NSLog(@"%@", [locations lastObject]);
    if([locations count]<=0){
        return;
    }
    CLLocation * newLocation = [locations lastObject];
    //CLLocationCoordinate2D theLocation = newLocation.coordinate;
    //CLLocationAccuracy theAccuracy = newLocation.horizontalAccuracy;
    
    NSTimeInterval locationAge = -[newLocation.timestamp timeIntervalSinceNow];
    
    if (locationAge > 30.0)
    {
        return;
    }
    [ViewController setLastLocation: [locations lastObject]];
        
    //View Area
    MKCoordinateRegion region = { { 0.0, 0.0 }, { 0.0, 0.0 } };
    region.center.latitude = [ViewController lastLocation].coordinate.latitude;
    region.center.longitude = [ViewController lastLocation].coordinate.longitude;
    region.span.longitudeDelta = 0.005f;
    region.span.longitudeDelta = 0.005f;
    [self.mapview setRegion:region animated:YES];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"didUpdateLocations" object:[ViewController lastLocation]];
    
    /* Schedule location manager to run again in 60 seconds
     [manager stopUpdatingLocation];
     self.timer = [NSTimer scheduledTimerWithTimeInterval:60 target:self selector:@selector(_turnOnLocationManager)  userInfo:nil repeats:NO];
     */
    
    //If the timer still valid, it means the 60 seconds are not yet over, and any other
    // process shouldn’t be started, so return the method here (Will not run the code below)
    if (self.shareModel.timer)
    {
        return;
    }
    
    // start a new background task case app is in background
    self.shareModel.bgTask = [BackgroundTaskManager sharedBackgroundTaskManager];
    [self.shareModel.bgTask beginNewBackgroundTask];
    
    //Restart the locationMaanger after 1 minute
    self.shareModel.timer = [NSTimer scheduledTimerWithTimeInterval:60 target:self
                                                           selector:@selector(restartLocationUpdates)
                                                           userInfo:nil
                                                            repeats:NO];
    
    //Will only stop the locationManager after 10 seconds, so that we can get some accurate locations
    //The location manager will only operate for 10 seconds to save battery
    if (self.shareModel.delay10Seconds)
    {
        [self.shareModel.delay10Seconds invalidate];
        self.shareModel.delay10Seconds = nil;
    }
    
    self.shareModel.delay10Seconds = [NSTimer scheduledTimerWithTimeInterval:10 target:self
                                                                    selector:@selector(stopLocationDelayBy10Seconds)
                                                                    userInfo:nil
                                                                     repeats:NO];
    
}

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(userLocation.coordinate, 800, 800);
    [self.mapview setRegion:[self.mapview regionThatFits:region] animated:YES];
}

- (void)_turnOnLocationManager {
    [[ViewController locationManager] startUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error{
    
    if([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied || [CLLocationManager authorizationStatus] == kCLErrorDenied ){
        //usuario no autorizo
        //si antes tenia gps, debo quitar el automatico
        [[NSNotificationCenter defaultCenter] postNotificationName:@"didFailWithError" object:error];
        
    } else {
        UIAlertView *servicesDisabledAlert = [[UIAlertView alloc] initWithTitle:@"Error en Localización" message:@"No se  pudo obtener tu posición." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [servicesDisabledAlert show];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"didUpdateLocations" object:Nil];
    }
}


- (void) didUpdateLocations : (NSNotification *) notification {
    //CLLocation *location =  (CLLocation *)[notification object];
    //NSLog(@"%@",location);
}


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


//Restart the locationManager
- (void) restartLocationUpdates
{
    // Invalidate the timer and set it to nil
    // because we are restarting the process
    if (self.shareModel.timer)
    {
        [self.shareModel.timer invalidate];
        self.shareModel.timer = nil;
    }
    
    CLLocationManager *locationManager = [ViewController locationManager];//[LocationTracker sharedLocationManager];
    locationManager.delegate = self;
    // any further initialization that you see fit
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
}

//Stop the locationManager
-(void)stopLocationDelayBy10Seconds
{
    // This method is called by the 10 seconds timer -  "delay10Seconds"
    // in order to conserve battery life
    // The location updates will then be stopped
    // and restarted after 60 seconds by the 60 seconds timer - "timer"
    CLLocationManager *locationManager = [ViewController locationManager];//[LocationTracker sharedLocationManager];
    [locationManager stopUpdatingLocation];
}

-(void)didChangeAuthorizationStatusOn{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    [prefs setObject:@"activo" forKey:@"activaGps"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(void)didChangeAuthorizationStatusOff{
    [self gpsStopLocating];
}



@end
