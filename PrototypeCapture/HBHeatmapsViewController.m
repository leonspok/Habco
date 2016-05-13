//
//  HBHeatmapsViewController.m
//  Habco
//
//  Created by Игорь Савельев on 13/05/16.
//  Copyright © 2016 Leonspok. All rights reserved.
//

#import "HBHeatmapsViewController.h"
#import "HBHeatmapRenderer.h"
#import "HBHeatmap.h"
#import "HBHeatmapCollectionViewCell.h"
#import "NYTPhotosViewController.h"
#import "NYTPhoto.h"

#define PER_ROW 3

static NSString *const kHeatmapCellIdentifier = @"HeatmapCell";

@interface HBHeatmapImage : NSObject<NYTPhoto>
@property (nonatomic, strong, readwrite) UIImage *image;
@property (nonatomic, strong) UIView *referenceView;
@end

@interface HBHeatmapsViewController () <UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, NYTPhotosViewControllerDelegate>
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (strong, nonatomic) IBOutlet UIView *loadingTitleView;
@property (weak, nonatomic) IBOutlet UILabel *loadingLabel;
@property (weak, nonatomic) IBOutlet UIProgressView *loadingProgressView;

@property (nonatomic, strong) HBHeatmapRenderer *renderer;
@property (nonatomic, strong) NSArray<HBHeatmap *> *heatmaps;

@property (nonatomic) BOOL statusBarHidden;

@end

@implementation HBHeatmapsViewController

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (BOOL)prefersStatusBarHidden {
    return self.statusBarHidden;
}

- (id)initWithPrototype:(HBCPrototype *)prototype {
    self = [self initWithNibName:NSStringFromClass(self.class) bundle:nil];
    if (self) {
        self.renderer = [[HBHeatmapRenderer alloc] initWithPrototype:prototype];
    }
    return self;
}

- (id)initWithPrototypeUser:(HBCPrototypeUser *)prototypeUser {
    self = [self initWithNibName:NSStringFromClass(self.class) bundle:nil];
    if (self) {
        self.renderer = [[HBHeatmapRenderer alloc] initWithPrototypeUser:prototypeUser];
    }
    return self;
}

- (id)initWithPrototypeRecord:(HBCPrototypeRecord *)prototypeRecord {
    self = [self initWithNibName:NSStringFromClass(self.class) bundle:nil];
    if (self) {
        self.renderer = [[HBHeatmapRenderer alloc] initWithPrototypeRecord:prototypeRecord];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"Heat Maps", nil);
    [self.loadingTitleView setBackgroundColor:[UIColor clearColor]];
    
    [self.collectionView registerNib:[UINib nibWithNibName:NSStringFromClass(HBHeatmapCollectionViewCell.class) bundle:nil] forCellWithReuseIdentifier:kHeatmapCellIdentifier];
    
    typeof(self) __weak weakSelf = self;
    [self.renderer setCompletionBlock:^(NSArray<HBHeatmap *> *heatmaps) {
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.navigationItem.titleView = nil;
            [weakSelf.collectionView reloadData];
        });
    }];
    [self.renderer setHeatmapRenderingCompletionBlock:^(HBHeatmap *heatmap) {
        dispatch_async(dispatch_get_main_queue(), ^{
            for (HBHeatmapCollectionViewCell *cell in weakSelf.collectionView.visibleCells) {
                if ([cell.heatmap isEqual:heatmap]) {
                    [cell setHeatmap:heatmap];
                    [cell setLoading:NO];
                    break;
                }
            }
        });
    }];
    [self.renderer setProgressBlock:^(float progress, HBHeatmap *heatmap) {
        if (weakSelf.heatmaps.count != weakSelf.renderer.allHeatmaps.count) {
            weakSelf.heatmaps = [weakSelf.renderer.allHeatmaps copy];
            [weakSelf.collectionView reloadData];
            return;
        }
        
        NSUInteger currentIndex = [weakSelf.heatmaps indexOfObject:heatmap]+1;
        NSUInteger total = weakSelf.heatmaps.count;
        
        NSString *title = [NSString stringWithFormat:@"%@ (%ld/%ld)", NSLocalizedString(@"Rendering", nil), (long)currentIndex, (long)total];
        [weakSelf.loadingLabel setText:title];
        [weakSelf.loadingProgressView setProgress:weakSelf.renderer.totalRenderingHeatmapProgress animated:YES];
    }];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.navigationItem.titleView = self.loadingTitleView;
    [self.renderer startHeatmapsRendering];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    if (!self.presentedViewController) {
        [self.renderer stopHeatmapsRendering];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.heatmaps.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    HBHeatmapCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kHeatmapCellIdentifier forIndexPath:indexPath];
    HBHeatmap *heatmap = [self.heatmaps objectAtIndex:indexPath.item];
    [cell setHeatmap:heatmap];
    [cell setLoading:![self.renderer.finishedHeatmaps containsObject:heatmap] && self.renderer.rendering];
    return cell;
}

#pragma mark UICollectionViewDelegateFlowLayout

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return 6.0f;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return 6.0f;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(6, 6, 6, 6);
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat width = (collectionView.frame.size.width-(PER_ROW+1)*6.0f)/PER_ROW;
    CGFloat ratio = [UIScreen mainScreen].bounds.size.height/[UIScreen mainScreen].bounds.size.width;
    CGFloat height = width*ratio;
    return CGSizeMake(width, height);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSMutableArray *photos = [NSMutableArray array];
    NSInteger currentIndex = indexPath.item;
    
    HBHeatmapCollectionViewCell *selectedCell = (HBHeatmapCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
    
    NSUInteger index = 0;
    for (HBHeatmap *heatmap in self.heatmaps) {
        HBHeatmapImage *heatmapImage = [[HBHeatmapImage alloc] init];
        heatmapImage.image = [UIImage imageWithContentsOfFile:[heatmap pathToHeatmap]];
        if (!heatmapImage.image) {
            continue;
        }
        
        HBHeatmapCollectionViewCell *cell = (HBHeatmapCollectionViewCell *)[collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0]];
        heatmapImage.referenceView = cell.heatmapImageView;
        [photos addObject:heatmapImage];
        if ([heatmap isEqual:selectedCell.heatmap]) {
            currentIndex = photos.count-1;
        }
        index++;
    }
    
    if (photos.count == 0) {
        return;
    }
    
    NYTPhotosViewController *photosController = [[NYTPhotosViewController alloc] initWithPhotos:photos initialPhoto:[photos objectAtIndex:currentIndex]];
    photosController.delegate = self;
    self.statusBarHidden = YES;
    [self setNeedsStatusBarAppearanceUpdate];
    [self presentViewController:photosController animated:YES completion:nil];
}

#pragma mark NYTPhotosViewControllerDelegate

- (UIView *)photosViewController:(NYTPhotosViewController *)photosViewController referenceViewForPhoto:(id<NYTPhoto>)photo {
    HBHeatmapImage *heatmapImage = (HBHeatmapImage *)photo;
    return heatmapImage.referenceView;
}

- (void)photosViewControllerDidDismiss:(NYTPhotosViewController *)photosViewController {
    self.statusBarHidden = NO;
    [self setNeedsStatusBarAppearanceUpdate];
}

@end

@implementation HBHeatmapImage
@synthesize image, imageData, placeholderImage, attributedCaptionCredit, attributedCaptionSummary, attributedCaptionTitle;
@end
