//
//  PCFPushHardwareUtil.h
//  PCFPushSDK
//
//  Created by DX123-XL on 2014-02-24.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PCFHardwareUtil : NSObject

+ (NSString *)operatingSystem;

+ (NSString *)operatingSystemVersion;

+ (NSString *)deviceModel;

+ (NSString *)deviceManufacturer;

@end
