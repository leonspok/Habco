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

static NSString *const kPrototypeCell = @"kPrototypeCell";

@interface HBPrototypesListViewController ()<UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;

@property (nonatomic, strong) NSMutableArray *filteredPrototypes;
@property (nonatomic, strong) NSMutableArray *prototypes;

@end

@implementation HBPrototypesListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"Prototypes", nil);
    
    UINib *nib = [UINib nibWithNibName:NSStringFromClass(HBPrototypeTableViewCell.class) bundle:nil];
    [self.tableView registerNib:nib forCellReuseIdentifier:kPrototypeCell];
    
    self.filteredPrototypes = [NSMutableArray array];
    self.prototypes = [NSMutableArray array];
    
    [self.searchBar setBackgroundImage:[UIImage new]];
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

#pragma UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.filteredPrototypes.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 90.0f;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    HBPrototypeTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kPrototypeCell forIndexPath:indexPath];
    [cell setPrototype:[self.filteredPrototypes objectAtIndex:indexPath.row]];
    return cell;
}

#pragma mark UITableViewDelegate

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleNone;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    //TODO: go to prototype details
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
