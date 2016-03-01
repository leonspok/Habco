//
//  LPViewTouchesRecognizer.h
//  PrototypeCapture
//
//  Created by Игорь Савельев on 01/03/16.
//  Copyright © 2016 Leonspok. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LPViewTouch.h"

@interface LPViewTouchesRecognizer : UIGestureRecognizer

@property (nonatomic, strong, readonly) NSArray<LPViewTouch *> *currentTouches;

@end
