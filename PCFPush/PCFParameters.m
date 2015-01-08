//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#import <objc/runtime.h>

#import "PCFParameters.h"
#import "PCFPushDebug.h"

#ifdef DEBUG
static BOOL kInDebug = YES;
#else
static BOOL kInDebug = NO;
#endif


@implementation PCFParameters

+ (PCFParameters *)defaultParameters
{
    return [self parametersWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"PCFParameters" ofType:@"plist"]];
}

+ (PCFParameters *)parametersWithContentsOfFile:(NSString *)path
{
    PCFParameters *params = [PCFParameters parameters];
    if (path) {
        @try {
            NSDictionary *plistDictionary = [[NSDictionary alloc] initWithContentsOfFile:path];
            [params setValuesForKeysWithDictionary:plistDictionary];
        } @catch (NSException *exception) {
            PCFPushLog(@"Exception while populating PCFParameters object. %@", exception);
            params = nil;
        }
    }
    return params;
}

+ (PCFParameters *)parameters
{
    PCFParameters *params = [[self alloc] init];
    params.pushAutoRegistrationEnabled = NO;
    return params;
}

- (NSString *)variantUUID
{
    return kInDebug ? self.developmentPushVariantUUID : self.productionPushVariantUUID;
}

- (NSString *)variantSecret
{
    return kInDebug ? self.developmentPushVariantSecret : self.productionPushVariantSecret;
}

- (BOOL)arePushParametersValid;
{
    SEL selectors[] = {
        @selector(pushDeviceAlias),
        @selector(pushAPIURL),
        @selector(pushAutoRegistrationEnabled),
        @selector(developmentPushVariantUUID),
        @selector(developmentPushVariantSecret),
        @selector(productionPushVariantUUID),
        @selector(productionPushVariantSecret),
    };
    
    // NOTE: pushTags are allowed to be nil or empty

    for (NSUInteger i = 0; i < sizeof(selectors)/sizeof(selectors[0]); i++) {
        id value = [self valueForKey:NSStringFromSelector(selectors[i])];
        if (!value || ([value respondsToSelector:@selector(length)] && [value length] <= 0)) {
            PCFPushLog(@"PCFParameters failed validation caused by an invalid parameter %@.", NSStringFromSelector(selectors[i]));
            return NO;
            break;
        }
    }
    return YES;
}

- (BOOL)inDebugMode
{
    return kInDebug;
}

@end
