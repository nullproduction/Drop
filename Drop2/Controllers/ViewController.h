//
//  ViewController.h
//  Drop
//
//  Created by Администратор on 7/2/13.
//  Copyright (c) 2013 Администратор. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController <NSFetchedResultsControllerDelegate> {
    NSFetchedResultsController *fetchedResultsController;
    NSManagedObjectContext *managedObjectContext;
}

@property (nonatomic, retain) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;
- (IBAction)insert:(id)sender;
- (IBAction)fetch:(id)sender;

@end
