//
//  HBUserDetailsViewController.m
//  Habco
//
//  Created by Игорь Савельев on 10/04/16.
//  Copyright © 2016 Leonspok. All rights reserved.
//

#import "HBUserDetailsViewController.h"
#import "HBPrototypesManager.h"
#import "HBCPrototypeUser.h"
#import "HBCPrototypeRecord.h"
#import "HBCPrototype.h"
#import "HBRecordTableViewCell.h"
#import "HBEditUserViewController.h"
#import "HBEditPrototypeViewController.h"
#import "HBRecordViewController.h"
#import "HBNavigationController.h"
#import "HBHeatmapsViewController.h"
#import "LPPrototypeCaptureRecorder.h"

@import AVKit;
@import AVFoundation;

static NSString *const kRecordCell = @"kRecordCell";

@interface HBUserDetailsViewController () <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *tableHeader;
@property (weak, nonatomic) IBOutlet UIImageView *userIcon;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *subtitleLabel;
@property (weak, nonatomic) IBOutlet UIButton *heatmapButton;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UITextView *descriptionTextView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *descriptionTextViewHeightConstraint;
@property (weak, nonatomic) IBOutlet UIView *emptyView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *emptyViewTopConstraint;

@property (nonatomic, strong, readwrite) HBCPrototypeUser *user;

@property (nonatomic, strong) NSMutableArray *records;

@end

@implementation HBUserDetailsViewController

- (id)initWithUser:(HBCPrototypeUser *)user {
    self = [self initWithNibName:NSStringFromClass(self.class) bundle:nil];
    if (self) {
        self.user = user;
    }
    return self;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (BOOL)prefersStatusBarHidden {
    return NO;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = self.user.prototype.name;
    
    self.navigationItem.rightBarButtonItems = @[[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"addIcon"] style:UIBarButtonItemStylePlain target:self action:@selector(addNewRecord:)], [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"optionsButton"] style:UIBarButtonItemStylePlain target:self action:@selector(showOptions:)]];
    
    UINib *nib = [UINib nibWithNibName:NSStringFromClass(HBRecordTableViewCell.class) bundle:nil];
    [self.tableView registerNib:nib forCellReuseIdentifier:kRecordCell];
    
    self.records = [NSMutableArray array];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self reloadUserInfo];
    [self reloadUserRecords];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark Info

- (void)reloadUserInfo {
    [self.titleLabel setText:self.user.name];
    
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
    
    if (self.user.lastRecordingDate) {
        [self.dateLabel setText:[NSString stringWithFormat:@"%@: %@", NSLocalizedString(@"Last record", nil), [dateFormatter stringFromDate:self.user.lastRecordingDate]]];
    } else {
        [self.dateLabel setText:[NSString stringWithFormat:@"%@: %@", NSLocalizedString(@"Added", nil), [dateFormatter stringFromDate:self.user.dateAdded]]];
    }
    
    CGSize descriptionSize;
    if (self.user.bio.length > 0) {
        NSMutableParagraphStyle *ps = [[NSMutableParagraphStyle alloc] init];
        ps.alignment = NSTextAlignmentLeft;
        ps.lineSpacing = 3.0f;
        NSAttributedString *desc = [[NSAttributedString alloc] initWithString:self.user.bio attributes:@{NSFontAttributeName: self.descriptionTextView.font, NSForegroundColorAttributeName: self.descriptionTextView.textColor, NSParagraphStyleAttributeName: ps}];
        [self.descriptionTextView setAttributedText:desc];
        descriptionSize = [self.descriptionTextView sizeThatFits:CGSizeMake(self.descriptionTextView.frame.size.width, HUGE_VALF)];
    } else {
        [self.descriptionTextView setText:@""];
        descriptionSize = CGSizeZero;
    }
    
    self.descriptionTextViewHeightConstraint.constant = descriptionSize.height;
    
    CGRect frame = self.tableHeader.frame;
    if (self.user.bio.length > 0) {
        frame.size.height = 91.0f+10.0f+self.descriptionTextViewHeightConstraint.constant;
    } else {
        frame.size.height = 90.0f;
    }
    [self.tableHeader setFrame:frame];
    [self.tableView setTableHeaderView:self.tableHeader];
    
    self.emptyViewTopConstraint.constant = frame.size.height;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        BOOL hasTouchLogs = NO;
        for (HBCPrototypeRecord *record in self.user.records) {
            NSString *path = [LPPrototypeCaptureRecorder pathToRecordedScreensFileFromFolder:[[HBPrototypesManager sharedManager] pathToFolderForRecord:record]];
            if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
                hasTouchLogs = YES;
                break;
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.heatmapButton setHidden:!hasTouchLogs];
        });
    });
}

- (void)reloadUserRecords {
    NSArray *records = [self.user.records sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"date" ascending:NO]]];
    [self.records removeAllObjects];
    [self.records addObjectsFromArray:records];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.tableView setScrollEnabled:(self.records.count > 0)];
    [self.emptyView setHidden:(self.records.count > 0)];
}

#pragma mark UIActions

- (IBAction)addNewRecord:(id)sender {
    HBRecordViewController *vc = [[HBRecordViewController alloc] initWithUser:self.user];
    [self.navigationController pushViewController:vc animated:YES];
}

- (IBAction)showOptions:(id)sender {
    if (!self.user) {
        return;
    }
    
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Options", nil) message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [actionSheet addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Edit", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        HBEditUserViewController *evc = [[HBEditUserViewController alloc] initWithUser:self.user title:NSLocalizedString(@"Edit", nil) saveButtonTitle:NSLocalizedString(@"Save", nil)];
        [evc setSaveBlock:^{
            [self dismissViewControllerAnimated:YES completion:nil];
        }];
        [evc setCancelBlock:^{
            [self dismissViewControllerAnimated:YES completion:nil];
        }];
        [self presentViewController:[[HBNavigationController alloc] initWithRootViewController:evc] animated:YES completion:nil];
    }]];
    [actionSheet addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Remove", nil) style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [[HBPrototypesManager sharedManager] removeUser:self.user];
        [self.navigationController popViewControllerAnimated:YES];
    }]];
    [actionSheet addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }]];
    [self presentViewController:actionSheet animated:YES completion:nil];
}

- (IBAction)playRecord:(UIButton *)sender {
    HBRecordTableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:sender.tag inSection:0]];
    if (cell.record.pathToVideo.length == 0) {
        return;
    }
    
    AVPlayerViewController *playerVC = [[AVPlayerViewController alloc] init];
    playerVC.player = [[AVPlayer alloc] initWithURL:[NSURL fileURLWithPath:[[[HBPrototypesManager sharedManager] pathToFolder] stringByAppendingString:cell.record.pathToVideo]]];
    playerVC.showsPlaybackControls = YES;
    playerVC.videoGravity = AVLayerVideoGravityResizeAspect;
    playerVC.modalPresentationStyle = UIModalPresentationOverFullScreen;
    [self presentViewController:playerVC animated:YES completion:^{
        [playerVC.player play];
    }];
}

- (IBAction)openHeatmaps:(id)sender {
    HBHeatmapsViewController *hvc = [[HBHeatmapsViewController alloc] initWithPrototypeUser:self.user];
    [self.navigationController pushViewController:hvc animated:YES];
}

#pragma UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.records.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60.0f;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleDelete;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    HBRecordTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kRecordCell forIndexPath:indexPath];
    [cell setRecord:[self.records objectAtIndex:indexPath.row]];
    [cell.playButton setTag:indexPath.row];
    [cell.playButton addTarget:self action:@selector(playRecord:) forControlEvents:UIControlEventTouchUpInside];
    return cell;
}

#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    HBRecordViewController *rvc = [[HBRecordViewController alloc] initWithRecord:[self.records objectAtIndex:indexPath.row]];
    [self.navigationController pushViewController:rvc animated:YES];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        HBCPrototypeRecord *record = [self.records objectAtIndex:indexPath.row];
        [self.records removeObjectAtIndex:indexPath.row];
        [[HBPrototypesManager sharedManager] removeRecord:record];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

@end
