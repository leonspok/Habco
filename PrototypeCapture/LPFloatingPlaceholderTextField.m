//
//  LPFloatingPlaceholderTextField.m
//  Commons
//
//  Created by Игорь Савельев on 30/03/16.
//  Copyright © 2016 Leonspok. All rights reserved.
//

#import "LPFloatingPlaceholderTextField.h"

#define MOVE_DISTANCE 12.0f

@interface LPFloatingPlaceholderTextField()
@property (nonatomic, strong) UILabel *defaultPlaceholderLabel;
@property (nonatomic, strong) UILabel *floatingPlaceholderLabel;
@end

@implementation LPFloatingPlaceholderTextField

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

- (void)awakeFromNib {
    [self buildView];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    if (![self isFirstResponder] && self.text.length == 0) {
        [self.floatingPlaceholderLabel setFrame:self.bounds];
        [self.defaultPlaceholderLabel setFrame:self.bounds];
    } else {
        [self.floatingPlaceholderLabel setFrame:CGRectApplyAffineTransform(self.bounds, CGAffineTransformMakeTranslation(0, -2*MOVE_DISTANCE))];
        [self.defaultPlaceholderLabel setFrame:CGRectApplyAffineTransform(self.bounds, CGAffineTransformMakeTranslation(0, -2*MOVE_DISTANCE))];
    }
}

- (void)buildView {
    [self setClipsToBounds:NO];
    
    if (!self.floatingPlaceholderLabel) {
        self.floatingPlaceholderLabel = [[UILabel alloc] initWithFrame:self.bounds];
        if (self.floatingPlaceholderFont) {
            [self.floatingPlaceholderLabel setFont:self.floatingPlaceholderFont];
        }
        if (self.floatingPlaceholderColor) {
            [self.floatingPlaceholderLabel setTextColor:self.floatingPlaceholderColor];
        }
        [self.floatingPlaceholderLabel setText:self.floatingPlaceholder];
        [self insertSubview:self.floatingPlaceholderLabel atIndex:0];
        [self.floatingPlaceholderLabel setHidden:YES];
    }
    
    if (!self.defaultPlaceholderLabel) {
        self.defaultPlaceholderLabel = [[UILabel alloc] initWithFrame:self.bounds];
        if (self.defaultPlaceholderFont) {
            [self.defaultPlaceholderLabel setFont:self.defaultPlaceholderFont];
        }
        if (self.defaultPlaceholderColor) {
            [self.defaultPlaceholderLabel setTextColor:self.defaultPlaceholderColor];
        }
        [self.defaultPlaceholderLabel setText:self.floatingPlaceholder];
        [self insertSubview:self.defaultPlaceholderLabel atIndex:1];
    }
    
    [self addTarget:self action:@selector(editingStarted:) forControlEvents:UIControlEventEditingDidBegin];
    [self addTarget:self action:@selector(editingFinished:) forControlEvents:UIControlEventEditingDidEnd];
}

- (void)setFloatingPlaceholder:(NSString *)floatingPlaceholder {
    _floatingPlaceholder = floatingPlaceholder;
    
    [self.floatingPlaceholderLabel setText:floatingPlaceholder];
    [self.defaultPlaceholderLabel setText:floatingPlaceholder];
}

#pragma mark Actions

- (void)setText:(NSString *)text {
    BOOL wasEmpty = self.text.length == 0;
    [super setText:text];
    BOOL becomeEmpty = self.text.length == 0;
    if (wasEmpty && !becomeEmpty) {
        [self.floatingPlaceholderLabel setHidden:NO];
        [self.floatingPlaceholderLabel setAlpha:0.0f];
        [self.floatingPlaceholderLabel setTransform:CGAffineTransformIdentity];
        [self setTransform:CGAffineTransformIdentity];
        [UIView animateWithDuration:0.2f delay:0 usingSpringWithDamping:1 initialSpringVelocity:0.1f options:UIViewAnimationOptionAllowAnimatedContent animations:^{
            [self.floatingPlaceholderLabel setAlpha:1.0f];
            [self.floatingPlaceholderLabel setTransform:CGAffineTransformMakeTranslation(0, -2*MOVE_DISTANCE)];
            [self.defaultPlaceholderLabel setAlpha:0.0f];
            [self.defaultPlaceholderLabel setTransform:CGAffineTransformMakeTranslation(0, -2*MOVE_DISTANCE)];
            [self setTransform:CGAffineTransformMakeTranslation(0, MOVE_DISTANCE)];
        } completion:^(BOOL finished) {
            [self.defaultPlaceholderLabel setHidden:YES];
        }];
    } else if (!wasEmpty && becomeEmpty) {
        [self.defaultPlaceholderLabel setHidden:NO];
        [self.defaultPlaceholderLabel setAlpha:0.0f];
        [self.defaultPlaceholderLabel setTransform:CGAffineTransformMakeTranslation(0, -2*MOVE_DISTANCE)];
        [self setTransform:CGAffineTransformMakeTranslation(0, MOVE_DISTANCE)];
        [UIView animateWithDuration:0.2f delay:0 usingSpringWithDamping:1 initialSpringVelocity:0.1f options:UIViewAnimationOptionAllowAnimatedContent animations:^{
            [self.floatingPlaceholderLabel setAlpha:0.0f];
            [self.floatingPlaceholderLabel setTransform:CGAffineTransformIdentity];
            [self.defaultPlaceholderLabel setAlpha:1.0f];
            [self.defaultPlaceholderLabel setTransform:CGAffineTransformIdentity];
            [self setTransform:CGAffineTransformIdentity];
        } completion:^(BOOL finished) {
            [self.floatingPlaceholderLabel setHidden:YES];
        }];
    }
}

- (IBAction)editingStarted:(id)sender {
    if (self.text.length == 0) {
        [self.floatingPlaceholderLabel setHidden:NO];
        [self.floatingPlaceholderLabel setAlpha:0.0f];
        [self.floatingPlaceholderLabel setTransform:CGAffineTransformIdentity];
        [self setTransform:CGAffineTransformIdentity];
        [UIView animateWithDuration:0.2f delay:0 usingSpringWithDamping:1 initialSpringVelocity:0.1f options:UIViewAnimationOptionAllowAnimatedContent animations:^{
            [self.floatingPlaceholderLabel setAlpha:1.0f];
            [self.floatingPlaceholderLabel setTransform:CGAffineTransformMakeTranslation(0, -2*MOVE_DISTANCE)];
            [self.defaultPlaceholderLabel setAlpha:0.0f];
            [self.defaultPlaceholderLabel setTransform:CGAffineTransformMakeTranslation(0, -2*MOVE_DISTANCE)];
            [self setTransform:CGAffineTransformMakeTranslation(0, MOVE_DISTANCE)];
        } completion:^(BOOL finished) {
            [self.defaultPlaceholderLabel setHidden:YES];
        }];
    }
}

- (IBAction)editingFinished:(id)sender {
    if (self.text.length == 0) {
        [self.defaultPlaceholderLabel setHidden:NO];
        [self.defaultPlaceholderLabel setAlpha:0.0f];
        [self.defaultPlaceholderLabel setTransform:CGAffineTransformMakeTranslation(0, -2*MOVE_DISTANCE)];
        [self setTransform:CGAffineTransformMakeTranslation(0, MOVE_DISTANCE)];
        [UIView animateWithDuration:0.2f delay:0 usingSpringWithDamping:1 initialSpringVelocity:0.1f options:UIViewAnimationOptionAllowAnimatedContent animations:^{
            [self.floatingPlaceholderLabel setAlpha:0.0f];
            [self.floatingPlaceholderLabel setTransform:CGAffineTransformIdentity];
            [self.defaultPlaceholderLabel setAlpha:1.0f];
            [self.defaultPlaceholderLabel setTransform:CGAffineTransformIdentity];
            [self setTransform:CGAffineTransformIdentity];
        } completion:^(BOOL finished) {
            [self.floatingPlaceholderLabel setHidden:YES];
        }];
    }
}

#pragma mark Setters

- (void)setFloatingPlaceholderFont:(UIFont *)floatingPlaceholderFont {
    _floatingPlaceholderFont = floatingPlaceholderFont;
    if (self.floatingPlaceholderFont) {
        [self.floatingPlaceholderLabel setFont:self.floatingPlaceholderFont];
    }
}

- (void)setFloatingPlaceholderColor:(UIColor *)floatingPlaceholderColor {
    _floatingPlaceholderColor = floatingPlaceholderColor;
    if (self.floatingPlaceholderColor) {
        [self.floatingPlaceholderLabel setTextColor:self.floatingPlaceholderColor];
    }
}

- (void)setDefaultPlaceholderFont:(UIFont *)defaultPlaceholderFont {
    _defaultPlaceholderFont = defaultPlaceholderFont;
    if (self.defaultPlaceholderColor) {
        [self.defaultPlaceholderLabel setFont:self.defaultPlaceholderFont];
    }
}

- (void)setDefaultPlaceholderColor:(UIColor *)defaultPlaceholderColor {
    _defaultPlaceholderColor = defaultPlaceholderColor;
    if (self.defaultPlaceholderColor) {
        [self.defaultPlaceholderLabel setTextColor:self.defaultPlaceholderColor];
    }
}

@end
