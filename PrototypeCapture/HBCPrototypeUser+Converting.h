//
//  HBCPrototypeUser+Converting.h
//  Habco
//
//  Created by Игорь Савельев on 06/04/16.
//  Copyright © 2016 Leonspok. All rights reserved.
//

#import "HBCPrototypeUser.h"

@class HBPrototypeUser;

@interface HBCPrototypeUser (Converting)

+ (HBCPrototypeUser *)createOrUpdateFrom:(HBPrototypeUser *)prototypeUser inContext:(NSManagedObjectContext *)context;
- (HBPrototypeUser *)toHBPrototypeUser;

@end
