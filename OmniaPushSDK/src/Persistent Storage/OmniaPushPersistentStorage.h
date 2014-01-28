//
//  OmniaPushPersistentStorage.h
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2014-01-17.
//  Copyright (c) 2014 Omnia. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OmniaPushPersistentStorage : NSObject

- (void) reset;

- (void) saveAPNSDeviceToken:(NSData*)apnsDeviceToken;
- (NSData*) loadAPNSDeviceToken;

- (void) saveBackEndDeviceID:(NSString*)backEndDeviceId;
- (NSString*) loadBackEndDeviceID;

@end
