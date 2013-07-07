//
//  ViewController.m
//

#import "ViewController.h"


@implementation ViewController

@synthesize fetchedResultsController, managedObjectContext;


/*
 * 
 */
- (void)viewDidLoad
{
    // Super
    [super viewDidLoad];
    
    // Notification persistentStoresDidChange
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(persistentStoresDidChange:) name:NSPersistentStoreCoordinatorStoresDidChangeNotification object:self.managedObjectContext.persistentStoreCoordinator];
    
    // Sync Button
    UIBarButtonItem *syncButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:[[UIApplication sharedApplication] delegate] action:@selector(beginSynchronizing:)];
    self.navigationItem.leftBarButtonItem = syncButton;
}


/*
 *
 */
- (IBAction)insert:(id)sender
{
    NSManagedObject *people = [NSEntityDescription
    insertNewObjectForEntityForName:@"People" inManagedObjectContext:self.managedObjectContext];
    
    // Set value
    [people setValue:[self genRandStringLength:10] forKey:@"name"];

    // Save
    NSError *error;
    if (![self.managedObjectContext save:&error])
    {
        NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
    }
}




/*
 *
 */
- (IBAction)fetch:(id)sender
{
    NSLog(@"FETCH");
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"People"
                                    inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    NSArray *fetchedObjects = [self.managedObjectContext executeFetchRequest:fetchRequest error:nil];
    for (NSManagedObject *item in fetchedObjects)
    {
        NSLog(@"Name: %@", [item valueForKey:@"name"]);
    }
}


/*
 *
 */
-(NSString *)genRandStringLength: (int) len {
    NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    NSMutableString *randomString = [NSMutableString stringWithCapacity: len];
    
    for (int i=0; i<len; i++) {
        [randomString appendFormat: @"%C", [letters characterAtIndex: arc4random() % [letters length]]];
    }
    
    return randomString;
}


/*
 *
 */
- (void)viewDidUnload
{
    // Remove notification
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSPersistentStoreCoordinatorStoresDidChangeNotification object:self.managedObjectContext.persistentStoreCoordinator];
    
    // Super
    [super viewDidUnload];
}


#pragma mark - NSPersistentStoreCoordinatorStoresDidChangeNotification method

/*
 * Persistent stores change
 */
- (void)persistentStoresDidChange:(NSNotification *)aNotification
{
    NSError *anyError = nil;
    BOOL success = [self.fetchedResultsController performFetch:&anyError];
    if (success == NO)
    {
        NSLog(@"Error fetching: %@", anyError);
    }
    
    //[self.tableView reloadData];
}

@end
