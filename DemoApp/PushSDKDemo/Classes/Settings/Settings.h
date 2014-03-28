//
//  Settings.h
//  PCFPushSDK
//
//  Created by Rob Szumlakowski on 2014-01-31.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PCFPushParameters;

@interface Settings : NSObject

+ (NSString *)releaseUUID;
+ (void)setReleaseUUID:(NSString *)releaseUUID;

+ (NSString *)releaseSecret;
+ (void)setReleaseSecret:(NSString *)releaseSecret;

+ (NSString *)deviceAlias;
+ (void)setDeviceAlias:(NSString *)deviceAlias;

+ (void)resetToDefaults;

+ (PCFPushParameters *)registrationParameters;
+ (NSDictionary *)defaults;

@end
