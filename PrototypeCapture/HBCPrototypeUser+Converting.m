//
//  HBCPrototypeUser+Converting.m
//  Habco
//
//  Created by Игорь Савельев on 06/04/16.
//  Copyright © 2016 Leonspok. All rights reserved.
//

#import "HBCPrototypeUser+Converting.h"
#import "HBCPrototypeUser+Converting.h"
#import "HBPrototypeUser.h"
#import "HBCPrototypeRecord+Converting.h"
#import "HBPrototypeRecord.h"
#import <MagicalRecord/MagicalRecord.h>
#import "NSSet+Utilities.h"
#import "NSOrderedSet+Utilities.h"

@implementation HBCPrototypeUser (Converting)

+ (HBCPrototypeUser *)createOrUpdateFrom:(HBPrototypeUser *)prototypeUser inContext:(NSManagedObjectContext *)context {
    if (!prototypeUser || !prototypeUser.uid) {
        return nil;
    }
    
    HBCPrototypeUser *cdUser = [HBCPrototypeUser MR_findFirstByAttribute:@"uid" withValue:prototypeUser.uid inContext:context];
    if (!cdUser) {
        cdUser = [HBCPrototypeUser MR_createEntityInContext:context];
    }
    cdUser.uid = prototypeUser.uid;
    cdUser.name = prototypeUser.name;
    cdUser.bio = prototypeUser.bio;
    cdUser.dateAdded = prototypeUser.dateAdded;
    
    if (prototypeUser.records) {
        NSOrderedSet *cdRecords = [prototypeUser.records mapWithBlock:^id(id obj) {
            return [HBCPrototypeRecord createOrUpdateFrom:obj inContext:context];
        }];
        for (HBCPrototypeRecord *record in cdRecords) {
            if (![cdUser.records containsObject:record]) {
                [cdUser addRecordsObject:record];
            }
        }
    }
    
    return cdUser;
}

- (HBPrototypeUser *)toHBPrototypeUser {
    HBCPrototypeUser *cdUser = (HBCPrototypeUser *)[self.managedObjectContext existingObjectWithID:self.objectID error:nil];
    if (!cdUser) {
        return nil;
    }
    HBPrototypeUser *user = [[HBPrototypeUser alloc] init];
    user.uid = cdUser.uid;
    user.name = cdUser.name;
    user.bio = cdUser.bio;
    user.dateAdded = cdUser.dateAdded;
    
    
    return user;
}

@end
