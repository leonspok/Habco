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

- (NSArray<HBCPrototype *> *)allPrototypes;
- (HBCPrototype *)createPrototypeWithName:(NSString *)name
                                      url:(NSURL *)url;
- (void)saveChangesInPrototype:(HBCPrototype *)prototype;
- (void)removePrototype:(HBCPrototype *)prototype;
- (HBCPrototypeUser *)createUserForPrototype:(HBCPrototype *)prototype;
- (void)saveChangesInUser:(HBCPrototypeUser *)prototypeUser;
- (void)removeUser:(HBCPrototypeUser *)user;
- (HBCPrototypeRecord *)createRecordForUser:(HBCPrototypeRecord *)record;
- (void)saveChangedToRecord:(HBCPrototypeRecord *)record;
- (void)removeRecord:(HBCPrototypeRecord *)record;

@end
