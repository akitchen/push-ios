//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#import "MSSPushRegistrationRequestData.h"

NSString *const kReleaseSecret = @"secret";

@implementation MSSPushRegistrationRequestData

+ (NSDictionary *)localToRemoteMapping
{
    static NSDictionary *localToRemoteMapping;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableDictionary *mapping = [NSMutableDictionary dictionaryWithDictionary:[super localToRemoteMapping]];
        [mapping setObject:kReleaseSecret forKey:MSS_STR_PROP(secret)];
        localToRemoteMapping = [NSDictionary dictionaryWithDictionary:mapping];
    });
    
    return localToRemoteMapping;
}

@end
