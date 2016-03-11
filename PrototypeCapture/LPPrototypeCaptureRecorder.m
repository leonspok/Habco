//
//  LPPrototypeCaptureRecorder.m
//  PrototypeCapture
//
//  Created by Игорь Савельев on 28/02/16.
//  Copyright © 2016 Leonspok. All rights reserved.
//

#import "LPPrototypeCaptureRecorder.h"
#import "LPViewTouchesRecognizer.h"

@import AVFoundation;

@interface LPPrototypeCaptureRecorder() <UIGestureRecognizerDelegate, AVCaptureFileOutputRecordingDelegate>
@property (nonatomic, strong) NSString *currentRecordFolder;
//@property (nonatomic, strong) CADisplayLink *recordingDisplayLink;
@property (nonatomic, strong) NSTimer *captureTargetViewTimer;
@property (nonatomic, strong) NSTimer *recordVideoTimer;
@property (nonatomic, strong) NSDate *currentRecordStartTime;
@property (nonatomic, strong) AVAssetWriter *videoWriter;
@property (nonatomic, strong) AVAssetWriterInput *videoWriterInput;
@property (atomic) BOOL shouldWriteFrame;
@property (nonatomic, strong) AVAssetWriterInputPixelBufferAdaptor *pixelBufferAdaptor;
@property (nonatomic, strong) UIImage *targetViewSnapshot;
@property (nonatomic, strong) LPViewTouchesRecognizer *touchesRecognizer;
@property (nonatomic, strong) AVCaptureDevice *frontCameraDevice;
@property (nonatomic, strong) AVCaptureDevice *audioDevice;
@property (strong, nonatomic) AVCaptureSession *frontCameraCaptureSession;

@end

@implementation LPPrototypeCaptureRecorder {
    dispatch_queue_t writeQueue;
    dispatch_queue_t snapshotQueue;
    dispatch_semaphore_t semaphore;
    CGRect capturingFrame;
    CGContextRef touchesDrawingContext;
    NSUInteger frameCounter;
}

- (id)initWithTargetView:(UIView *)view baseFolder:(NSString *)baseFolder {
    self = [super init];
    if (self) {
        _targetView = view;
        _baseFolder = baseFolder;
        self.fps = 12;
        self.downscale = 2.0f;
        
        writeQueue = dispatch_queue_create("Recording Queue", DISPATCH_QUEUE_CONCURRENT);
        snapshotQueue = dispatch_queue_create("Snapshot Queue", DISPATCH_QUEUE_CONCURRENT);
        
        semaphore = dispatch_semaphore_create(1);
        touchesDrawingContext = NULL;
    }
    return self;
}

#pragma mark Recording

- (void)getSnapshotCompletion:(void (^)(UIImage *))completion {
    UIGraphicsBeginImageContextWithOptions(capturingFrame.size, YES, 1.0f);
    
    if (self.withTouches) {
        CGAffineTransform flipVertical = CGAffineTransformMake(1, 0, 0, -1, 0, capturingFrame.size.height);
        CGContextConcatCTM(UIGraphicsGetCurrentContext(), flipVertical);
    }
    
    [self.targetView drawViewHierarchyInRect:capturingFrame afterScreenUpdates:NO];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    if (self.withTouches) {
        NSArray<LPViewTouch *> *touches = [self.touchesRecognizer currentTouches];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            if (!self.recording || touchesDrawingContext == NULL) {
                return;
            }
            
            CGContextDrawImage(touchesDrawingContext, capturingFrame, image.CGImage);
            
            size_t gradLocationsNum = 2;
            CGFloat gradLocations[2] = {0.0f, 1.0f};
            CGFloat gradColors[8] = {0.0f,0.0f,0.0f,0.0f,0.0f,0.0f,0.0f,0.5f};
            CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
            CGGradientRef gradient = CGGradientCreateWithColorComponents(colorSpace, gradColors, gradLocations, gradLocationsNum);
            CGColorSpaceRelease(colorSpace);
            
            for (LPViewTouch *touch in touches) {
                CGPoint location = touch.location;
                location.x /= self.downscale;
                location.y /= self.downscale;
                CGFloat radius = touch.radius/self.downscale;
                CGFloat shadowRadius = touch.shadowRadius/self.downscale;
                CGFloat alpha = touch.alpha;
                
                CGPathRef path = CGPathCreateWithEllipseInRect(CGRectMake(location.x-radius, location.y-radius, radius*2, radius*2), NULL);
                CGContextBeginPath(touchesDrawingContext);
                CGContextAddPath(touchesDrawingContext, path);
                
                CGContextSetFillColorWithColor(touchesDrawingContext, [UIColor colorWithWhite:0.95f alpha:alpha].CGColor);
                CGContextFillPath(touchesDrawingContext);
                CGPathRelease(path);
                
                CGContextDrawRadialGradient(touchesDrawingContext, gradient, location, (radius+shadowRadius), location, radius, kCGGradientDrawsBeforeStartLocation);
            }
            
            CGGradientRelease(gradient);
            
            CGImageRef cgImage = CGBitmapContextCreateImage(touchesDrawingContext);
            UIImage *snapshotImage = [[UIImage alloc] initWithCGImage:cgImage];
            CGImageRelease(cgImage);
            
            if (completion) {
                completion(snapshotImage);
            }
        });
    } else {
        if (completion) {
            completion(image);
        }
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
        if (!self.shouldWriteFrame) {
            return;
        }
        while(!self.pixelBufferAdaptor.assetWriterInput.readyForMoreMediaData) {}
        if (!self.shouldWriteFrame) {
            return;
        }
        
        CVPixelBufferRef pixelBuffer = [self pixelBufferFromCGImage:snapshot.CGImage];
        BOOL appended = YES;
        if (pixelBuffer != NULL) {
            appended = [self.pixelBufferAdaptor appendPixelBuffer:pixelBuffer withPresentationTime:CMTimeMake((int64_t)frameCounter, (int32_t)self.fps)];
            NSLog(@"%@", [NSString stringWithFormat:@"Frame #%ld %@", (long)frameCounter, appended? @"appended" : @"not appended"]);
            CVPixelBufferRelease(pixelBuffer);
            if (appended) {
                frameCounter++;
            }
        }
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
    if (self.recording) {
        return;
    }
    
    //Init folder
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd HH.mm.ss"];
    NSString *folderName = [formatter stringFromDate:[NSDate date]];
    NSString *newRecordingFolder = [self.baseFolder stringByAppendingPathComponent:folderName];
    [[NSFileManager defaultManager] createDirectoryAtPath:newRecordingFolder withIntermediateDirectories:NO attributes:nil error:nil];
    self.currentRecordFolder = newRecordingFolder;
    
    capturingFrame = (CGRect){CGPointZero, CGSizeMake(floor(self.targetView.bounds.size.width/self.downscale), floor(self.targetView.bounds.size.height/self.downscale))};
    
    //Video writer
    NSError *error = nil;
    self.videoWriter = [[AVAssetWriter alloc] initWithURL:[NSURL fileURLWithPath:[self.currentRecordFolder stringByAppendingPathComponent:@"video.mp4"]] fileType:AVFileTypeMPEG4 error:&error];
    NSParameterAssert(self.videoWriter);
    
    NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:AVVideoCodecH264, AVVideoCodecKey, @(capturingFrame.size.width), AVVideoWidthKey, @(capturingFrame.size.height), AVVideoHeightKey, nil];
    AVAssetWriterInput* writerInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
    NSParameterAssert(writerInput);
    NSParameterAssert([self.videoWriter canAddInput:writerInput]);
    [self.videoWriter addInput:writerInput];
    
    self.pixelBufferAdaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:writerInput sourcePixelBufferAttributes:nil];
    
    //Touches
    if (!self.withTouches || self.touchesRecognizer) {
        [self.touchesRecognizer.view removeGestureRecognizer:self.touchesRecognizer];
        self.touchesRecognizer = nil;
    }
    if (touchesDrawingContext != NULL) {
        CGContextRelease(touchesDrawingContext);
        touchesDrawingContext = NULL;
    }
    
    if (self.withTouches) {
        self.touchesRecognizer = [[LPViewTouchesRecognizer alloc] init];
        [self.targetView addGestureRecognizer:self.touchesRecognizer];
        self.touchesRecognizer.delegate = self;
        self.targetView.multipleTouchEnabled = YES;
        
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        touchesDrawingContext = CGBitmapContextCreate(nil, capturingFrame.size.width, capturingFrame.size.height, 8, capturingFrame.size.width * (CGColorSpaceGetNumberOfComponents(colorSpace) + 1), colorSpace, kCGImageAlphaPremultipliedLast);
        CGColorSpaceRelease(colorSpace);
        
        CGAffineTransform flipVertical = CGAffineTransformMake(1, 0, 0, -1, 0, capturingFrame.size.height);
        CGContextConcatCTM(touchesDrawingContext, flipVertical);
    }
    
    //Camera
    
    if (self.frontCameraCaptureSession.outputs.count > 0) {
        AVCaptureMovieFileOutput *fileOutput = ((AVCaptureMovieFileOutput *)[self.frontCameraCaptureSession.outputs firstObject]);
        [fileOutput stopRecording];
    }
    if (self.frontCameraCaptureSession) {
        [self.frontCameraCaptureSession stopRunning];
        self.frontCameraCaptureSession = nil;
    }
    
    if (self.withFrontCamera) {
        NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
        for(AVCaptureDevice *device in devices) {
            if([device position] == AVCaptureDevicePositionFront) {
                self.frontCameraDevice = device;
            }
        }
        self.audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
        
        AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:self.frontCameraDevice error:nil];
        AVCaptureDeviceInput *audioInput = [AVCaptureDeviceInput deviceInputWithDevice:self.audioDevice error:nil];
        self.frontCameraCaptureSession = [[AVCaptureSession alloc] init];
        [self.frontCameraCaptureSession beginConfiguration];
        [self.frontCameraCaptureSession addInput:input];
        [self.frontCameraCaptureSession addInput:audioInput];
        AVCaptureMovieFileOutput *movieOutput = [[AVCaptureMovieFileOutput alloc] init];
        [self.frontCameraCaptureSession addOutput:movieOutput];
        [self.frontCameraCaptureSession setSessionPreset:AVCaptureSessionPresetHigh];
        [self.frontCameraCaptureSession commitConfiguration];
    }
    
    _readyToRecord = YES;
}

- (void)startRecording {
    if (!self.isReadyToRecord || self.isRecording) {
        return;
    }
    _recording = YES;
    
    self.captureTargetViewTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f/self.fps target:self selector:@selector(captureFrame) userInfo:nil repeats:YES];
    self.recordVideoTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f/self.fps target:self selector:@selector(recordFrame) userInfo:nil repeats:YES];
    
    self.currentRecordStartTime = [NSDate date];
    
    [self.videoWriter startWriting];
    [self.videoWriter startSessionAtSourceTime:kCMTimeZero];
    
    if (self.withFrontCamera) {
        [self.frontCameraCaptureSession startRunning];
        if (self.frontCameraCaptureSession.outputs.count > 0) {
            AVCaptureMovieFileOutput *fileOutput = ((AVCaptureMovieFileOutput *)[self.frontCameraCaptureSession.outputs firstObject]);
            [fileOutput startRecordingToOutputFileURL:[NSURL fileURLWithPath:[self.currentRecordFolder stringByAppendingPathComponent:@"camera.mp4"]] recordingDelegate:self];
        }
    }
    
    frameCounter = 0;
    
    self.shouldWriteFrame = YES;
    [self captureFrame];
    [self recordFrame];
}

- (void)stopRecording {
    [self.captureTargetViewTimer invalidate];
    self.captureTargetViewTimer = nil;
    [self.recordVideoTimer invalidate];
    self.recordVideoTimer = nil;
    
    self.shouldWriteFrame = NO;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0f/self.fps * NSEC_PER_SEC)), writeQueue, ^{
        [self.videoWriterInput markAsFinished];
        [self.videoWriter endSessionAtSourceTime:CMTimeMake([[NSDate date] timeIntervalSinceDate:self.currentRecordStartTime], 1)];
        [self.videoWriter finishWritingWithCompletionHandler:^{
            if (self.withTouches || self.touchesRecognizer) {
                [self.touchesRecognizer.view removeGestureRecognizer:self.touchesRecognizer];
                self.touchesRecognizer = nil;
            }
            
            if (self.withFrontCamera) {
                if (self.frontCameraCaptureSession.outputs.count > 0) {
                    AVCaptureMovieFileOutput *fileOutput = ((AVCaptureMovieFileOutput *)[self.frontCameraCaptureSession.outputs firstObject]);
                    [fileOutput stopRecording];
                }
                if (self.frontCameraCaptureSession) {
                    [self.frontCameraCaptureSession stopRunning];
                    self.frontCameraCaptureSession = nil;
                }
            }
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if (!self.recording && touchesDrawingContext != NULL) {
                    CGContextRelease(touchesDrawingContext);
                    touchesDrawingContext = NULL;
                }
            });
            
            _recording = NO;
            _readyToRecord = NO;
        }];
    });
}

- (void)render {
    NSString *currentRecordFolder = self.currentRecordFolder;
    NSString *path = [currentRecordFolder stringByAppendingPathComponent:@"rendered.mp4"];
    
    AVURLAsset *screenCaptureAsset = [AVURLAsset assetWithURL:[NSURL fileURLWithPath:[currentRecordFolder stringByAppendingPathComponent:@"video.mp4"]]];
    AVAssetTrack *screenCaptureTrack = [[screenCaptureAsset tracksWithMediaType:AVMediaTypeVideo] firstObject];
    AVURLAsset *frontCameraCaptureAsset = [AVURLAsset assetWithURL:[NSURL fileURLWithPath:[currentRecordFolder stringByAppendingPathComponent:@"camera.mp4"]]];
    AVAssetTrack *frontCameraCaptureTrack = [[frontCameraCaptureAsset tracksWithMediaType:AVMediaTypeVideo] firstObject];
    AVAssetTrack *audioTrack = [[frontCameraCaptureAsset tracksWithMediaType:AVMediaTypeAudio] firstObject];
    
    AVMutableComposition *mixComposition = [AVMutableComposition composition];
    
    NSError *error;
    AVMutableCompositionTrack *screenCaptureCompositionTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    [screenCaptureCompositionTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, screenCaptureTrack.asset.duration) ofTrack:screenCaptureTrack atTime:kCMTimeZero error:&error];
    if (error) {
        NSLog(@"Screen capture: %@\n%@\n%@", error.debugDescription, screenCaptureTrack, screenCaptureCompositionTrack);
    }
    
    AVMutableCompositionTrack *frontCameraCaptureCompositionTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    [frontCameraCaptureCompositionTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, frontCameraCaptureTrack.asset.duration) ofTrack:frontCameraCaptureTrack atTime:kCMTimeZero error:&error];
    if (error) {
        NSLog(@"Front camera: %@\n%@\n%@", error.debugDescription, frontCameraCaptureTrack, frontCameraCaptureCompositionTrack);
    }
    
    AVMutableCompositionTrack *audioCompositionTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    [audioCompositionTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, audioTrack.asset.duration) ofTrack:audioTrack atTime:kCMTimeZero error:&error];
    if (error) {
        NSLog(@"Audio: %@\n%@\n%@", error.debugDescription, audioTrack.description, audioCompositionTrack);
    }
    
    AVMutableVideoCompositionInstruction *mainInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    if (CMTimeGetSeconds(screenCaptureAsset.duration) > CMTimeGetSeconds(frontCameraCaptureAsset.duration)) {
        mainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, screenCaptureAsset.duration);
    } else {
        mainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, frontCameraCaptureAsset.duration);
    }
    
    AVMutableVideoCompositionLayerInstruction *screenCaptureLayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:screenCaptureCompositionTrack];
    CGAffineTransform screenCaptureLayerMove = CGAffineTransformMakeTranslation(roundf(160.0f-screenCaptureTrack.naturalSize.width/2.0f), roundf(240.0f-screenCaptureTrack.naturalSize.height/2.0f));
    [screenCaptureLayerInstruction setTransform:screenCaptureLayerMove atTime:kCMTimeZero];
    
    AVMutableVideoCompositionLayerInstruction *frontCameraCaptureLayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:frontCameraCaptureCompositionTrack];
    CGAffineTransform transform = CGAffineTransformMakeTranslation(roundf(480.0f-frontCameraCaptureTrack.naturalSize.width/2.0f), roundf(240.0f-frontCameraCaptureTrack.naturalSize.height/2.0f));
    [frontCameraCaptureLayerInstruction setTransform:CGAffineTransformConcat(frontCameraCaptureTrack.preferredTransform, transform) atTime:kCMTimeZero];
    
    [mainInstruction setLayerInstructions:@[screenCaptureLayerInstruction, frontCameraCaptureLayerInstruction]];
    
    AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition videoComposition];
    [videoComposition setInstructions:@[mainInstruction]];
    [videoComposition setFrameDuration:CMTimeMake(1, 30)];
    [videoComposition setRenderSize:CGSizeMake(640, 480)];
    [videoComposition setRenderScale:1.0f];
    
    if([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    }
    NSURL *url = [NSURL fileURLWithPath:path];
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPresetMediumQuality];
    [exporter setOutputURL:url];
    [exporter setOutputFileType:AVFileTypeMPEG4];
    [exporter setVideoComposition:videoComposition];
    [exporter exportAsynchronouslyWithCompletionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            if (exporter.status == AVAssetExportSessionStatusCompleted) {
                NSLog(@"DONE!");
            } else {
                NSLog(@"Exporting: %@", exporter.error.debugDescription);
            }
        });
    }];
}

#pragma mark UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceivePress:(UIPress *)press {
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

#pragma mark AVCaptureFileOutputRecordingDelegate

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error {
    
}

@end
