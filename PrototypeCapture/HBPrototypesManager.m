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

- (HBCPrototype *)createPrototypeWithName:(NSString *)name url:(NSURL *)url {
    __block NSString *uid;
    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext * _Nonnull localContext) {
        HBCPrototype *prototype = [HBCPrototype MR_createEntityInContext:localContext];
        uid = [[NSUUID UUID] UUIDString];
        prototype.uid = uid;
        prototype.name = name;
        prototype.url = [url absoluteString];
        
        NSString *pathToPrototypeFolder = [self.pathToFolder stringByAppendingPathComponent:uid];
        if (![[NSFileManager defaultManager] fileExistsAtPath:pathToPrototypeFolder]) {
            NSError *error;
            [[NSFileManager defaultManager] createDirectoryAtPath:pathToPrototypeFolder withIntermediateDirectories:YES attributes:nil error:&error];
            if (error) {
                DDLogError(@"Creating folder for prototype: %@", error);
            }
        }
    }];
    return [HBCPrototype MR_findFirstByAttribute:@"uid" withValue:uid];
}

- (void)saveChangesInPrototype:(HBCPrototype *)prototype {
    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext * _Nonnull localContext) {
        HBCPrototype *localPrototype = [prototype MR_inContext:localContext];
        
    }];
}

@end
