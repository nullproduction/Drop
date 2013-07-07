//
//  AppDelegate.m
//

#import "AppDelegate.h"


@interface AppDelegate () <DBSessionDelegate, TICDSApplicationSyncManagerDelegate, TICDSDocumentSyncManagerDelegate>
@end

@implementation AppDelegate

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;


/*
 * Init
 */
+ (void)initialize
{
    // Log
    [TICDSLog setVerbosity:TICDSLogVerbosityEveryStep];
}

/*
 * Finish Launching
 */
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    
    // Activity sync
    if(kShowActivitySync==YES)
    {
        NSLog(@"show");
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(activityDidIncrease:) name:TICDSApplicationSyncManagerDidIncreaseActivityNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(activityDidDecrease:) name:TICDSApplicationSyncManagerDidDecreaseActivityNotification object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(activityDidIncrease:) name:TICDSDocumentSyncManagerDidIncreaseActivityNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(activityDidDecrease:) name:TICDSDocumentSyncManagerDidDecreaseActivityNotification object:nil];
    }
    
    // Push managedObjectContext
    self.navigationController = (UINavigationController *)self.window.rootViewController;
    ViewController *rootViewController = (ViewController *)self.navigationController.topViewController;
    rootViewController.managedObjectContext = self.managedObjectContext;
    
    // Set root viewController
    [self.window setRootViewController:self.navigationController];
    [self.window makeKeyAndVisible];
    
    // Create session
    DBSession *session = [[DBSession alloc] initWithAppKey:kTICDDropboxSyncKey appSecret:kTICDDropboxSyncSecret root:kDBRootAppFolder];
    
    session.delegate = self;
    [DBSession setSharedSession:session];
    
    // If session exists
    if ([[DBSession sharedSession] isLinked])
    {
        [self registerSyncManager];
    }
    else
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void)
        {
            [[DBSession sharedSession] linkFromController:self.navigationController];
        });
    }
    
    return YES;
}


/*
 * Application Will Terminate
 */
- (void)applicationWillTerminate:(UIApplication *)application
{
    // Save Content
    [self saveContext];
}


/*
 * Save Content
 */
- (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil)
    {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error])
        {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}



/*
 * managedObjectContext
 */
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil)
    {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil)
    {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return _managedObjectContext;
}


/*
 * managedObjectModel
 */
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:kModelURL withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}


/*
 * Persistent Store Coordinator
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    
    if (_persistentStoreCoordinator != nil)
    {
        return _persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:kStoreURL];
    
    // Check for an existing store here
    if ([[NSFileManager defaultManager] fileExistsAtPath:storeURL.path] == NO)
    {
        self.downloadStoreAfterRegistering = YES;
    }
    
    NSError *error = nil;
    
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error])
    {
        
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}


/*
 * Application DocumentsDirectory
 */
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}


/*
 * Authorization Failure
 */
- (void)sessionDidReceiveAuthorizationFailure:(DBSession *)session userId:(NSString *)userId
{
    [[DBSession sharedSession] linkFromController:self.navigationController];
}


/*
 * Handle open URL
 */
- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url
{
    if ([[DBSession sharedSession] handleOpenURL:url])
    {
        if ([[DBSession sharedSession] isLinked])
        {
            NSLog(@"App linked successfully!");
            [self registerSyncManager];
        }
        return YES;
    }
    return NO;
}


/*
 * Register SyncManager
 */
- (void)registerSyncManager
{
    // Manager
    TICDSDropboxSDKBasedApplicationSyncManager *manager = [TICDSDropboxSDKBasedApplicationSyncManager defaultApplicationSyncManager];
    
    //Get the unique sync identifier
    NSString *clientUuid = [[NSUserDefaults standardUserDefaults] stringForKey:kSyncClientUUIDKey];
    if (clientUuid == nil)
    {
        clientUuid = [TICDSUtilities uuidString];
        [[NSUserDefaults standardUserDefaults] setValue:clientUuid forKey:kSyncClientUUIDKey];
    }
    
    // Name device
    NSString *deviceDescription = [[UIDevice currentDevice] name];
    
    // Register 
    [manager registerWithDelegate:self
              globalAppIdentifier:kGlobalAppIdentifier
           uniqueClientIdentifier:clientUuid
                      description:deviceDescription
                         userInfo:nil];
}


#pragma mark - TICDSApplicationSyncManagerDelegate methods


/*
 * First Time Registration
 */
- (void)applicationSyncManagerDidPauseRegistrationToAskWhetherToUseEncryptionForFirstTimeRegistration:(TICDSApplicationSyncManager *)aSyncManager
{
    [aSyncManager continueRegisteringWithEncryptionPassword:kEncryptionPassword];
}


/*
 * Request password
 */
- (void)applicationSyncManagerDidPauseRegistrationToRequestPasswordForEncryptedApplicationSyncData:(TICDSApplicationSyncManager *)aSyncManager
{
    [aSyncManager continueRegisteringWithEncryptionPassword:kEncryptionPassword];
}


/*
 * Application SyncManager
 */
- (TICDSDocumentSyncManager *)applicationSyncManager:(TICDSApplicationSyncManager *)aSyncManager preConfiguredDocumentSyncManagerForDownloadedDocumentWithIdentifier:(NSString *)anIdentifier atURL:(NSURL *)aFileURL
{
    return nil;
}


/*
 * Finish Registerin
 */
- (void)applicationSyncManagerDidFinishRegistering:(TICDSApplicationSyncManager *)aSyncManager
{
    self.managedObjectContext.synchronized = YES;
    
    TICDSDropboxSDKBasedDocumentSyncManager *docSyncManager = [[TICDSDropboxSDKBasedDocumentSyncManager alloc] init];
    
    [docSyncManager registerWithDelegate:self
                          appSyncManager:aSyncManager
                    managedObjectContext:[self managedObjectContext]
                      documentIdentifier:kDocumentIdentifier
                             description:@"Application's data"
                                userInfo:nil];
    
    [self setDocumentSyncManager:docSyncManager];
}


#pragma mark - TICDSDocumentSyncManagerDelegate methods


/*
 * Sync Conflict
 */
- (void)documentSyncManager:(TICDSDocumentSyncManager *)aSyncManager didPauseSynchronizationAwaitingResolutionOfSyncConflict:(id)aConflict
{
    [aSyncManager continueSynchronizationByResolvingConflictWithResolutionType:TICDSSyncConflictResolutionTypeLocalWins];
}


/*
 * Store URL
 */
- (NSURL *)documentSyncManager:(TICDSDocumentSyncManager *)aSyncManager URLForWholeStoreToUploadForDocumentWithIdentifier:(NSString *)anIdentifier description:(NSString *)aDescription userInfo:(NSDictionary *)userInfo
{
    return [[self applicationDocumentsDirectory] URLByAppendingPathComponent:kStoreURL];
}


/*
 * Synchronize With Error
 */
- (void)documentSyncManager:(TICDSDocumentSyncManager *)aSyncManager didFailToSynchronizeWithError:(NSError *)anError
{
    NSLog(@"%s %@", __PRETTY_FUNCTION__, anError);
}


/*
 * File not exists
 */
- (void)documentSyncManager:(TICDSDocumentSyncManager *)aSyncManager didPauseRegistrationAsRemoteFileStructureDoesNotExistForDocumentWithIdentifier:(NSString *)anIdentifier description:(NSString *)aDescription userInfo:(NSDictionary *)userInfo
{
    self.downloadStoreAfterRegistering = NO;
    [aSyncManager continueRegistrationByCreatingRemoteFileStructure:YES];
}


/*
 * File deleted
 */
- (void)documentSyncManager:(TICDSDocumentSyncManager *)aSyncManager didPauseRegistrationAsRemoteFileStructureWasDeletedForDocumentWithIdentifier:(NSString *)anIdentifier description:(NSString *)aDescription userInfo:(NSDictionary *)userInfo
{
    self.downloadStoreAfterRegistering = NO;
    [aSyncManager continueRegistrationByCreatingRemoteFileStructure:YES];
}


/*
 * Finish registering
 */
- (void)documentSyncManagerDidFinishRegistering:(TICDSDocumentSyncManager *)aSyncManager
{
    if (self.shouldDownloadStoreAfterRegistering)
    {
        [aSyncManager initiateDownloadOfWholeStore];
    }
    else
    {
        [aSyncManager initiateSynchronization];
    }
    
    [aSyncManager beginPollingRemoteStorageForChanges];
}


/*
 * Deleted client
 */
- (void)documentSyncManagerDidDetermineThatClientHadPreviouslyBeenDeletedFromSynchronizingWithDocument:(TICDSDocumentSyncManager *)aSyncManager
{
    self.downloadStoreAfterRegistering = YES;
}


/*
 * Upload whole store
 */
- (BOOL)documentSyncManagerShouldUploadWholeStoreAfterDocumentRegistration:(TICDSDocumentSyncManager *)aSyncManager
{
    return self.shouldDownloadStoreAfterRegistering == NO;
}


/*
 * Replace store
 */
- (void)documentSyncManager:(TICDSDocumentSyncManager *)aSyncManager willReplaceStoreWithDownloadedStoreAtURL:(NSURL *)aStoreURL
{
    NSError *anyError = nil;
    BOOL success = [self.persistentStoreCoordinator removePersistentStore:[self.persistentStoreCoordinator persistentStoreForURL:aStoreURL] error:&anyError];
    
    if (success == NO)
    {
        NSLog(@"Failed to remove persistent store at %@: %@", aStoreURL, anyError);
    }
}


/*
 * After replace store
 */
- (void)documentSyncManager:(TICDSDocumentSyncManager *)aSyncManager didReplaceStoreWithDownloadedStoreAtURL:(NSURL *)aStoreURL
{
    NSError *anyError = nil;
    id store = [self.persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:aStoreURL options:nil error:&anyError];
    
    if (store == nil)
    {
        NSLog(@"Failed to add persistent store at %@: %@", aStoreURL, anyError);
    }
}


/*
 * Begin Synchronizing
 */
- (IBAction)beginSynchronizing:(id)sender
{
    NSError *saveError = nil;
    [self.managedObjectContext save:&saveError];
    if (saveError != nil)
    {
        NSLog(@"%s %@", __PRETTY_FUNCTION__, saveError);
    }
    
    [self.documentSyncManager initiateSynchronization];
}


/*
 * Save change
 */
- (void)documentSyncManager:(TICDSDocumentSyncManager *)aSyncManager didMakeChangesToObjectsInBackgroundContextAndSaveWithNotification:(NSNotification *)aNotification
{
    NSError *saveError = nil;
    [self.managedObjectContext save:&saveError];
    if (saveError != nil)
    {
        NSLog(@"%s %@", __PRETTY_FUNCTION__, saveError);
    }
}

/*
 * Synchronizing After save data
 */
- (BOOL)documentSyncManager:(TICDSDocumentSyncManager *)aSyncManager shouldBeginSynchronizingAfterManagedObjectContextDidSave:(NSManagedObjectContext *)aMoc;
{
    return YES;
}


#pragma mark - Sync Manager Activity Notification methods

/*
 * Activity Increase
 */
- (void)activityDidIncrease:(NSNotification *)aNotification
{
    self.activity++;
    
    if (self.activity > 0)
    {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    }
}

/*
 * Activity Decrease
 */
- (void)activityDidDecrease:(NSNotification *)aNotification
{
    if (self.activity > 0)
    {
        self.activity--;
    }
    
    if (self.activity < 1)
    {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    }
}

@end
