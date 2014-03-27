//
//  CFPushSDK.h
//  CFPushSDK
//
//  Created by Rob Szumlakowski on 2013-12-31.
//  Copyright (c) 2013 Pivotal. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CFPushParameters;

/**
 * Primary entry point for the Omnia Push Client SDK library.
 *
 * Usage: see `README.md`
 *
 */
@interface CFPushSDK : NSObject

/**
 * Asynchronously registers the device and application for receiving push notifications.  If the application
 * is already registered then this call will do nothing.  If some of the registration parameters are different
 * then the last successful registration then the device will be re-registered with the new parameters.
 *
 * @param parameters Provides the parameters required for registration.  May not be `nil`.
 *
 * @param success block that will be executed if registration finishes successfully. This callback will
 *                be called on the main queue.  May be `nil`.
 *
 * @param failure block that will be executed if registration fails. This callback will be called on the main
 *                queue.  May be `nil`.
 */

#warning - Fix documentation
+ (void)registerWithParameters:(CFPushParameters *)parameters
                       success:(void (^)(void))success
                       failure:(void (^)(NSError *error))failure;


/**
 * Asynchronously unregisters the device and application from receiving push notifications.  If the application
 * is not yet registered, then this call will do nothing.
 *
 * @param success block that will be executed if unregistration is successful. This callback will be called on 
 *                the main queue. May be 'nil'.
 *
 * @param failure block that will be executed if unregistration fails. This callback will be called on the main
 *                queue. May be 'nil'.
 */
+ (void)unregisterSuccess:(void (^)(void))success
                  failure:(void (^)(NSError *error))failure;


@end
