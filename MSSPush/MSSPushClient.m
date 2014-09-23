//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#import <objc/runtime.h>

#import "MSSPushClient.h"
#import "MSSPushDebug.h"
#import "MSSPushErrors.h"
#import "MSSParameters.h"
#import "MSSAppDelegate.h"
#import "MSSNotifications.h"
#import "MSSPushErrorUtil.h"
#import "MSSAppDelegateProxy.h"
#import "MSSPushURLConnection.h"
#import "NSObject+MSSJsonizable.h"
#import "MSSPushPersistentStorage.h"
#import "MSSPushRegistrationResponseData.h"

static MSSPushClient *_sharedMSSPushClient;
static dispatch_once_t _sharedMSSPushClientToken;

@implementation MSSPushClient

+ (instancetype)shared
{
    dispatch_once(&_sharedMSSPushClientToken, ^{
        if (!_sharedMSSPushClient) {
            _sharedMSSPushClient = [[self alloc] init];
        }
    });
    return _sharedMSSPushClient;
}

- (id)init
{
    self = [super init];
    if (self) {
        self.notificationTypes = (UIRemoteNotificationTypeAlert
                                  |UIRemoteNotificationTypeBadge
                                  |UIRemoteNotificationTypeSound);
        self.registrationParameters = [MSSParameters defaultParameters];
        [self swapAppDelegate];
    }
    return self;
}

- (MSSAppDelegate *)swapAppDelegate
{
    UIApplication *application = [UIApplication sharedApplication];
    MSSAppDelegate *pushAppDelegate;
    
    if (application.delegate == self.appDelegateProxy) {
        pushAppDelegate = (MSSAppDelegate *)[self.appDelegateProxy swappedAppDelegate];
        
    } else {
        self.appDelegateProxy = [[MSSAppDelegateProxy alloc] init];
        
        @synchronized(application) {
            pushAppDelegate = [[MSSAppDelegate alloc] init];
            self.appDelegateProxy.originalAppDelegate = application.delegate;
            self.appDelegateProxy.swappedAppDelegate = pushAppDelegate;
            application.delegate = self.appDelegateProxy;
        }
    }
    
    [pushAppDelegate setPushRegistrationBlockWithSuccess:^(NSData *deviceToken) {
        [self APNSRegistrationSuccess:deviceToken];
        
    } failure:^(NSError *error) {
        if (self.failureBlock) {
            self.failureBlock(error);
        }
    }];
    
    return pushAppDelegate;
}

- (void)resetInstance
{
    self.registrationParameters = nil;
}

+ (void)resetSharedClient
{
    if (_sharedMSSPushClient) {
        [_sharedMSSPushClient resetInstance];
    }
    
    _sharedMSSPushClientToken = 0;
    _sharedMSSPushClient = nil;
}

- (void)registerForRemoteNotifications
{
    if (!self.registrationParameters) {
        [NSException raise:NSInvalidArgumentException format:@"Parameters may not be nil."];
    }
    
    if (![self.registrationParameters arePushParametersValid]) {
        [NSException raise:NSInvalidArgumentException format:@"Parameters are not valid. See log for more info."];
    }

    UIApplication *application = [UIApplication sharedApplication];
    
    if ([application respondsToSelector:@selector(registerForRemoteNotifications)]) {
        
        // If this line gives you a compiler error then you need to make sure you have updated
        // your Xcode to at least Xcode 6.0:
        [application registerForRemoteNotifications]; // iOS 8.0+
        
    } else {
        
        // < iOS 8.0. Deprecated on iOS 8.0.
        [application registerForRemoteNotificationTypes:self.notificationTypes];
    }
}

- (void)unregisterForRemoteNotificationsWithSuccess:(void (^)(void))success
                                            failure:(void (^)(NSError *error))failure
{
    NSString *deviceId = [MSSPushPersistentStorage serverDeviceID];
    if (!deviceId || deviceId.length <= 0) {
        MSSPushLog(@"Not currently registered.");
        [self handleUnregistrationSuccess:success userInfo:@{ @"Response": @"Already unregistered."}];
        return;
    }
    
    [MSSPushURLConnection unregisterDeviceID:deviceId
                                  parameters:self.registrationParameters
                                     success:^(NSURLResponse *response, NSData *data) {
                                         
                                         [self handleUnregistrationSuccess:success userInfo:@{ @"URLResponse" : response }];
                                     }
                                     failure:failure];
}

- (void) handleUnregistrationSuccess:(void (^)(void))success userInfo:(NSDictionary*)userInfo
{
    [MSSPushPersistentStorage reset];
    
    if (success) {
        success();
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:MSSPushUnregisterNotification object:self userInfo:userInfo];
}

typedef void (^RegistrationBlock)(NSURLResponse *response, id responseData);

+ (RegistrationBlock)registrationBlockWithParameters:(MSSParameters *)parameters
                                         deviceToken:(NSData *)deviceToken
                                             success:(void (^)(void))successBlock
                                             failure:(void (^)(NSError *error))failureBlock
{
    RegistrationBlock registrationBlock = ^(NSURLResponse *response, id responseData) {
        NSError *error;
        
        if (!responseData || ([responseData isKindOfClass:[NSData class]] && [(NSData *)responseData length] <= 0)) {
            error = [MSSPushErrorUtil errorWithCode:MSSPushBackEndRegistrationEmptyResponseData localizedDescription:@"Response body is empty when attempting registration with back-end server"];
            MSSPushLog(@"%@", error);
            
            if (failureBlock) {
                failureBlock(error);
            }
            return;
        }
        
        MSSPushRegistrationResponseData *parsedData = [MSSPushRegistrationResponseData mss_fromJSONData:responseData error:&error];
        
        if (error) {
            MSSPushLog(@"%@", error);
            
            if (failureBlock) {
                failureBlock(error);
            }
            return;
        }
        
        if (!parsedData.deviceUUID) {
            error = [MSSPushErrorUtil errorWithCode:MSSPushBackEndRegistrationResponseDataNoDeviceUuid localizedDescription:@"Response body from registering with the back-end server does not contain an UUID "];
            MSSPushLog(@"%@", error);
            
            if (failureBlock) {
                failureBlock(error);
            }
            return;
        }
        
        MSSPushLog(@"Registration with back-end succeded. Device ID: \"%@\".", parsedData.deviceUUID);
        [MSSPushPersistentStorage setAPNSDeviceToken:deviceToken];
        [MSSPushPersistentStorage setServerDeviceID:parsedData.deviceUUID];
        [MSSPushPersistentStorage setVariantUUID:parameters.variantUUID];
        [MSSPushPersistentStorage setVariantSecret:parameters.variantSecret];
        [MSSPushPersistentStorage setDeviceAlias:parameters.pushDeviceAlias];
        [MSSPushPersistentStorage setTags:parameters.pushTags];
        
        if (successBlock) {
            successBlock();
        }
        
        NSDictionary *userInfo = @{ @"URLResponse" : response };
        [[NSNotificationCenter defaultCenter] postNotificationName:MSSPushRegistrationSuccessNotification object:self userInfo:userInfo];
    };
    
    return registrationBlock;
}

- (void)APNSRegistrationSuccess:(NSData *)deviceToken
{
    if (!deviceToken) {
        [NSException raise:NSInvalidArgumentException format:@"Device Token cannot not be nil."];
    }
    if (![deviceToken isKindOfClass:[NSData class]]) {
        [NSException raise:NSInvalidArgumentException format:@"Device Token type does not match expected type. NSData."];
    }
    
    if ([self.class updateRegistrationRequiredForDeviceToken:deviceToken parameters:self.registrationParameters]) {
        RegistrationBlock registrationBlock = [self.class registrationBlockWithParameters:self.registrationParameters
                                                                              deviceToken:deviceToken
                                                                                  success:self.successBlock
                                                                                  failure:self.failureBlock];
        
        [MSSPushURLConnection updateRegistrationWithDeviceID:[MSSPushPersistentStorage serverDeviceID]
                                                  parameters:self.registrationParameters
                                                 deviceToken:deviceToken
                                                     success:registrationBlock
                                                     failure:self.failureBlock];
        
    } else if ([self.class registrationRequiredForDeviceToken:deviceToken parameters:self.registrationParameters]) {
        [self.class sendRegisterRequestWithParameters:self.registrationParameters
                                          deviceToken:deviceToken
                                              success:self.successBlock
                                              failure:self.failureBlock];
        
    } else if (self.successBlock) {
        self.successBlock();
    }
}

+ (void)sendRegisterRequestWithParameters:(MSSParameters *)parameters
                              deviceToken:(NSData *)deviceToken
                                  success:(void (^)(void))successBlock
                                  failure:(void (^)(NSError *error))failureBlock
{
    RegistrationBlock registrationBlock = [self registrationBlockWithParameters:parameters
                                                                    deviceToken:deviceToken
                                                                        success:successBlock
                                                                        failure:failureBlock];
    [MSSPushURLConnection registerWithParameters:parameters
                                     deviceToken:deviceToken
                                         success:registrationBlock
                                         failure:failureBlock];
}

+ (BOOL)updateRegistrationRequiredForDeviceToken:(NSData *)deviceToken
                                      parameters:(MSSParameters *)parameters
{
    // If not currently registered with the back-end then update registration is not required
    if (![MSSPushPersistentStorage APNSDeviceToken]) {
        return NO;
    }
    
    if (![self localDeviceTokenMatchesNewToken:deviceToken]) {
        return YES;
    }
    
    if (![self localParametersMatchNewParameters:parameters]) {
        return YES;
    }
    
    return NO;
}

+ (BOOL)registrationRequiredForDeviceToken:(NSData *)deviceToken
                                parameters:(MSSParameters *)parameters
{
    // If not currently registered with the back-end then registration will be required
    if (![MSSPushPersistentStorage serverDeviceID]) {
        return YES;
    }
    
    if (![self localDeviceTokenMatchesNewToken:deviceToken]) {
        return YES;
    }
    
    if (![self localParametersMatchNewParameters:parameters]) {
        return YES;
    }
    
    return NO;
}

+ (BOOL)localParametersMatchNewParameters:(MSSParameters *)parameters
{
    // If any of the registration parameters are different then unregistration is required
    NSString *savedVariantUUID = [MSSPushPersistentStorage variantUUID];
    if ((parameters.variantUUID == nil && savedVariantUUID != nil) || (parameters.variantUUID != nil && ![parameters.variantUUID isEqualToString:savedVariantUUID])) {
        MSSPushLog(@"Parameters specify a different variantUUID. Unregistration and re-registration will be required.");
        return NO;
    }
    
    NSString *savedVariantSecret = [MSSPushPersistentStorage variantSecret];
    if ((parameters.variantSecret == nil && savedVariantSecret != nil) || (parameters.variantSecret != nil && ![parameters.variantSecret isEqualToString:savedVariantSecret])) {
        MSSPushLog(@"Parameters specify a different variantSecret. Unregistration and re-registration will be required.");
        return NO;
    }
    
    NSString *savedDeviceAlias = [MSSPushPersistentStorage deviceAlias];
    if ((parameters.pushDeviceAlias == nil && savedDeviceAlias != nil) || (parameters.pushDeviceAlias != nil && ![parameters.pushDeviceAlias isEqualToString:savedDeviceAlias])) {
        MSSPushLog(@"Parameters specify a different deviceAlias. Unregistration and re-registration will be required.");
        return NO;
    }
    
    NSSet *savedTags = [MSSPushPersistentStorage tags];
    BOOL areSavedTagsNilOrEmpty = savedTags == nil || savedTags.count == 0;
    BOOL areNewTagsNilOrEmpty = parameters.pushTags == nil || parameters.pushTags.count == 0;
    if ((areNewTagsNilOrEmpty && !areSavedTagsNilOrEmpty) || (!areNewTagsNilOrEmpty && ![parameters.pushTags isEqualToSet:savedTags])) {
        MSSPushLog(@"Parameters specify a different set of tags. Update registration will be required.");
        return NO;
    }

    return YES;
}

+ (BOOL)localDeviceTokenMatchesNewToken:(NSData *)deviceToken {
    if (![deviceToken isEqualToData:[MSSPushPersistentStorage APNSDeviceToken]]) {
        MSSPushLog(@"APNS returned a different APNS token. Unregistration and re-registration will be required.");
        return NO;
    }
    return YES;
}

@end
