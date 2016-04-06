//
//  HBCPrototypeRecord+Converting.h
//  Habco
//
//  Created by Игорь Савельев on 06/04/16.
//  Copyright © 2016 Leonspok. All rights reserved.
//

#import "HBCPrototypeRecord.h"

@class HBPrototypeRecord;

@interface HBCPrototypeRecord (Converting)

+ (HBCPrototypeRecord *)createOrUpdateFrom:(HBPrototypeRecord *)prototypeRecord inContext:(NSManagedObjectContext *)context;
- (HBPrototypeRecord *)toHBPrototypeRecord;

@end
