//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MSSPushRegistrationData.h"

#define kSubscribeTags @"subscribe"
#define kUnsubscribeTags @"unsubscribe"

@interface MSSPushRegistrationPutRequestData : MSSPushRegistrationData

// Note - these properties need to be NSArrays since the iOS built-in JSON
// serializer can't seem to handle NSSet objects.

@property NSArray *subscribeTags;
@property NSArray *unsubscribeTags;

@end
