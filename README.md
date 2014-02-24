Omnia Mobile Services Push Client SDK for iOS
=============================================

Features
--------

The Omnia Mobile Services Push Client SDK is a small tool that will register your application and device with the Omnia
Push Messaging server for receiving push messages.

At this time, this SDK does not provide any code for receiving push messages.

Device Requirements
-------------------

The Push SDK requires iOS 6.0 or greater.  It should work on both 32-bit and 64-bit devices.

Library Requirements
--------------------

This library does not depend on any external libraries or frameworks.

Instructions for Integrating the Omnia Mobile Push Services Push Client SDK for Android
---------------------------------------------------------------------------------------

In order to receive push messages from Omnia in your Android application you will need to follow these tasks:

 1. You will need to obtain a certificate and provisioning profile from Apple before you can use push notifications
    in your application.  Please follow the instructions here:

        https://developer.apple.com/library/ios/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/Chapters/ProvisioningDevelopment.html#//apple_ref/doc/uid/TP40008194-CH104-SW3

 2. Set up your project, application, and a release on the Omnia administration console.  This task is beyond the scope
    of this document, but please note that you will need the certificate (P12 file) obtained from Apple in the above step.

    After setting up your release in Omnia, make sure to note the Release UUID and Release Secret parameters.  You will
    need them below.

 3. Download the project framework and add it to your project.

 4. Add the following lines of code to the initialization section of your application (probably your implementation of
    UIApplicationDelegate).
 
    Include the following header:
	
        #import "OmniaPushSDK.h"
	    

    In your `application:didFinishLaunchingWithOptions` method, please add the following lines:
   
        OmniaPushRegistrationParameters *parameters = [[OmniaPushRegistrationParameters alloc] initForNotificationTypes:REQUESTED_REMOTE_NOTIFICATION_TYPES
                                                                                                            releaseUuid:YOUR_RELEASE_UUID
                                                                                                          releaseSecret:YOUR_RELEASE_SECRET
                                                                                                            deviceAlias:YOUR_DEVICE_ALIAS];
        [OmniaPushSDK registerWithParameters:parameters];
   

    The `YOUR_RELEASE_UUID` and `YOUR_RELEASE_SECRET` are described above.  The `YOUR_DEVICE_ALIAS` is a custom field that
    you can use to differentiate this device from others in your own push messaging campaigns.  You can leave it empty
    if you'd like.  The `REQUESTED_REMOTE_NOTIFICATION_TYPES` are the notification types that your application will display
	when push notifications are received while your application is not running in the foreground.

	The notification types are described here:

	    https://developer.apple.com/library/ios/documentation/uikit/reference/UIApplication_Class/Reference/Reference.html#//apple_ref/doc/c_ref/UIRemoteNotificationType

    You should only have to call this method once per the life-time of your application.  Any calls after the first will be ignored.

    The `startRegistration` method is asynchronous and will return before registration is complete.  If you need to know
    when registration is complete (or if it fails), then provide a `OmniaPushRegistrationListener` as the second argument.

    You do not need to call UIApplication `registerForRemoteNotificationTypes:`.  The library takes care of that for you.

 6. The library is not set up, at this time, to receive push messages for you since Apple has provided straightforward
    boilerplate code that you can copy into your application.  In order to receive messages in your application, please
    follow the instructions here:

         https://developer.apple.com/library/ios/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/Chapters/IPhoneOSClientImp.html#//apple_ref/doc/uid/TP40008194-CH103-SW4

Building the SDK itself
-----------------------

Although you do not need any extra libraries or frameworks to build the project itself, you will need to modify
your local Xcode installation in order to support building universal frameworks.  You will need to use this project
in order to build this project:

* https://github.com/kstenerud/iOS-Universal-Framework

Clone that repo onto your computer, close XCode, and run the `install.sh` script in the `Real
Framework` subdirectory.


The source code of the project is divided into three targets:

 * OmniaPushSDK - framework target
 
     The redistributable portion of the framework.

 * Specs - iOS application target

     Unit tests.  Implemented using [Cedar](https://github.com/pivotal/cedar).

	 This target produces an application that links against the OmniaPushSDK source code directly
	 and runs the unit tests.  Watch the console window for the test results.  The application itself
	 has no visible UI.  You can also run these tests by running the `run_specs.sh` script from the
	 command line.

 * DemoApp

     Demo application.


	 More information below in the "Demo Application" section"


Building the Framework
----------------------

The "OmniaPushSDK" target produces a universal framework suitable for building against arm and simulator platforms.  This target
depends on the [iOS Universal Framework](https://github.com/kstenerud/iOS-Universal-Framework) build system to produce this framework.

To build the framework, make sure the iOS Universal Framework is installed and load the OmniaPushSDK project in Xcode.  Select
the "OmniaPushSDK" target and select "Archive" from the "Build" menu in Xcode.  After the project is built, Xcode should open a
Finder window containing the resultant Framework.  I recommend amending the filename to include the suffixes "iOS" and the current
version.  e.g.:  "OmniaPushSDK-iOS-0.2.framework".

Staging Server
--------------

At this time, the library is hard coded to use the staging server on Amazon AWS.  You can confirm the current server
by looking at the `BACK_END_REGISTRATION_REQUEST_URL` string value in `OmniaPushConst.h`.  The intent is to change this value
to point to a production server when it is available.

Note that the existing staging server is currently hardcoded to use the Apple APNS "sandbox" server only and is
not suitable for production use at this time.

Demo Application
----------------

This application has a visible UI that can be used to demonstrate and exercise the features of the Push SDK.  It "cheats"
and links directly to the OmniaPushSDK source code and is able to access the internal features of the SDK that are not
exposed with its external interface.  This application is not intended to be an example of how to integrate the library,
but is intended to be used to used by developer or a testing team during development of the library itself.

You can use this sample application to test registration against the Apple Push Notification Service (APNS) and the
Omnia Mobile Services back-end server for push messages.  Although not currently supported by the library itself, you
can also send and receive push messages with the sample application.

Before running this application you will need to create your own certificate, provisioning profile, and application
on the Apple Developer iOS Member Center.

Watch the log output in the sample application's display to see what the Push library is doing in the background.  This
log output should also be visible in the iOS device console (for debug builds), but the sample application registers a
"listener" with the Push Library's logger so it can show you what's going on.

Press the "Register" button in the sample application action bar to ask the Push Library to register the device.  If
the device is not already registered, then you should see a lot of output scroll by as the library registers with
both APNS and Omnia.  If the device is already registered then the output should be shorter.

You can clear the locally saved registration data with the "Clear Current Registration" button on the Settings screen.
Clearing the registration data will force a full registration the next time that you press the "Register" button.

You can copy the contents of the log to the device clipboard by pressing the "Copy" button on the toolbar.  This feature
can be useful if you want to email someone a device log, copy some of the JSON from a log message, or get one of the device
tokens, for example.

You can change the registration preferences at run-time by pressing the "Settings" tool bar button.  Selecting this item
will load the Settings screen.  This screen will allow you to modify the three values passed to the library initialization
method above.  You can change the hard coded values by editing the definitions in the `Settings.m` file in the DemoApp.

You can reset the registration preferences to the default values by selecting the "Reset to Defaults" action bar item in
the Settings screen.

The sample application (not the library) is also set up to receive push messages once the device has been registered
with APNS and Omnia.  Although the library does not support receiving push messages at this time (since the Apple framework
already provides very straightforward example code that you can copy into your application), the sample application
does as a demonstration to show that the "system works".  It can be useful for testing your registration set up, or
for testing the server itself.

Simple Demo Application
-----------------------


