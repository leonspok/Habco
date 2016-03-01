//
//  LPViewTouch.h
//  PrototypeCapture
//
//  Created by Игорь Савельев on 01/03/16.
//  Copyright © 2016 Leonspok. All rights reserved.
//

#import <Foundation/Foundation.h>

@import UIKit;

@interface LPViewTouch : NSObject

@property (nonatomic) CGPoint location;
@property (nonatomic) CGFloat radius;
@property (nonatomic) CGFloat shadowRadius;
@property (nonatomic) CGFloat alpha;

- (id)initWithTouch:(UITouch *)touch fromView:(UIView *)view;

- (BOOL)intersectsWith:(LPViewTouch *)touch;

@end
