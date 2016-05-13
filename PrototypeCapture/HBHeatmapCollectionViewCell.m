//
//  HBHeatmapCollectionViewCell.m
//  Habco
//
//  Created by Игорь Савельев on 13/05/16.
//  Copyright © 2016 Leonspok. All rights reserved.
//

#import "HBHeatmapCollectionViewCell.h"
#import "HBHeatmap.h"

@implementation HBHeatmapCollectionViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    [self.wrapper.layer setCornerRadius:5.0f];
    [self.wrapper.layer setMasksToBounds:YES];
}

- (void)setHeatmap:(HBHeatmap *)heatmap {
    _heatmap = heatmap;
    
    UIImage *screenshot = [[UIImage alloc] initWithContentsOfFile:[heatmap pathToScreenshot]];
    [self.screenshotImageView setImage:screenshot];
    
    UIImage *heatmapImage = [[UIImage alloc] initWithContentsOfFile:[heatmap pathToHeatmap]];
    [self.heatmapImageView setImage:heatmapImage];
}

- (void)setLoading:(BOOL)loading {
    _loading = loading;
    [self.loadingView setHidden:!loading];
}

@end
