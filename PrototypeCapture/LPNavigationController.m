//
//  LPNavigationController.m
//  Habco
//
//  Created by Игорь Савельев on 08/04/16.
//  Copyright © 2016 Leonspok. All rights reserved.
//

#import "LPNavigationController.h"

@interface LPNavigationController ()

@end

@implementation LPNavigationController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    if (self.topViewController) {
        return [self.topViewController preferredStatusBarStyle];
    }
    return [super preferredStatusBarStyle];
}

- (BOOL)prefersStatusBarHidden {
    if (self.topViewController) {
        return [self.topViewController prefersStatusBarHidden];
    }
    return [super prefersStatusBarHidden];
}

#pragma mark UINavigationController methods

- (void)viewControllerChangedTo:(UIViewController *)viewController {
    [self setNeedsStatusBarAppearanceUpdate];
}

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    [super pushViewController:viewController animated:animated];
    [self viewControllerChangedTo:viewController];
}

- (UIViewController *)popViewControllerAnimated:(BOOL)animated {
    UIViewController *result = [super popViewControllerAnimated:animated];
    [self viewControllerChangedTo:self.topViewController];
    return result;
}

- (NSArray *)popToRootViewControllerAnimated:(BOOL)animated {
    NSArray *result = [super popToRootViewControllerAnimated:animated];
    [self viewControllerChangedTo:self.topViewController];
    return result;
}

- (NSArray *)popToViewController:(UIViewController *)viewController animated:(BOOL)animated {
    NSArray *result = [super popToViewController:viewController animated:animated];
    [self viewControllerChangedTo:self.topViewController];
    return result;
}

- (void)setViewControllers:(NSArray *)viewControllers animated:(BOOL)animated {
    [super setViewControllers:viewControllers animated:animated];
    [self viewControllerChangedTo:self.topViewController];
}

@end
