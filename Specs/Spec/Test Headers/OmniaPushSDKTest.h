//
//  OmniaPushSDKTest.h
//  OmniaPushSDK
//
//  Created by DX123-XL on 3/12/2014.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import "OmniaPushSDK.h"

@interface OmniaPushSDK (TestingHeader)

+ (void)setWorkerQueue:(NSOperationQueue *)workerQueue;

@end