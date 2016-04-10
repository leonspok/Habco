//
//  HBRecordTableViewCell.h
//  Habco
//
//  Created by Игорь Савельев on 10/04/16.
//  Copyright © 2016 Leonspok. All rights reserved.
//

#import <UIKit/UIKit.h>

@class HBCPrototypeRecord;

@interface HBRecordTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *recordPreviewImageView;
@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIImageView *disclosureIcon;

@property (nonatomic, strong) HBCPrototypeRecord *record;

@end
