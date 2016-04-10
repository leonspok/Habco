//
//  HBRecordTableViewCell.m
//  Habco
//
//  Created by Игорь Савельев on 10/04/16.
//  Copyright © 2016 Leonspok. All rights reserved.
//

#import "HBRecordTableViewCell.h"
#import "HBCPrototypeRecord.h"
#import "HBPrototypesManager.h"

@import AVFoundation;

@implementation HBRecordTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    [self setBackgroundColor:[UIColor clearColor]];
    [self.contentView setBackgroundColor:[UIColor clearColor]];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    [self.recordPreviewImageView.layer setCornerRadius:5.0f];
    [self.recordPreviewImageView.layer setMasksToBounds:YES];
    
    [self.playButton.layer setCornerRadius:5.0f];
    [self.playButton.layer setMasksToBounds:YES];
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

- (void)setRecord:(HBCPrototypeRecord *)record {
    _record = record;
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"dd MMM yyyy"];
    NSDateFormatter *timeFormatter = [[NSDateFormatter alloc] init];
    [timeFormatter setDateFormat:@"HH:mm"];
    
    NSString *titleString = [NSString stringWithFormat:@"%@\n%@", [dateFormatter stringFromDate:record.date], [timeFormatter stringFromDate:record.date]];
    [self.titleLabel setText:titleString];
    
    if (!record.pathToVideo) {
        return;
    }
    
    AVURLAsset *asset = [AVURLAsset assetWithURL:[NSURL fileURLWithPath:[[[HBPrototypesManager sharedManager] pathToFolder] stringByAppendingString:record.pathToVideo]]];
    AVAssetImageGenerator *imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
    [imageGenerator setAppliesPreferredTrackTransform:YES];
    
    NSError *error;
    CGImageRef imageRef = [imageGenerator copyCGImageAtTime:CMTimeMake(1, 1) actualTime:nil error:&error];
    if (error) {
        DDLogError(@"%@", error);
    }
    
    [self.recordPreviewImageView setImage:[UIImage imageWithCGImage:imageRef]];
}

@end
