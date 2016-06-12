//
//  IBOnboardingViewController.m
//  Habco
//
//  Created by Игорь Савельев on 12/06/16.
//  Copyright © 2016 Leonspok. All rights reserved.
//

#import "IBOnboardingViewController.h"

@import AVFoundation;

static NSString *kTitleKey = @"title";
static NSString *kStartKey = @"start";
static NSString *kStopKey = @"stop";

@interface IBOnboardingViewController ()
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIButton *nextButton;
@property (weak, nonatomic) IBOutlet UIView *videoWrapper;
@property (weak, nonatomic) IBOutlet UIView *welcomeView;
@property (weak, nonatomic) IBOutlet UILabel *recordedLabel;

@property (nonatomic, strong) AVPlayerLayer *playerLayer;
@property (nonatomic, strong) AVPlayer *player;

@property (nonatomic, strong) NSArray<NSDictionary *> *stages;
@property (nonatomic) NSUInteger currentStageIndex;

@end

@implementation IBOnboardingViewController

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.titleLabel setAlpha:0];
    [self.videoWrapper setAlpha:0];
    [self.nextButton setAlpha:0];
    [self.recordedLabel setAlpha:0.0f];
    
    [self.welcomeView setAlpha:0];
    [self.welcomeView setTransform:CGAffineTransformMakeTranslation(0, 20.0f)];
    
    self.stages = @[@{kTitleKey: NSLocalizedString(@"Add prototype", nil),
                      kStartKey: @0.2,
                      kStopKey: @6},
                    @{kTitleKey: NSLocalizedString(@"Add user to prototype", nil),
                      kStartKey: @6,
                      kStopKey: @13},
                    @{kTitleKey: NSLocalizedString(@"Setup recording", nil),
                      kStartKey: @13,
                      kStopKey: @16.5},
                    @{kTitleKey: NSLocalizedString(@"Give your device to user and start recording", nil),
                      kStartKey: @16,
                      kStopKey: @24},
                    @{kTitleKey: NSLocalizedString(@"Watch results and draw conclusions", nil),
                      kStartKey: @24,
                      kStopKey: @40}];
    self.currentStageIndex = 0;
    
    [self.titleLabel setText:[[self.stages objectAtIndex:self.currentStageIndex] objectForKey:kTitleKey]];
    AVPlayerItem *playerItem = [[AVPlayerItem alloc] initWithURL:[[NSBundle mainBundle] URLForResource:@"onboarding" withExtension:@"mp4"]];
    AVPlayer *player = [[AVPlayer alloc] initWithPlayerItem:playerItem];
    typeof(player) __weak weakPlayer = player;
    [player addPeriodicTimeObserverForInterval:CMTimeMake(200, 1000) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        NSTimeInterval currentTime = CMTimeGetSeconds(time);
        if (currentTime >= [[[self.stages objectAtIndex:self.currentStageIndex] objectForKey:kStopKey] floatValue]) {
            [weakPlayer seekToTime:CMTimeMake([[[self.stages objectAtIndex:self.currentStageIndex] objectForKey:kStartKey] floatValue]*1000.0f, 1000)];
        }
    }];
    AVPlayerLayer *layer = [AVPlayerLayer playerLayerWithPlayer:player];
    [layer setFrame:CGRectMake(5, 5, self.videoWrapper.layer.bounds.size.width-10.0f, self.videoWrapper.layer.bounds.size.height-10.0f)];
    [layer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    [self.videoWrapper.layer addSublayer:layer];
    
    [self.videoWrapper.layer setCornerRadius:8.0f];
    [self.videoWrapper.layer setMasksToBounds:YES];
    [self.videoWrapper.layer setBorderWidth:1.0f];
    [self.videoWrapper.layer setBorderColor:[UIColor colorWithWhite:1 alpha:0.3f].CGColor];
    
    self.player = player;
    self.playerLayer = layer;
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    [self.playerLayer setFrame:CGRectMake(5, 5, self.videoWrapper.layer.bounds.size.width-10.0f, self.videoWrapper.layer.bounds.size.height-10.0f)];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [UIView animateWithDuration:0.8f delay:0 usingSpringWithDamping:1 initialSpringVelocity:0.3f options:UIViewAnimationOptionAllowAnimatedContent animations:^{
        [self.welcomeView setAlpha:1.0f];
        [self.welcomeView setTransform:CGAffineTransformIdentity];
    } completion:nil];
    [self.player play];
    [UIView animateWithDuration:0.8f delay:3.0f usingSpringWithDamping:1 initialSpringVelocity:0.1f options:UIViewAnimationOptionAllowAnimatedContent animations:^{
        [self.welcomeView setAlpha:0.0f];
        [self.welcomeView setTransform:CGAffineTransformMakeTranslation(0, -20.0f)];
        [self.titleLabel setAlpha:1];
        [self.videoWrapper setAlpha:1];
        [self.nextButton setAlpha:1];
        [self.recordedLabel setAlpha:1];
    } completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (IBAction)changeStage:(id)sender {
    if (self.currentStageIndex == self.stages.count-1) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
        });
        return;
    } else if (self.currentStageIndex == self.stages.count-2) {
        [self.nextButton setTitle:NSLocalizedString(@"Close", nil) forState:UIControlStateNormal];
    }
    [self.nextButton setEnabled:NO];
    [UIView animateWithDuration:0.5f delay:0 usingSpringWithDamping:1 initialSpringVelocity:0.1f options:UIViewAnimationOptionAllowAnimatedContent animations:^{
        [self.titleLabel setTransform:CGAffineTransformMakeTranslation(-20.0f, 0)];
        [self.titleLabel setAlpha:0.0f];
    } completion:^(BOOL finished) {
        self.currentStageIndex++;
        [self.titleLabel setText:[[self.stages objectAtIndex:self.currentStageIndex] objectForKey:kTitleKey]];
        
        [self.titleLabel setTransform:CGAffineTransformMakeTranslation(20.0f, 0)];
        [UIView animateWithDuration:0.5f delay:0 usingSpringWithDamping:1 initialSpringVelocity:0.1f options:UIViewAnimationOptionAllowAnimatedContent animations:^{
            [self.titleLabel setTransform:CGAffineTransformIdentity];
            [self.titleLabel setAlpha:1.0f];
        } completion:^(BOOL finished) {
            [self.nextButton setEnabled:YES];
        }];
    }];
}

@end
