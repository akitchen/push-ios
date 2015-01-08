//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#import "MSSPushErrors.h"
#import "NSURLConnection+MSSBackEndConnection.h"
#import "NSObject+MSSJsonizable.h"
#import "MSSPushDebug.h"
#import "MSSPushErrorUtil.h"

@implementation NSURLConnection (MSSBackEndConnection)

+ (void)mss_sendAsynchronousRequest:(NSURLRequest *)request
                            success:(void (^)(NSURLResponse *response, NSData *data))success
                            failure:(void (^)(NSError *error))failure
{
    [self mss_sendAsynchronousRequest:request
                                queue:[NSOperationQueue mainQueue]
                              success:success
                              failure:failure];
}

+ (void)mss_sendAsynchronousRequest:(NSURLRequest *)request
                              queue:(NSOperationQueue *)queue
                            success:(void (^)(NSURLResponse *response, NSData *data))success
                            failure:(void (^)(NSError *error))failure
{
    if (!request || !request.URL) {
        MSSPushLog(@"Required URL request is nil.");
        NSError *error = [NSError errorWithDomain:MSSPushErrorDomain code:MSSPushBackEndUnregistrationFailedRequestStatusCode userInfo:nil];
        if (failure) {
            failure(error);
        }
        return;
    }
    
    //TODO Complete GZIP code to compress HTTPBody on POST/PUT
    //    if (request.HTTPBody) {
    //        [request setValue:@"gzip" forHTTPHeaderField:@"Content-Encoding"];
    //    }
    
    CompletionHandler handler = [self completionHandlerWithSuccessBlock:success failureBlock:failure];
    [self sendAsynchronousRequest:request
                            queue:queue
                completionHandler:handler];
}

#pragma mark - Utility Methods

+ (BOOL)successfulStatusForHTTPResponse:(NSHTTPURLResponse *)response {
    if (![response isKindOfClass:[NSHTTPURLResponse class]]) {
        return NO;
    }
    return [response statusCode] >= 200 && [response statusCode] < 300;
}

+ (BOOL)isAuthError:(NSError*)error {
    if (!error) {
        return NO;
    }
    return ([error.domain isEqualToString:NSURLErrorDomain] && (error.code == NSURLErrorUserCancelledAuthentication || error.code == NSURLErrorUserAuthenticationRequired));
}

+ (CompletionHandler)completionHandlerWithSuccessBlock:(void (^)(NSURLResponse *response, NSData *data))success
                                failureBlock:(void (^)(NSError *error))failure
{
    CompletionHandler handler = ^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        if ([self isAuthError:connectionError]) {
            MSSPushCriticalLog(@"NSURLRequest failed with authentication error.");
            if (failure) {
                NSError *authError = [MSSPushErrorUtil errorWithCode:MSSPushBackEndRegistrationAuthenticationError localizedDescription:@"Authentication error while communicating with the back-end server.  Check your variant uuid and secret parameters."];
                failure(authError);
            }
        } else if (connectionError) {
            MSSPushCriticalLog(@"NSURLRequest failed with error: %@ %@", connectionError, connectionError.userInfo);
            if (failure) {
                failure(connectionError);
            }
        } else if (![self successfulStatusForHTTPResponse:(NSHTTPURLResponse *)response]) {
            NSString *description = [NSString stringWithFormat:@"Failed HTTP Status Code: %ld", (long)[(NSHTTPURLResponse *)response statusCode]];
            NSError *error = [MSSPushErrorUtil errorWithCode:MSSPushBackEndRegistrationFailedHTTPStatusCode localizedDescription:description];
            MSSPushCriticalLog(@"NSURLRequest unsuccessful HTTP response code: %@ %@", error, error.userInfo);
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
