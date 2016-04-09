//
//  HBCreateRecordViewController.h
//  Habco
//
//  Created by Игорь Савельев on 09/04/16.
//  Copyright © 2016 Leonspok. All rights reserved.
//

#import "HBViewController.h"

@class HBCPrototypeRecord, HBCPrototypeUser;

@interface HBRecordViewController : HBViewController

@property (nonatomic, strong, readonly) HBCPrototypeRecord *record;

- (id)initWithRecord:(HBCPrototypeRecord *)record;
- (id)initWithUser:(HBCPrototypeUser *)user;

@end
