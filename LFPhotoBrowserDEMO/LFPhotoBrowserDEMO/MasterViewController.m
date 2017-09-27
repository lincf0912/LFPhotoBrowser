//
//  MasterViewController.m
//  LFPhotoBrowserDEMO
//
//  Created by LamTsanFeng on 2016/10/18.
//  Copyright © 2016年 GZMiracle. All rights reserved.
//

#import "MasterViewController.h"

#import "PhotoTableViewController.h"
#import "PhotoCollectionViewController.h"

@interface MasterViewController ()

@property NSMutableArray *objects;
@end

@implementation MasterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    /** 原生UITableViewController自动计算 */
    if (@available(iOS 11.0, *)){
        [self.tableView setContentInsetAdjustmentBehavior:UIScrollViewContentInsetAdjustmentAutomatic];
    }
    // Do any additional setup after loading the view, typically from a nib.
    self.objects = [NSMutableArray arrayWithObjects:@"网络数据（tableview）",@"本地数据（collectionview）", nil];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.objects.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];

    NSString *object = self.objects[indexPath.row];
    cell.textLabel.text = [object description];
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0) {
        PhotoTableViewController *photoTableVC = [PhotoTableViewController new];
        [self.navigationController pushViewController:photoTableVC animated:YES];
    } else if (indexPath.row == 1) {
        PhotoCollectionViewController *photoCollectionVC = [PhotoCollectionViewController new];
        [self.navigationController pushViewController:photoCollectionVC animated:YES];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
