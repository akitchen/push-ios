//
//  PCFPushBackEndRegistrationResponseData.m
//  PCFPushSDK
//
//  Created by Rob Szumlakowski on 2014-01-21.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import "PCFPushRegistrationResponseData.h"

NSString *const kDeviceUUID = @"device_uuid";

@implementation PCFPushRegistrationResponseData

+ (NSDictionary *)localToRemoteMapping
{
    static NSDictionary *localToRemoteMapping;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableDictionary *mapping = [NSMutableDictionary dictionaryWithDictionary:[super localToRemoteMapping]];
        [mapping setObject:kDeviceUUID forKey:PCF_STR_PROP(deviceUUID)];
        localToRemoteMapping = [NSDictionary dictionaryWithDictionary:mapping];
    });
    
    return localToRemoteMapping;
}

@end
