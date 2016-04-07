//
//  UIImageView+Transitions.m
//  Leonspok
//
//  Created by Игорь Савельев on 14/04/15.
//  Copyright (c) 2015 10tracks. All rights reserved.
//

#import "UIImageView+Transitions.h"

@implementation UIImageView(Transitions)

- (void)setImage:(UIImage *)image withTransitionDuration:(CFTimeInterval)duration {
    CATransition *transition = [CATransition animation];
    transition.duration = duration;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.type = kCATransitionFade;
    [self.layer addAnimation:transition forKey:nil];
    
    [self setImage:image];
}

@end
