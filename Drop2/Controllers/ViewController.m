//
//  ViewController.m
//  Drop
//
//  Created by Администратор on 7/2/13.
//  Copyright (c) 2013 Администратор. All rights reserved.
//

#import "ViewController.h"


@implementation ViewController

@synthesize fetchedResultsController, managedObjectContext;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
}


- (IBAction)insert:(id)sender
{
    NSManagedObject *people = [NSEntityDescription
    insertNewObjectForEntityForName:@"People" inManagedObjectContext:self.managedObjectContext];
    
    // Set value
    [people setValue:[self genRandStringLength:10] forKey:@"name"];

    // Save
    NSError *error;
    if (![self.managedObjectContext save:&error]) {
        NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
   }
}

- (IBAction)fetch:(id)sender
{
    NSLog(@"FETCH");
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"People"
                                    inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    NSArray *fetchedObjects = [self.managedObjectContext executeFetchRequest:fetchRequest error:nil];
    for (NSManagedObject *item in fetchedObjects) {
        NSLog(@"Name: %@", [item valueForKey:@"name"]);
    }
}



-(NSString *)genRandStringLength: (int) len {
    NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    NSMutableString *randomString = [NSMutableString stringWithCapacity: len];
    
    for (int i=0; i<len; i++) {
        [randomString appendFormat: @"%C", [letters characterAtIndex: arc4random() % [letters length]]];
    }
    
    return randomString;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
