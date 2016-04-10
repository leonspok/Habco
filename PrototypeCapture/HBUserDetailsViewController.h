//
//  HBUserDetailsViewController.h
//  Habco
//
//  Created by Игорь Савельев on 10/04/16.
//  Copyright © 2016 Leonspok. All rights reserved.
//

#import "HBViewController.h"

@class HBCPrototypeUser;

@interface HBUserDetailsViewController : HBViewController

@property (nonatomic, strong, readonly) HBCPrototypeUser *user;

- (id)initWithUser:(HBCPrototypeUser *)user;

@end
