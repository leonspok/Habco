//
//  HBUsersListViewController.h
//  Habco
//
//  Created by Игорь Савельев on 08/04/16.
//  Copyright © 2016 Leonspok. All rights reserved.
//

#import "HBViewController.h"

@class HBCPrototype, HBCPrototypeUser;

@interface HBUsersListViewController : HBViewController

@property (nonatomic, strong, readonly) HBCPrototype *prototype;
@property (nonatomic, strong) void (^userWasSelectedBlock)(HBCPrototypeUser *user);

- (id)initWithPrototype:(HBCPrototype *)prototype;

@end
