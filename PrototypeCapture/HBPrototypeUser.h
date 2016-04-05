//
//  HBPrototypeUser.h
//  Habco
//
//  Created by Игорь Савельев on 06/04/16.
//  Copyright © 2016 Leonspok. All rights reserved.
//

#import <Foundation/Foundation.h>

@class HBPrototype, HBPrototypeRecord;

@interface HBPrototypeUser : NSObject

@property (nonatomic, strong) NSString *uid;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *bio;
@property (nonatomic, strong) NSDate *dateAdded;
@property (nonatomic, strong) NSDate *lastRecordingDate;
@property (nonatomic, strong) HBPrototype *prototype;
@property (nonatomic, strong) NSOrderedSet<HBPrototypeRecord *> *records;

@end
