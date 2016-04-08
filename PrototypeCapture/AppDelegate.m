//
//  AppDelegate.m
//  PrototypeCapture
//
//  Created by Игорь Савельев on 28/02/16.
//  Copyright © 2016 Leonspok. All rights reserved.
//

#import "AppDelegate.h"
#import "LPNavigationController.h"
#import "HBPrototypesListViewController.h"
#import "UIColor+Pallete.h"
#import "PCWebViewWrapperViewController.h"
#import <MagicalRecord/MagicalRecord.h>

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    [DDLog addLogger:[DDASLLogger sharedInstance]];
    
    [MagicalRecord setupCoreDataStackWithStoreNamed:@"Habco"];
    [MagicalRecord setLoggingLevel:MagicalRecordLoggingLevelError];
    
    UINavigationController *nc = [[LPNavigationController alloc] initWithRootViewController:[[HBPrototypesListViewController alloc] initWithNibName:NSStringFromClass(HBPrototypesListViewController.class) bundle:nil]];
    [nc.navigationBar setTranslucent:NO];
    [nc.navigationBar setBarTintColor:[UIColor backgroundColor]];
    [nc.navigationBar setTintColor:[UIColor whiteColor]];
    [nc.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]}];
    [nc.navigationBar setShadowImage:[UIImage new]];
    
    UIView *navigationBarBottomBorder = [[UIView alloc] initWithFrame:CGRectMake(0, nc.navigationBar.frame.size.height-1.0f, nc.navigationBar.frame.size.width, 1.0f)];
    [navigationBarBottomBorder setBackgroundColor:[UIColor colorWithWhite:1 alpha:0.3f]];
    [navigationBarBottomBorder setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleTopMargin];
    [nc.navigationBar addSubview:navigationBarBottomBorder];
    
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.rootViewController = nc;
    [self.window makeKeyAndVisible];
    
    return YES;
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
