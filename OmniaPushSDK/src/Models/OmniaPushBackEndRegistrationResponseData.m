//
//  OmniaPushBackEndRegistrationResponseData.m
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2014-01-21.
//  Copyright (c) 2014 Omnia. All rights reserved.
//

#import "OmniaPushBackEndRegistrationResponseData.h"
#import "OmniaPushDebug.h"

@implementation OmniaPushBackEndRegistrationResponseData

- (NSDictionary*) toDictionary
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    if (self.replicantId) dict[@"replicant_id"] = self.replicantId;
    if (self.deviceUuid) dict[@"device_uuid"] = self.deviceUuid;
    if (self.deviceAlias) dict[@"device_alias"] = self.deviceAlias;
    if (self.deviceManufacturer) dict[@"device_manufacturer"] = self.deviceManufacturer;
    if (self.deviceModel) dict[@"device_model"] = self.deviceModel;
    if (self.os) dict[@"os"] = self.os;
    if (self.osVersion) dict[@"os_version"] = self.osVersion;
    if (self.registrationToken) dict[@"registration_token"] = self.registrationToken;
    return dict;
}

- (NSData*) toJsonData
{
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:[self toDictionary] options:0 error:&error];
    if (error) {
        OmniaPushCriticalLog(@"Error upon serializing object to JSON: %@", error);
        return nil;
    } else {
        return jsonData;
    }
}
@end
