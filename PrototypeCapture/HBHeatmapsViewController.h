//
//  HBHeatmapsViewController.h
//  Habco
//
//  Created by Игорь Савельев on 13/05/16.
//  Copyright © 2016 Leonspok. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HBViewController.h"

@class HBCPrototype, HBCPrototypeUser, HBCPrototypeRecord;

@interface HBHeatmapsViewController : HBViewController

- (id)initWithPrototype:(HBCPrototype *)prototype;
- (id)initWithPrototypeUser:(HBCPrototypeUser *)prototypeUser;
- (id)initWithPrototypeRecord:(HBCPrototypeRecord *)prototypeRecord;

@end
