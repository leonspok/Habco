//
//  HBPrototypeDetailsViewController.m
//  Habco
//
//  Created by Игорь Савельев on 10/04/16.
//  Copyright © 2016 Leonspok. All rights reserved.
//

#import "HBPrototypeDetailsViewController.h"
#import "HBCPrototype.h"
#import "HBCPrototypeUser.h"
#import "HBCPrototypeRecord.h"
#import "HBPrototypesManager.h"
#import "HBUserTableViewCell.h"
#import "HBPrototypePreviewViewController.h"
#import "HBUsersListViewController.h"
#import "HBRecordViewController.h"
#import "HBEditPrototypeViewController.h"
#import "HBEditUserViewController.h"

static NSString *const kUserCell = @"kUserCell";

@interface HBPrototypeDetailsViewController () <UITableViewDelegate, UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *tableHeader;
@property (weak, nonatomic) IBOutlet UIImageView *prototypeIcon;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *subtitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UIButton *urlButton;
@property (weak, nonatomic) IBOutlet UITextView *descriptionTextView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *descriptionTextViewHeightConstraint;

@property (nonatomic, strong, readwrite) HBCPrototype *prototype;

@property (nonatomic, strong) NSMutableArray *users;

@end

@implementation HBPrototypeDetailsViewController

- (id)initWithPrototype:(HBCPrototype *)prototype {
    self = [self initWithNibName:NSStringFromClass(HBPrototypeDetailsViewController.class) bundle:nil];
    if (self) {
        self.prototype = prototype;
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
    
    self.title = NSLocalizedString(@"Details", nil);
    self.navigationItem.rightBarButtonItems = @[[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"addIcon"] style:UIBarButtonItemStylePlain target:self action:@selector(addNewRecord:)], [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"optionsButton"] style:UIBarButtonItemStylePlain target:self action:@selector(showOptions:)]];
    
    UINib *nib = [UINib nibWithNibName:NSStringFromClass(HBUserTableViewCell.class) bundle:nil];
    [self.tableView registerNib:nib forCellReuseIdentifier:kUserCell];
    
    self.users = [NSMutableArray array];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self reloadPrototypeInfo];
    [self reloadPrototypeUsers];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark Info

- (void)reloadPrototypeInfo {
    [self.titleLabel setText:self.prototype.name];
    
    NSString *subtitleString;
    NSString *usersPart;
    NSString *recordsPart;
    
    if (self.prototype.users.count == 1) {
        usersPart = NSLocalizedString(@"1 user", nil);
    } else if (self.prototype.users.count > 0) {
        usersPart = [NSString stringWithFormat:@"%ld %@", (long)self.prototype.users.count, NSLocalizedString(@"users", nil)];
    } else {
        usersPart = NSLocalizedString(@"No recordings yet", nil);
    }
    
    NSUInteger recordsCount = 0;
    for (HBCPrototypeUser *user in self.prototype.users) {
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
    
    if (self.prototype.lastRecordingDate) {
        [self.dateLabel setText:[NSString stringWithFormat:@"%@: %@", NSLocalizedString(@"Last record", nil), [dateFormatter stringFromDate:self.prototype.lastRecordingDate]]];
    } else {
        [self.dateLabel setText:[NSString stringWithFormat:@"%@: %@", NSLocalizedString(@"Created", nil), [dateFormatter stringFromDate:self.prototype.dateCreated]]];
    }
    
    [self.urlButton setTitle:self.prototype.url forState:UIControlStateNormal];
    
    self.descriptionTextViewHeightConstraint.constant = [self.descriptionTextView sizeThatFits:CGSizeMake(self.descriptionTextView.frame.size.width, HUGE_VALF)].height;
    [self.descriptionTextView setNeedsLayout];
    [self.descriptionTextView layoutIfNeeded];
    if (self.prototype.prototypeDescription.length > 0) {
        [self.descriptionTextView setText:self.prototype.prototypeDescription];
        CGRect frame = self.tableHeader.frame;
        frame.size.height = 122.0f+16.0f+self.descriptionTextViewHeightConstraint.constant;
        [self.tableHeader setFrame:frame];
        [self.tableView setTableHeaderView:self.tableHeader];
    } else {
        [self.descriptionTextView setText:self.prototype.prototypeDescription];
        CGRect frame = self.tableHeader.frame;
        frame.size.height = 116.0f;
        [self.tableHeader setFrame:frame];
        [self.tableView setTableHeaderView:self.tableHeader];
    }
}

- (void)reloadPrototypeUsers {
    NSMutableArray *users = [[self.prototype.users allObjects] mutableCopy];
    [users sortUsingComparator:^NSComparisonResult(HBCPrototypeUser * _Nonnull obj1, HBCPrototypeUser * _Nonnull obj2) {
        if (obj1.lastRecordingDate && obj2.lastRecordingDate) {
            return [obj1.lastRecordingDate compare:obj2.lastRecordingDate];
        } else if (!obj1.lastRecordingDate && obj2.lastRecordingDate) {
            return [obj1.dateAdded compare:obj2.lastRecordingDate];
        } else if (obj1.lastRecordingDate && !obj2.lastRecordingDate) {
            return [obj1.lastRecordingDate compare:obj2.dateAdded];
        } else {
            return [obj1.dateAdded compare:obj2.dateAdded];
        }
    }];
    [self.users removeAllObjects];
    [self.users addObjectsFromArray:users];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
}

#pragma mark UIActions

- (IBAction)openPreview:(id)sender {
    HBPrototypePreviewViewController *pvc = [[HBPrototypePreviewViewController alloc] initWithURL:[NSURL URLWithString:self.prototype.url]];
    [self presentViewController:pvc animated:YES completion:nil];
}

- (IBAction)addNewRecord:(id)sender {
    HBUsersListViewController *uvc = [[HBUsersListViewController alloc] initWithPrototype:self.prototype];
    [uvc setUserWasSelectedBlock:^(HBCPrototypeUser *user) {
        HBRecordViewController *vc = [[HBRecordViewController alloc] initWithUser:user];
        [self.navigationController pushViewController:vc animated:YES];
    }];
    [self.navigationController pushViewController:uvc animated:YES];
}

- (IBAction)showOptions:(id)sender {
    if (!self.prototype) {
        return;
    }
    
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Options", nil) message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [actionSheet addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Edit", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        HBEditPrototypeViewController *evc = [[HBEditPrototypeViewController alloc] initWithPrototype:self.prototype title:NSLocalizedString(@"Edit", nil) saveButtonTitle:NSLocalizedString(@"Save", nil)];
        [evc setSaveBlock:^{
            [self dismissViewControllerAnimated:YES completion:nil];
        }];
        [evc setCancelBlock:^{
            [self dismissViewControllerAnimated:YES completion:nil];
        }];
        [self presentViewController:evc animated:YES completion:nil];
    }]];
    [actionSheet addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Add user", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        HBEditUserViewController *evc = [[HBEditUserViewController alloc] initWithPrototype:self.prototype title:NSLocalizedString(@"Add user", nil) saveButtonTitle:NSLocalizedString(@"Save", nil)];
        [evc setSaveBlock:^{
            [self dismissViewControllerAnimated:YES completion:nil];
        }];
        [evc setCancelBlock:^{
            [self dismissViewControllerAnimated:YES completion:nil];
        }];
        [self presentViewController:evc animated:YES completion:nil];
    }]];
    [actionSheet addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Remove", nil) style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [[HBPrototypesManager sharedManager] removePrototype:self.prototype];
        [self.navigationController popViewControllerAnimated:YES];
    }]];
    [actionSheet addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }]];
    [self presentViewController:actionSheet animated:YES completion:nil];
}

#pragma UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.users.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 90.0f;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleDelete;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    HBUserTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kUserCell forIndexPath:indexPath];
    [cell setUser:[self.users objectAtIndex:indexPath.row]];
    return cell;
}

#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    //TODO: go to user details
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        HBCPrototypeUser *user = [self.users objectAtIndex:indexPath.row];
        [self.users removeObjectAtIndex:indexPath.row];
        [[HBPrototypesManager sharedManager] removeUser:user];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}


@end
