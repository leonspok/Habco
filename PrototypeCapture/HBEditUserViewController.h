//
//  HBEditUserViewController.h
//  Habco
//
//  Created by Игорь Савельев on 08/04/16.
//  Copyright © 2016 Leonspok. All rights reserved.
//

#import <UIKit/UIKit.h>

@class HBCPrototype, HBCPrototypeUser;

@interface HBEditUserViewController : UIViewController

@property (nonatomic, strong) HBCPrototypeUser *user;
@property (nonatomic, strong) void (^saveBlock)();

- (id)initWithPrototype:(HBCPrototype *)prototype title:(NSString *)title saveButtonTitle:(NSString *)saveButtonTitle;

- (id)initWithUser:(HBCPrototypeUser *)user title:(NSString *)title saveButtonTitle:(NSString *)saveButtonTitle;

@end
