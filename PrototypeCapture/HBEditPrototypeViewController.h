//
//  HBEditPrototypeViewController.h
//  Habco
//
//  Created by Игорь Савельев on 07/04/16.
//  Copyright © 2016 Leonspok. All rights reserved.
//

#import "HBViewController.h"

@class HBCPrototype;

@interface HBEditPrototypeViewController : HBViewController

@property (nonatomic, strong) void (^saveBlock)();
@property (nonatomic, strong) void (^cancelBlock)();
@property (nonatomic, strong) HBCPrototype *prototype;

- (id)initWithPrototype:(HBCPrototype *)prototype title:(NSString *)title saveButtonTitle:(NSString *)saveButtonTitle;

@end
