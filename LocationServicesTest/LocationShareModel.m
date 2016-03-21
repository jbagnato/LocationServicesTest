//
//  LocationShareModel.m
//  SocialDrivePremium
//
//  Created by Juan Bagnato on 20/3/16.
//  Copyright © 2016 Juan Bagnato. All rights reserved.
//

#import "LocationShareModel.h"

@implementation LocationShareModel
//Class method to make sure the share model is synch across the app
+ (id)sharedModel
{
    static id sharedMyModel = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyModel = [[self alloc] init];
    });
    return sharedMyModel;
}

@end
