//
//  LPRoundRectButton.m
//  Leonspok
//
//  Created by Игорь Савельев on 18/08/15.
//  Copyright (c) 2015 10tracks. All rights reserved.
//

#import "LPRoundRectButton.h"

@implementation LPRoundRectButton {
    NSMutableDictionary *backgroundColors;
    NSMutableDictionary *borderColors;
}

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
    backgroundColors = [NSMutableDictionary dictionary];
    [backgroundColors setObject:self.backgroundColor? : [UIColor whiteColor] forKey:@(UIControlStateNormal)];
    
    borderColors = [NSMutableDictionary dictionary];
    [borderColors setObject:self.backgroundColor? : [UIColor whiteColor] forKey:@(UIControlStateNormal)];
    
    self.cornerRadius = 0.0f;
    self.borderWidth = 0.0f;
}

#pragma mark Setters

- (void)setCornerRadius:(CGFloat)cornerRadius {
    [self.layer setCornerRadius:cornerRadius];
}

- (void)setBorderWidth:(CGFloat)borderWidth {
    [self.layer setBorderWidth:borderWidth];
}

- (void)setBackgroundColor:(UIColor *)backgroundColor forState:(UIControlState)state {
    [backgroundColors setObject:backgroundColor forKey:@(state)];
    [self makeChangesForState:self.state];
}

- (void)setBorderColor:(UIColor *)color forState:(UIControlState)state {
    [borderColors setObject:color forKey:@(state)];
    [self makeChangesForState:self.state];
}

#pragma mark States handling

- (UIColor *)backgroundColorForState:(UIControlState)state {
    UIColor *color = [backgroundColors objectForKey:@(state)];
    if (!color) {
        color = [backgroundColors objectForKey:@(UIControlStateNormal)];
    }
    return color;
}

- (UIColor *)borderColorForState:(UIControlState)state {
    UIColor *color = [borderColors objectForKey:@(state)];
    if (!color) {
        color = [borderColors objectForKey:@(UIControlStateNormal)];
    }
    return color;
}

- (void)makeChangesForState:(UIControlState)state {
    self.backgroundColor = [self backgroundColorForState:state];
    self.layer.borderColor = [self borderColorForState:state].CGColor;
}

#pragma mark Observing state changes

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    [self makeChangesForState:self.state];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesCancelled:touches withEvent:event];
    [self makeChangesForState:self.state];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesEnded:touches withEvent:event];
    [self makeChangesForState:self.state];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesMoved:touches withEvent:event];
    [self makeChangesForState:self.state];
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    [self makeChangesForState:self.state];
}

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    [self makeChangesForState:self.state];
}

- (void)setEnabled:(BOOL)enabled {
    [super setEnabled:enabled];
    [self makeChangesForState:self.state];
}

@end
