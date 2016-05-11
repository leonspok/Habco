//
//  HBCreateRecordViewController.m
//  Habco
//
//  Created by Игорь Савельев on 09/04/16.
//  Copyright © 2016 Leonspok. All rights reserved.
//

#import "HBRecordViewController.h"
#import "HBSwitchTableViewCell.h"
#import "HBSliderTableViewCell.h"
#import "HBCPrototypeUser.h"
#import "HBCPrototypeRecord.h"
#import "HBCPrototype.h"
#import "HBCRecordingSettings.h"
#import "HBPrototypesManager.h"
#import "LPPrototypeCaptureRecorder.h"

@import WebKit;
@import AVFoundation;
@import AVKit;

static int kHBRecordViewControllerKVOContext;

static NSString *const kSwitchCell = @"kSwitchCell";
static NSString *const kSliderCell = @"kSliderCell";

@interface HBRecordViewController () <UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate>
@property (weak, nonatomic) IBOutlet UIView *setupWrapper;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *setupWrapperTopConstraint;
@property (weak, nonatomic) IBOutlet UITableView *settingsTableView;

@property (weak, nonatomic) IBOutlet UIView *recordingWrapper;
@property (nonatomic, strong) WKWebView *webView;
@property (weak, nonatomic) IBOutlet UIProgressView *webViewLoadingProgress;
@property (nonatomic, strong) UIScreenEdgePanGestureRecognizer *openControlsGestureRecognizer;
@property (weak, nonatomic) IBOutlet UIView *webViewOverlay;
@property (strong, nonatomic) IBOutlet UITapGestureRecognizer *closeControlsGestureRecognizer;
@property (weak, nonatomic) IBOutlet UIView *recordingControlsView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *recordingControlsViewLeftConstraint;
@property (weak, nonatomic) IBOutlet UIButton *toggleRecordingButton;
@property (weak, nonatomic) IBOutlet UILabel *recordingDurationLabel;
@property (nonatomic, strong) NSTimer *recordingDurationChangeTimer;
@property (nonatomic, strong) LPPrototypeCaptureRecorder *recorder;

@property (weak, nonatomic) IBOutlet UIView *recordView;
@property (weak, nonatomic) IBOutlet UIImageView *recordPreviewImage;
@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (weak, nonatomic) IBOutlet UIView *renderingProgressView;
@property (weak, nonatomic) IBOutlet UILabel *renderingProgressLabel;

@property (nonatomic, strong, readwrite) HBCPrototypeRecord *record;
@property (nonatomic, strong, readwrite) HBCPrototypeUser *user;

@property (nonatomic) BOOL recordingWrapperPresented;
@property (nonatomic) BOOL controlsPresented;
@property (nonatomic) BOOL shouldAnimateTransitions;

@property (nonatomic) BOOL withTouches;
@property (nonatomic) BOOL withFrontCamera;
@property (nonatomic) NSUInteger maxFPS;
@property (nonatomic) float downscale;
@property (nonatomic) BOOL withTouchesLogging;

@end

@implementation HBRecordViewController

- (id)initWithUser:(HBCPrototypeUser *)user {
    self = [self initWithNibName:NSStringFromClass(self.class) bundle:nil];
    if (self) {
        self.user = user;
    }
    return self;
}

- (id)initWithRecord:(HBCPrototypeRecord *)record {
    self = [self initWithNibName:NSStringFromClass(self.class) bundle:nil];
    if (self) {
        self.record = record;
        self.user = record.user;
    }
    return self;
}

- (void)dealloc {
    [self.webView removeObserver:self forKeyPath:@"estimatedProgress"];
    [self.webView removeObserver:self forKeyPath:@"URL"];
    [self.recorder removeObserver:self forKeyPath:@"status"];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (BOOL)prefersStatusBarHidden {
    return self.recordingWrapperPresented;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    WKWebViewConfiguration *conf = [[WKWebViewConfiguration alloc] init];
    conf.allowsInlineMediaPlayback = YES;
    conf.allowsAirPlayForMediaPlayback = NO;
    conf.allowsPictureInPictureMediaPlayback = NO;
    self.webView = [[WKWebView alloc] initWithFrame:self.recordingWrapper.bounds configuration:conf];
    self.webView.customUserAgent = [HBPrototypesManager sharedManager].customUserAgent;
    [self.webView setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
    [self.recordingWrapper insertSubview:self.webView atIndex:0];
    [self.webView addObserver:self forKeyPath:@"estimatedProgress" options:NSKeyValueObservingOptionNew context:&kHBRecordViewControllerKVOContext];
    [self.webView addObserver:self forKeyPath:@"URL" options:NSKeyValueObservingOptionNew context:&kHBRecordViewControllerKVOContext];

    self.openControlsGestureRecognizer = [[UIScreenEdgePanGestureRecognizer alloc] initWithTarget:self action:@selector(openControlsGesture:)];
    self.openControlsGestureRecognizer.delegate = self;
    [self.webView addGestureRecognizer:self.openControlsGestureRecognizer];
    
    UINib *switchCellNib = [UINib nibWithNibName:NSStringFromClass(HBSwitchTableViewCell.class) bundle:nil];
    [self.settingsTableView registerNib:switchCellNib forCellReuseIdentifier:kSwitchCell];
    
    UINib *sliderCellNib = [UINib nibWithNibName:NSStringFromClass(HBSliderTableViewCell.class) bundle:nil];
    [self.settingsTableView registerNib:sliderCellNib forCellReuseIdentifier:kSliderCell];
    
    self.withTouches = [self.user.prototype.recordingSettings.withTouches boolValue];
    self.withFrontCamera = [self.user.prototype.recordingSettings.withFrontCamera boolValue];
    self.maxFPS = [self.user.prototype.recordingSettings.maxFPS unsignedIntegerValue];
    self.downscale = [self.user.prototype.recordingSettings.downscale floatValue];
    self.withTouchesLogging = [self.user.prototype.recordingSettings.withTouchesLogging boolValue];
    
    [self.recordPreviewImage.layer setCornerRadius:5.0f];
    [self.recordPreviewImage.layer setMasksToBounds:YES];
    [self.playButton.layer setCornerRadius:5.0f];
    [self.playButton.layer setMasksToBounds:YES];
    
    if (!self.record) {
        self.title = NSLocalizedString(@"New record", nil);
        [self.settingsTableView setHidden:NO];
        [self.recordView setHidden:YES];
        [self setRecordingWrapperPresented:NO];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Record", nil) style:UIBarButtonItemStylePlain target:self action:@selector(initRecording:)];
    } else {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"dd MMM yyyy HH:mm"];
        self.title = [dateFormatter stringFromDate:self.record.date];
        [self setRecordingWrapperPresented:NO];
        [self.settingsTableView setHidden:YES];
        [self.recordView setHidden:NO];
        [self.renderingProgressView setHidden:YES];
        [self setThumbnailImage];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"optionsButton"] style:UIBarButtonItemStylePlain target:self action:@selector(showOptions:)];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self setShouldAnimateTransitions:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (self.recordingWrapperPresented) {
        [self setRecordingWrapperPresented:NO];
        [self startRecordingButtonPressed:self.toggleRecordingButton];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    if (context == &kHBRecordViewControllerKVOContext) {
        if (object == self.webView && [keyPath isEqualToString:@"estimatedProgress"]) {
            [self.webViewLoadingProgress setProgress:self.webView.estimatedProgress animated:YES];
            if (self.webViewLoadingProgress.progress == 1) {
                [self.webViewLoadingProgress setProgress:0 animated:NO];
            }
        } else if (object == self.webView && [keyPath isEqualToString:@"URL"]) {
            [self screenChanged];
        } else if (object == self.recorder && [keyPath isEqualToString:@"status"]) {
            BOOL hasError = NO;
            if (self.recorder.status == LPPrototypeCaptureRecorderStatusRecordingError) {
                DDLogError(@"%@", self.recorder.recordingError);
                hasError = YES;
            } else if (self.recorder.status == LPPrototypeCaptureRecorderStatusRenderingError) {
                DDLogError(@"%@", self.recorder.renderingError);
                hasError = YES;
            }
            
            if (hasError) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (self.presentedViewController) {
                        return;
                    }
                    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", nil) message:NSLocalizedString(@"Something went wrong while recording. It might be because of low performance on your device. Try to lower settings.", nil) preferredStyle:UIAlertControllerStyleAlert];
                    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
                        if (self.record) {
                            [[HBPrototypesManager sharedManager] removeRecord:self.record];
                        }
                        [self.navigationController popViewControllerAnimated:YES];
                    }]];
                    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Try again", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                        if (self.record) {
                            [[HBPrototypesManager sharedManager] removeRecord:self.record];
                        }
                        [self initRecording:nil];
                    }]];
                    [self presentViewController:alertController animated:YES completion:nil];
                });
            }
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark Info

- (void)setThumbnailImage {
    if (!self.record) {
        return;
    }
    
    AVURLAsset *asset = [AVURLAsset assetWithURL:[NSURL fileURLWithPath:[[[HBPrototypesManager sharedManager] pathToFolder] stringByAppendingString:self.record.pathToVideo]]];
    AVAssetImageGenerator *imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
    [imageGenerator setAppliesPreferredTrackTransform:YES];
    
    NSError *error;
    CGImageRef imageRef = [imageGenerator copyCGImageAtTime:CMTimeMake(1, 1) actualTime:nil error:&error];
    if (error) {
        DDLogError(@"%@", error);
    }
    
    [self.recordPreviewImage setImage:[UIImage imageWithCGImage:imageRef]];
}

- (void)setRecordingDurationInfo {
    NSTimeInterval duration = self.recorder.recordingDuration;
    long minutes = (long)roundf(duration/60.0f);
    long seconds = ((long)duration)%60;
    [self.recordingDurationLabel setText:[NSString stringWithFormat:@"%ld:%02ld", minutes, seconds]];
}

#pragma mark GesturRecognizers

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceivePress:(UIPress *)press {
    return YES;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    if (gestureRecognizer == self.openControlsGestureRecognizer) {
        CGPoint location = [self.openControlsGestureRecognizer locationInView:self.view];
        CGPoint translation = [self.openControlsGestureRecognizer translationInView:self.view];
        if (location.x <= 20.0f && translation.x > 0) {
            [self openControlsGesture:self.openControlsGestureRecognizer];
        }
    }
    return YES;
}

- (IBAction)openControlsGesture:(UIScreenEdgePanGestureRecognizer *)sender {
    [self setControlsPresented:YES animated:YES];
}

- (IBAction)closeControlsGesture:(UITapGestureRecognizer *)sender {
    [self setControlsPresented:NO animated:YES];
}

#pragma mark Touches

- (void)screenChanged {
    NSString *urlString = [[self.webView URL] absoluteString];
    NSUInteger slashLocation = [urlString rangeOfString:@"/" options:NSBackwardsSearch].location;
    while (slashLocation == urlString.length-1 && urlString.length > 0) {
        urlString = [urlString substringToIndex:slashLocation];
        slashLocation = [urlString rangeOfString:@"/" options:NSBackwardsSearch].location;
    }
    if (slashLocation == NSNotFound || urlString.length == 0) {
        return;
    }
    NSString *name = [urlString substringFromIndex:slashLocation+1];
    DDLogVerbose(@"Opened screen: %@", name);
    if (name && self.recorder.status == LPPrototypeCaptureRecorderStatusRecording) {
        [self.recorder screenChangedTo:name];
    }
}

#pragma mark Transformations

- (void)setRecordingWrapperPresented:(BOOL)recordingWrapperPresented {
    [self setRecordingWrapperPresented:recordingWrapperPresented animated:NO];
}

- (void)setRecordingWrapperPresented:(BOOL)presented animated:(BOOL)animated {
    _recordingWrapperPresented = presented;
    
    [self.navigationController setNavigationBarHidden:presented animated:animated];
    [self.setupWrapperTopConstraint setConstant:(presented? (self.view.bounds.size.height) : 0.0f)];
    [self.setupWrapper setNeedsLayout];
    
    if (animated) {
        [UIView animateWithDuration:0.3f delay:0 usingSpringWithDamping:1 initialSpringVelocity:0.1f options:UIViewAnimationOptionAllowAnimatedContent animations:^{
            [self.setupWrapper layoutIfNeeded];
            [self.navigationController setNeedsStatusBarAppearanceUpdate];
        } completion:nil];
    } else {
        [self.setupWrapper layoutIfNeeded];
        [self.navigationController setNeedsStatusBarAppearanceUpdate];
    }
}

- (void)setControlsPresented:(BOOL)controlsPresented {
    [self setControlsPresented:controlsPresented animated:NO];
}

- (void)setControlsPresented:(BOOL)controlsPresented animated:(BOOL)animated {
    _controlsPresented = controlsPresented;
    
    [self.recordingDurationChangeTimer invalidate];
    self.recordingDurationChangeTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(setRecordingDurationInfo) userInfo:nil repeats:YES];
    
    if (animated) {
        if (controlsPresented) {
            [self.webViewOverlay setHidden:NO];
            [self.webViewOverlay setAlpha:0.0f];
            
            [self.recordingControlsViewLeftConstraint setConstant:0.0f];
            [self.recordingControlsView setNeedsLayout];
            [UIView animateWithDuration:0.3f delay:0 usingSpringWithDamping:1 initialSpringVelocity:0.1f options:UIViewAnimationOptionAllowAnimatedContent animations:^{
                [self.recordingControlsView layoutIfNeeded];
                [self.webViewOverlay setAlpha:1.0f];
            } completion:nil];
        } else {
            [self.recordingControlsViewLeftConstraint setConstant:(-self.recordingControlsView.frame.size.width)];
            [self.recordingControlsView setNeedsLayout];
            [UIView animateWithDuration:0.3f delay:0 usingSpringWithDamping:1 initialSpringVelocity:0.1f options:UIViewAnimationOptionAllowAnimatedContent animations:^{
                [self.recordingControlsView layoutIfNeeded];
                [self.webViewOverlay setAlpha:0.0f];
            } completion:^(BOOL finished) {
                [self.webViewOverlay setHidden:YES];
            }];
        }
    } else {
        [self.webViewOverlay setHidden:!controlsPresented];
        [self.webViewOverlay setAlpha:(controlsPresented? 1.0f : 0.0f)];
        
        [self.recordingControlsViewLeftConstraint setConstant:(controlsPresented? 0.0f : (-self.recordingControlsView.frame.size.width))];
        [self.recordingControlsView setNeedsLayout];
        [self.recordingControlsView layoutIfNeeded];
    }
}

#pragma mark UIActions

- (IBAction)initRecording:(id)sender {
    self.user.prototype.recordingSettings.withTouches = @(self.withTouches);
    self.user.prototype.recordingSettings.withFrontCamera = @(self.withFrontCamera);
    self.user.prototype.recordingSettings.maxFPS = @(self.maxFPS);
    self.user.prototype.recordingSettings.downscale = @(self.downscale);
    self.user.prototype.recordingSettings.withTouchesLogging = @(self.withTouchesLogging);
    [[HBPrototypesManager sharedManager] saveChangesInPrototype:self.user.prototype];
    
    [self.recordingDurationLabel setText:@"0:00"];
    [self setControlsPresented:NO];
    [self setRecordingWrapperPresented:YES animated:YES];
    [self.toggleRecordingButton setEnabled:NO];
    [self.toggleRecordingButton setSelected:NO];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if ([self.webView.URL absoluteString].length > 0) {
            [self.webView reload];
        } else {
            [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:self.user.prototype.url]]];
        }
        [self.webViewLoadingProgress setProgress:0];
        [self setControlsPresented:YES animated:YES];
        
        self.record = [[HBPrototypesManager sharedManager] createRecordForUser:self.user];
        if (self.recorder) {
            [self.recorder removeObserver:self forKeyPath:@"status"];
        }
        self.recorder = [[LPPrototypeCaptureRecorder alloc] initWithTargetView:self.webView folder:[[HBPrototypesManager sharedManager] pathToFolderForRecord:self.record]];
        [self.recorder addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:&kHBRecordViewControllerKVOContext];
        [self.recorder setWithTouches:self.withTouches];
        [self.recorder setWithFrontCamera:self.withFrontCamera];
        [self.recorder setFps:self.maxFPS];
        [self.recorder setDownscale:self.downscale];
        [self.recorder setWithTouchesLogging:self.withTouchesLogging];
        
        [self.recorder prepareForRecording];
        [self.toggleRecordingButton setEnabled:YES];
    });
}

- (IBAction)showOptions:(id)sender {
    if (!self.record) {
        return;
    }
    
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Options", nil) message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [actionSheet addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Share", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSArray *itemsToShare = @[[NSURL fileURLWithPath:[[[HBPrototypesManager sharedManager] pathToFolder] stringByAppendingString:self.record.pathToVideo]]];
        UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:itemsToShare applicationActivities:nil];
        [self presentViewController:activityViewController animated:YES completion:nil];
    }]];
    [actionSheet addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Remove", nil) style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [[HBPrototypesManager sharedManager] removeRecord:self.record];
        [self.navigationController popViewControllerAnimated:YES];
    }]];
    [actionSheet addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }]];
    [self presentViewController:actionSheet animated:YES completion:nil];
}

- (IBAction)startRecordingButtonPressed:(id)sender {
    if (self.recorder.status == LPPrototypeCaptureRecorderStatusReadyToRecord) {
        [self.recorder startRecording];
        [self setControlsPresented:NO animated:YES];
        [self.toggleRecordingButton setSelected:YES];
        [self screenChanged];
    } else {
        if (self.recorder.status == LPPrototypeCaptureRecorderStatusRecording) {
            [self.recorder stopRecording];
        }
        [self.toggleRecordingButton setSelected:self.shouldAnimateTransitions];
        
        typeof(self) __weak weakSelf = self;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            while (self.recorder.status == LPPrototypeCaptureRecorderStatusRecording) {
                [NSThread sleepForTimeInterval:0.1f];
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.settingsTableView setHidden:YES];
                [self.recordView setHidden:NO];
                self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"optionsButton"] style:UIBarButtonItemStylePlain target:self action:@selector(showOptions:)];
                
                if (self.recorder.status == LPPrototypeCaptureRecorderStatusReadyToRender) {
                    [self.renderingProgressView setHidden:NO];
                    [self.playButton setEnabled:NO];
                    [self.navigationItem.rightBarButtonItem setEnabled:NO];
                } else {
                    [self.renderingProgressView setHidden:YES];
                    
                    self.record.date = [NSDate date];
                    self.record.pathToVideo = [self.recorder.pathToResultVideo stringByReplacingOccurrencesOfString:[[HBPrototypesManager sharedManager] pathToFolder] withString:@""];
                    
                    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                    [dateFormatter setDateFormat:@"dd MMM yyyy HH:mm"];
                    self.title = [dateFormatter stringFromDate:self.record.date];
                    
                    [[HBPrototypesManager sharedManager] saveChangesInRecord:self.record];
                    [self setThumbnailImage];
                }
                
                [self setRecordingWrapperPresented:NO animated:self.shouldAnimateTransitions];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    if (self.recorder.status == LPPrototypeCaptureRecorderStatusReadyToRender) {
                        [self.recorder setRenderingProgressBlock:^(float progress) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                NSUInteger percent = (NSUInteger)roundf(progress*100);
                                [weakSelf.renderingProgressLabel setText:[NSString stringWithFormat:@"%@ (%ld%%)", NSLocalizedString(@"Rendering", nil), (long)percent]];
                            });
                        }];
                        
                        [self.recorder render];
                        
                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                            while (self.recorder.status == LPPrototypeCaptureRecorderStatusRendering) {
                                [NSThread sleepForTimeInterval:0.1f];
                            }
                            
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [weakSelf.renderingProgressView setHidden:YES];
                                [weakSelf.playButton setEnabled:YES];
                                [weakSelf.navigationItem.rightBarButtonItem setEnabled:YES];
                                
                                weakSelf.record.date = [NSDate date];
                                weakSelf.record.pathToVideo = [weakSelf.recorder.pathToResultVideo stringByReplacingOccurrencesOfString:[[HBPrototypesManager sharedManager] pathToFolder] withString:@""];
                                [[HBPrototypesManager sharedManager] saveChangesInRecord:weakSelf.record];
                                
                                weakSelf.record.user.lastRecordingDate = weakSelf.record.date;
                                [[HBPrototypesManager sharedManager] saveChangesInUser:weakSelf.record.user];
                                
                                weakSelf.record.user.prototype.lastRecordingDate = weakSelf.record.date;
                                [[HBPrototypesManager sharedManager] saveChangesInPrototype:weakSelf.record.user.prototype];
                                
                                [[NSFileManager defaultManager] removeItemAtPath:weakSelf.recorder.pathToCameraCaptureVideo error:nil];
                                [[NSFileManager defaultManager] removeItemAtPath:weakSelf.recorder.pathToScreenCaptureVideo error:nil];
                                
                                NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                                [dateFormatter setDateFormat:@"dd MMM yyyy HH:mm"];
                                weakSelf.title = [dateFormatter stringFromDate:weakSelf.record.date];
                                
                                [weakSelf setThumbnailImage];
                            });
                        });
                    }
                });
            });
        });
    }
}

- (IBAction)maxFPSChanged:(UISlider *)slider {
    HBSliderTableViewCell *cell = [self.settingsTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
    NSUInteger value = roundf(slider.value);
    [cell.valueLabel setText:[NSString stringWithFormat:@"%ld", (long)value]];
    self.maxFPS = value;
}

- (IBAction)downscaleChanged:(UISlider *)slider {
    HBSliderTableViewCell *cell = [self.settingsTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:3 inSection:0]];
    CGFloat value = slider.value;
    [cell.valueLabel setText:[NSString stringWithFormat:@"%.1f", value]];
    self.downscale = value;
}

- (IBAction)toggleTouches:(UIButton *)sw {
    self.withTouches = !self.withTouches;
    [sw setSelected:self.withTouches];
    if (!self.withTouches && self.withTouchesLogging) {
        self.withTouchesLogging = NO;
        [self.settingsTableView reloadData];
    }
}

- (IBAction)toggleFrontCamera:(UIButton *)sw {
    self.withFrontCamera = !self.withFrontCamera;
    [sw setSelected:self.withFrontCamera];
}

- (IBAction)toggleTouchesLogging:(UIButton *)sw {
    self.withTouchesLogging = !self.withTouchesLogging;
    [sw setSelected:self.withTouchesLogging];
    if (self.withTouchesLogging && !self.withTouches) {
        self.withTouches = YES;
        [self.settingsTableView reloadData];
    }
}

- (IBAction)playVideo:(id)sender {
    AVPlayerViewController *playerVC = [[AVPlayerViewController alloc] init];
    playerVC.player = [[AVPlayer alloc] initWithURL:[NSURL fileURLWithPath:[[[HBPrototypesManager sharedManager] pathToFolder] stringByAppendingString:self.record.pathToVideo]]];
    playerVC.showsPlaybackControls = YES;
    playerVC.videoGravity = AVLayerVideoGravityResizeAspect;
    playerVC.modalPresentationStyle = UIModalPresentationOverFullScreen;
    [self presentViewController:playerVC animated:YES completion:^{
        [playerVC.player play];
    }];
}

#pragma mark UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 5;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row < 3) {
        return 50.0f;
    } else if (indexPath.row < 5) {
        return 100.0f;
    }
    return 0.0f;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.row) {
        case 0: {
            HBSwitchTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kSwitchCell forIndexPath:indexPath];
            [cell.titleLabel setText:NSLocalizedString(@"Draw touches", nil)];
            [cell.switchButton setSelected:self.withTouches];
            [cell.switchButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
            [cell.switchButton addTarget:self action:@selector(toggleTouches:) forControlEvents:UIControlEventTouchUpInside];
            return cell;
        }
            break;
        case 1: {
            HBSwitchTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kSwitchCell forIndexPath:indexPath];
            [cell.titleLabel setText:NSLocalizedString(@"Log touches", nil)];
            [cell.switchButton setSelected:self.withTouchesLogging];
            [cell.switchButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
            [cell.switchButton addTarget:self action:@selector(toggleTouchesLogging:) forControlEvents:UIControlEventTouchUpInside];
            return cell;
        }
            break;
        case 2: {
            HBSwitchTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kSwitchCell forIndexPath:indexPath];
            [cell.titleLabel setText:NSLocalizedString(@"Front camera", nil)];
            [cell.switchButton setSelected:self.withFrontCamera];
            [cell.switchButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
            [cell.switchButton addTarget:self action:@selector(toggleFrontCamera:) forControlEvents:UIControlEventTouchUpInside];
            return cell;
        }
            break;
        case 3: {
            HBSliderTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kSliderCell forIndexPath:indexPath];
            [cell.titleLabel setText:NSLocalizedString(@"Max FPS", nil)];
            [cell.valueLabel setText:[NSString stringWithFormat:@"%ld", (long)self.maxFPS]];
            [cell.slider setMaximumValue:30.0f];
            [cell.slider setMinimumValue:10.0f];
            [cell.slider setValue:self.maxFPS];
            [cell.slider removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
            [cell.slider addTarget:self action:@selector(maxFPSChanged:) forControlEvents:UIControlEventValueChanged];
            return cell;
        }
            break;
        case 4: {
            HBSliderTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kSliderCell forIndexPath:indexPath];
            [cell.titleLabel setText:NSLocalizedString(@"Screen capture downscale", nil)];
            [cell.valueLabel setText:[NSString stringWithFormat:@"%.1f", self.downscale]];
            [cell.slider setMaximumValue:3.0f];
            [cell.slider setMinimumValue:1.0f];
            [cell.slider setValue:self.downscale];
            [cell.slider removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
            [cell.slider addTarget:self action:@selector(downscaleChanged:) forControlEvents:UIControlEventValueChanged];
            return cell;
        }
            break;
        
        default:
            break;
    }
    return nil;
}

@end
