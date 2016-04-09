//
//  HBSwitchTableViewCell.m
//  Habco
//
//  Created by Игорь Савельев on 09/04/16.
//  Copyright © 2016 Leonspok. All rights reserved.
//

#import "HBSwitchTableViewCell.h"

@implementation HBSwitchTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    [self setBackgroundColor:[UIColor clearColor]];
    [self.contentView setBackgroundColor:[UIColor clearColor]];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
}

@end
