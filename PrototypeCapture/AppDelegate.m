//
//  AppDelegate.m
//  PrototypeCapture
//
//  Created by Игорь Савельев on 28/02/16.
//  Copyright © 2016 Leonspok. All rights reserved.
//

#import "AppDelegate.h"
#import "HBPrototypesListViewController.h"
#import "HBPrototypesManager.h"
#import "HBNavigationController.h"
#import "PCWebViewWrapperViewController.h"
#import "NSDictionary+NSURL.h"
#import <MagicalRecord/MagicalRecord.h>

@import SafariServices;
@import AVKit;

@interface AppDelegate ()
@property (nonatomic, strong) SFSafariViewController *safariViewController;
@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    [DDLog addLogger:[DDASLLogger sharedInstance]];
    
    [MagicalRecord setupCoreDataStackWithStoreNamed:@"Habco"];
    [MagicalRecord setLoggingLevel:MagicalRecordLoggingLevelError];
    
    HBNavigationController *nc = [[HBNavigationController alloc] initWithRootViewController:[[HBPrototypesListViewController alloc] initWithNibName:NSStringFromClass(HBPrototypesListViewController.class) bundle:nil]];
    
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    CGRect windowFrame = CGRectMake(0, 0, 375, 667);
    windowFrame.origin.x = (screenBounds.size.width-windowFrame.size.width)/2.0f;
    windowFrame.origin.y = (screenBounds.size.height-windowFrame.size.height)/2.0f;
    
    self.window = [[UIWindow alloc] initWithFrame:screenBounds];
    self.window.rootViewController = nc;
    [self.window makeKeyAndVisible];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if ([[HBPrototypesManager sharedManager] shouldRequestCustomUserAgent]) {
            [self openSafariViewController];
        }
    });
    
    return YES;
}

- (void)openSafariViewController {
    NSString *scriptletString = @"http://leonspok.tumblr.com/habco_get_user_agent";
    SFSafariViewController *svc = [[SFSafariViewController alloc] initWithURL:[NSURL URLWithString:scriptletString]];
    [svc.view setFrame:CGRectMake(0, 0, 100, 100)];
    [self.window.rootViewController.view insertSubview:svc.view atIndex:0];
    [self.window.rootViewController addChildViewController:svc];
    [svc didMoveToParentViewController:self.window.rootViewController];
    self.safariViewController = svc;
    [self.window.rootViewController setNeedsStatusBarAppearanceUpdate];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.safariViewController.view removeFromSuperview];
        [self.safariViewController removeFromParentViewController];
        self.safariViewController = nil;
        [self.window.rootViewController setNeedsStatusBarAppearanceUpdate];
    });
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<NSString *,id> *)options {
    NSString *urlString = [url absoluteString];
    if ([urlString hasPrefix:@"habco://set_user_agent"]) {
        NSDictionary *params = [NSDictionary dictionaryWithURL:url];
        if ([params objectForKey:@"user_agent"]) {
            [[HBPrototypesManager sharedManager] setCustomUserAgent:[params objectForKey:@"user_agent"]];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.safariViewController.view removeFromSuperview];
            [self.safariViewController removeFromParentViewController];
            self.safariViewController = nil;
            [self.window.rootViewController setNeedsStatusBarAppearanceUpdate];
        });
    }
    return YES;
}

- (UIInterfaceOrientationMask)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window {
    if ([self.window.rootViewController.presentedViewController isKindOfClass:[AVPlayerViewController class]]) {
        return UIInterfaceOrientationMaskAll;
    }
    else return UIInterfaceOrientationMaskPortrait;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
