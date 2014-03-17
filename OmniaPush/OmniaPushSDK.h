//
//  OmniaPushSDK.h
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2013-12-31.
//  Copyright (c) 2013 Pivotal. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OmniaPushRegistrationParameters;

/**
 * Primary entry point for the Omnia Push Client SDK library.
 *
 * Usage: see `README.md`
 *
 */
@interface OmniaPushSDK : NSObject

/**
 * Asynchronously registers the device and application for receiving push notifications.  If the application
 * is already registered then this call will do nothing.  If some of the registration parameters are different
 * then the last successful registration then the device will be re-registered with the new parameters.  Only
 * the first call to either of the register methods will do anything.  Only one registration attempt is allowed
 * per lifetime of the process.
 *
 * @param parameters Provides the parameters required for registration.  May not be `nil`.
 */
+ (void)registerWithParameters:(OmniaPushRegistrationParameters *)parameters;

/**
 * Asynchronously registers the device and application for receiving push notifications.  If the application
 * is already registered then this call will do nothing.  If some of the registration parameters are different
 * then the last successful registration then the device will be re-registered with the new parameters.  Only
 * the first call to either of the register methods will do anything.  Only one registration attempt is allowed
 * per lifetime of the process.
 *
 * @param parameters Provides the parameters required for registration.  May not be `nil`.
 *
 * @param listener Optional listener for receiving a callback after registration finishes. This callback will
 *                 be called on the main thread.  May be `nil`.
 *
 * @note It is possible for APNS registration to fail silently and never call back.  These
 *       scenarios could be considered failures, but will never be reported.
 */
+ (void)registerWithParameters:(OmniaPushRegistrationParameters *)parameters
                       success:(void (^)(NSURLResponse *response, id responseObject))success
                       failure:(void (^)(NSURLResponse *response, NSError *error))failure;

@end
