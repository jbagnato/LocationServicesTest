//
//  LocationShareModel.h
//  SocialDrivePremium
//
//  Created by Juan Bagnato on 20/3/16.
//  Copyright © 2016 Juan Bagnato. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "BackgroundTaskManager.h"
#import <CoreLocation/CoreLocation.h>

@interface LocationShareModel : NSObject

@property (nonatomic) NSTimer *timer;
@property (nonatomic) NSTimer * delay10Seconds;
@property (nonatomic) BackgroundTaskManager * bgTask;
@property (nonatomic) NSMutableArray *myLocationArray;

+(id)sharedModel;

@end
