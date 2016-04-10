//
//  HBPrototypeDetailsViewController.h
//  Habco
//
//  Created by Игорь Савельев on 10/04/16.
//  Copyright © 2016 Leonspok. All rights reserved.
//

#import "HBViewController.h"

@class HBCPrototype;

@interface HBPrototypeDetailsViewController : HBViewController

@property (nonatomic, strong, readonly) HBCPrototype *prototype;

- (id)initWithPrototype:(HBCPrototype *)prototype;

@end
