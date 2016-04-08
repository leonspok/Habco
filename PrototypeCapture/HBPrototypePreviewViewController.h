//
//  HBPrototypePreviewViewController.h
//  Habco
//
//  Created by Игорь Савельев on 08/04/16.
//  Copyright © 2016 Leonspok. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HBPrototypePreviewViewController : UIViewController

@property (nonatomic, strong, readonly) NSURL *url;

- (id)initWithURL:(NSURL *)url;

@end
