//
//  HBPrototypesListViewController.m
//  Habco
//
//  Created by Игорь Савельев on 08/04/16.
//  Copyright © 2016 Leonspok. All rights reserved.
//

#import "HBPrototypesListViewController.h"
#import "HBEditPrototypeViewController.h"
#import "HBNavigationController.h"
#import "HBPrototypeTableViewCell.h"
#import "HBPrototypesManager.h"
#import "HBCPrototype.h"
#import "HBPrototypeDetailsViewController.h"
#import "IBOnboardingViewController.h"

static NSString *const kPrototypeCell = @"kPrototypeCell";

@interface HBPrototypesListViewController ()<UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) IBOutlet UIView *emptyView;

@property (nonatomic, strong) NSMutableArray *filteredPrototypes;
@property (nonatomic, strong) NSMutableArray *prototypes;

@end

@implementation HBPrototypesListViewController

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (BOOL)prefersStatusBarHidden {
    return NO;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"Prototypes", nil);
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"addIcon"] style:UIBarButtonItemStylePlain target:self action:@selector(addPrototype:)];
    
    UINib *nib = [UINib nibWithNibName:NSStringFromClass(HBPrototypeTableViewCell.class) bundle:nil];
    [self.tableView registerNib:nib forCellReuseIdentifier:kPrototypeCell];
    
    self.filteredPrototypes = [NSMutableArray array];
    self.prototypes = [NSMutableArray array];
    
    self.tableView.contentInset = UIEdgeInsetsMake(-self.tableView.tableHeaderView.frame.size.height, 0, 0, 0);
    
    [self reloadPrototypes];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self reloadPrototypes];
    
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"onboarding_shown"]) {
        IBOnboardingViewController *onboarding = [[IBOnboardingViewController alloc] initWithNibName:NSStringFromClass(IBOnboardingViewController.class) bundle:nil];
        [self presentViewController:onboarding animated:NO completion:^{
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"onboarding_shown"];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark Data

- (void)reloadPrototypes {
    [self.prototypes removeAllObjects];
    [self.prototypes addObjectsFromArray:[[HBPrototypesManager sharedManager] allPrototypes]];
    
    if (self.prototypes.count == 0) {
        [self.emptyView setHidden:NO];
    } else {
        [self.emptyView setHidden:YES];
    }
    
    [self.filteredPrototypes removeAllObjects];
    if (self.searchBar.text.length > 0) {
        [self.filteredPrototypes addObjectsFromArray:[self.prototypes filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(name CONTAINS[cd] %@) OR (prototypeDescription CONTAINS[cd] %@)", self.searchBar.text, self.searchBar.text]]];
    } else {
        [self.filteredPrototypes addObjectsFromArray:self.prototypes];
    }
    
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
}

#pragma mark UIActions

- (IBAction)addPrototype:(id)sender {
    HBEditPrototypeViewController *newVC = [[HBEditPrototypeViewController alloc] initWithPrototype:nil title:NSLocalizedString(@"Create new", nil) saveButtonTitle:NSLocalizedString(@"Save", nil)];
    [newVC setSaveBlock:^{
        [self dismissViewControllerAnimated:YES completion:nil];
        [self.searchBar setText:@""];
        [self reloadPrototypes];
    }];
    [newVC setCancelBlock:^{
        [self dismissViewControllerAnimated:YES completion:nil];
    }];
    [self presentViewController:[[HBNavigationController alloc] initWithRootViewController:newVC] animated:YES completion:nil];
}

#pragma mark UIScrollViewDelegate

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
    CGPoint offset = self.tableView.contentOffset;
    
    CGFloat barHeight = self.tableView.tableHeaderView.frame.size.height;
    if (offset.y <= barHeight/2.0f && self.prototypes.count > 0) {
        self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
    } else {
        self.tableView.contentInset = UIEdgeInsetsMake(-barHeight, 0, 0, 0);
    }
    
    self.tableView.contentOffset = offset;
}

#pragma UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.filteredPrototypes.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 90.0f;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleDelete;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    HBPrototypeTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kPrototypeCell forIndexPath:indexPath];
    [cell setPrototype:[self.filteredPrototypes objectAtIndex:indexPath.row]];
    return cell;
}

#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    HBPrototypeDetailsViewController *dvc = [[HBPrototypeDetailsViewController alloc] initWithPrototype:[self.filteredPrototypes objectAtIndex:indexPath.row]];
    [self.navigationController pushViewController:dvc animated:YES];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        HBCPrototype *prototype = [self.filteredPrototypes objectAtIndex:indexPath.row];
        [self.filteredPrototypes removeObjectAtIndex:indexPath.row];
        [self.prototypes removeObject:prototype];
        [[HBPrototypesManager sharedManager] removePrototype:prototype];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

#pragma mark UISearchBarDelegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    [self.filteredPrototypes removeAllObjects];
    if (self.searchBar.text.length > 0) {
        [self.filteredPrototypes addObjectsFromArray:[self.prototypes filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(name CONTAINS[cd] %@) OR (prototypeDescription CONTAINS[cd] %@)", self.searchBar.text, self.searchBar.text]]];
    } else {
        [self.filteredPrototypes addObjectsFromArray:self.prototypes];
    }
    
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
}

@end
