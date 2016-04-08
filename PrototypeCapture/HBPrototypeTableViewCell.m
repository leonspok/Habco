//
//  HBPrototypeTableViewCell.m
//  Habco
//
//  Created by Игорь Савельев on 08/04/16.
//  Copyright © 2016 Leonspok. All rights reserved.
//

#import "HBPrototypeTableViewCell.h"
#import "HBCPrototype.h"
#import "HBCPrototypeUser.h"
#import "HBCPrototypeRecord.h"

@implementation HBPrototypeTableViewCell

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

- (void)setPrototype:(HBCPrototype *)prototype {
    _prototype = prototype;
    [self.titleLabel setText:prototype.name];
    
    NSString *subtitleString;
    NSString *usersPart;
    NSString *recordsPart;
    
    if (prototype.users.count == 1) {
        usersPart = NSLocalizedString(@"1 user", nil);
    } else if (prototype.users.count > 0) {
        usersPart = [NSString stringWithFormat:@"%ld %@", (long)prototype.users.count, NSLocalizedString(@"users", nil)];
    } else {
        usersPart = NSLocalizedString(@"No recordings yet", nil);
    }
    
    NSUInteger recordsCount = 0;
    for (HBCPrototypeUser *user in prototype.users) {
        recordsCount += user.records.count;
    }
    
    if (recordsCount == 1) {
        recordsPart = NSLocalizedString(@", 1 record", nil);
    } else if (recordsCount > 0) {
        recordsPart = [NSString stringWithFormat:@", %ld %@", (long)recordsCount, NSLocalizedString(@"records", nil)];
    } else {
        recordsPart = @"";
    }
    
    subtitleString = [NSString stringWithFormat:@"%@%@", usersPart, recordsPart];
    [self.subtitleLabel setText:subtitleString];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"dd MMM yyyy"];
    
    if (prototype.lastRecordingDate) {
        [self.dateLabel setText:[NSString stringWithFormat:@"%@: %@", NSLocalizedString(@"Last record", nil), [dateFormatter stringFromDate:prototype.lastRecordingDate]]];
    } else {
        [self.dateLabel setText:[NSString stringWithFormat:@"%@: %@", NSLocalizedString(@"Created", nil), [dateFormatter stringFromDate:prototype.dateCreated]]];
    }
}

@end
