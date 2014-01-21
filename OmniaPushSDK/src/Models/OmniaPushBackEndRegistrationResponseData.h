//
//  OmniaPushBackEndRegistrationResponseData.h
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2014-01-21.
//  Copyright (c) 2014 Omnia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OmniaPushDictionaryizable.h"
#import "OmniaPushJsonizable.h"

@interface OmniaPushBackEndRegistrationResponseData : NSObject<OmniaPushJsonizable, OmniaPushDictionaryizable>

@property (nonatomic) NSString *replicantId;
@property (nonatomic) NSString *deviceUuid;
@property (nonatomic) NSString *deviceAlias;
@property (nonatomic) NSString *deviceManufacturer;
@property (nonatomic) NSString *deviceModel;
@property (nonatomic) NSString *os;
@property (nonatomic) NSString *osVersion;
@property (nonatomic) NSString *registrationToken;

@end
