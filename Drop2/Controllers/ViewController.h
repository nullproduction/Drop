//
//  ViewController.h
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController <NSFetchedResultsControllerDelegate>
{
    NSFetchedResultsController *fetchedResultsController;
    NSManagedObjectContext *managedObjectContext;
}

@property (nonatomic, retain) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;
- (IBAction)insert:(id)sender;
- (IBAction)fetch:(id)sender;

@end
