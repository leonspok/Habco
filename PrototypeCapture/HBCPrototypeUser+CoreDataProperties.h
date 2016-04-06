//
//  HBCPrototypeUser+CoreDataProperties.h
//  Habco
//
//  Created by Игорь Савельев on 06/04/16.
//  Copyright © 2016 Leonspok. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "HBCPrototypeUser.h"

NS_ASSUME_NONNULL_BEGIN

@class HBCPrototype, HBCPrototypeRecord;

@interface HBCPrototypeUser (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *bio;
@property (nullable, nonatomic, retain) NSDate *dateAdded;
@property (nullable, nonatomic, retain) NSString *name;
@property (nullable, nonatomic, retain) NSString *uid;
@property (nullable, nonatomic, retain) NSDate *lastRecordingDate;
@property (nullable, nonatomic, retain) HBCPrototype *prototype;
@property (nullable, nonatomic, retain) NSSet<HBCPrototypeRecord *> *records;

@end

@interface HBCPrototypeUser (CoreDataGeneratedAccessors)

- (void)addRecordsObject:(HBCPrototypeRecord *)value;
- (void)removeRecordsObject:(HBCPrototypeRecord *)value;
- (void)addRecords:(NSSet<HBCPrototypeRecord *> *)values;
- (void)removeRecords:(NSSet<HBCPrototypeRecord *> *)values;

@end

NS_ASSUME_NONNULL_END
