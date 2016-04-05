//
//  HBCPrototype+CoreDataProperties.h
//  Habco
//
//  Created by Игорь Савельев on 06/04/16.
//  Copyright © 2016 Leonspok. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "HBCPrototype.h"

NS_ASSUME_NONNULL_BEGIN

@class HBCRecordingSettings, HBCPrototypeUser;

@interface HBCPrototype (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *uid;
@property (nullable, nonatomic, retain) NSString *name;
@property (nullable, nonatomic, retain) NSString *url;
@property (nullable, nonatomic, retain) NSDate *dateCreated;
@property (nullable, nonatomic, retain) NSDate *lastDateRecorded;
@property (nullable, nonatomic, retain) NSString *prototypeDescription;
@property (nullable, nonatomic, retain) HBCRecordingSettings *recordingSettings;
@property (nullable, nonatomic, retain) NSSet<HBCPrototypeUser *> *users;

@end

@interface HBCPrototype (CoreDataGeneratedAccessors)

- (void)addUsersObject:(HBCPrototypeUser *)value;
- (void)removeUsersObject:(HBCPrototypeUser *)value;
- (void)addUsers:(NSSet<HBCPrototypeUser *> *)values;
- (void)removeUsers:(NSSet<HBCPrototypeUser *> *)values;

@end

NS_ASSUME_NONNULL_END
