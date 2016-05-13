//
//  HBHeatmapCollectionViewCell.h
//  Habco
//
//  Created by Игорь Савельев on 13/05/16.
//  Copyright © 2016 Leonspok. All rights reserved.
//

#import <UIKit/UIKit.h>

@class HBHeatmap;

@interface HBHeatmapCollectionViewCell : UICollectionViewCell
@property (weak, nonatomic) IBOutlet UIView *wrapper;
@property (weak, nonatomic) IBOutlet UIImageView *screenshotImageView;
@property (weak, nonatomic) IBOutlet UIImageView *heatmapImageView;
@property (weak, nonatomic) IBOutlet UIView *loadingView;

@property (nonatomic) BOOL loading;

@property (nonatomic, strong) HBHeatmap *heatmap;

@end
