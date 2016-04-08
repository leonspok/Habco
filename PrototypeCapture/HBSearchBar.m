//
//  HBSearchBar.m
//  Habco
//
//  Created by Игорь Савельев on 08/04/16.
//  Copyright © 2016 Leonspok. All rights reserved.
//

#import "HBSearchBar.h"
#import "UIColor+Pallete.h"

@implementation HBSearchBar

- (id)init {
    self = [super init];
    if (self) {
        [self buildView];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self buildView];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self buildView];
    }
    return self;
}

- (void)buildView {
    [self setBarTintColor:[UIColor backgroundColor]];
    [self setBackgroundImage:[UIImage new]];
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(100, 30), NO, 1.0f);
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, 100, 30) cornerRadius:5.0f];
    CGContextSetFillColorWithColor(UIGraphicsGetCurrentContext(), [UIColor colorWithWhite:1 alpha:0.1f].CGColor);
    CGContextBeginPath(UIGraphicsGetCurrentContext());
    CGContextAddPath(UIGraphicsGetCurrentContext(), path.CGPath);
    CGContextFillPath(UIGraphicsGetCurrentContext());
    UIImage *searchFieldBackgroundImage = UIGraphicsGetImageFromCurrentImageContext();
    searchFieldBackgroundImage = [searchFieldBackgroundImage resizableImageWithCapInsets:UIEdgeInsetsMake(5, 5, 5, 5)];
    UIGraphicsEndImageContext();
    
    [self setSearchFieldBackgroundImage:searchFieldBackgroundImage forState:UIControlStateNormal];
    [[UITextField appearanceWhenContainedInInstancesOfClasses:@[self.class]] setDefaultTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor], NSFontAttributeName: [UIFont systemFontOfSize:14.0f]}];
    [[UILabel appearanceWhenContainedInInstancesOfClasses:@[self.class]] setFont:[UIFont systemFontOfSize:14.0f]];
    [[UILabel appearanceWhenContainedInInstancesOfClasses:@[self.class]] setTextColor:[UIColor colorWithWhite:1 alpha:0.3f]];
    [[UIImageView appearanceWhenContainedInInstancesOfClasses:@[self.class]] setTintColor:[UIColor colorWithWhite:1 alpha:0.3f]];
}

@end
