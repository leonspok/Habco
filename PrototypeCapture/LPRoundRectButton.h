//
//  LPRoundRectButton.h
//  Leonspok
//
//  Created by Игорь Савельев on 18/08/15.
//  Copyright (c) 2015 10tracks. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LPRoundRectButton : UIButton

@property (nonatomic) CGFloat cornerRadius;
@property (nonatomic) CGFloat borderWidth;

- (void)setBackgroundColor:(UIColor *)backgroundColor
                  forState:(UIControlState)state;

- (void)setBorderColor:(UIColor *)color
              forState:(UIControlState)state;

@end
