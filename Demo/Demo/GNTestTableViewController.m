//
//  GNTestTableViewController.m
//  Demo
//
//  Created by ccd on 16/12/1.
//  Copyright © 2016年 ccd. All rights reserved.
//


#import "GNTestTableViewController.h"
#import "MJRefresh.h"

@interface GNTestTableViewController ()

@property (nonatomic,assign) NSInteger cellCount;

@end

@implementation GNTestTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"];
    self.tableView.tableFooterView = [[UIView alloc]init];
    
    self.tableView.mj_header = [MJRefreshNormalHeader headerWithRefreshingTarget:self refreshingAction:@selector(loadNew)];
    self.tableView.mj_footer = [MJRefreshAutoNormalFooter footerWithRefreshingTarget:self refreshingAction:@selector(loadMore)];
    self.tableView.mj_footer.automaticallyHidden = YES;
    
    [self.tableView.mj_header beginRefreshing];
}

- (void)loadNew{
    _cellCount = 5;
    [self.tableView reloadData];
    [self.tableView.mj_header endRefreshing];
    [self.tableView.mj_footer resetNoMoreData];
}
- (void)loadMore{
    if (_cellCount == 50) {
        [self.tableView.mj_footer endRefreshingWithNoMoreData];
        return;
    }
    _cellCount += 5;
    [self.tableView reloadData];
    [self.tableView.mj_footer endRefreshing];
}
#pragma mark - Table view data source
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _cellCount;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    cell.textLabel.text = [NSString stringWithFormat:@"%zd",indexPath.row + 1];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 50;
}


@end
