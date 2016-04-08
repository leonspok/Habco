//
//  HBPrototypesListViewController.m
//  Habco
//
//  Created by Игорь Савельев on 08/04/16.
//  Copyright © 2016 Leonspok. All rights reserved.
//

#import "HBPrototypesListViewController.h"
#import "HBEditPrototypeViewController.h"
#import "HBPrototypeTableViewCell.h"
#import "HBPrototypesManager.h"
#import "HBCPrototype.h"

//TODO: remove
#import "HBEditUserViewController.h"

static NSString *const kPrototypeCell = @"kPrototypeCell";

@interface HBPrototypesListViewController ()<UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;

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
    
    [self.searchBar setBackgroundImage:[UIImage new]];
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(100, 30), NO, 1.0f);
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, 100, 30) cornerRadius:5.0f];
    CGContextSetFillColorWithColor(UIGraphicsGetCurrentContext(), [UIColor colorWithWhite:1 alpha:0.1f].CGColor);
    CGContextBeginPath(UIGraphicsGetCurrentContext());
    CGContextAddPath(UIGraphicsGetCurrentContext(), path.CGPath);
    CGContextFillPath(UIGraphicsGetCurrentContext());
    UIImage *searchFieldBackgroundImage = UIGraphicsGetImageFromCurrentImageContext();
    searchFieldBackgroundImage = [searchFieldBackgroundImage resizableImageWithCapInsets:UIEdgeInsetsMake(5, 5, 5, 5)];
    UIGraphicsEndImageContext();
    
    [self.searchBar setSearchFieldBackgroundImage:searchFieldBackgroundImage forState:UIControlStateNormal];
    [[UITextField appearanceWhenContainedInInstancesOfClasses:@[UISearchBar.class]] setDefaultTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor], NSFontAttributeName: [UIFont systemFontOfSize:14.0f]}];
    [[UILabel appearanceWhenContainedInInstancesOfClasses:@[UISearchBar.class]] setFont:[UIFont systemFontOfSize:14.0f]];
    [[UILabel appearanceWhenContainedInInstancesOfClasses:@[UISearchBar.class]] setTextColor:[UIColor colorWithWhite:1 alpha:0.3f]];
    [[UIImageView appearanceWhenContainedInInstancesOfClasses:@[UISearchBar.class]] setTintColor:[UIColor colorWithWhite:1 alpha:0.3f]];
    
    self.tableView.contentInset = UIEdgeInsetsMake(-self.tableView.tableHeaderView.frame.size.height, 0, 0, 0);
    
    [self reloadPrototypes];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark Data

- (void)reloadPrototypes {
    [self.prototypes removeAllObjects];
    [self.prototypes addObjectsFromArray:[[HBPrototypesManager sharedManager] allPrototypes]];
    
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
        [self.navigationController popToViewController:self animated:YES];
        [self.searchBar setText:@""];
        [self reloadPrototypes];
    }];
    [self.navigationController pushViewController:newVC animated:YES];
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
    //TODO: go to prototype details
    HBEditUserViewController *editVC = [[HBEditUserViewController alloc] initWithPrototype:[self.filteredPrototypes objectAtIndex:indexPath.row] title:NSLocalizedString(@"Add user", nil) saveButtonTitle:NSLocalizedString(@"Save", nil)];
    [editVC setSaveBlock:^{
        [self.navigationController popToViewController:self animated:YES];
        [self reloadPrototypes];
    }];
    [self.navigationController pushViewController:editVC animated:YES];
    
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
