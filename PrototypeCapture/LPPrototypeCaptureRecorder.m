//
//  LPPrototypeCaptureRecorder.m
//  PrototypeCapture
//
//  Created by Игорь Савельев on 28/02/16.
//  Copyright © 2016 Leonspok. All rights reserved.
//

#import "LPPrototypeCaptureRecorder.h"

@import AVFoundation;

@interface LPPrototypeCaptureRecorder()
@property (nonatomic, strong) NSString *currentRecordFolder;
//@property (nonatomic, strong) CADisplayLink *recordingDisplayLink;
@property (nonatomic, strong) NSTimer *captureTargetViewTimer;
@property (nonatomic, strong) NSTimer *recordVideoTimer;
@property (nonatomic, strong) NSDate *currentRecordStartTime;
@property (nonatomic, strong) AVAssetWriter *videoWriter;
@property (nonatomic, strong) AVAssetWriterInput *videoWriterInput;
@property (nonatomic, strong) AVAssetWriterInputPixelBufferAdaptor *pixelBufferAdaptor;
@property (nonatomic, strong) UIImage *targetViewSnapshot;

@end

@implementation LPPrototypeCaptureRecorder {
    dispatch_queue_t writeQueue;
    dispatch_queue_t snapshotQueue;
    dispatch_semaphore_t semaphore;
    CGRect capturingFrame;
    NSUInteger frameCounter;
    NSMutableArray *frames;
}

- (id)initWithTargetView:(UIView *)view baseFolder:(NSString *)baseFolder {
    self = [super init];
    if (self) {
        _targetView = view;
        _baseFolder = baseFolder;
        self.fps = 15;
        self.downscale = 1.5f;
        
        writeQueue = dispatch_queue_create("Recording Queue", DISPATCH_QUEUE_CONCURRENT);
        snapshotQueue = dispatch_queue_create("Snapshot Queue", DISPATCH_QUEUE_CONCURRENT);
        
        semaphore = dispatch_semaphore_create(1);
        frames = [NSMutableArray array];
    }
    return self;
}

#pragma mark Recording

- (void)getSnapshotCompletion:(void (^)(UIImage *))completion {
    UIGraphicsBeginImageContextWithOptions(capturingFrame.size, YES, 1.0f);
    [self.targetView drawViewHierarchyInRect:capturingFrame afterScreenUpdates:NO];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    if (completion) {
        completion(image);
    }
}

- (CVPixelBufferRef)pixelBufferFromCGImage:(CGImageRef)image {
    CGSize frameSize = CGSizeMake(CGImageGetWidth(image), CGImageGetHeight(image));
    NSDictionary *options = @{(__bridge NSString *)kCVPixelBufferCGImageCompatibilityKey: @(YES),
                              (__bridge NSString *)kCVPixelBufferCGBitmapContextCompatibilityKey: @(YES)};
    CVPixelBufferRef pixelBuffer;
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, frameSize.width, frameSize.height,  kCVPixelFormatType_32ARGB, (__bridge CFDictionaryRef) options, &pixelBuffer);
    if (status != kCVReturnSuccess) {
        return NULL;
    }
    
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    void *data = CVPixelBufferGetBaseAddress(pixelBuffer);
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(data, frameSize.width, frameSize.height, 8, CVPixelBufferGetBytesPerRow(pixelBuffer), rgbColorSpace, (CGBitmapInfo) kCGImageAlphaNoneSkipFirst);
    CGContextDrawImage(context, CGRectMake(0, 0, CGImageGetWidth(image), CGImageGetHeight(image)), image);
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    
    return pixelBuffer;
}

- (void)recordSnapshot:(UIImage *)snapshot timestamp:(NSTimeInterval)timestamp {
    dispatch_async(writeQueue, ^{
        while(!self.pixelBufferAdaptor.assetWriterInput.readyForMoreMediaData) {}
        
        CVPixelBufferRef pixelBuffer = [self pixelBufferFromCGImage:snapshot.CGImage];
        BOOL appended = YES;
        if (pixelBuffer != NULL) {
            appended = [self.pixelBufferAdaptor appendPixelBuffer:pixelBuffer withPresentationTime:CMTimeMake((int64_t)frameCounter, (int32_t)self.fps)];
            CVPixelBufferRelease(pixelBuffer);
        }        
//        if (appended) {
//            NSLog(@"Successfully appended frame %ld", (long)frameCounter);
//        } else {
//            NSLog(@"Failed append frame %ld", (long)frameCounter);
//        }
        frameCounter++;
    });
}

- (void)captureFrame {
    if (dispatch_semaphore_wait(semaphore, DISPATCH_TIME_NOW) == 0) {
        [self getSnapshotCompletion:^(UIImage *image) {
            dispatch_semaphore_signal(semaphore);
            self.targetViewSnapshot = image;
        }];
    }
}

- (void)recordFrame {
    NSTimeInterval timestamp = [[NSDate date] timeIntervalSinceDate:self.currentRecordStartTime];
    [self recordSnapshot:self.targetViewSnapshot timestamp:timestamp];
}

#pragma mark Managing

- (void)prepareForRecording {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd HH.mm.ss"];
    NSString *folderName = [formatter stringFromDate:[NSDate date]];
    NSString *newRecordingFolder = [self.baseFolder stringByAppendingPathComponent:folderName];
    [[NSFileManager defaultManager] createDirectoryAtPath:newRecordingFolder withIntermediateDirectories:NO attributes:nil error:nil];
    
    self.currentRecordFolder = newRecordingFolder;
    _readyToRecord = YES;
}

- (void)startRecording {
    if (!self.isReadyToRecord || self.isRecording) {
        return;
    }
    _recording = YES;
    
    capturingFrame = (CGRect){CGPointZero, CGSizeMake(floor(self.targetView.bounds.size.width/self.downscale), floor(self.targetView.bounds.size.height/self.downscale))};
    
    NSError *error = nil;
    self.videoWriter = [[AVAssetWriter alloc] initWithURL:[NSURL fileURLWithPath:[self.currentRecordFolder stringByAppendingPathComponent:@"video.mp4"]] fileType:AVFileTypeMPEG4 error:&error];
    NSParameterAssert(self.videoWriter);
    
    NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:AVVideoCodecH264, AVVideoCodecKey, @(capturingFrame.size.width), AVVideoWidthKey, @(capturingFrame.size.height), AVVideoHeightKey, nil];
    AVAssetWriterInput* writerInput = [AVAssetWriterInput                                  assetWriterInputWithMediaType:AVMediaTypeVideo                                        outputSettings:videoSettings];
    NSParameterAssert(writerInput);
    NSParameterAssert([self.videoWriter canAddInput:writerInput]);
    self.videoWriterInput.expectsMediaDataInRealTime = YES;
    [self.videoWriter addInput:writerInput];

    self.pixelBufferAdaptor = [AVAssetWriterInputPixelBufferAdaptor                                                  assetWriterInputPixelBufferAdaptorWithAssetWriterInput:writerInput sourcePixelBufferAttributes:nil];
    
    self.captureTargetViewTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f/self.fps target:self selector:@selector(captureFrame) userInfo:nil repeats:YES];
    self.recordVideoTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f/self.fps target:self selector:@selector(recordFrame) userInfo:nil repeats:YES];
    
    self.currentRecordStartTime = [NSDate date];
    
    [self.videoWriter startWriting];
    [self.videoWriter startSessionAtSourceTime:kCMTimeZero];
    
    frameCounter = 0;
    
    [self captureFrame];
    [self recordFrame];
}

- (void)stopRecording {
    [self.captureTargetViewTimer invalidate];
    self.captureTargetViewTimer = nil;
    [self.recordVideoTimer invalidate];
    self.recordVideoTimer = nil;
    
    [self.videoWriterInput markAsFinished];
    [self.videoWriter endSessionAtSourceTime:CMTimeMake([[NSDate date] timeIntervalSinceDate:self.currentRecordStartTime], 1)];
    [self.videoWriter finishWritingWithCompletionHandler:^{
        
    }];
    
    _recording = NO;
    _readyToRecord = NO;
}

@end
