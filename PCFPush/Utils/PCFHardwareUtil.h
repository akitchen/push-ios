//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PCFHardwareUtil : NSObject

+ (NSString *)operatingSystem;

+ (NSString *)operatingSystemVersion;

+ (NSString *)deviceModel;

+ (NSString *)deviceManufacturer;

@end
