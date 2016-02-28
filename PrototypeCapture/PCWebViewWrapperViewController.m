//
//  PCWebViewWrapperViewController.m
//  PrototypeCapture
//
//  Created by Игорь Савельев on 28/02/16.
//  Copyright © 2016 Leonspok. All rights reserved.
//

#import "PCWebViewWrapperViewController.h"
#import "LPPrototypeCaptureRecorder.h"

@import WebKit;

@interface PCWebViewWrapperViewController ()
@property (nonatomic, strong) LPPrototypeCaptureRecorder *recorder;
@property (strong, nonatomic) WKWebView *webView;
@property (weak, nonatomic) IBOutlet UIView *webViewWrapper;
@end

@implementation PCWebViewWrapperViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.webView = [[WKWebView alloc] initWithFrame:self.webViewWrapper.bounds];
    self.webView.customUserAgent = @"Mozilla/5.0 (iPhone; CPU iPhone OS 9_1 like Mac OS X) AppleWebKit/601.1.46 (KHTML, like Gecko) Version/9.0 Mobile/13B143 Safari/601.1";
    [self.webViewWrapper addSubview:self.webView];
    
    //self.webView.scalesPageToFit = YES;
    //[self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://framerjs.com/examples/preview/#airbnb-navigation.framer"]]];
    //[self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://share.framerjs.com/o2o8qjfx73gi/"]]];
    //[self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://share.framerjs.com/85ec7i6zjtaq/"]]];
    //[self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://share.framerjs.com/47o9uv5kemjf/"]]];
    //[self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://framerjs.com/examples/preview/#apple-tv-icon.framer"]]];
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://framerjs.com/examples/preview/#human-clubs.framer"]]];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *pathToDocumentsFolder = [paths objectAtIndex:0];
    NSLog(@"%@", pathToDocumentsFolder);
    
    self.recorder = [[LPPrototypeCaptureRecorder alloc] initWithTargetView:self.webView baseFolder:pathToDocumentsFolder];
}

- (IBAction)toggleRecording:(id)sender {
    if ([self.recorder isRecording]) {
        [self.recorder stopRecording];
        [sender setSelected:NO];
    } else {
        [self.recorder prepareForRecording];
        [self.recorder startRecording];
        [sender setSelected:YES];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
