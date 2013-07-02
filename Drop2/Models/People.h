//
//  People.h
//  Drop
//
//  Created by Администратор on 7/2/13.
//  Copyright (c) 2013 Администратор. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface People : NSManagedObject

@property (nonatomic, retain) NSNumber * faceID;
@property (nonatomic, retain) NSString * name;

@end
