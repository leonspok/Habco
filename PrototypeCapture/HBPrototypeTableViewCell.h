//
//  HBPrototypeTableViewCell.h
//  Habco
//
//  Created by Игорь Савельев on 08/04/16.
//  Copyright © 2016 Leonspok. All rights reserved.
//

#import <UIKit/UIKit.h>

@class HBCPrototype;

@interface HBPrototypeTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *prototypeIcon;
@property (weak, nonatomic) IBOutlet UIImageView *disclosureIcon;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *subtitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UIView *separator;

@property (nonatomic, strong) HBCPrototype *prototype;

@end
