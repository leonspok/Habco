//
//  LPRoundRectButton.h
//  Leonspok
//
//  Created by Игорь Савельев on 18/08/15.
//  Copyright (c) 2015 10tracks. All rights reserved.
//

#import <UIKit/UIKit.h>

IB_DESIGNABLE

@interface LPRoundRectButton : UIButton

@property (nonatomic) IBInspectable CGFloat cornerRadius;
@property (nonatomic) IBInspectable CGFloat borderWidth;
@property (nonatomic) IBInspectable UIColor *defaultBorderColor;

- (void)setBackgroundColor:(UIColor *)backgroundColor
                  forState:(UIControlState)state;

- (void)setBorderColor:(UIColor *)color
              forState:(UIControlState)state;

@end
