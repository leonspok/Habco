//
//  HBRecordingSettings.h
//  Habco
//
//  Created by Игорь Савельев on 06/04/16.
//  Copyright © 2016 Leonspok. All rights reserved.
//

#import <Foundation/Foundation.h>

@class HBPrototype;

@interface HBRecordingSettings : NSObject

@property (nonatomic) BOOL withTouches;
@property (nonatomic) BOOL withFrontCamera;
@property (nonatomic) NSUInteger maxFPS;
@property (nonatomic) float downscale;

@property (nonatomic, strong) HBPrototype *prototype;

@end
