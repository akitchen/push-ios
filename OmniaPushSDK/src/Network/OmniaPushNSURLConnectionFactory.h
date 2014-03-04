//
//  OmniaPushNSURLConnectionFactory.h
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2014-01-28.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol OmniaPushNSURLConnectionFactory <NSObject>

+ (NSURLConnection *) connectionWithRequest:(NSURLRequest *)request
                                   delegate:(id<NSURLConnectionDelegate>)delegate;

@end
