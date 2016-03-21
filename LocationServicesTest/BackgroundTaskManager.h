//
//  BackgroundTaskManager.h
//  SocialDrivePremium
//
//  Created by Juan Bagnato on 20/3/16.
//  Copyright © 2016 Juan Bagnato. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIApplication.h>

@interface BackgroundTaskManager : NSObject

+(instancetype)sharedBackgroundTaskManager;

-(UIBackgroundTaskIdentifier)beginNewBackgroundTask;
-(void)endAllBackgroundTasks;

@end
