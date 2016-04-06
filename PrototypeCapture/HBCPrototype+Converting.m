//
//  HBCPrototype+Converting.m
//  Habco
//
//  Created by Игорь Савельев on 06/04/16.
//  Copyright © 2016 Leonspok. All rights reserved.
//

#import "HBCPrototype+Converting.h"
#import "HBCRecordingSettings+Converting.h"
#import "HBCPrototypeUser+Converting.h"
#import "HBRecordingSettings.h"
#import "HBPrototypeUser.h"
#import <MagicalRecord/MagicalRecord.h>
#import "HBPrototype.h"
#import "HBPrototypeRecord.h"
#import "NSSet+Utilities.h"
#import "NSOrderedSet+Utilities.h"

@implementation HBCPrototype (Converting)

+ (HBCPrototype *)createOrUpdateFrom:(HBPrototype *)prototype inContext:(NSManagedObjectContext *)context {
    if (!prototype || !prototype.uid) {
        return nil;
    }
    
    HBCPrototype *cdPrototype = [HBCPrototype MR_findFirstByAttribute:@"uid" withValue:prototype.uid inContext:context];
    if (!cdPrototype) {
        cdPrototype = [HBCPrototype MR_createEntityInContext:context];
    }
    
    cdPrototype.uid = prototype.uid;
    cdPrototype.name = prototype.name;
    cdPrototype.prototypeDescription = prototype.prototypeDescription;
    cdPrototype.url = [prototype.url absoluteString];
    cdPrototype.dateCreated = prototype.dateCreated;
    if (cdPrototype.recordingSettings && prototype.recordingSettings) {
        cdPrototype.recordingSettings.withTouches = @(prototype.recordingSettings.withTouches);
        cdPrototype.recordingSettings.withFrontCamera = @(prototype.recordingSettings.withFrontCamera);
        cdPrototype.recordingSettings.maxFPS = @(prototype.recordingSettings.maxFPS);
        cdPrototype.recordingSettings.downscale = @(prototype.recordingSettings.downscale);
    } else if (prototype.recordingSettings) {
        cdPrototype.recordingSettings = [HBCRecordingSettings createOrUpdateFrom:prototype.recordingSettings inContext:context];
    }
    if (prototype.users) {
        NSOrderedSet *cdUsers = [prototype.users mapWithBlock:^id(id obj) {
            return [HBCPrototypeUser createOrUpdateFrom:obj inContext:context];
        }];
        for (HBCPrototypeUser *user in cdUsers) {
            if (![cdPrototype.users containsObject:user]) {
                [cdPrototype addUsersObject:user];
            }
        }
    }
    return cdPrototype;
}

- (HBPrototype *)toHBPrototype {
    HBCPrototype *cdPrototype = (HBCPrototype *)[self.managedObjectContext existingObjectWithID:self.objectID error:nil];
    if (!cdPrototype) {
        return nil;
    }
    HBPrototype *prototype = [HBPrototype new];
    prototype.uid = cdPrototype.uid;
    prototype.name = cdPrototype.name;
    prototype.prototypeDescription = cdPrototype.prototypeDescription;
    prototype.url = [NSURL URLWithString:cdPrototype.url];
    prototype.dateCreated = cdPrototype.dateCreated;
    prototype.recordingSettings = [cdPrototype.recordingSettings toHBRecordingSettings];
    prototype.recordingSettings.prototype = prototype;
    
    NSMutableArray *users = [[[cdPrototype.users mapWithBlock:^id(id obj) {
        HBPrototypeUser *user = [obj toHBPrototypeUser];
        user.prototype = prototype;
        return user;
    }] allObjects] mutableCopy];
    [users sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"lastRecordingDate" ascending:NO]]];
    prototype.users = [NSOrderedSet orderedSetWithArray:users];
    
    NSMutableArray *allRecords = [NSMutableArray array];
    for (HBPrototypeUser *user in prototype.users) {
        [allRecords addObjectsFromArray:[user.records array]];
    }
    [allRecords sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"date" ascending:NO]]];
    prototype.allRecords = [NSOrderedSet orderedSetWithArray:allRecords];
    if (prototype.users.count > 0) {
        prototype.lastRecordingDate = [[prototype.allRecords firstObject] date];
    } else {
        prototype.lastRecordingDate = nil;
    }
    
    return prototype;
}

@end
