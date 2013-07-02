//
//  People.h
//
#import "TICoreDataSync.h"


@interface People : TICDSSynchronizedManagedObject

@property (nonatomic, retain) NSNumber * faceID;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * ticdsSyncID;

@end
