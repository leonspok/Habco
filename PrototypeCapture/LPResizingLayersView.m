//
//  LPResizingLayersView.m
//  Leonspok
//
//  Created by Игорь Савельев on 23/06/15.
//  Copyright (c) 2015 10tracks. All rights reserved.
//

#import "LPResizingLayersView.h"

@implementation LPResizingLayersView {
    NSMutableArray *resizingLayers;
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
    resizingLayers = [NSMutableArray array];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    for (CALayer *layer in resizingLayers) {
        [layer setFrame:self.bounds];
    }
}

- (NSArray *)resizingLayers {
    return resizingLayers;
}

- (void)addResizingLayer:(CALayer *)layer {
    if (!layer) {
        return;
    }
    [layer setFrame:self.bounds];
    [self.layer addSublayer:layer];
    [resizingLayers addObject:layer];
}

- (void)removeResizingLayer:(CALayer *)layer {
    if (!layer) {
        return;
    }
    [layer removeFromSuperlayer];
    [resizingLayers removeObject:layer];
}

@end
