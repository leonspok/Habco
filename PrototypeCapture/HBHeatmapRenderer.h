//
//  HBHeatmapRenderer.h
//  Habco
//
//  Created by Игорь Савельев on 11/05/16.
//  Copyright © 2016 Leonspok. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HBHeatmap.h"

@class HBCPrototype, HBCPrototypeUser, HBCPrototypeRecord;

@interface HBHeatmapRenderer : NSObject

@property (nonatomic, strong, readonly) HBCPrototype *prototype;
@property (nonatomic, strong, readonly) HBCPrototypeUser *prototypeUser;
@property (nonatomic, strong, readonly) HBCPrototypeRecord *prototypeRecord;

@property (nonatomic, strong, readonly) NSArray<HBHeatmap *> *finishedHeatmaps;
@property (nonatomic, strong, readonly) NSArray<HBHeatmap *> *allHeatmaps;
@property (nonatomic, strong, readonly) HBHeatmap *currentRenderingHeatmap;
@property (nonatomic, readonly) float currentRenderingHeatmapProgress;
@property (nonatomic, readonly) float totalRenderingHeatmapProgress;
@property (nonatomic, readonly) BOOL rendering;

@property (nonatomic, strong, readonly) NSString *pathToHeatmapsFolder;

@property (nonatomic, strong) void (^progressBlock)(float progress, HBHeatmap *heatmap);
@property (nonatomic, strong) void (^completionBlock)(NSArray<HBHeatmap *> *heatmaps);

- (id)initWithPrototype:(HBCPrototype *)prototype;
- (id)initWithPrototypeUser:(HBCPrototypeUser *)prototypeUser;
- (id)initWithPrototypeRecord:(HBCPrototypeRecord *)prototypeRecord;

+ (NSString *)pathToHeatmapsFolderForPrototype:(HBCPrototype *)prototype;
+ (NSString *)pathToHeatmapsFolderForPrototypeUser:(HBCPrototypeUser *)prototypeUser;
+ (NSString *)pathToHeatmapsFolderForPrototypeRecord:(HBCPrototypeRecord *)prototypeRecord;

- (void)startHeatmapsRendering;
- (void)stopHeatmapsRendering;

@end
