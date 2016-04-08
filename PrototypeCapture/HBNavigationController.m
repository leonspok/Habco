//
//  HBNavigationController.m
//  Habco
//
//  Created by Игорь Савельев on 08/04/16.
//  Copyright © 2016 Leonspok. All rights reserved.
//

#import "HBNavigationController.h"
#import "UIColor+Pallete.h"

@interface HBNavigationController ()

@end

@implementation HBNavigationController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.navigationBar setTranslucent:NO];
    [self.navigationBar setBarTintColor:[UIColor backgroundColor]];
    [self.navigationBar setTintColor:[UIColor whiteColor]];
    [self.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]}];
    [self.navigationBar setShadowImage:[UIImage new]];
    
    UIView *navigationBarBottomBorder = [[UIView alloc] initWithFrame:CGRectMake(0, self.navigationBar.frame.size.height-1.0f, self.navigationBar.frame.size.width, 1.0f)];
    [navigationBarBottomBorder setBackgroundColor:[UIColor colorWithWhite:1 alpha:0.3f]];
    [navigationBarBottomBorder setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleTopMargin];
    [self.navigationBar addSubview:navigationBarBottomBorder];
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
