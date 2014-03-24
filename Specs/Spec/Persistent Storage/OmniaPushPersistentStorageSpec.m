//
//  OmniaPushPersistentStorageSpec.mm
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2014-02-14.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import "Kiwi.h"

#import "OmniaPushPersistentStorage.h"
#import "OmniaSpecHelper.h"

SPEC_BEGIN(OmniaPushPersistentStorageSpec)

describe(@"OmniaPushPersistentStorage", ^{

    __block OmniaSpecHelper *helper;

    beforeEach(^{
        helper = [[OmniaSpecHelper alloc] init];
        [OmniaPushPersistentStorage reset];
    });
                   
    it(@"should start empty", ^{
        [[[OmniaPushPersistentStorage APNSDeviceToken] should] beNil];
        [[[OmniaPushPersistentStorage backEndDeviceID] should] beNil];
        [[[OmniaPushPersistentStorage releaseUUID] should] beNil];
        [[[OmniaPushPersistentStorage releaseSecret] should] beNil];
        [[[OmniaPushPersistentStorage deviceAlias] should] beNil];
    });
    
    it(@"should be able to save the APNS device token", ^{
        [OmniaPushPersistentStorage setAPNSDeviceToken:helper.apnsDeviceToken];
        [[[OmniaPushPersistentStorage APNSDeviceToken] should] equal:helper.apnsDeviceToken];
    });
    
    it(@"should be able to save the back-end device ID", ^{
        [OmniaPushPersistentStorage setBackEndDeviceID:helper.backEndDeviceId];
        [[[OmniaPushPersistentStorage backEndDeviceID] should] equal:helper.backEndDeviceId];
    });
    
    it(@"should be able to save the release UUID", ^{
        [OmniaPushPersistentStorage setReleaseUUID:TEST_RELEASE_UUID_1];
        [[[OmniaPushPersistentStorage releaseUUID] should] equal:TEST_RELEASE_UUID_1];
    });
    
    it(@"should be able to save the release secret", ^{
        [OmniaPushPersistentStorage setReleaseSecret:TEST_RELEASE_SECRET_1];
        [[[OmniaPushPersistentStorage releaseSecret] should] equal:(TEST_RELEASE_SECRET_1)];
    });
    
    it(@"should be able to save the device alias", ^{
        [OmniaPushPersistentStorage setDeviceAlias:TEST_DEVICE_ALIAS_1];
        [[[OmniaPushPersistentStorage deviceAlias] should] equal:TEST_DEVICE_ALIAS_1];
    });
    
    it(@"should clear values after being reset", ^{
        [OmniaPushPersistentStorage setAPNSDeviceToken:helper.apnsDeviceToken];
        [OmniaPushPersistentStorage setBackEndDeviceID:helper.backEndDeviceId];
        [OmniaPushPersistentStorage reset];
        [[[OmniaPushPersistentStorage APNSDeviceToken] should] beNil];
        [[[OmniaPushPersistentStorage backEndDeviceID] should] beNil];
    });
});

SPEC_END
