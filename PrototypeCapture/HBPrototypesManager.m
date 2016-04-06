//
//  HBPrototypesManager.m
//  Habco
//
//  Created by Игорь Савельев on 06/04/16.
//  Copyright © 2016 Leonspok. All rights reserved.
//

#import "HBPrototypesManager.h"
#import <MagicalRecord/MagicalRecord.h>
#import "HBCPrototype.h"
#import "HBCRecordingSettings.h"
#import "HBCPrototypeUser.h"
#import "HBCPrototypeRecord.h"

@interface HBPrototypesManager()
@property (nonatomic, strong) NSString *pathToFolder;
@end

@implementation HBPrototypesManager

+ (instancetype)sharedManager {
    static HBPrototypesManager *__sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __sharedManager = [[HBPrototypesManager alloc] init];
    });
    return __sharedManager;
}

- (id)init {
    self = [super init];
    if (self) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        self.pathToFolder = [paths firstObject];
    }
    return self;
}

- (NSArray<HBCPrototype *> *)allPrototypes {
    NSArray<HBCPrototype *> *prototypes = [HBCPrototype MR_findAllSortedBy:@"lastRecordingDate" ascending:NO];
    return prototypes;
}

- (NSArray<HBCPrototypeRecord *> *)allRecordsFor:(HBCPrototype *)prototype {
    NSMutableArray *records = [NSMutableArray array];
    for (HBCPrototypeUser *user in prototype.users) {
        [records addObjectsFromArray:[user.records allObjects]];
    }
    [records sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"date" ascending:NO]]];
    return records;
}

- (HBCPrototype *)createPrototype {
    __block NSString *uid;
    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext * _Nonnull localContext) {
        HBCPrototype *prototype = [HBCPrototype MR_createEntityInContext:localContext];
        uid = [[NSUUID UUID] UUIDString];
        prototype.uid = uid;
        
        prototype.recordingSettings = [HBCRecordingSettings MR_createEntityInContext:localContext];
        prototype.recordingSettings.withTouches = @YES;
        prototype.recordingSettings.withFrontCamera = @YES;
        prototype.recordingSettings.maxFPS = @(15);
        prototype.recordingSettings.downscale = @(1.5f);
    }];
    
    HBCPrototype *prototype = [HBCPrototype MR_findFirstByAttribute:@"uid" withValue:uid];
    
    NSString *pathToPrototypeFolder = [self pathToFolderForPrototype:prototype];
    if (![[NSFileManager defaultManager] fileExistsAtPath:pathToPrototypeFolder]) {
        NSError *error;
        [[NSFileManager defaultManager] createDirectoryAtPath:pathToPrototypeFolder withIntermediateDirectories:YES attributes:nil error:&error];
        if (error) {
            DDLogError(@"Creating folder for prototype: %@", error);
        }
    }
    
    NSString *pathToPlist = [pathToPrototypeFolder stringByAppendingPathComponent:@"info.plist"];
    [[prototype jsonRepresentation] writeToFile:pathToPlist atomically:YES];
    
    return prototype;
}

- (NSString *)pathToFolderForPrototype:(HBCPrototype *)prototype {
    return [self.pathToFolder stringByAppendingPathComponent:prototype.uid];
}

- (void)saveChangesInPrototype:(HBCPrototype *)prototype {
    
    NSString *pathToPlist = [[self pathToFolderForPrototype:prototype] stringByAppendingPathComponent:@"info.plist"];
    [[prototype jsonRepresentation] writeToFile:pathToPlist atomically:YES];
    
    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext * _Nonnull localContext) {
        HBCPrototype *localPrototype = [prototype MR_inContext:localContext];
        localPrototype.name = prototype.name;
        localPrototype.prototypeDescription = prototype.prototypeDescription;
        localPrototype.dateCreated = prototype.dateCreated;
        localPrototype.url = prototype.url;
        localPrototype.lastRecordingDate = prototype.lastRecordingDate;
        localPrototype.recordingSettings.withTouches = prototype.recordingSettings.withTouches;
        localPrototype.recordingSettings.withFrontCamera = prototype.recordingSettings.withFrontCamera;
        localPrototype.recordingSettings.maxFPS = prototype.recordingSettings.maxFPS;
        localPrototype.recordingSettings.downscale = prototype.recordingSettings.downscale;
    }];
}

- (void)removePrototype:(HBCPrototype *)prototype {
    NSString *pathToPrototypeFolder = [self pathToFolderForPrototype:prototype];
    if ([[NSFileManager defaultManager] fileExistsAtPath:pathToPrototypeFolder]) {
        [[NSFileManager defaultManager] removeItemAtPath:pathToPrototypeFolder error:nil];
    }
    
    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext * _Nonnull localContext) {
        HBCPrototype *localPrototype = [prototype MR_inContext:localContext];
        [localPrototype MR_deleteEntityInContext:localContext];
    }];
}

- (HBCPrototypeUser *)createUserForPrototype:(HBCPrototype *)prototype {
    __block NSString *uid;
    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext * _Nonnull localContext) {
        HBCPrototypeUser *user = [HBCPrototypeUser MR_createEntityInContext:localContext];
        uid = [[NSUUID UUID] UUIDString];
        user.uid = uid;
        user.prototype = [prototype MR_inContext:localContext];
    }];
    
    HBCPrototypeUser *user = [HBCPrototypeUser MR_findFirstByAttribute:@"uid" withValue:uid];
    
    NSString *pathToUserFolder = [self pathToFolderForUser:user];
    if (![[NSFileManager defaultManager] fileExistsAtPath:pathToUserFolder]) {
        NSError *error;
        [[NSFileManager defaultManager] createDirectoryAtPath:pathToUserFolder withIntermediateDirectories:YES attributes:nil error:&error];
        if (error) {
            DDLogError(@"Creating folder for user: %@", error);
        }
    }
    
    NSString *pathToPlist = [pathToUserFolder stringByAppendingPathComponent:@"info.plist"];
    [[user jsonRepresentation] writeToFile:pathToPlist atomically:YES];
    
    return user;
}

- (NSString *)pathToFolderForUser:(HBCPrototypeUser *)user {
    return [[self pathToFolderForPrototype:user.prototype] stringByAppendingPathComponent:user.uid];
}

- (void)saveChangesInUser:(HBCPrototypeUser *)prototypeUser {
    
    NSString *pathToPlist = [[self pathToFolderForUser:prototypeUser] stringByAppendingPathComponent:@"info.plist"];
    [[prototypeUser jsonRepresentation] writeToFile:pathToPlist atomically:YES];
    
    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext * _Nonnull localContext) {
        HBCPrototypeUser *localUser = [prototypeUser MR_inContext:localContext];
        localUser.name = prototypeUser.name;
        localUser.bio = prototypeUser.bio;
        localUser.dateAdded = prototypeUser.dateAdded;
        localUser.lastRecordingDate = prototypeUser.lastRecordingDate;
    }];
}

- (void)removeUser:(HBCPrototypeUser *)user {
    NSString *pathToUserFolder = [self pathToFolderForUser:user];
    if ([[NSFileManager defaultManager] fileExistsAtPath:pathToUserFolder]) {
        [[NSFileManager defaultManager] removeItemAtPath:pathToUserFolder error:nil];
    }
    
    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext * _Nonnull localContext) {
        HBCPrototypeUser *localUser = [user MR_inContext:localContext];
        [localUser MR_deleteEntityInContext:localContext];
    }];
}

- (HBCPrototypeRecord *)createRecordForUser:(HBCPrototypeUser *)user {
    __block NSString *uid;
    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext * _Nonnull localContext) {
        HBCPrototypeRecord *record = [HBCPrototypeRecord MR_createEntityInContext:localContext];
        uid = [[NSUUID UUID] UUIDString];
        record.uid = uid;
        record.user = user;
    }];
    
    HBCPrototypeRecord *record = [HBCPrototypeRecord MR_findFirstByAttribute:@"uid" withValue:uid];
    
    NSString *pathToRecordFolder = [self pathToFolderForRecord:record];
    if (![[NSFileManager defaultManager] fileExistsAtPath:pathToRecordFolder]) {
        NSError *error;
        [[NSFileManager defaultManager] createDirectoryAtPath:pathToRecordFolder withIntermediateDirectories:YES attributes:nil error:&error];
        if (error) {
            DDLogError(@"Creating folder for record: %@", error);
        }
    }
    
    NSString *pathToPlist = [pathToRecordFolder stringByAppendingPathComponent:@"info.plist"];
    [[record jsonRepresentation] writeToFile:pathToPlist atomically:YES];
    
    return record;
}

- (NSString *)pathToFolderForRecord:(HBCPrototypeRecord *)record {
    return [[self pathToFolderForUser:record.user] stringByAppendingPathComponent:record.uid];
}

- (void)saveChangedInRecord:(HBCPrototypeRecord *)record {
    
    NSString *pathToPlist = [[self pathToFolderForRecord:record] stringByAppendingPathComponent:@"info.plist"];
    [[record jsonRepresentation] writeToFile:pathToPlist atomically:YES];
    
    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext * _Nonnull localContext) {
        HBCPrototypeRecord *localRecord = [record MR_inContext:localContext];
        localRecord.date = record.date;
        localRecord.user.lastRecordingDate = localRecord.date;
        localRecord.user.prototype.lastRecordingDate = localRecord.date;
        localRecord.pathToVideo = record.pathToVideo;
    }];
}

- (void)removeRecord:(HBCPrototypeRecord *)record {
    
    NSString *pathToRecord = [self pathToFolderForRecord:record];
    if ([[NSFileManager defaultManager] fileExistsAtPath:pathToRecord]) {
        [[NSFileManager defaultManager] removeItemAtPath:pathToRecord error:nil];
    }
    
    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext * _Nonnull localContext) {
        HBCPrototypeRecord *localRecord = [record MR_inContext:localContext];
        [localRecord MR_deleteEntityInContext:localContext];
    }];
}

@end
