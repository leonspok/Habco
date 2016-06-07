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

#define COLLECT_SCREENS_PROGRESS 0.05f
#define RENDERING_PROGRESS 0.95f

#define COPY_SCREENSHOT_PROGRESS 0.03f
#define CALCULATE_RAW_MATRIX_PROGRESS 0.04f
#define NORMALIZE_MATRIX_PROGRESS 0.03f
#define DRAW_HEATMAP_IMAGE_PROGRESS 0.85f
#define SAVE_HEATMAP_IMAGE_PROGRESS 0.05f

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
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            if (weakSelf.allHeatmaps.count > 0) {
                NSUInteger index = [weakSelf.allHeatmaps indexOfObject:heatmap];
                CGFloat totalProgress = (double)index/(double)weakSelf.allHeatmaps.count+progress/weakSelf.allHeatmaps.count;
                weakSelf.totalRenderingHeatmapProgress = COLLECT_SCREENS_PROGRESS+totalProgress*RENDERING_PROGRESS;
            }
            if (progressBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    progressBlock(progress, heatmap);
                });
            }
        });
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
    NSArray *users = [prototype.users sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"uid" ascending:YES]]];
    for (HBCPrototypeUser *user in users) {
        NSString *l = [self fullLogsForPrototypeUser:user name:name];
        if (l.length == 0) {
            continue;
        }
        
        if (!first) {
            [logs appendString:@"\n"];
        }
        [logs appendString:l];
        
        if (first) {
            first = NO;
        }
    }
    return logs;
}

- (NSString *)fullLogsForPrototypeUser:(HBCPrototypeUser *)prototypeUser name:(NSString *)name {
    NSMutableString *logs = [NSMutableString string];
    BOOL first = YES;
    NSArray *records = [prototypeUser.records sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"uid" ascending:YES]]];
    for (HBCPrototypeRecord *record in records) {
        NSString *l = [self fullLogsForPrototypeRecord:record name:name];
        if (l.length == 0) {
            continue;
        }
        
        if (!first) {
            [logs appendString:@"\n"];
        }
        [logs appendString:l];
        
        if (first) {
            first = NO;
        }
    }
    return logs;
}

- (NSString *)fullLogsForPrototypeRecord:(HBCPrototypeRecord *)prototypeRecord name:(NSString *)name {
    NSString *logs = [NSString stringWithContentsOfFile:[LPPrototypeCaptureRecorder pathToTouchesLogForScreen:name andFolder:[[HBPrototypesManager sharedManager] pathToFolderForRecord:prototypeRecord]] encoding:NSUTF8StringEncoding error:nil];
    if (logs.length == 0) {
        return @"";
    }
    NSArray *lines = [[logs componentsSeparatedByString:@"\n"] filterWithBlock:^BOOL(NSString *obj) {
        return obj.length > 0;
    }];
    if (lines.count == 0) {
        return @"";
    }
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
        if (![[NSFileManager defaultManager] fileExistsAtPath:[self pathToHeatmapsFolder]]) {
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
            self.rendering = NO;
            if (self.completionBlock) {
                self.completionBlock(self.allHeatmaps);
            }
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
            if ([heatmap.hashString isEqualToString:md5]) {
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
                break;
            }
            
            UIImage *heatmapImage = [self renderImageFor:heatmap fromTouchLogs:logs];
            if (self.cancelled) {
                break;
            }
            
            NSData *data = UIImagePNGRepresentation(heatmapImage);
            [data writeToFile:heatmap.pathToHeatmap atomically:YES];
            [heatmap setHashString:md5];
            [finished addObject:heatmap];
            if (self.cancelled) {
                break;
            }
            
            self.currentRenderingHeatmapProgress = 1.0f;
            if (self.progressBlock) {
                self.progressBlock(self.currentRenderingHeatmapProgress, self.currentRenderingHeatmap);
            }
            
            if (self.heatmapRenderingCompletionBlock) {
                self.heatmapRenderingCompletionBlock(self.currentRenderingHeatmap);
            }
        }
        
        self.rendering = NO;
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
    
    NSString *firstLine = [lines firstObject];
    if (![firstLine hasPrefix:@"SIZE:"]) {
        return nil;
    }
    NSString *sizePart = [firstLine stringByReplacingOccurrencesOfString:@"SIZE:" withString:@""];
    NSArray<NSNumber *> *numbers = [[sizePart componentsSeparatedByString:@";"] mapWithBlock:^id(NSString *obj) {
        return @([obj floatValue]);
    }];
    
    NSUInteger width = [[numbers firstObject] unsignedIntegerValue];
    NSUInteger height = [[numbers lastObject] unsignedIntegerValue];
    CGSize currentSize = CGSizeMake(width, height);
    
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
            if ([line hasPrefix:@"SIZE:"]) {
                NSString *sizePart = [line stringByReplacingOccurrencesOfString:@"SIZE:" withString:@""];
                NSArray<NSNumber *> *numbers = [[sizePart componentsSeparatedByString:@";"] mapWithBlock:^id(NSString *obj) {
                    return @([obj floatValue]);
                }];
                
                NSUInteger width = [[numbers firstObject] unsignedIntegerValue];
                NSUInteger height = [[numbers lastObject] unsignedIntegerValue];
                currentSize = CGSizeMake(width, height);
            }
            continue;
        }
        CGFloat scale = MIN(width/currentSize.width, height/currentSize.height);
        
        NSString *touchPart = [line stringByReplacingOccurrencesOfString:@"TOUCH:" withString:@""];
        NSArray<NSNumber *> *numbers = [[touchPart componentsSeparatedByString:@";"] mapWithBlock:^id(NSString *obj) {
            return @([obj floatValue]);
        }];
        NSInteger jx = (NSInteger)floorf([[numbers objectAtIndex:0] floatValue]*scale);
        NSInteger ix = (NSInteger)floorf([[numbers objectAtIndex:2] floatValue]*scale);
        NSInteger radius = MAX(10.0f, [[numbers objectAtIndex:2] floatValue]*scale);
        NSInteger shadowRadius = (NSInteger)floorf([[numbers objectAtIndex:3] floatValue]*scale);
        for (NSUInteger i = MAX(0, ix-(radius+shadowRadius)); i <= MIN(height, ix+(radius+shadowRadius)); i++) {
            for (NSUInteger j = MAX(0, jx-(radius+shadowRadius)); j <= MIN(width, jx+(radius+shadowRadius)); j++) {
                CGFloat deltaI = (CGFloat)i-(CGFloat)ix;
                CGFloat deltaJ = (CGFloat)j-(CGFloat)jx;
                CGFloat distance = sqrtf(powf(deltaI, 2)+powf(deltaJ, 2));
                if (distance > radius+shadowRadius) {
                    continue;
                } else if (distance >= radius) {
                    matrix[getIndex(i, j, width)] += (1-(distance-radius)/shadowRadius)*0.6f;
                } else {
                    matrix[getIndex(i, j, width)] += (1-(distance-radius)/shadowRadius)*0.4f+0.6f;
                }
            }
        }
        float progress = (float)lineIndex/(float)lines.count;
        lineIndex++;
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
            if (matrix[index] > maxValue) {
                maxValue = matrix[index];
            }
            
            if (self.cancelled) {
                free(matrix);
                return nil;
            }
        }
        NSUInteger index = getIndex(i, width-1, width);
        NSUInteger totalIndex = width*height;
        float progress = (float)(index+1)/(float)totalIndex;
        self.currentRenderingHeatmapProgress = COPY_SCREENSHOT_PROGRESS+CALCULATE_RAW_MATRIX_PROGRESS+progress*NORMALIZE_MATRIX_PROGRESS/2.0f;
        if (self.progressBlock) {
            self.progressBlock(self.currentRenderingHeatmapProgress, self.currentRenderingHeatmap);
        }
    }
    
    if (maxValue > 0) {
        for (NSUInteger i = 0; i < height; i++) {
            for (NSUInteger j = 0; j < width; j++) {
                NSUInteger index = getIndex(i, j, width);
                matrix[index] = matrix[index]/maxValue;
                
                if (self.cancelled) {
                    free(matrix);
                    return nil;
                }
            }
            NSUInteger index = getIndex(i, width-1, width);
            NSUInteger totalIndex = width*height;
            float progress = (float)(index+1)/(float)totalIndex;
            self.currentRenderingHeatmapProgress = COPY_SCREENSHOT_PROGRESS+CALCULATE_RAW_MATRIX_PROGRESS+NORMALIZE_MATRIX_PROGRESS/2.0f*(1+progress);
            if (self.progressBlock) {
                self.progressBlock(self.currentRenderingHeatmapProgress, self.currentRenderingHeatmap);
            }
        }
    }
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(nil, width, height, 8, width * (CGColorSpaceGetNumberOfComponents(colorSpace) + 1), colorSpace, kCGImageAlphaPremultipliedLast);
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), [UIImage imageWithContentsOfFile:[heatmap pathToScreenshot]].CGImage);
    for (NSUInteger i = 0; i < height; i++) {
        for (NSUInteger j = 0; j < width; j++) {
            NSUInteger index = getIndex(i, j, width);
            float val = MAX(0.0f, 1.0f-matrix[index])*240.0f/360.0f;
            UIColor *color = [UIColor colorWithHue:val saturation:1.0f lightness:0.5f alpha:0.3f];
            CGContextSetFillColorWithColor(context, color.CGColor);
            CGContextFillRect(context, CGRectMake(j, (height-1)-i, 1, 1));
            
            if (self.cancelled) {
                CGContextRelease(context);
                CGColorSpaceRelease(colorSpace);
                free(matrix);
                return nil;
            }
        }
        NSUInteger index = getIndex(i, width-1, width);
        NSUInteger totalIndex = width*height;
        float progress = (float)(index+1)/(float)totalIndex;
        self.currentRenderingHeatmapProgress = COPY_SCREENSHOT_PROGRESS+CALCULATE_RAW_MATRIX_PROGRESS+NORMALIZE_MATRIX_PROGRESS+progress*DRAW_HEATMAP_IMAGE_PROGRESS;
        if (self.progressBlock) {
            self.progressBlock(self.currentRenderingHeatmapProgress, self.currentRenderingHeatmap);
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