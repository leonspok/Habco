//
//  HBCPrototypeRecord+CoreDataProperties.h
//  Habco
//
//  Created by Игорь Савельев on 06/04/16.
//  Copyright © 2016 Leonspok. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "HBCPrototypeRecord.h"

NS_ASSUME_NONNULL_BEGIN

@class HBCPrototypeUser;

@interface HBCPrototypeRecord (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *uid;
@property (nullable, nonatomic, retain) NSDate *date;
@property (nullable, nonatomic, retain) NSString *pathToVideo;
@property (nullable, nonatomic, retain) HBCPrototypeUser *user;

@end

NS_ASSUME_NONNULL_END
