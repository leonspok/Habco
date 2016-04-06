//
//  HBCPrototype+Converting.h
//  Habco
//
//  Created by Игорь Савельев on 06/04/16.
//  Copyright © 2016 Leonspok. All rights reserved.
//

#import "HBCPrototype.h"

@class HBPrototype;

@interface HBCPrototype (Converting)

+ (HBCPrototype *)createOrUpdateFrom:(HBPrototype *)prototype inContext:(NSManagedObjectContext *)context;
- (HBPrototype *)toHBPrototype;

@end
