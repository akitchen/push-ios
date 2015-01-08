//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^CompletionHandler)(NSURLResponse *response, NSData *data, NSError *connectionError);

@interface NSURLConnection (PCFBackEndConnection)

+ (void)pcf_sendAsynchronousRequest:(NSURLRequest *)request
                            success:(void (^)(NSURLResponse *response, NSData *data))success
                            failure:(void (^)(NSError *error))failure;

+ (void)pcf_sendAsynchronousRequest:(NSURLRequest *)request
                              queue:(NSOperationQueue *)queue
                            success:(void (^)(NSURLResponse *response, NSData *data))success
                            failure:(void (^)(NSError *error))failure;

@end
