//
//  HBUserTableViewCell.m
//  Habco
//
//  Created by Игорь Савельев on 08/04/16.
//  Copyright © 2016 Leonspok. All rights reserved.
//

#import "HBUserTableViewCell.h"
#import "HBCPrototype.h"
#import "HBCPrototypeUser.h"
#import "HBCPrototypeRecord.h"

@implementation HBUserTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    [self setBackgroundColor:[UIColor clearColor]];
    [self.contentView setBackgroundColor:[UIColor clearColor]];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    UIColor *newColor = selected? [UIColor colorWithWhite:1 alpha:0.1f] : [UIColor clearColor];
    if (animated) {
        [UIView animateWithDuration:0.2f animations:^{
            [self.contentView setBackgroundColor:newColor];
        }];
    } else {
        [self.contentView setBackgroundColor:newColor];
    }
}

- (void)setUser:(HBCPrototypeUser *)user {
    _user = user;
    [self.titleLabel setText:user.name];
    
    NSString *recordsPart;
    
    NSUInteger recordsCount = self.user.records.count;
    
    if (recordsCount == 1) {
        recordsPart = NSLocalizedString(@"1 record", nil);
    } else if (recordsCount > 0) {
        recordsPart = [NSString stringWithFormat:@"%ld %@", (long)recordsCount, NSLocalizedString(@"records", nil)];
    } else {
        recordsPart = @"No records yet";
    }
    
    [self.subtitleLabel setText:recordsPart];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"dd MMM yyyy"];
    
    if (user.lastRecordingDate) {
        [self.dateLabel setText:[NSString stringWithFormat:@"%@: %@", NSLocalizedString(@"Last record", nil), [dateFormatter stringFromDate:user.lastRecordingDate]]];
    } else {
        [self.dateLabel setText:[NSString stringWithFormat:@"%@: %@", NSLocalizedString(@"Added", nil), [dateFormatter stringFromDate:user.dateAdded]]];
    }
}

@end
