//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#import "Kiwi.h"

#import "MSSPush.h"
#import "MSSPushClientTest.h"
#import "MSSPushClient.h"
#import "MSSPushErrors.h"
#import "MSSPushSpecsHelper.h"
#import "MSSPushPersistentStorage.h"
#import "MSSParameters.h"
#import "MSSPushBackEndRegistrationResponseDataTest.h"
#import "MSSPushRegistrationPutRequestData.h"
#import "MSSPushRegistrationPostRequestData.h"
#import "NSURLConnection+MSSPushAsync2Sync.h"
#import "NSURLConnection+MSSBackEndConnection.h"
#import "NSObject+MSSJsonizable.h"

SPEC_BEGIN(MSSPushSpecs)

describe(@"MSSPush", ^{
    __block MSSPushSpecsHelper *helper = nil;
    __block id<UIApplicationDelegate> previousAppDelegate;
    
    beforeEach(^{
        [MSSPushClient resetSharedClient];
        helper = [[MSSPushSpecsHelper alloc] init];
        [helper setupApplication];
        [helper setupApplicationDelegate];
        [helper setupParameters];
        previousAppDelegate = helper.applicationDelegate;
    });
    
    afterEach(^{
        previousAppDelegate = nil;
        [helper reset];
        helper = nil;
    });
    
    describe(@"setting parameters", ^{
       
        it(@"should raise an exception if parameters are nil", ^{
            [[theBlock(^{
                [MSSPush setRegistrationParameters:nil];
            }) should] raiseWithName:NSInvalidArgumentException];
        });

        it(@"should raise an exception if parameters are invalid", ^{
            helper.params.productionPushVariantUUID = nil;
            [[theBlock(^{
                [MSSPush setRegistrationParameters:helper.params];
            }) should] raiseWithName:NSInvalidArgumentException];
        });
        
        it(@"should raise an exception if startRegistration is called without parameters being set", ^{
            [[theBlock(^{
                [MSSPush registerForPushNotifications];
            }) should] raise];
        });
    });
    
    describe(@"updating registration", ^{

        __block NSInteger successCount;
        __block NSInteger updateRegistrationCount;
        __block void (^testBlock)(SEL sel, id newPersistedValue);
        __block NSSet *expectedSubscribeTags;
        __block NSSet *expectedUnsubscribeTags;

        beforeEach(^{
            successCount = 0;
            updateRegistrationCount = 0;
            expectedSubscribeTags = nil;
            expectedUnsubscribeTags = nil;
            
            [helper setupApplicationForSuccessfulRegistration];
            [helper setupApplicationDelegateForSuccessfulRegistration];

            [[NSURLConnection shouldEventually] receive:@selector(sendAsynchronousRequest:queue:completionHandler:)];
            [[(id)helper.applicationDelegate shouldEventually] receive:@selector(application:didRegisterForRemoteNotificationsWithDeviceToken:) withCount:1];
            
            [NSURLConnection stub:@selector(sendAsynchronousRequest:queue:completionHandler:) withBlock:^id(NSArray *params) {
                NSURLRequest *request = params[0];
                
                __block NSData *newData;
                __block NSHTTPURLResponse *newResponse;
                
                if ([request.HTTPMethod isEqualToString:@"DELETE"]) {
                    fail(@"unregistration request made.");
                }
                
                if ([request.HTTPMethod isEqualToString:@"PUT"] || [request.HTTPMethod isEqualToString:@"POST"]) {
                    
                    if ([request.HTTPMethod isEqualToString:@"PUT"]) {
                        updateRegistrationCount++;
                    } else {
                        fail(@"PUT update expected.");
                    }
                    
                    NSError *error;
                    MSSPushRegistrationPutRequestData *requestBody = [MSSPushRegistrationPutRequestData mss_fromJSONData:request.HTTPBody error:&error];
                    if (error) {
                        fail(@"Could not parse HTTP request body");
                    }
                    
                    [[requestBody shouldNot] beNil];
                    if (expectedSubscribeTags) {
                        [[[NSSet setWithArray:requestBody.subscribeTags] should] equal:expectedSubscribeTags];
                    } else {
                        [[requestBody.subscribeTags should] beNil];
                    }
                    if (expectedUnsubscribeTags) {
                        [[[NSSet setWithArray:requestBody.unsubscribeTags] should] equal:expectedUnsubscribeTags];
                    } else {
                        [[requestBody.unsubscribeTags should] beNil];
                    }
                    
                    newResponse = [[NSHTTPURLResponse alloc] initWithURL:nil statusCode:200 HTTPVersion:nil headerFields:nil];
                    NSDictionary *dict = @{
                                           RegistrationAttributes.deviceOS           : TEST_OS,
                                           RegistrationAttributes.deviceOSVersion    : TEST_OS_VERSION,
                                           RegistrationAttributes.deviceAlias        : TEST_DEVICE_ALIAS,
                                           RegistrationAttributes.deviceManufacturer : TEST_DEVICE_MANUFACTURER,
                                           RegistrationAttributes.deviceModel        : TEST_DEVICE_MODEL,
                                           RegistrationAttributes.variantUUID        : TEST_VARIANT_UUID,
                                           RegistrationAttributes.registrationToken  : TEST_REGISTRATION_TOKEN,
                                           kDeviceUUID                               : TEST_DEVICE_UUID,
                                           };
                    newData = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:nil];
                }
                
                CompletionHandler handler = params[2];
                handler(newResponse, newData, nil);
                return nil;
            }];
            
            testBlock = ^(SEL sel, id newPersistedValue) {
                
                [helper setupDefaultPersistedParameters];
                
                [MSSPushPersistentStorage performSelector:sel withObject:newPersistedValue];
                
                [MSSPush setCompletionBlockWithSuccess:^{
                    successCount++;
                } failure:^(NSError *error) {
                    fail(@"registration failure block executed");
                }];

                helper.params.pushAutoRegistrationEnabled = NO;
                [MSSPush setRegistrationParameters:helper.params];
                [MSSPush registerForPushNotifications];
            };
        });
        
        afterEach(^{
            [[theValue(successCount) shouldEventually] equal:theValue(1)];
            [[theValue(updateRegistrationCount) shouldEventually] equal:theValue(1)];
        });

        it(@"should update after the variantUuid changes", ^{
            testBlock(@selector(setVariantUUID:), @"DIFFERENT STRING");
        });
        
        it(@"should update after the variantUuid is initially set", ^{
            testBlock(@selector(setVariantUUID:), nil);
        });
        
        it(@"should update after the variantSecret changes", ^{
            testBlock(@selector(setVariantSecret:), @"DIFFERENT STRING");
        });
        
        it(@"should update after the variantSecret is initially set", ^{
            testBlock(@selector(setVariantSecret:), nil);
        });
        
        it(@"should update after the deviceAlias changes", ^{
            testBlock(@selector(setDeviceAlias:), @"DIFFERENT STRING");
        });
        
        it(@"should update after the deviceAlias is initially set", ^{
            testBlock(@selector(setDeviceAlias:), nil);
        });
        
        it(@"should update after the APNSDeviceToken changes", ^{
            testBlock(@selector(setAPNSDeviceToken:), [@"DIFFERENT TOKEN" dataUsingEncoding:NSUTF8StringEncoding]);
        });
        
        it(@"should update after the tags change to a different value", ^{
            expectedSubscribeTags = helper.tags1;
            expectedUnsubscribeTags = [NSSet setWithArray:@[ @"DIFFERENT TAG" ]];
            testBlock(@selector(setTags:), expectedUnsubscribeTags);
        });
        
        it(@"should update after tags initially set from nil", ^{
            expectedSubscribeTags = helper.tags1;
            testBlock(@selector(setTags:), nil);
        });
        
        it(@"should update after tags initially set from empty", ^{
            expectedSubscribeTags = helper.tags1;
            testBlock(@selector(setTags:), [NSSet set]);
        });
        
        it(@"should update after tags change to nil", ^{
            helper.params.pushTags = nil;
            expectedUnsubscribeTags = helper.tags1;
            testBlock(@selector(setTags:), helper.tags1);
        });
        
        it(@"should update after tags change to empty", ^{
            helper.params.pushTags = [NSSet set];
            expectedUnsubscribeTags = helper.tags1;
            testBlock(@selector(setTags:), helper.tags1);
        });
    });
    
    describe(@"successful registration", ^{
        
        beforeEach(^{
            [MSSPushClient resetSharedClient];
            [helper setupApplicationForSuccessfulRegistration];
            [helper setupApplicationDelegateForSuccessfulRegistration];
        });
        
        it(@"should bypass registering against Remote Push Server if Device Token matches the stored token.", ^{
            
            __block BOOL successBlockExecuted = NO;
            __block NSSet *expectedTags;
            
            [[(id)helper.applicationDelegate shouldEventually] receive:@selector(application:didRegisterForRemoteNotificationsWithDeviceToken:) withCount:2];
            [[NSURLConnection shouldEventually] receive:@selector(sendAsynchronousRequest:queue:completionHandler:) withCount:1];
            
            [NSURLConnection stub:@selector(sendAsynchronousRequest:queue:completionHandler:) withBlock:^id(NSArray *params) {
                NSURLRequest *request = params[0];
                
                __block NSData *newData;
                __block NSHTTPURLResponse *newResponse;
                
                if (![request.HTTPMethod isEqualToString:@"POST"]) {
                    fail(@"Request must be a POST");
                }
                
                newResponse = [[NSHTTPURLResponse alloc] initWithURL:nil statusCode:200 HTTPVersion:nil headerFields:nil];
                NSDictionary *dict = @{
                                       RegistrationAttributes.deviceOS           : TEST_OS,
                                       RegistrationAttributes.deviceOSVersion    : TEST_OS_VERSION,
                                       RegistrationAttributes.deviceAlias        : TEST_DEVICE_ALIAS,
                                       RegistrationAttributes.deviceManufacturer : TEST_DEVICE_MANUFACTURER,
                                       RegistrationAttributes.deviceModel        : TEST_DEVICE_MODEL,
                                       RegistrationAttributes.variantUUID        : TEST_VARIANT_UUID,
                                       RegistrationAttributes.registrationToken  : TEST_REGISTRATION_TOKEN,
                                       kDeviceUUID                               : TEST_DEVICE_UUID,
                                       };
                newData = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:nil];
                
                NSError *error;
                MSSPushRegistrationPostRequestData *requestBody = [MSSPushRegistrationPostRequestData mss_fromJSONData:request.HTTPBody error:&error];
                if (error) {
                    fail(@"Could not parse HTTP request body");
                }
                [[requestBody shouldNot] beNil];
                if (expectedTags) {
                    [[[NSSet setWithArray:requestBody.tags] should] equal:expectedTags];
                } else {
                    [[requestBody.tags should] beNil];
                }
             
                CompletionHandler handler = params[2];
                handler(newResponse, newData, nil);
                return nil;
            }];
            
            expectedTags = helper.tags1;
            [MSSPush load];
            [MSSPush setRegistrationParameters:helper.params];
            [MSSPush setCompletionBlockWithSuccess:^{
                successBlockExecuted = YES;
            } failure:^(NSError *error) {
                fail(@"registration failure block executed");
            }];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidFinishLaunchingNotification object:nil];
            [[theValue(successBlockExecuted) shouldEventually] beTrue];
            successBlockExecuted = NO;
            [MSSPush load];
            // TODO - confirm that the request body has the correct subscribe list of tags
            
            [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidFinishLaunchingNotification object:nil];
            [[theValue(successBlockExecuted) shouldEventually] beTrue];
        });
    });
    
    describe(@"failed registration", ^{
        
        __block NSError *testError;
        __block BOOL expectedResult = NO;
        
        beforeEach(^{
            [MSSPushClient resetSharedClient];
            
            testError = [NSError errorWithDomain:@"Some boring error" code:0 userInfo:nil];
            [helper setupApplicationForFailedRegistrationWithError:testError];
            [helper setupApplicationDelegateForFailedRegistrationWithError:testError];
            expectedResult = NO;
        });
        
        afterEach(^{
            [[theValue(expectedResult) should] beTrue];
            [[[MSSPushPersistentStorage APNSDeviceToken] should] beNil];
            expectedResult = NO;
            testError = nil;
        });
        
        it(@"should handle registration failures from APNS", ^{
            [MSSPush load];
            
            [[(id)helper.applicationDelegate shouldEventually] receive:@selector(application:didFailToRegisterForRemoteNotificationsWithError:)];
            
            [MSSPush setRegistrationParameters:helper.params];
            [MSSPush setCompletionBlockWithSuccess:nil
                                           failure:^(NSError *error) {
                                               expectedResult = YES;
                                           }];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidFinishLaunchingNotification object:nil];
        });
    });
    
    context(@"valid object arguements", ^{
        __block BOOL wasExpectedResult = NO;
        __block MSSPushSpecsHelper *helper;
        
        beforeEach(^{
            helper = [[MSSPushSpecsHelper alloc] init];
            [helper setupParameters];
            wasExpectedResult = NO;
        });
        
        afterEach(^{
            [[theValue(wasExpectedResult) should] beTrue];
            [helper reset];
            helper = nil;
        });
        
        it(@"should handle an HTTP status error", ^{
            NSError *error;
            [helper swizzleAsyncRequestWithSelector:@selector(HTTPErrorResponseRequest:queue:completionHandler:) error:&error];
            
            [MSSPushClient sendRegisterRequestWithParameters:helper.params
                                                 deviceToken:helper.apnsDeviceToken
                                                     success:^{
                                                         wasExpectedResult = NO;
                                                     }
                                                     failure:^(NSError *error) {
                                                         [[error.domain should] equal:MSSPushErrorDomain];
                                                         [[theValue(error.code) should] equal:theValue(MSSPushBackEndRegistrationFailedHTTPStatusCode)];
                                                         wasExpectedResult = YES;
                                                     }];
        });
        
        
        it(@"should handle a successful response with empty data", ^{
            NSError *error;
            [helper swizzleAsyncRequestWithSelector:@selector(emptyDataResponseRequest:queue:completionHandler:) error:&error];
            
            [MSSPushClient sendRegisterRequestWithParameters:helper.params
                                                 deviceToken:helper.apnsDeviceToken
                                                     success:^{
                                                         wasExpectedResult = NO;
                                                     }
                                                     failure:^(NSError *error) {
                                                         [[error.domain should] equal:MSSPushErrorDomain];
                                                         [[theValue(error.code) should] equal:theValue(MSSPushBackEndRegistrationEmptyResponseData)];
                                                         wasExpectedResult = YES;
                                                     }];
        });
        
        it(@"should handle a successful response with nil data", ^{
            NSError *error;
            [helper swizzleAsyncRequestWithSelector:@selector(nilDataResponseRequest:queue:completionHandler:) error:&error];
            
            [MSSPushClient sendRegisterRequestWithParameters:helper.params
                                                 deviceToken:helper.apnsDeviceToken
                                                     success:^{
                                                         wasExpectedResult = NO;
                                                     }
                                                     failure:^(NSError *error) {
                                                         [[error.domain should] equal:MSSPushErrorDomain];
                                                         [[theValue(error.code) should] equal:theValue(MSSPushBackEndRegistrationEmptyResponseData)];
                                                         wasExpectedResult = YES;
                                                     }];
        });
        
        it(@"should handle a successful response with zero-length", ^{
            NSError *error;
            [helper swizzleAsyncRequestWithSelector:@selector(zeroLengthDataResponseRequest:queue:completionHandler:) error:&error];
            
            [MSSPushClient sendRegisterRequestWithParameters:helper.params
                                                 deviceToken:helper.apnsDeviceToken
                                                     success:^{
                                                         wasExpectedResult = NO;
                                                     }
                                                     failure:^(NSError *error) {
                                                         [[error.domain should] equal:MSSPushErrorDomain];
                                                         [[theValue(error.code) should] equal:theValue(MSSPushBackEndRegistrationEmptyResponseData)];
                                                         wasExpectedResult = YES;
                                                     }];
        });
        
        it(@"should handle a successful response that contains unparseable text", ^{
            NSError *error;
            [helper swizzleAsyncRequestWithSelector:@selector(unparseableDataResponseRequest:queue:completionHandler:) error:&error];
            
            [MSSPushClient sendRegisterRequestWithParameters:helper.params
                                                 deviceToken:helper.apnsDeviceToken
                                                     success:^{
                                                         wasExpectedResult = NO;
                                                     }
                                                     failure:^(NSError *error) {
                                                         [[error shouldNot] beNil];
                                                         wasExpectedResult = YES;
                                                     }];
        });
        
        it(@"should require a device_uuid in the server response", ^{
            NSError *error;
            [helper swizzleAsyncRequestWithSelector:@selector(missingUUIDResponseRequest:queue:completionHandler:) error:&error];
            
            [MSSPushClient sendRegisterRequestWithParameters:helper.params
                                                 deviceToken:helper.apnsDeviceToken
                                                     success:^{
                                                         wasExpectedResult = NO;
                                                     }
                                                     failure:^(NSError *error) {
                                                         wasExpectedResult = YES;
                                                         [[error.domain should] equal:MSSPushErrorDomain];
                                                         [[theValue(error.code) should] equal:theValue(MSSPushBackEndRegistrationResponseDataNoDeviceUuid)];
                                                     }];
        });
    });
    
    describe(@"successful unregistration from push server", ^{
        
        __block BOOL successBlockExecuted = NO;
        
        beforeEach(^{
            [helper setupDefaultPersistedParameters];
            successBlockExecuted = NO;
            
            [NSURLConnection stub:@selector(sendAsynchronousRequest:queue:completionHandler:) withBlock:^id(NSArray *params) {
                NSURLRequest *request = params[0];
                
                __block NSHTTPURLResponse *newResponse;
                
                if ([request.HTTPMethod isEqualToString:@"DELETE"]) {
                    newResponse = [[NSHTTPURLResponse alloc] initWithURL:nil statusCode:204 HTTPVersion:nil headerFields:nil];
                } else {
                    fail(@"Request method must be DELETE");
                }
                
                CompletionHandler handler = params[2];
                handler(newResponse, nil, nil);
                return nil;
            }];
        });
        
        afterEach(^{
            SEL selectors[] = {
                @selector(APNSDeviceToken),
                @selector(serverDeviceID),
                @selector(variantUUID),
                @selector(deviceAlias),
            };
            
            for (NSUInteger i = 0; i < sizeof(selectors)/sizeof(selectors[0]); i++) {
                [[[MSSPushPersistentStorage performSelector:selectors[i]] should] beNil];
            }
        });
        
        it(@"should succesfully unregister if the device has a persisted backEndDeviceUUID and should remove all persisted parameters when unregister is successful", ^{
            [[[MSSPushPersistentStorage serverDeviceID] shouldNot] beNil];
            [[NSURLConnection shouldEventually] receive:@selector(sendAsynchronousRequest:queue:completionHandler:)];
            
            [MSSPush unregisterWithPushServerSuccess:^{
                successBlockExecuted = YES;
                
            } failure:^(NSError *error) {
                fail(@"unregistration failure block executed");
            }];
            
            [[theValue(successBlockExecuted) shouldEventually] beTrue];
        });
    });
    
    describe(@"unsuccessful unregistration when device not registered on push server", ^{
        __block BOOL failureBlockExecuted = NO;
        
        beforeEach(^{
            [helper setupDefaultPersistedParameters];
            
            [NSURLConnection stub:@selector(sendAsynchronousRequest:queue:completionHandler:) withBlock:^id(NSArray *params) {
                NSURLRequest *request = params[0];
                
                __block NSHTTPURLResponse *newResponse;
                
                if ([request.HTTPMethod isEqualToString:@"DELETE"]) {
                    newResponse = [[NSHTTPURLResponse alloc] initWithURL:nil statusCode:404 HTTPVersion:nil headerFields:nil];
                }
                
                CompletionHandler handler = params[2];
                handler(newResponse, nil, nil);
                return nil;
            }];
        });
        
        it(@"should perform failure block if server responds with a 404 (DeviceUUID not registered on server) ", ^{
            
            [[NSURLConnection shouldEventually] receive:@selector(sendAsynchronousRequest:queue:completionHandler:)];
            
            [MSSPush unregisterWithPushServerSuccess:^{
                fail(@"unregistration success block executed");
                
            } failure:^(NSError *error) {
                failureBlockExecuted = YES;
                
            }];
            
            [[theValue(failureBlockExecuted) shouldEventually] beTrue];
        });
        
    });
    
    describe(@"unsuccessful unregistration", ^{
        __block BOOL failureBlockExecuted = NO;
        
        beforeEach(^{
            [helper setupDefaultPersistedParameters];
            failureBlockExecuted = NO;
            
            [NSURLConnection stub:@selector(sendAsynchronousRequest:queue:completionHandler:) withBlock:^id(NSArray *params) {
                NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorTimedOut userInfo:nil];
                CompletionHandler handler = params[2];
                handler(nil, nil, error);
                return nil;
            }];
        });
        
        it(@"should perform failure block if server request returns error", ^{
            [[NSURLConnection shouldEventually] receive:@selector(sendAsynchronousRequest:queue:completionHandler:)];
            
            [MSSPush unregisterWithPushServerSuccess:^{
                fail(@"unregistration success block executed incorrectly");
                
            } failure:^(NSError *error) {
                failureBlockExecuted = YES;
                
            }];
            
            [[theValue(failureBlockExecuted) shouldEventually] beTrue];
        });
    });
});

SPEC_END
