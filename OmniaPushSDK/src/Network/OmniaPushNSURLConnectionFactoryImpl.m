//
//  OmniaPushNSURLConnectionFactoryImpl.m
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2014-01-28.
//  Copyright (c) 2014 Omnia. All rights reserved.
//

#import "OmniaPushNSURLConnectionFactoryImpl.h"
#import "OmniaPushNSURLConnectionFactory.h"

@implementation OmniaPushNSURLConnectionFactoryImpl

- (NSURLConnection*) getNSURLConnectionWithRequest:(NSURLRequest*)request
                                          delegate:(id<NSURLConnectionDelegate>)delegate
{
    return [NSURLConnection connectionWithRequest:request delegate:delegate];
}

@end
