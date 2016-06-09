//
//  HBPrototypesManager.h
//  Habco
//
//  Created by Игорь Савельев on 06/04/16.
//  Copyright © 2016 Leonspok. All rights reserved.
//

#import <Foundation/Foundation.h>

@class HBCPrototype, HBCPrototypeRecord, HBCPrototypeUser, HBCRecordingSettings;

@interface HBPrototypesManager : NSObject

+ (instancetype)sharedManager;

@property (nonatomic, readonly) NSString *pathToFolder;
@property (nonatomic, strong) NSString *customUserAgent;
@property (nonatomic, readonly) BOOL shouldRequestCustomUserAgent;

- (void)removeUnfinishedRecords;

- (NSArray<HBCPrototype *> *)allPrototypes;
- (NSArray<HBCPrototypeRecord *> *)allRecordsFor:(HBCPrototype *)prototype;

- (HBCPrototype *)createPrototype;
- (NSString *)pathToFolderForPrototype:(HBCPrototype *)prototype;
- (void)saveChangesInPrototype:(HBCPrototype *)prototype;
- (void)removePrototype:(HBCPrototype *)prototype;

- (HBCPrototypeUser *)createUserForPrototype:(HBCPrototype *)prototype;
- (NSString *)pathToFolderForUser:(HBCPrototypeUser *)user;
- (void)saveChangesInUser:(HBCPrototypeUser *)prototypeUser;
- (void)removeUser:(HBCPrototypeUser *)user;

- (HBCPrototypeRecord *)createRecordForUser:(HBCPrototypeUser *)user;
- (NSString *)pathToFolderForRecord:(HBCPrototypeRecord *)record;
- (void)saveChangesInRecord:(HBCPrototypeRecord *)record;
- (void)removeRecord:(HBCPrototypeRecord *)record;

@end
