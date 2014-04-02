//
//  PCFPushRegistrationParametersSpec.mm
//  PCFPushSDK
//
//  Created by Rob Szumlakowski on 2014-02-14.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import "Kiwi.h"

#import "PCFPushParameters.h"

static NSInteger TEST_NOTIFICATION_TYPES = UIRemoteNotificationTypeAlert;

static NSString *const TEST_variant_uuid   = @"SOS-WE-LIKE-IT-SPICY";
static NSString *const TEST_RELEASE_SECRET = @"Put sweet chili sauce on everything";
static NSString *const TEST_DEVICE_ALIAS   = @"Extreme spiciness classification";

SPEC_BEGIN(PCFPushRegistrationParametersSpec)

describe(@"PCFPushRegistrationParameters", ^{
    
    __block PCFPushParameters *model;

    afterEach(^{
        model = nil;
    });
    
    context(@"initializing with bad arguments", ^{
        
        afterEach(^{
            [[model should] beNil];
        });
        
        it(@"should require a non-nil releaseUuid", ^{
            [[theBlock(^{model = [PCFPushParameters parametersWithNotificationTypes:TEST_NOTIFICATION_TYPES variantUUID:nil releaseSecret:TEST_RELEASE_SECRET deviceAlias:TEST_DEVICE_ALIAS];})
              should] raise];
        });
        
        it(@"should require a non-empty releaseUuid", ^{
            [[theBlock(^{model = [PCFPushParameters parametersWithNotificationTypes:TEST_NOTIFICATION_TYPES variantUUID:@"" releaseSecret:TEST_RELEASE_SECRET deviceAlias:TEST_DEVICE_ALIAS];})
              should] raise];
        });
        
        it(@"should require a non-nil releaseSecret", ^{
            [[theBlock(^{model = [PCFPushParameters parametersWithNotificationTypes:TEST_NOTIFICATION_TYPES variantUUID:TEST_variant_uuid releaseSecret:nil deviceAlias:TEST_DEVICE_ALIAS];})
              should] raise];
        });
        
        it(@"should require a non-empty releaseSecret", ^{
            [[theBlock(^{model = [PCFPushParameters parametersWithNotificationTypes:TEST_NOTIFICATION_TYPES variantUUID:TEST_variant_uuid releaseSecret:@"" deviceAlias:TEST_DEVICE_ALIAS];})
              should] raise];
        });
        
        it(@"should require a non-nil deviceAlias", ^{
            [[theBlock(^{model = [PCFPushParameters parametersWithNotificationTypes:TEST_NOTIFICATION_TYPES variantUUID:TEST_variant_uuid releaseSecret:TEST_RELEASE_SECRET deviceAlias:nil];})
              should] raise];
        });
    });
    
    context(@"initializing with valid arguments (empty device alias)", ^{
        
        beforeEach(^{
            model = [PCFPushParameters parametersWithNotificationTypes:TEST_NOTIFICATION_TYPES variantUUID:TEST_variant_uuid releaseSecret:TEST_RELEASE_SECRET deviceAlias:@""];
        });
        
        it(@"should be initialized successfully", ^{
            [[model shouldNot] beNil];
        });
        
        it(@"should retain its arguments as properties", ^{
            [[theValue(model.remoteNotificationTypes) should] equal:theValue(TEST_NOTIFICATION_TYPES)];
            [[model.variantUUID should] equal:TEST_variant_uuid];
            [[model.releaseSecret should] equal:TEST_RELEASE_SECRET];
            [[model.deviceAlias should] beEmpty];
        });
    });

    context(@"initializing with valid arguments (non-nil device alias)", ^{
       
        beforeEach(^{
            model = [PCFPushParameters parametersWithNotificationTypes:TEST_NOTIFICATION_TYPES variantUUID:TEST_variant_uuid releaseSecret:TEST_RELEASE_SECRET deviceAlias:TEST_DEVICE_ALIAS];
        });
        
        it(@"should be initialized successfully", ^{
            [[model shouldNot] beNil];
        });
        
        it(@"should retain its arguments as properties", ^{
            [[theValue(model.remoteNotificationTypes) should] equal:theValue(TEST_NOTIFICATION_TYPES)];
            [[model.variantUUID should] equal:TEST_variant_uuid];
            [[model.releaseSecret should] equal:TEST_RELEASE_SECRET];
            [[model.deviceAlias should] equal:TEST_DEVICE_ALIAS];
        });
    });
});

SPEC_END
