//
//  PCFPushClient.m
//  
//
//  Created by DX123-XL on 2014-04-23.
//
//

#import <UIKit/UIKit.h>

#import "PCFPushClient.h"
#import "PCFPushParameters.h"
#import "PCFPushAppDelegate.h"
#import "PCFPushAppDelegateProxy.h"
#import "PCFPushPersistentStorage.h"
#import "PCFPushURLConnection.h"
#import "NSObject+PCFPushJsonizable.h"
#import "PCFPushRegistrationResponseData.h"
#import "NSURLConnection+PCFPushBackEndConnection.h"
#import "PCFPushDebug.h"
#import "PCFPushErrorUtil.h"
#import "PCFPushErrors.h"

static PCFPushClient *_sharedPCFPushClient;
static dispatch_once_t _sharedPCFPushClientToken;

@implementation PCFPushClient

+ (instancetype)shared
{
    dispatch_once(&_sharedPCFPushClientToken, ^{
        if (!_sharedPCFPushClient) {
            _sharedPCFPushClient = [[self alloc] init];
        }
    });
    return _sharedPCFPushClient;
}

+ (void)resetSharedPushClient
{
    _sharedPCFPushClientToken = 0;
    _sharedPCFPushClient = nil;
}

- (id)init
{
    self = [super init];
    if (self) {
        self.notificationTypes = (UIRemoteNotificationTypeAlert
                                  |UIRemoteNotificationTypeBadge
                                  |UIRemoteNotificationTypeSound);
        [self swapAppDelegate];
    }
    return self;
}

- (void)swapAppDelegate
{
    UIApplication *application = [UIApplication sharedApplication];
    PCFPushAppDelegate *pushAppDelegate;
    
    if (application.delegate == self.appDelegateProxy) {
        pushAppDelegate = (PCFPushAppDelegate *)[self.appDelegateProxy pushAppDelegate];
        
    } else {
        self.appDelegateProxy = [[PCFPushAppDelegateProxy alloc] init];
        
        @synchronized(application) {
            pushAppDelegate = [[PCFPushAppDelegate alloc] init];
            self.appDelegateProxy.originalAppDelegate = application.delegate;
            self.appDelegateProxy.pushAppDelegate = pushAppDelegate;
            application.delegate = self.appDelegateProxy;
        }
    }
    
    [pushAppDelegate setRegistrationBlockWithSuccess:^(NSData *deviceToken) {
        [self APNSRegistrationSuccess:deviceToken];
        
    } failure:^(NSError *error) {
        if (self.failureBlock) {
            self.failureBlock(error);
        }
    }];
}

- (void)registerForRemoteNotifications
{
    if (self.notificationTypes != UIRemoteNotificationTypeNone) {
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:self.notificationTypes];
    }
}

typedef void (^RegistrationBlock)(NSURLResponse *response, id responseData);

+ (RegistrationBlock)registrationBlockWithParameters:(PCFPushParameters *)parameters
                                         deviceToken:(NSData *)deviceToken
                                             success:(void (^)(void))successBlock
                                             failure:(void (^)(NSError *error))failureBlock
{
    RegistrationBlock registrationBlock = ^(NSURLResponse *response, id responseData) {
        NSError *error;
        
        if (!responseData || ([responseData isKindOfClass:[NSData class]] && [(NSData *)responseData length] <= 0)) {
            error = [PCFPushErrorUtil errorWithCode:PCFPushBackEndRegistrationEmptyResponseData localizedDescription:@"Response body is empty when attempting registration with back-end server"];
            failureBlock(error);
            return;
        }
        
        PCFPushRegistrationResponseData *parsedData = [PCFPushRegistrationResponseData fromJSONData:responseData error:&error];
        
        if (error) {
            failureBlock(error);
            return;
        }
        
        if (!parsedData.deviceUUID) {
            error = [PCFPushErrorUtil errorWithCode:PCFPushBackEndRegistrationResponseDataNoDeviceUuid localizedDescription:@"Response body from registering with the back-end server does not contain an UUID "];
            failureBlock(error);
            return;
        }
        
        PCFPushLog(@"Registration with back-end succeded. Device ID: \"%@\".", parsedData.deviceUUID);
        [PCFPushPersistentStorage setAPNSDeviceToken:deviceToken];
        [PCFPushPersistentStorage setPushServerDeviceID:parsedData.deviceUUID];
        [PCFPushPersistentStorage setVariantUUID:parameters.variantUUID];
        [PCFPushPersistentStorage setReleaseSecret:parameters.releaseSecret];
        [PCFPushPersistentStorage setDeviceAlias:parameters.deviceAlias];
        
        successBlock();
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
        
        [PCFPushURLConnection updateRegistrationWithDeviceID:[PCFPushPersistentStorage pushServerDeviceID]
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

+ (void)sendRegisterRequestWithParameters:(PCFPushParameters *)parameters
                              deviceToken:(NSData *)deviceToken
                                  success:(void (^)(void))successBlock
                                  failure:(void (^)(NSError *error))failureBlock
{
    RegistrationBlock registrationBlock = [self registrationBlockWithParameters:parameters
                                                                    deviceToken:deviceToken
                                                                        success:successBlock
                                                                        failure:failureBlock];
    [PCFPushURLConnection registerWithParameters:parameters
                                    deviceToken:deviceToken
                                        success:registrationBlock
                                        failure:failureBlock];
}

+ (BOOL)updateRegistrationRequiredForDeviceToken:(NSData *)deviceToken
                                      parameters:(PCFPushParameters *)parameters
{
    // If not currently registered with the back-end then update registration is not required
    if (![PCFPushPersistentStorage APNSDeviceToken]) {
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
                                parameters:(PCFPushParameters *)parameters
{
    // If not currently registered with the back-end then registration will be required
    if (![PCFPushPersistentStorage pushServerDeviceID]) {
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

+ (BOOL)localParametersMatchNewParameters:(PCFPushParameters *)parameters
{
    // If any of the registration parameters are different then unregistration is required
    if (![parameters.variantUUID isEqualToString:[PCFPushPersistentStorage variantUUID]]) {
        PCFPushLog(@"Parameters specify a different variantUUID. Unregistration and re-registration will be required.");
        return NO;
    }
    
    if (![parameters.releaseSecret isEqualToString:[PCFPushPersistentStorage releaseSecret]]) {
        PCFPushLog(@"Parameters specify a different releaseSecret. Unregistration and re-registration will be required.");
        return NO;
    }
    
    if (![parameters.deviceAlias isEqualToString:[PCFPushPersistentStorage deviceAlias]]) {
        PCFPushLog(@"Parameters specify a different deviceAlias. Unregistration and re-registration will be required.");
        return NO;
    }
    
    return YES;
}

+ (BOOL)localDeviceTokenMatchesNewToken:(NSData *)deviceToken {
    if (![deviceToken isEqualToData:[PCFPushPersistentStorage APNSDeviceToken]]) {
        PCFPushLog(@"APNS returned a different APNS token. Unregistration and re-registration will be required.");
        return NO;
    }
    return YES;
}

@end
