//
//  LPFloatingPlaceholderTextField.h
//  Commons
//
//  Created by Игорь Савельев on 30/03/16.
//  Copyright © 2016 Leonspok. All rights reserved.
//

#import <UIKit/UIKit.h>

IB_DESIGNABLE

@interface LPFloatingPlaceholderTextField : UITextField

@property (nonatomic, strong) IBInspectable NSString *floatingPlaceholder;

@property (nonatomic, strong) IBInspectable UIColor *defaultPlaceholderColor;
@property (nonatomic, strong) IBInspectable UIFont *defaultPlaceholderFont;

@property (nonatomic, strong) IBInspectable UIColor *floatingPlaceholderColor;
@property (nonatomic, strong) IBInspectable UIFont *floatingPlaceholderFont;

@end
