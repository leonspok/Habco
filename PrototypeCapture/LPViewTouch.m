//
//  LPViewTouch.m
//  PrototypeCapture
//
//  Created by Игорь Савельев on 01/03/16.
//  Copyright © 2016 Leonspok. All rights reserved.
//

#import "LPViewTouch.h"

@implementation LPViewTouch

- (id)initWithTouch:(UITouch *)touch fromView:(UIView *)view {
    self = [super init];
    if (self) {
        self.location = [touch locationInView:view];
        self.radius = touch.majorRadius;
        self.shadowRadius = touch.majorRadiusTolerance;
        self.alpha = 0.8f;
        if (touch.maximumPossibleForce > 1.0f) {
            self.alpha += 0.2f*(touch.force-1.0f)/touch.maximumPossibleForce;
        }
    }
    return self;
}

- (BOOL)intersectsWith:(LPViewTouch *)touch {
    CGFloat distance = sqrt(pow(self.location.x-touch.location.x, 2)+pow(self.location.y-touch.location.y, 2));
    if (distance <= self.radius+touch.radius-5.0f) {
        return YES;
    } else {
        return NO;
    }
}

@end
