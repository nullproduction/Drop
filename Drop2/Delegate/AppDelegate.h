//
//  AppDelegate.h
//  Drop
//
//  Created by Администратор on 7/2/13.
//  Copyright (c) 2013 Администратор. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TICoreDataSync.h"
#import "DropboxSDK.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate, DBSessionDelegate,
DBLoginControllerDelegate, TICDSApplicationSyncManagerDelegate, TICDSDocumentSyncManagerDelegate>
{
    TICDSDocumentSyncManager *_documentSyncManager;
    BOOL _downloadStoreAfterRegistering;
}

#define kTICDDropboxSyncKey @"c9o9lj5p5nx9w97"
#define kTICDDropboxSyncSecret @"6x0oj4zifup8a1y"

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@property (retain) TICDSDocumentSyncManager *documentSyncManager;
@property (nonatomic, assign,getter = shouldDownloadStoreAfterRegistering) BOOL downloadStoreAfterRegistering;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;
- (void)registerSyncManager;

@end
