//
//  PCFPushSpecHelper.mm
//  PCFPushSDK
//
//  Created by Rob Szumlakowski on 2013-12-31.
//  Copyright (c) 2013 Pivotal. All rights reserved.
//

#import "Kiwi.h"

#import "PCFPushSpecHelper.h"
#import "PCFAppDelegate.h"
#import "PCFAppDelegateProxy.h"
#import "PCFPushSDK.h"
#import "JRSwizzle.h"
#import "PCFPushDebug.h"
#import "PCFPersistentStorage+Push.h"
#import "PCFParameters.h"

#if !__has_feature(objc_arc)
#error This spec must be compiled with ARC to work properly
#endif

@interface TestAppDelegate : NSObject <UIApplicationDelegate>
@end

@interface TestAppDelegateRemotePush : TestAppDelegate
@end

@implementation TestAppDelegate
@end

@implementation TestAppDelegateRemotePush

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    completionHandler(UIBackgroundFetchResultNoData);
}

@end

NSInteger TEST_NOTIFICATION_TYPES = UIRemoteNotificationTypeAlert;

NSString *const TEST_ANALYTICS_URL_1   = @"http://testAnalytics.url.com";
NSString *const TEST_ANALYTICS_KEY     = @"TEST-ANALYTICS-KEY";


NSString *const TEST_PUSH_API_URL_1   = @"http://test.url.com";
NSString *const TEST_VARIANT_UUID_1   = @"444-555-666-777";
NSString *const TEST_RELEASE_SECRET_1 = @"No secret is as strong as its blabbiest keeper";
NSString *const TEST_DEVICE_ALIAS_1   = @"Let's watch cat videos";
NSString *const TEST_VARIANT_UUID_2   = @"222-444-999-ZZZ";
NSString *const TEST_RELEASE_SECRET_2 = @"My cat's breath smells like cat food";
NSString *const TEST_DEVICE_ALIAS_2   = @"I can haz cheezburger?";

@implementation PCFPushSpecHelper

# pragma mark - Spec Helper lifecycle

- (instancetype) init
{
    self = [super init];
    if (self) {
        self.apnsDeviceToken = [@"TEST DEVICE TOKEN 1" dataUsingEncoding:NSUTF8StringEncoding];
        self.apnsDeviceToken2 = [@"TEST DEVICE TOKEN 2" dataUsingEncoding:NSUTF8StringEncoding];
        self.backEndDeviceId = @"BACK END DEVICE ID 1";
        self.backEndDeviceId2 = @"BACK END DEVICE ID 2";
        self.base64AuthString1 = @"NDQ0LTU1NS02NjYtNzc3Ok5vIHNlY3JldCBpcyBhcyBzdHJvbmcgYXMgaXRzIGJsYWJiaWVzdCBrZWVwZXI=";//TEST_VARIANT_UUID_1:TEST_RELEASE_SECRET_1
        self.base64AuthString2 = @"MjIyLTQ0NC05OTktWlpaOk15IGNhdCdzIGJyZWF0aCBzbWVsbHMgbGlrZSBjYXQgZm9vZA==";//TEST_VARIANT_UUID_2:TEST_RELEASE_SECRET_2
        self.application = [UIApplication sharedApplication];
        [PCFPersistentStorage resetPushPersistedValues];
    }
    return self;
}

- (void) reset
{
    self.params = nil;
    self.apnsDeviceToken = nil;
    self.apnsDeviceToken2 = nil;
    self.backEndDeviceId = nil;
    self.backEndDeviceId2 = nil;
    self.application = nil;
    self.applicationDelegate = nil;
}

#pragma mark - Application helpers

- (id) setupApplication
{
    self.application = [KWMock mockForClass:[UIApplication class]];
    [UIApplication stub:@selector(sharedApplication) andReturn:self.application];
    return self.application;
}

- (void)stubApplication
{
    [self.application stub:@selector(delegate) andReturn:self.applicationDelegate];
    [self.application stub:@selector(setDelegate:) withBlock:^id(NSArray *params) {
        if ([params[0] conformsToProtocol:@protocol(UIApplicationDelegate)]) {
            self.applicationDelegate = params[0];
        }
        return nil;
    }];
}

- (void) setupApplicationForSuccessfulRegistration
{
    [self setupApplicationForSuccessfulRegistrationWithNewApnsDeviceToken:self.apnsDeviceToken];
}

- (void) setupApplicationForSuccessfulRegistrationWithNewApnsDeviceToken:(NSData *)newApnsDeviceToken
{
    [self.application stub:@selector(registerForRemoteNotificationTypes:) withBlock:^id(NSArray *params) {
        if ([self.applicationDelegate respondsToSelector:@selector(application:didRegisterForRemoteNotificationsWithDeviceToken:)]) {
            [(PCFAppDelegate *)self.applicationDelegate application:self.application
                       didRegisterForRemoteNotificationsWithDeviceToken:newApnsDeviceToken];
        }
        return nil;
    }];
}

- (void) setupApplicationForFailedRegistrationWithError:(NSError *)error
{
    [self.application stub:@selector(registerForRemoteNotificationTypes:) withBlock:^id(NSArray *params) {
        if ([self.applicationDelegate respondsToSelector:@selector(application:didFailToRegisterForRemoteNotificationsWithError:)]) {
            [(PCFAppDelegate *)self.applicationDelegate application:self.application
                             didFailToRegisterForRemoteNotificationsWithError:error];
        }
        return nil;
    }];
}

#pragma mark - App Delegate Helpers

- (id<UIApplicationDelegate>) setupMockApplicationDelegateWithoutRemotePush
{
    self.applicationDelegate = [KWMock mockForClass:[TestAppDelegate class]];
    [(NSObject *)self.applicationDelegate stub:@selector(conformsToProtocol:)
                                     andReturn:@YES
                                 withArguments:@protocol(UIApplicationDelegate)];
    
    [self stubApplication];
    
    return self.applicationDelegate;
}

- (id<UIApplicationDelegate>) setupMockApplicationDelegateWithRemotePush
{
    self.applicationDelegate = [KWMock mockForClass:[TestAppDelegateRemotePush class]];
    [(NSObject *)self.applicationDelegate stub:@selector(conformsToProtocol:)
                                     andReturn:@YES
                                 withArguments:@protocol(UIApplicationDelegate)];
    [(NSObject *)self.applicationDelegate stub:@selector(application:didReceiveRemoteNotification:fetchCompletionHandler:) withBlock:^id(NSArray *params) {
        void (^completionHandler)(UIBackgroundFetchResult) = params[2];
        completionHandler(UIBackgroundFetchResultNoData);
        return nil;
    }];
    
    [self stubApplication];
    
    return self.applicationDelegate;
}

- (id<UIApplicationDelegate>) setupApplicationDelegate
{
    self.applicationDelegate = [[PCFAppDelegate alloc] init];
    [self stubApplication];
    return self.applicationDelegate;
}

- (void) setupApplicationDelegateForSuccessfulRegistration
{
    [self setupApplicationDelegateForSuccessfulRegistrationWithApnsDeviceToken:self.apnsDeviceToken];
}

- (void) setupApplicationDelegateForSuccessfulRegistrationWithApnsDeviceToken:(NSData *)apnsDeviceToken
{
    [(id)self.applicationDelegate stub:@selector(application:didRegisterForRemoteNotificationsWithDeviceToken:) withArguments:self.application, apnsDeviceToken, nil];
}

- (void) setupApplicationDelegateForFailedRegistrationWithError:(NSError *)error
{
    [(id)self.applicationDelegate stub:@selector(application:didFailToRegisterForRemoteNotificationsWithError:) withArguments:self.application, error, nil];
}

- (void) setupApplicationDelegateToReceiveNotification:(NSDictionary *)userInfo
{
    [(id)self.applicationDelegate stub:@selector(application:didReceiveRemoteNotification:) withArguments:self.application, userInfo, nil];
}

#pragma mark - Parameters helpers

- (PCFParameters *)setupParameters
{
    PCFParameters *params = [PCFParameters parameters];
    params.developmentPushVariantUUID = TEST_VARIANT_UUID_1;
    params.developmentPushReleaseSecret = TEST_RELEASE_SECRET_1;
    params.pushAPIURL = TEST_PUSH_API_URL_1;
    params.pushDeviceAlias = TEST_DEVICE_ALIAS_1;
    params.pushAutoRegistrationEnabled = YES;
    params.analyticsAPIURL = TEST_ANALYTICS_URL_1;
    params.developmentAnalyticsKey = TEST_ANALYTICS_KEY;
    self.params = params;
    return self.params;
}

- (void) changeVariantUUIDInParameters:(NSString*)newVariantUUID
{
    [self.params setDevelopmentPushVariantUUID:newVariantUUID];
}

- (void) changeReleaseSecretInParameters:(NSString*)newReleaseSecret
{
    [self.params setDevelopmentPushReleaseSecret:newReleaseSecret];
}

- (void) changeDeviceAliasInParameters:(NSString*)newDeviceAlias
{
    [self.params setPushDeviceAlias:newDeviceAlias];
}

- (void)setupDefaultSavedParameters
{
    [PCFPersistentStorage setReleaseSecret:TEST_RELEASE_SECRET_1];
    [PCFPersistentStorage setVariantUUID:TEST_VARIANT_UUID_1];
    [PCFPersistentStorage setDeviceAlias:TEST_DEVICE_ALIAS_1];
    [PCFPersistentStorage setAPNSDeviceToken:self.apnsDeviceToken];
    [PCFPersistentStorage setServerDeviceID:self.backEndDeviceId];
}

#pragma mark - NSURLConnection Helpers

- (BOOL) swizzleAsyncRequestWithSelector:(SEL)selector
                                   error:(NSError **)error
{
    return [NSURLConnection jr_swizzleClassMethod:@selector(sendAsynchronousRequest:queue:completionHandler:) withClassMethod:selector error:error];
}

@end
