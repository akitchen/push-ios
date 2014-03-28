//
//  CFPushDBManager.m
//  
//
//  Created by DX123-XL on 2014-03-27.
//
//

#import <CoreData/CoreData.h>

#import "CFPushDBManager.h"
#import "CFPushDebug.h"

@interface CFPushDBManager ()

@property NSURL *storeURL;
@property (nonatomic)  NSManagedObjectContext *managedObjectContext;
@property (nonatomic)  NSManagedObjectModel *managedObjectModel;
@property (nonatomic)  NSPersistentStoreCoordinator *persistentStoreCoordinator;

@end

@implementation CFPushDBManager

- (NSManagedObjectModel *)managedObjectModel {
    if (!_managedObjectModel) {
        return _managedObjectModel;
    }
    
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"CFPushDataModel" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    
    return _managedObjectModel;
}


- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return _managedObjectContext;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator) {
        return _persistentStoreCoordinator;
    }
    
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.managedObjectModel];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:self.storeURL options:nil error:&error]) {
        CFPushCriticalLog(@"Error adding persistent store: %@, %@", error, [error userInfo]);
        [[NSFileManager defaultManager] removeItemAtURL:self.storeURL error:nil];
        [_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:self.storeURL options:nil error:&error];
    }
    
    return _persistentStoreCoordinator;
}

- (NSURL *)storeDirectoryURL {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *libraryDirectoryURL = [[fileManager URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask] lastObject];
    NSURL *directoryURL = [libraryDirectoryURL URLByAppendingPathComponent:@"CFPushDB"];
    
    if (![fileManager fileExistsAtPath:[directoryURL path]]) {
        NSError *error = nil;
        if (![fileManager createDirectoryAtURL:directoryURL withIntermediateDirectories:YES attributes:nil error:&error]) {
            CFPushCriticalLog(@"Error creating database directory %@: %@", [directoryURL lastPathComponent], error);
        }
    }
    
    return directoryURL;
}

@end
