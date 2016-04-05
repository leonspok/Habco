//
//  HBPrototype.h
//  Habco
//
//  Created by Игорь Савельев on 06/04/16.
//  Copyright © 2016 Leonspok. All rights reserved.
//

#import <Foundation/Foundation.h>

@class HBRecordingSettings, HBPrototypeUser, HBPrototypeRecord;

@interface HBPrototype : NSObject

@property (nonatomic, strong) NSString *uid;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *prototypeDescription;
@property (nonatomic, strong) NSURL *url;
@property (nonatomic, strong) NSDate *dateCreated;
@property (nonatomic, strong) NSDate *lastDateRecorded;
@property (nonatomic, strong) HBRecordingSettings *recordingSettings;

@property (nonatomic, strong) NSOrderedSet<HBPrototypeUser *> *users;
@property (nonatomic, strong) NSOrderedSet<HBPrototypeRecord *> *allRecords;

@end
