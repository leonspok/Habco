//
//  LPPrototypeCaptureRecorder.h
//  PrototypeCapture
//
//  Created by Игорь Савельев on 28/02/16.
//  Copyright © 2016 Leonspok. All rights reserved.
//

#import <Foundation/Foundation.h>

@import UIKit;

@interface LPPrototypeCaptureRecorder : NSObject

@property (nonatomic, strong, readonly) NSString *baseFolder;
@property (nonatomic, strong, readonly) UIView *targetView;
@property (nonatomic) NSUInteger fps;
@property (nonatomic) CGFloat downscale;
@property (nonatomic, getter=isRecording) BOOL recording;
@property (nonatomic, getter=isReadyToRecord) BOOL readyToRecord;

- (id)initWithTargetView:(UIView *)view baseFolder:(NSString *)baseFolder;
- (void)prepareForRecording;
- (void)startRecording;
- (void)stopRecording;

@end
