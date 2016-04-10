//
//  HBPrototypePreviewViewController.m
//  Habco
//
//  Created by Игорь Савельев on 08/04/16.
//  Copyright © 2016 Leonspok. All rights reserved.
//

#import "HBPrototypePreviewViewController.h"
#import "HBPrototypesManager.h"

@import WebKit;

static int kHBPrototypePreviewViewControllerKVOContext;

@interface HBPrototypePreviewViewController ()
@property (nonatomic, strong) WKWebView *webView;
@property (weak, nonatomic) IBOutlet UIProgressView *loadingProgress;
@property (nonatomic, strong, readwrite) NSURL *url;
@end

@implementation HBPrototypePreviewViewController

- (id)initWithURL:(NSURL *)url {
    self = [self initWithNibName:NSStringFromClass(self.class) bundle:nil];
    if (self) {
        self.url = url;
    }
    return self;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    WKWebViewConfiguration *conf = [[WKWebViewConfiguration alloc] init];
    conf.allowsInlineMediaPlayback = YES;
    conf.allowsAirPlayForMediaPlayback = NO;
    conf.allowsPictureInPictureMediaPlayback = NO;
    
    self.webView = [[WKWebView alloc] initWithFrame:self.view.bounds configuration:conf];
    [self.webView setCustomUserAgent:[HBPrototypesManager sharedManager].customUserAgent];
    [self.webView setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
    [self.view insertSubview:self.webView atIndex:0];
    
    [self.webView loadRequest:[NSURLRequest requestWithURL:self.url]];
    
    [self.webView addObserver:self forKeyPath:@"estimatedProgress" options:NSKeyValueObservingOptionNew context:&kHBPrototypePreviewViewControllerKVOContext];
}

- (void)dealloc {
    [self.webView removeObserver:self forKeyPath:@"estimatedProgress"];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (IBAction)close:(id)sender {
    if (self.presentingViewController) {
        [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    if (context == &kHBPrototypePreviewViewControllerKVOContext) {
        if (object == self.webView && [keyPath isEqualToString:@"estimatedProgress"]) {
            [self.loadingProgress setProgress:self.webView.estimatedProgress animated:YES];
            if (self.loadingProgress.progress == 1) {
                [self.loadingProgress setHidden:YES];
            }
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end
