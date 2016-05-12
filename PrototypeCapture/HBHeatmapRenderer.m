//
//  HBHeatmapRenderer.m
//  Habco
//
//  Created by Игорь Савельев on 11/05/16.
//  Copyright © 2016 Leonspok. All rights reserved.
//

#import "HBHeatmapRenderer.h"
#import "HBPrototypesManager.h"
#import "HBHeatmap.h"
#import "HBCPrototype.h"
#import "HBCPrototypeUser.h"
#import "HBCPrototypeRecord.h"
#import "NSArray+Utilities.h"
#import "LPPrototypeCaptureRecorder.h"
#import "NSString+MD5.h"
#import "EDColor.h"

#define COLLECT_SCREENS_PROGRESS 0.1f
#define RENDERING_PROGRESS 0.9f

#define COPY_SCREENSHOT_PROGRESS 0.2f
#define CALCULATE_RAW_MATRIX_PROGRESS 0.3f
#define NORMALIZE_MATRIX_PROGRESS 0.1f
#define DRAW_HEATMAP_IMAGE_PROGRESS 0.2f
#define SAVE_HEATMAP_IMAGE_PROGRESS 0.2f

@interface HBHeatmapRenderer()
@property (nonatomic, strong, readwrite) HBCPrototype *prototype;
@property (nonatomic, strong, readwrite) HBCPrototypeUser *prototypeUser;
@property (nonatomic, strong, readwrite) HBCPrototypeRecord *prototypeRecord;
@property (nonatomic, strong, readwrite) NSMutableArray<HBHeatmap *> *finishedHeatmaps;
@property (nonatomic, strong, readwrite) NSArray<HBHeatmap *> *allHeatmaps;
@property (nonatomic, strong, readwrite) HBHeatmap *currentRenderingHeatmap;
@property (nonatomic, readwrite) float currentRenderingHeatmapProgress;
@property (nonatomic, readwrite) float totalRenderingHeatmapProgress;
@property (nonatomic, readwrite) BOOL rendering;
@property (nonatomic) BOOL cancelled;
@property (nonatomic, strong) NSString *folder;

@property (nonatomic) dispatch_queue_t renderingQueue;

@end

@implementation HBHeatmapRenderer

- (id)init {
    self = [super init];
    if (self) {
        self.rendering = NO;
        self.renderingQueue = dispatch_queue_create("Rendering heatmaps queue", DISPATCH_QUEUE_CONCURRENT);
    }
    return self;
}

- (id)initWithPrototype:(HBCPrototype *)prototype {
    self = [self init];
    if (self) {
        _prototype = prototype;
        self.folder = [[HBPrototypesManager sharedManager] pathToFolderForPrototype:prototype];
    }
    return self;
}

- (id)initWithPrototypeUser:(HBCPrototypeUser *)prototypeUser {
    self = [self init];
    if (self) {
        _prototypeUser = prototypeUser;
        self.folder = [[HBPrototypesManager sharedManager] pathToFolderForUser:prototypeUser];
    }
    return self;
}

- (id)initWithPrototypeRecord:(HBCPrototypeRecord *)prototypeRecord {
    self = [self init];
    if (self) {
        _prototypeRecord = prototypeRecord;
        self.folder = [[HBPrototypesManager sharedManager] pathToFolderForRecord:prototypeRecord];
    }
    return self;
}

#pragma mark Setters

- (void)setProgressBlock:(void (^)(float, HBHeatmap *))progressBlock {
    typeof(self) __weak weakSelf = self;
    _progressBlock = ^(float progress, HBHeatmap *heatmap) {
        if (weakSelf.allHeatmaps.count > 0) {
            NSUInteger index = [weakSelf.allHeatmaps indexOfObject:heatmap];
            CGFloat totalProgress = (double)index/(double)weakSelf.allHeatmaps.count+progress/weakSelf.allHeatmaps.count;
            weakSelf.totalRenderingHeatmapProgress = COLLECT_SCREENS_PROGRESS+totalProgress*RENDERING_PROGRESS;
        }
        if (progressBlock) {
            progressBlock(progress, heatmap);
        }
    };
}

#pragma mark Paths

- (NSString *)pathToHeatmapsFolder {
    if (self.prototype) {
        return [HBHeatmapRenderer pathToHeatmapsFolderForPrototype:self.prototype];
    } else if (self.prototypeUser) {
        return [HBHeatmapRenderer pathToHeatmapsFolderForPrototypeUser:self.prototypeUser];
    } else if (self.prototypeRecord) {
        return [HBHeatmapRenderer pathToHeatmapsFolderForPrototypeRecord:self.prototypeRecord];
    }
    return nil;
}

+ (NSString *)pathToHeatmapsFolderForPrototype:(HBCPrototype *)prototype {
    return [[[HBPrototypesManager sharedManager] pathToFolderForPrototype:prototype] stringByAppendingPathComponent:@"heatmaps"];
}

+ (NSString *)pathToHeatmapsFolderForPrototypeUser:(HBCPrototypeUser *)prototypeUser {
    return [[[HBPrototypesManager sharedManager] pathToFolderForUser:prototypeUser] stringByAppendingPathComponent:@"heatmaps"];
}

+ (NSString *)pathToHeatmapsFolderForPrototypeRecord:(HBCPrototypeRecord *)prototypeRecord {
    return [[[HBPrototypesManager sharedManager] pathToFolderForRecord:prototypeRecord] stringByAppendingPathComponent:@"heatmaps"];
}

#pragma mark Screens

- (NSArray<NSString *> *)getAllScreensForPrototype:(HBCPrototype *)prototype {
    NSMutableSet *screensSet = [NSMutableSet set];
    for (HBCPrototypeUser *prototypeUser in prototype.users) {
        [screensSet addObjectsFromArray:[self getAllScreensForPrototypeUser:prototypeUser]];
    }
    return [screensSet allObjects];
}

- (NSArray<NSString *> *)getAllScreensForPrototypeUser:(HBCPrototypeUser *)prototypeUser {
    NSMutableSet *screensSet = [NSMutableSet set];
    for (HBCPrototypeRecord *prototypeRecord in prototypeUser.records) {
        [screensSet addObjectsFromArray:[self getAllScreensForPrototypeRecord:prototypeRecord]];
    }
    return [screensSet allObjects];
}

- (NSArray<NSString *> *)getAllScreensForPrototypeRecord:(HBCPrototypeRecord *)prototypeRecord {
    NSString *folder = [[HBPrototypesManager sharedManager] pathToFolderForRecord:prototypeRecord];
    NSString *recordedScreensStr = [NSString stringWithContentsOfFile:[LPPrototypeCaptureRecorder pathToRecordedScreensFileFromFolder:folder] encoding:NSUTF8StringEncoding error:nil];
    return [[recordedScreensStr componentsSeparatedByString:@"\n"] filterWithBlock:^BOOL(NSString *obj) {
        return obj.length > 0;
    }];
}

- (NSArray<HBHeatmap *> *)getAllHeatmaps {
    if (self.prototype) {
        return [[self getAllScreensForPrototype:self.prototype] mapWithBlock:^id(id obj) {
            return [[HBHeatmap alloc] initWithName:obj baseFolder:[self pathToHeatmapsFolder]];
        }];
    } else if (self.prototypeUser) {
        return [[self getAllScreensForPrototypeUser:self.prototypeUser] mapWithBlock:^id(id obj) {
            return [[HBHeatmap alloc] initWithName:obj baseFolder:[self pathToHeatmapsFolder]];
        }];
    } else if (self.prototypeRecord) {
        return [[self getAllScreensForPrototypeRecord:self.prototypeRecord] mapWithBlock:^id(id obj) {
            return [[HBHeatmap alloc] initWithName:obj baseFolder:[self pathToHeatmapsFolder]];
        }];
    }
    return nil;
}

#pragma mark Logs

- (NSString *)fullLogsForPrototype:(HBCPrototype *)prototype name:(NSString *)name {
    NSMutableString *logs = [NSMutableString string];
    BOOL first = YES;
    for (HBCPrototypeUser *user in prototype.users) {
        if (first) {
            first = NO;
        }
        if (!first) {
            [logs appendString:@"\n"];
        }
        [logs appendString:[self fullLogsForPrototypeUser:user name:name]];
    }
    NSArray *lines = [[logs componentsSeparatedByString:@"\n"] sortedArrayUsingComparator:^NSComparisonResult(NSString * _Nonnull obj1, NSString * _Nonnull obj2) {
        return [obj1 compare:obj2];
    }];
    return [lines componentsJoinedByString:@"\n"];
}

- (NSString *)fullLogsForPrototypeUser:(HBCPrototypeUser *)prototypeUser name:(NSString *)name {
    NSMutableString *logs = [NSMutableString string];
    BOOL first = YES;
    for (HBCPrototypeRecord *record in prototypeUser.records) {
        if (first) {
            first = NO;
        }
        if (!first) {
            [logs appendString:@"\n"];
        }
        [logs appendString:[self fullLogsForPrototypeRecord:record name:name]];
    }
    NSArray *lines = [[logs componentsSeparatedByString:@"\n"] sortedArrayUsingComparator:^NSComparisonResult(NSString * _Nonnull obj1, NSString * _Nonnull obj2) {
        return [obj1 compare:obj2];
    }];
    return [lines componentsJoinedByString:@"\n"];
}

- (NSString *)fullLogsForPrototypeRecord:(HBCPrototypeRecord *)prototypeRecord name:(NSString *)name {
    NSString *logs = [NSString stringWithContentsOfFile:[LPPrototypeCaptureRecorder pathToRecordedScreensFileFromFolder:[[HBPrototypesManager sharedManager] pathToFolderForRecord:prototypeRecord]] encoding:NSUTF8StringEncoding error:nil];
    NSArray *lines = [[logs componentsSeparatedByString:@"\n"] sortedArrayUsingComparator:^NSComparisonResult(NSString * _Nonnull obj1, NSString * _Nonnull obj2) {
        return [obj1 compare:obj2];
    }];
    return [lines componentsJoinedByString:@"\n"];
}

- (NSString *)fullLogsForScreenWithName:(NSString *)name {
    if (self.prototype) {
        return [self fullLogsForPrototype:self.prototype name:name];
    } else if (self.prototypeUser) {
        return [self fullLogsForPrototypeUser:self.prototypeUser name:name];
    } else if (self.prototypeRecord) {
        return [self fullLogsForPrototypeRecord:self.prototypeRecord name:name];
    }
    return nil;
}

#pragma mark Screenshot

- (NSString *)pathToImageForScreenWithName:(NSString *)name {
    if (self.prototype) {
        for (HBCPrototypeUser *user in self.prototype.users) {
            for (HBCPrototypeRecord *record in user.records) {
                NSString *imagePath = [LPPrototypeCaptureRecorder pathToScreenshotForScreen:name andFolder:[[HBPrototypesManager sharedManager] pathToFolderForRecord:record]];
                if ([[NSFileManager defaultManager] fileExistsAtPath:imagePath]) {
                    return imagePath;
                }
            }
        }
    } else if (self.prototypeUser) {
        for (HBCPrototypeRecord *record in self.prototypeUser.records) {
            NSString *imagePath = [LPPrototypeCaptureRecorder pathToScreenshotForScreen:name andFolder:[[HBPrototypesManager sharedManager] pathToFolderForRecord:record]];
            if ([[NSFileManager defaultManager] fileExistsAtPath:imagePath]) {
                return imagePath;
            }
        }
    } else if (self.prototypeRecord) {
        NSString *imagePath = [LPPrototypeCaptureRecorder pathToScreenshotForScreen:name andFolder:[[HBPrototypesManager sharedManager] pathToFolderForRecord:self.prototypeRecord]];
        if ([[NSFileManager defaultManager] fileExistsAtPath:imagePath]) {
            return imagePath;
        }
    }
    return nil;
}

#pragma mark Rendering

- (void)startHeatmapsRendering {
    if (self.rendering) {
        return;
    }
    self.rendering = YES;
    self.cancelled = NO;
    self.totalRenderingHeatmapProgress = 0.0f;
    self.currentRenderingHeatmapProgress = 0.0f;
    
    dispatch_async(self.renderingQueue, ^{
        if ([[NSFileManager defaultManager] fileExistsAtPath:[self pathToHeatmapsFolder]]) {
            NSError *error;
            [[NSFileManager defaultManager] createDirectoryAtPath:[self pathToHeatmapsFolder] withIntermediateDirectories:YES attributes:nil error:&error];
            if (error) {
                DDLogError(@"Creating heatmaps directory: %@", error);
            }
        }
        
        self.allHeatmaps = [self getAllHeatmaps];
        NSMutableArray *finished = [NSMutableArray array];
        self.finishedHeatmaps = finished;
        self.totalRenderingHeatmapProgress = COLLECT_SCREENS_PROGRESS;
        if (self.cancelled) {
            return;
        }
        
        for (HBHeatmap *heatmap in self.allHeatmaps) {
            self.currentRenderingHeatmap = heatmap;
            self.currentRenderingHeatmapProgress = 0.0f;
            
            if (self.progressBlock) {
                self.progressBlock(self.currentRenderingHeatmapProgress, self.currentRenderingHeatmap);
            }
            
            NSString *logs = [self fullLogsForScreenWithName:heatmap.name];
            NSString *md5 = [logs MD5String];
            if ([heatmap.hash isEqualToString:md5]) {
                self.currentRenderingHeatmapProgress = 1.0f;
                if (self.progressBlock) {
                    self.progressBlock(self.currentRenderingHeatmapProgress, self.currentRenderingHeatmap);
                }
                continue;
            }
            
            NSString *imagePath = [self pathToImageForScreenWithName:heatmap.name];
            if (imagePath.length == 0) {
                self.currentRenderingHeatmapProgress = 1.0f;
                if (self.progressBlock) {
                    self.progressBlock(self.currentRenderingHeatmapProgress, self.currentRenderingHeatmap);
                }
                continue;
            }
            
            NSError *error;
            if ([[NSFileManager defaultManager] fileExistsAtPath:heatmap.pathToScreenshot]) {
                [[NSFileManager defaultManager] removeItemAtPath:heatmap.pathToScreenshot error:&error];
            }
            [[NSFileManager defaultManager] copyItemAtPath:imagePath toPath:heatmap.pathToScreenshot error:&error];
            if (error) {
                DDLogError(@"%@", error);
            }
            self.currentRenderingHeatmapProgress = COPY_SCREENSHOT_PROGRESS;
            if (self.progressBlock) {
                self.progressBlock(self.currentRenderingHeatmapProgress, self.currentRenderingHeatmap);
            }
            if (self.cancelled) {
                return;
            }
            
            UIImage *heatmapImage = [self renderImageFor:heatmap fromTouchLogs:logs];
            if (self.cancelled) {
                return;
            }
            
            NSData *data = UIImagePNGRepresentation(heatmapImage);
            [data writeToFile:heatmap.pathToHeatmap atomically:YES];
            [heatmap setHash:md5];
            [finished addObject:heatmap];
            if (self.cancelled) {
                return;
            }
            
            self.currentRenderingHeatmapProgress = 1.0f;
        }
        
        if (self.completionBlock) {
            self.completionBlock(self.allHeatmaps);
        }
    });
}

- (UIImage *)renderImageFor:(HBHeatmap *)heatmap fromTouchLogs:(NSString *)logs {
    NSArray *lines = [logs componentsSeparatedByString:@"\n"];
    if (lines.count == 0 || self.cancelled){
        return nil;
    }
    
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
    
    NSString *firstLine = [lines firstObject];
    if (![firstLine hasPrefix:@"SIZE:"]) {
        return nil;
    }
    NSString *sizePart = [firstLine stringByReplacingOccurrencesOfString:@"SIZE:" withString:@""];
    NSArray<NSNumber *> *numbers = [[sizePart componentsSeparatedByString:@";"] mapWithBlock:^id(id obj) {
        return [numberFormatter numberFromString:obj];
    }];
    
    NSUInteger width = [[numbers firstObject] unsignedIntegerValue];
    NSUInteger height = [[numbers lastObject] unsignedIntegerValue];
    
    NSUInteger (^getIndex)(NSUInteger i, NSUInteger j, NSUInteger mWidth) = ^NSUInteger (NSUInteger i, NSUInteger j, NSUInteger mWidth) {
        return i*mWidth+j;
    };
    
    float *matrix = malloc(sizeof(float)*width*height);
    for (NSUInteger i = 0; i < height; i++) {
        for (NSUInteger j = 0; j < width; j++) {
            matrix[getIndex(i, j, width)] = 0.0f;
        }
    }
    
    NSUInteger lineIndex = 0;
    for (NSString *line in lines) {
        if (![line hasPrefix:@"TOUCH:"]) {
            continue;
        }
        NSString *touchPart = [line stringByReplacingOccurrencesOfString:@"TOUCH:" withString:@""];
        NSArray<NSNumber *> *numbers = [[touchPart componentsSeparatedByString:@";"] mapWithBlock:^id(id obj) {
            return [numberFormatter numberFromString:obj];
        }];
        NSUInteger jx = [[numbers objectAtIndex:0] unsignedIntegerValue];
        NSUInteger ix = [[numbers objectAtIndex:1] unsignedIntegerValue];
        NSUInteger radius = [[numbers objectAtIndex:2] unsignedIntegerValue];
        float alpha = [[numbers objectAtIndex:3] floatValue];
        for (NSUInteger i = MAX(0, ix-radius); i < MIN(height, ix+radius); i++) {
            for (NSUInteger j = MAX(0, jx-radius); j < MIN(width, jx+radius); j++) {
                matrix[getIndex(i, j, width)] += 1.0f;
            }
        }
        float progress = (float)lineIndex/(float)lines.count;
        self.currentRenderingHeatmapProgress = COPY_SCREENSHOT_PROGRESS+progress*CALCULATE_RAW_MATRIX_PROGRESS;
        if (self.progressBlock) {
            self.progressBlock(self.currentRenderingHeatmapProgress, self.currentRenderingHeatmap);
        }
        
        if (self.cancelled) {
            free(matrix);
            return nil;
        }
    }
    
    float maxValue = 0.0f;
    for (NSUInteger i = 0; i < height; i++) {
        for (NSUInteger j = 0; j < width; j++) {
            NSUInteger index = getIndex(i, j, width);
            NSUInteger totalIndex = width*height;
            if (matrix[index] > maxValue) {
                maxValue = matrix[index];
            }
            float progress = (float)(index+1)/(float)totalIndex;
            self.currentRenderingHeatmapProgress = COPY_SCREENSHOT_PROGRESS+CALCULATE_RAW_MATRIX_PROGRESS+progress*NORMALIZE_MATRIX_PROGRESS/2.0f;
            if (self.progressBlock) {
                self.progressBlock(self.currentRenderingHeatmapProgress, self.currentRenderingHeatmap);
            }
            
            if (self.cancelled) {
                free(matrix);
                return nil;
            }
        }
    }
    
    for (NSUInteger i = 0; i < height; i++) {
        for (NSUInteger j = 0; j < width; j++) {
            NSUInteger index = getIndex(i, j, width);
            NSUInteger totalIndex = width*height;
            matrix[index] = matrix[index]/maxValue;
            float progress = (float)(index+1)/(float)totalIndex;
            self.currentRenderingHeatmapProgress = COPY_SCREENSHOT_PROGRESS+CALCULATE_RAW_MATRIX_PROGRESS+NORMALIZE_MATRIX_PROGRESS/2.0f*(1+progress);
            if (self.progressBlock) {
                self.progressBlock(self.currentRenderingHeatmapProgress, self.currentRenderingHeatmap);
            }
            
            if (self.cancelled) {
                free(matrix);
                return nil;
            }
        }
    }
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(nil, width, height, 8, width * (CGColorSpaceGetNumberOfComponents(colorSpace) + 1), colorSpace, kCGImageAlphaPremultipliedLast);
    for (NSUInteger i = 0; i < height; i++) {
        for (NSUInteger j = 0; j < width; j++) {
            NSUInteger index = getIndex(i, j, width);
            NSUInteger totalIndex = width*height;
            float val = matrix[index];
            UIColor *color = [UIColor colorWithHue:val saturation:1.0f lightness:0.5f alpha:1.0f];
            CGContextSetFillColorWithColor(context, color.CGColor);
            CGContextFillRect(context, CGRectMake(i, j, width, height));
            float progress = (float)(index+1)/(float)totalIndex;
            self.currentRenderingHeatmapProgress = COPY_SCREENSHOT_PROGRESS+CALCULATE_RAW_MATRIX_PROGRESS+NORMALIZE_MATRIX_PROGRESS+progress*DRAW_HEATMAP_IMAGE_PROGRESS;
            if (self.progressBlock) {
                self.progressBlock(self.currentRenderingHeatmapProgress, self.currentRenderingHeatmap);
            }
            
            if (self.cancelled) {
                CGContextRelease(context);
                CGColorSpaceRelease(colorSpace);
                free(matrix);
                return nil;
            }
        }
    }
    CGImageRef cgImage = CGBitmapContextCreateImage(context);
    UIImage *image = [[UIImage alloc] initWithCGImage:cgImage];
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    CGImageRelease(cgImage);
    free(matrix);
    
    return image;
}

- (void)stopHeatmapsRendering {
    if (!self.rendering) {
        return;
    }
    self.cancelled = YES;
    self.totalRenderingHeatmapProgress = 0.0f;
    self.currentRenderingHeatmapProgress = 0.0f;
    self.currentRenderingHeatmap = nil;
    self.finishedHeatmaps = nil;
}

@end