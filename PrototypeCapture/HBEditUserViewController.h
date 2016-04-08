//
//  HBEditUserViewController.h
//  Habco
//
//  Created by Игорь Савельев on 08/04/16.
//  Copyright © 2016 Leonspok. All rights reserved.
//

#import "HBViewController.h"

@class HBCPrototype, HBCPrototypeUser;

@interface HBEditUserViewController : HBViewController

@property (nonatomic, strong) HBCPrototypeUser *user;
@property (nonatomic, strong) void (^saveBlock)();
@property (nonatomic, strong) void (^cancelBlock)();

- (id)initWithPrototype:(HBCPrototype *)prototype title:(NSString *)title saveButtonTitle:(NSString *)saveButtonTitle;

- (id)initWithUser:(HBCPrototypeUser *)user title:(NSString *)title saveButtonTitle:(NSString *)saveButtonTitle;

@end
