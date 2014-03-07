//
//  OmniaPushApplicationDelegateSwitcher.h
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2014-01-13.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol OmniaPushApplicationDelegateSwitcherProtocol <NSObject>

+ (void)switchApplicationDelegate:(NSObject<UIApplicationDelegate> *)applicationDelegate inApplication:(UIApplication *)application;

@end
