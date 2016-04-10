//
//  LPViewTouchesRecognizer.m
//  PrototypeCapture
//
//  Created by Игорь Савельев on 01/03/16.
//  Copyright © 2016 Leonspok. All rights reserved.
//

#import "LPViewTouchesRecognizer.h"
#import <UIKit/UIGestureRecognizerSubclass.h>

@interface LPViewTouchesRecognizer()
@property (nonatomic, strong, readwrite) NSArray<LPViewTouch *> *currentTouches;
@property (nonatomic, strong, readwrite) NSArray<UITouch *> *touchObjects;
@end

@implementation LPViewTouchesRecognizer

- (BOOL)cancelsTouchesInView {
    return NO;
}

- (void)recordTouches:(NSSet<UITouch *> *)touches {
    @synchronized (self) {
        NSMutableArray *allTouches = [NSMutableArray arrayWithArray:touches.allObjects];
        [allTouches addObjectsFromArray:self.touchObjects];
        NSMutableArray *finalTouches = [NSMutableArray array];
        NSMutableArray *newTouches = [NSMutableArray array];
        for (UITouch *touch in allTouches) {
            if (touch.phase == UITouchPhaseEnded || touch.phase == UITouchPhaseCancelled) {
                continue;
            }
            [finalTouches addObject:touch];
            
            LPViewTouch *viewTouch = [[LPViewTouch alloc] initWithTouch:touch fromView:self.view];
            BOOL intersects = NO;
            for (LPViewTouch *newTouch in newTouches) {
                if ([newTouch intersectsWith:viewTouch]) {
                    intersects = YES;
                    break;
                }
            }
            if (!intersects) {
                [newTouches addObject:viewTouch];
            }
        }
        self.currentTouches = newTouches;
        self.touchObjects = finalTouches;
    }
}

- (void)reset {
    [super reset];
    self.currentTouches = nil;
    self.touchObjects = nil;
    self.state = UIGestureRecognizerStatePossible;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    [self recordTouches:touches];
    self.state = UIGestureRecognizerStateBegan;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesMoved:touches withEvent:event];
    [self recordTouches:touches];
    self.state = UIGestureRecognizerStateChanged;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesEnded:touches withEvent:event];
    [self recordTouches:touches];
    self.state = UIGestureRecognizerStateEnded;
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesCancelled:touches withEvent:event];
    [self recordTouches:touches];
    self.state = UIGestureRecognizerStateEnded;
}

@end
