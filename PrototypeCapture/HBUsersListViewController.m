//
//  HBUsersListViewController.m
//  Habco
//
//  Created by Игорь Савельев on 08/04/16.
//  Copyright © 2016 Leonspok. All rights reserved.
//

#import "HBUsersListViewController.h"
#import "HBUserTableViewCell.h"
#import "HBEditUserViewController.h"
#import "HBNavigationController.h"
#import "HBCPrototype.h"
#import "HBCPrototypeUser.h"
#import "HBPrototypesManager.h"

static NSString *const kUserCell = @"kUserCell";

@interface HBUsersListViewController () <UITableViewDelegate, UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;

@property (nonatomic, strong, readwrite) HBCPrototype *prototype;

@property (nonatomic, strong) NSMutableArray *filteredUsers;
@property (nonatomic, strong) NSMutableArray *users;

@end

@implementation HBUsersListViewController

- (id)initWithPrototype:(HBCPrototype *)prototype {
    self = [self initWithNibName:NSStringFromClass(HBUsersListViewController.class) bundle:nil];
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
    
    self.title = NSLocalizedString(@"Users", nil);
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"addIcon"] style:UIBarButtonItemStylePlain target:self action:@selector(addUser:)];
    
    UINib *nib = [UINib nibWithNibName:NSStringFromClass(HBUserTableViewCell.class) bundle:nil];
    [self.tableView registerNib:nib forCellReuseIdentifier:kUserCell];
    
    self.users = [NSMutableArray array];
    self.filteredUsers = [NSMutableArray array];
    [self reloadUsers];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark Data

- (void)reloadUsers {
    [self.users removeAllObjects];
    [self.users addObjectsFromArray:self.prototype.users.allObjects];
    [self.users sortUsingComparator:^NSComparisonResult(HBCPrototypeUser * _Nonnull obj1, HBCPrototypeUser * _Nonnull obj2) {
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
    
    [self.filteredUsers removeAllObjects];
    if (self.searchBar.text.length > 0) {
        [self.filteredUsers addObjectsFromArray:[self.users filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(name CONTAINS[cd] %@) OR (bio CONTAINS[cd] %@)", self.searchBar.text, self.searchBar.text]]];
    } else {
        [self.filteredUsers addObjectsFromArray:self.users];
    }
    
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
}

#pragma mark UIActions

- (IBAction)addUser:(id)sender {
    HBEditUserViewController *newVC = [[HBEditUserViewController alloc] initWithPrototype:self.prototype title:NSLocalizedString(@"Add user", nil) saveButtonTitle:NSLocalizedString(@"Save", nil)];
    HBEditUserViewController * __weak weakNewVC = newVC;
    [newVC setSaveBlock:^{
        HBCPrototypeUser *user = weakNewVC.user;
        [self dismissViewControllerAnimated:YES completion:nil];
        [self.searchBar setText:@""];
        [self reloadUsers];
        if (self.userWasSelectedBlock) {
            self.userWasSelectedBlock(user);
        }
    }];
    [newVC setCancelBlock:^{
        [self dismissViewControllerAnimated:YES completion:nil];
    }];
    [self presentViewController:[[HBNavigationController alloc] initWithRootViewController:newVC] animated:YES completion:nil];
}

#pragma UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.filteredUsers.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 90.0f;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleDelete;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    HBUserTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kUserCell forIndexPath:indexPath];
    [cell setUser:[self.filteredUsers objectAtIndex:indexPath.row]];
    return cell;
}

#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.userWasSelectedBlock) {
        self.userWasSelectedBlock([self.filteredUsers objectAtIndex:indexPath.row]);
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        HBCPrototypeUser *user = [self.filteredUsers objectAtIndex:indexPath.row];
        [self.filteredUsers removeObjectAtIndex:indexPath.row];
        [self.users removeObject:user];
        [[HBPrototypesManager sharedManager] removeUser:user];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

#pragma mark UISearchBarDelegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    [self.filteredUsers removeAllObjects];
    if (self.searchBar.text.length > 0) {
        [self.filteredUsers addObjectsFromArray:[self.users filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(name CONTAINS[cd] %@) OR (bio CONTAINS[cd] %@)", self.searchBar.text, self.searchBar.text]]];
    } else {
        [self.filteredUsers addObjectsFromArray:self.users];
    }
    
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
}

@end
