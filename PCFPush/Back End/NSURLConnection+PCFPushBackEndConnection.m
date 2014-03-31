//
//  NSURLConnection+PCFPushBackEndConnection.m
//  PCFPushSDK
//
//  Created by DX123-XL on 3/4/2014.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import "PCFPushErrors.h"
#import "NSURLConnection+PCFPushBackEndConnection.h"
#import "NSObject+PCFPushJsonizable.h"
#import "PCFPushParameters.h"
#import "PCFPushHexUtil.h"
#import "PCFPushHardwareUtil.h"
#import "PCFPushRegistrationRequestData.h"
#import "PCFPushParameters.h"
#import "PCFPushDebug.h"
#import "PCFPushErrorUtil.h"

typedef void (^Handler)(NSURLResponse *response, NSData *data, NSError *connectionError);

static NSString *const BACK_END_REQUEST_URL = @"http://ec2-54-234-124-123.compute-1.amazonaws.com:8090/v1";
static NSString *const BACK_END_REGISTRATION_REQUEST_URL = @"registration";
static NSString *const BACK_END_ANALYTICS_REQUEST_URL = @"analytics";
static CGFloat BACK_END_REGISTRATION_TIMEOUT_IN_SECONDS = 60.0;

@implementation NSURLConnection (PCFPushBackEndConnection)

+ (NSURL *)baseURL
{
    static NSURL *baseURL;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        baseURL = [NSURL URLWithString:BACK_END_REQUEST_URL];
    });
    return baseURL;
}

+ (void)cf_unregisterDeviceID:(NSString *)deviceID
                   success:(void (^)(NSURLResponse *response, NSData *data))success
                   failure:(void (^)(NSError *error))failure
{
    [self cf_sendAsynchronousRequest:[self unregisterRequestForBackEndDeviceID:deviceID]
                                success:success
                                failure:failure];
}

+ (void)cf_registerWithParameters:(PCFPushParameters *)parameters
                      devToken:(NSData *)devToken
                       success:(void (^)(NSURLResponse *response, NSData *data))success
                       failure:(void (^)(NSError *error))failure
{
    [self cf_sendAsynchronousRequest:[self registrationRequestForAPNSDeviceToken:devToken
                                                                      parameters:parameters]
                             success:success
                             failure:failure];
}

+ (void)cf_sendAsynchronousRequest:(NSURLRequest *)request
                        success:(void (^)(NSURLResponse *response, NSData *data))success
                        failure:(void (^)(NSError *error))failure
{
    if (!success) {
        [NSException raise:NSInvalidArgumentException format:@"success block may not be nil"];
    }
    
    if (!failure) {
        [NSException raise:NSInvalidArgumentException format:@"failure block may not be nil"];
    }
    
    if (!request) {
        NSError *error = [NSError errorWithDomain:PCFPushErrorDomain code:PCFPushBackEndUnregistrationFailedRequestStatusCode userInfo:nil];
        failure(error);
        return;
    }
    
    Handler handler = [self completionHandlerWithSuccessBlock:success failureBlock:failure];
    [self sendAsynchronousRequest:request
                            queue:[NSOperationQueue mainQueue]
                completionHandler:handler];
}

#pragma mark - Registration

+ (NSMutableURLRequest *)registrationRequestForAPNSDeviceToken:(NSData *)apnsDeviceToken
                                                    parameters:(PCFPushParameters *)parameters
{
    if (!apnsDeviceToken) {
        [NSException raise:NSInvalidArgumentException format:@"APNSDeviceToken may not be nil"];
    }
    
    if (!parameters) {
        [NSException raise:NSInvalidArgumentException format:@"PCFPushRegistrationParameters may not be nil"];
    }
    
    NSURL *registrationURL = [NSURL URLWithString:BACK_END_REGISTRATION_REQUEST_URL relativeToURL:self.baseURL];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:registrationURL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:BACK_END_REGISTRATION_TIMEOUT_IN_SECONDS];
    request.HTTPMethod = @"POST";
    request.HTTPBody = [self requestBodyDataForForAPNSDeviceToken:apnsDeviceToken parameters:parameters];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    PCFPushLog(@"Back-end registration request: \"%@\".", [[NSString alloc] initWithData:request.HTTPBody encoding:NSUTF8StringEncoding]);
    return request;
}

+ (NSData *)requestBodyDataForForAPNSDeviceToken:(NSData *)apnsDeviceToken
                                      parameters:(PCFPushParameters *)parameters
{
    NSError *error = nil;
    PCFPushRegistrationRequestData *requestData = [self requestDataForAPNSDeviceToken:apnsDeviceToken parameters:parameters];
    return [requestData toJSONData:&error];
}

+ (PCFPushRegistrationRequestData *)requestDataForAPNSDeviceToken:(NSData *)apnsDeviceToken
                                                       parameters:(PCFPushParameters *)parameters
{
    static NSString *osVersion = nil;
    if (!osVersion) {
        osVersion = [[UIDevice currentDevice] systemVersion];
    }
    
    static NSString *deviceModel = nil;
    if (!deviceModel) {
        deviceModel = [PCFPushHardwareUtil hardwareSimpleDescription];
    }
    
    PCFPushRegistrationRequestData *requestData = [[PCFPushRegistrationRequestData alloc] init];
    requestData.registrationToken = [PCFPushHexUtil hexDumpForData:apnsDeviceToken];
    requestData.releaseUUID = parameters.releaseUUID;
    requestData.secret = parameters.releaseSecret;
    requestData.deviceAlias = parameters.deviceAlias;
    requestData.deviceManufacturer = @"Apple";
    requestData.deviceModel = deviceModel;
    requestData.os = @"ios";
    requestData.osVersion = osVersion;
    return requestData;
}

#pragma mark - Unregister

+ (NSMutableURLRequest *)unregisterRequestForBackEndDeviceID:(NSString *)backEndDeviceUUID
{
    if (!backEndDeviceUUID) {
        return nil;
    }
    
    NSURL *rootURL = [NSURL URLWithString:BACK_END_REGISTRATION_REQUEST_URL relativeToURL:self.baseURL];
    NSURL *deviceURL = [NSURL URLWithString:backEndDeviceUUID relativeToURL:rootURL];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:deviceURL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:BACK_END_REGISTRATION_TIMEOUT_IN_SECONDS];
    request.HTTPMethod = @"DELETE";
    return request;
}

#pragma mark - Sync Analytics

+ (void)cf_syncAnalyicEvents:(NSArray *)events
                 forDeviceID:(NSString *)deviceID
                     success:(void (^)(NSURLResponse *response, NSData *data))success
                     failure:(void (^)(NSError *error))failure
{
    if (!events) {
        PCFPushCriticalLog(@"Analytic events is nil. Unable to sync analytics with server.");
        return;
    }
    
    if (events.count == 0) {
        PCFPushCriticalLog(@"Analytic events is empty. Unable to sync analytics with server.");
        return;
    }
    
    NSMutableURLRequest *request = [self syncAnalyicEventsRequestWithDeviceID:deviceID];
    NSError *error;
    NSData *bodyData = [events toJSONData:&error];
    if (error) {
        PCFPushCriticalLog(@"Error while converting analytic event to JSON: %@ %@", error, error.userInfo);
        return;
    }
    request.HTTPBody = bodyData;
    
    Handler handler = [self completionHandlerWithSuccessBlock:success failureBlock:failure];
    [self sendAsynchronousRequest:request
                            queue:[NSOperationQueue currentQueue]
                completionHandler:handler];
}

+ (NSMutableURLRequest *)syncAnalyicEventsRequestWithDeviceID:(NSString *)backEndDeviceUUID
{
    if (!backEndDeviceUUID) {
        return nil;
    }
    
    NSURL *analyticsURL = [NSURL URLWithString:BACK_END_ANALYTICS_REQUEST_URL relativeToURL:self.baseURL];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:analyticsURL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:BACK_END_REGISTRATION_TIMEOUT_IN_SECONDS];
    request.HTTPMethod = @"POST";
    return request;
}

#pragma mark - Utility Methods

+ (BOOL)unsuccessfulStatusForHTTPResponse:(NSHTTPURLResponse *)response {
    return [response isKindOfClass:[NSHTTPURLResponse class]] && ([response statusCode] < 200 || [response statusCode] >= 300);
}

+ (Handler)completionHandlerWithSuccessBlock:(void (^)(NSURLResponse *response, NSData *data))success
                                failureBlock:(void (^)(NSError *error))failure
{
    Handler handler = ^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        if (connectionError) {
            PCFPushCriticalLog(@"NSURLRequest failed with error: %@ %@", connectionError, connectionError.userInfo);
            if (failure) {
                failure(connectionError);
            }
        } else if ([self unsuccessfulStatusForHTTPResponse:(NSHTTPURLResponse *)response]) {
            NSError *error = [PCFPushErrorUtil errorWithCode:PCFPushBackEndRegistrationFailedHTTPStatusCode localizedDescription:@"Failed HTTP Status Code"];
            PCFPushCriticalLog(@"NSURLRequest unsuccessful HTTP response code: %@ %@", error, error.userInfo);
            if (failure) {
                failure(error);
            }
        } else {
            if (success) {
                success(response, data);
            }
        }
    };
    return handler;
}

@end
