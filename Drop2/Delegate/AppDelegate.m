//
//  AppDelegate.m
//  Drop
//
//  Created by Администратор on 7/2/13.
//  Copyright (c) 2013 Администратор. All rights reserved.
//

#import "AppDelegate.h"
#import "ViewController.h"

@implementation AppDelegate

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

@synthesize documentSyncManager = _documentSyncManager;
@synthesize downloadStoreAfterRegistering =
_downloadStoreAfterRegistering;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Dropbox session
    DBSession *session = [[DBSession alloc] initWithConsumerKey:kTICDDropboxSyncKey
                            consumerSecret:kTICDDropboxSyncSecret];
    [session setDelegate:self];
    [DBSession setSharedSession:session];
    
    // Request login dropbox
    if([session isLinked] ) {
        [self registerSyncManager];
    } else {
        DBLoginController *loginController =
        [[DBLoginController alloc] init];
        [loginController setDelegate:self];
        [[self navigationController] pushViewController:loginController animated:NO];
    }
    
    // Push managedObjectContext
    ViewController *rootViewController = (ViewController *)self.window.rootViewController;
    rootViewController.managedObjectContext = self.managedObjectContext;

    return YES;
}

- (void)sessionDidReceiveAuthorizationFailure:(DBSession *)session
{
    DBLoginController *loginController =
    [[DBLoginController alloc] init];
    [loginController setDelegate:self];
    
    [[self navigationController] pushViewController:loginController
                                           animated:YES];
}


- (void)loginControllerDidLogin:(DBLoginController *)controller
{
    [[self navigationController] popViewControllerAnimated:YES];
    
    [self registerSyncManager];
}

- (void)loginControllerDidCancel:(DBLoginController *)controller
{
    [[self navigationController] popViewControllerAnimated:YES];
}

- (void)registerSyncManager
{
    TICDSDropboxSDKBasedApplicationSyncManager *manager =
    [TICDSDropboxSDKBasedApplicationSyncManager
     defaultApplicationSyncManager];
    
    NSString *clientUuid = [[NSUserDefaults standardUserDefaults]
                            stringForKey:@"iOSNotebookAppSyncClientUUID"];
    if( !clientUuid ) {
        clientUuid = [TICDSUtilities uuidString];
        [[NSUserDefaults standardUserDefaults]
         setValue:clientUuid
         forKey:@"iOSNotebookAppSyncClientUUID"];
    }
    
    NSString *deviceDescription = [[UIDevice currentDevice] name];
    
    [manager registerWithDelegate:self
              globalAppIdentifier:@"com.mezhevikin.Drop2"
           uniqueClientIdentifier:clientUuid
                      description:deviceDescription
                         userInfo:nil];
}


- (void)applicationSyncManagerDidPauseRegistrationToAskWhether\
ToUseEncryptionForFirstTimeRegistration:
(TICDSApplicationSyncManager *)aSyncManager
{
    [aSyncManager continueRegisteringWithEncryptionPassword:nil];
}


- (void)applicationSyncManagerDidPauseRegistrationToRequestPassword\
ForEncryptedApplicationSyncData:
(TICDSApplicationSyncManager *)aSyncManager
{
    [aSyncManager continueRegisteringWithEncryptionPassword:nil];
}


- (TICDSDocumentSyncManager *)applicationSyncManager:
(TICDSApplicationSyncManager *)aSyncManager
preConfiguredDocumentSyncManagerForDownloadedDocumentWithIdentifier:
(NSString *)anIdentifier atURL:(NSURL *)aFileURL
{
    return nil;
}

- (void)applicationSyncManagerDidFinishRegistering:
(TICDSApplicationSyncManager *)aSyncManager
{
    TICDSDropboxSDKBasedDocumentSyncManager *docSyncManager =
    [[TICDSDropboxSDKBasedDocumentSyncManager alloc] init];
    
    [docSyncManager registerWithDelegate:self
                          appSyncManager:aSyncManager
                    managedObjectContext:[self managedObjectContext]
                      documentIdentifier:@"Drop2"
                             description:@"Application's data"
                                userInfo:nil];
    [self setDocumentSyncManager:docSyncManager];
    
}


- (void)documentSyncManager:(TICDSDocumentSyncManager *)aSyncManager
didPauseSynchronizationAwaitingResolutionOfSyncConflict:
(id)aConflict
{
    [aSyncManager
     continueSynchronizationByResolvingConflictWithResolutionType:
     TICDSSyncConflictResolutionTypeLocalWins];
}


- (NSURL *)documentSyncManager:(TICDSDocumentSyncManager *)aSyncManager
URLForWholeStoreToUploadForDocumentWithIdentifier:
(NSString *)anIdentifier
                   description:(NSString *)aDescription
                      userInfo:(NSDictionary *)userInfo
{
    return [[self applicationDocumentsDirectory]
            URLByAppendingPathComponent:@"Drop2.sqlite"];
}


- (void)documentSyncManager:(TICDSDocumentSyncManager *)aSyncManager
didPauseRegistrationAsRemoteFileStructureDoesNotExist\
ForDocumentWithIdentifier:(NSString *)anIdentifier
description:(NSString *)aDescription
userInfo:(NSDictionary *)userInfo
{
    [aSyncManager continueRegistrationByCreatingRemoteFileStructure:YES];
}

- (void)documentSyncManager:(TICDSDocumentSyncManager *)aSyncManager
didPauseRegistrationAsRemoteFileStructureWasDeleted\
ForDocumentWithIdentifier:(NSString *)anIdentifier
description:(NSString *)aDescription
userInfo:(NSDictionary *)userInfo
{
    [aSyncManager continueRegistrationByCreatingRemoteFileStructure:YES];
}

- (void)documentSyncManagerDidFinishRegistering:
(TICDSDocumentSyncManager *)aSyncManager
{
    if( [self shouldDownloadStoreAfterRegistering] ) {
        [[self documentSyncManager] initiateDownloadOfWholeStore];
    }
}


- (void)documentSyncManager:(TICDSDocumentSyncManager *)aSyncManager
didPauseRegistrationAsRemoteFileStructureDoesNotExist\
ForDocumentWithIdentifier:(NSString *)anIdentifier
description:(NSString *)aDescription
userInfo:(NSDictionary *)userInfo
{
    [self setDownloadStoreAfterRegistering:NO];
    [aSyncManager continueRegistrationByCreatingRemoteFileStructure:YES];
}

- (void)documentSyncManager:(TICDSDocumentSyncManager *)aSyncManager
didPauseRegistrationAsRemoteFileStructureWasDeleted\
ForDocumentWithIdentifier:(NSString *)anIdentifier
description:(NSString *)aDescription
userInfo:(NSDictionary *)userInfo
{
    [self setDownloadStoreAfterRegistering:NO];
    [aSyncManager continueRegistrationByCreatingRemoteFileStructure:YES];
}

- (void)documentSyncManagerDidDetermineThat\
ClientHadPreviouslyBeenDeletedFrom\
SynchronizingWithDocument:(TICDSDocumentSyncManager *)aSyncManager
{
    [self setDownloadStoreAfterRegistering:YES];
}


- (BOOL)documentSyncManagerShouldUploadWholeStore\
AfterDocumentRegistration:(TICDSDocumentSyncManager *)aSyncManager
{
    return ![self shouldDownloadStoreAfterRegistering];
}


- (void)documentSyncManager:(TICDSDocumentSyncManager *)aSyncManager
willReplaceStoreWithDownloadedStoreAtURL:(NSURL *)aStoreURL
{
    NSError *anyError = nil;
    BOOL success = [[self persistentStoreCoordinator]
                    removePersistentStore:
                    [[self persistentStoreCoordinator]
                     persistentStoreForURL:aStoreURL]
                    error:&anyError];
    
    if( !success ) {
        NSLog(@"Failed to remove persistent store at %@: %@",
              aStoreURL, anyError);
    }
}


- (void)documentSyncManager:(TICDSDocumentSyncManager *)aSyncManager
didReplaceStoreWithDownloadedStoreAtURL:(NSURL *)aStoreURL
{
    NSError *anyError = nil;
    id store = [[self persistentStoreCoordinator]
                addPersistentStoreWithType:NSSQLiteStoreType
                configuration:nil
                URL:aStoreURL options:nil error:&anyError];
    
    if( !store ) {
        NSLog(@"Failed to add persistent store at %@: %@",
              aStoreURL, anyError);
    }
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Saves changes in the application's managed object context before the application terminates.
    [self saveContext];
}

- (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

#pragma mark - Core Data stack

// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return _managedObjectContext;
}

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Drop2" withExtension:@"momd"];
    _managedObjectModel = [[TICDSSynchronizedManagedObjectContext alloc] init];
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"Drop2.sqlite"];

    //
    if( ![[NSFileManager defaultManager] fileExistsAtPath:[storeURL path]] ) {
        [self setDownloadStoreAfterRegistering:YES];
    }
    ///
    
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter:
         @{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES}
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}

// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (void)dealloc
{
   
}

@end
