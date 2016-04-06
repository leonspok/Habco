//
//  HBRecordingSettings.m
//  Habco
//
//  Created by Игорь Савельев on 06/04/16.
//  Copyright © 2016 Leonspok. All rights reserved.
//

#import "HBRecordingSettings.h"

@implementation HBRecordingSettings

- (id)init {
    self = [super init];
    if (self) {
        self.withTouches = YES;
        self.withFrontCamera = YES;
        self.maxFPS = 15;
        self.downscale = 1.5f;
    }
    return self;
}

@end
