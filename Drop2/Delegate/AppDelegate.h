//
//  AppDelegate.h
//

#import "Config.h"
#import "TICoreDataSync.h"
#import "ViewController.h"
#import "DropboxSDK.h"

@interface AppDelegate : NSObject <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@property (retain) TICDSDocumentSyncManager *documentSyncManager;
@property (nonatomic, assign, getter = shouldDownloadStoreAfterRegistering) BOOL downloadStoreAfterRegistering;
@property (nonatomic, assign) NSInteger activity;

@property (nonatomic, retain) IBOutlet UINavigationController *navigationController;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;

- (IBAction)beginSynchronizing:(id)sender;

@end
