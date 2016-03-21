//
//  BackgroundTaskManager.m
//  SocialDrivePremium
//
//  Created by Juan Bagnato on 20/3/16.
//  Copyright © 2016 Juan Bagnato. All rights reserved.
//

#import "BackgroundTaskManager.h"


@interface BackgroundTaskManager()
@property (nonatomic, strong)NSMutableArray* bgTaskIdList;
@property (assign) UIBackgroundTaskIdentifier masterTaskId;
@end


@implementation BackgroundTaskManager

+(instancetype)sharedBackgroundTaskManager{
    static BackgroundTaskManager* sharedBGTaskManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedBGTaskManager = [[BackgroundTaskManager alloc] init];
    });
    
    return sharedBGTaskManager;
}

-(id)init{
    self = [super init];
    if(self){
        _bgTaskIdList = [NSMutableArray array];
        _masterTaskId = UIBackgroundTaskInvalid;
    }
    
    return self;
}


-(UIBackgroundTaskIdentifier)beginNewBackgroundTask
{
    
    // Once called, the beginNewBackgroundTask will start a new background task, if the app is indeed in the
    // background, and will then explicitly end all the other tasks to prevent the app from being killed by the system
    
    UIApplication* application = [UIApplication sharedApplication];
    
    UIBackgroundTaskIdentifier bgTaskId = UIBackgroundTaskInvalid;
    if([application respondsToSelector:@selector(beginBackgroundTaskWithExpirationHandler:)])
    {
        
        bgTaskId = [application beginBackgroundTaskWithExpirationHandler:^{
            
            NSLog(@"background task %lu expired", (unsigned long)bgTaskId);
            
        }];
        
        if ( self.masterTaskId == UIBackgroundTaskInvalid )
        {
            self.masterTaskId = bgTaskId;
            NSLog(@"started master task %lu", (unsigned long)self.masterTaskId);
        }
        else
        {
            //add this id to our list
            NSLog(@"started background task %lu", (unsigned long)bgTaskId);
            [self.bgTaskIdList addObject:@(bgTaskId)];
            // the endBackgroundTasks is simply a convenience method that ends all of the
            // background tasks excl. the masterTask.
            [self endBackgroundTasks];
        }
    }
    
    return bgTaskId;
}


// has a BOOL parameter, indicating if all background tasks should be stopped
// This method is called only through the two convenience methods
// endBackgroundTasks that passes NO as a parameter
// and endAllBackgroundTasks that passes YES as a parameter
-(void)drainBGTaskList:(BOOL)all
{
    //mark end of each of our background task
    UIApplication* application = [UIApplication sharedApplication];
    
    if([application respondsToSelector:@selector(endBackgroundTask:)])
    {
        NSUInteger count=self.bgTaskIdList.count;
        
        // when the "all" parameter is false, the integer value starts with one
        // the for then goes on ending all the previous tasks keeping only the one
        // that was just added
        for ( NSUInteger i=(all?0:1); i<count; i++ )             {
            UIBackgroundTaskIdentifier bgTaskId = [[self.bgTaskIdList objectAtIndex:0] integerValue];     NSLog(@"ending background task with id -%lu", (unsigned long)bgTaskId);     [application endBackgroundTask:bgTaskId];     [self.bgTaskIdList removeObjectAtIndex:0];             }                      if ( self.bgTaskIdList.count > 0 )
        {
            NSLog(@"kept background task id %@", [self.bgTaskIdList objectAtIndex:0]);
        }
        
        if ( all )
        {
            // case "all" was true, all the tasks must be terminated, including the masterTask
            NSLog(@"no more background tasks running");
            [application endBackgroundTask:self.masterTaskId];
            self.masterTaskId = UIBackgroundTaskInvalid;
        } else
        {
            NSLog(@"kept master background task id %lu", (unsigned long)self.masterTaskId);
        }
    }
}

-(void)endBackgroundTasks
{
    [self drainBGTaskList:NO];
}

-(void)endAllBackgroundTasks
{
    [self drainBGTaskList:YES];
}


@end
