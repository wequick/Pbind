//
//  LSTableViewController.m
//  Less
//
//  Created by galen on 15/4/27.
//  Copyright (c) 2015年 galen. All rights reserved.
//

#import "LSTableViewController.h"

@interface LSTableViewController ()

@end

@implementation LSTableViewController

- (UITableViewStyle)preferredTableViewStyle {
    return UITableViewStylePlain;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    _tableView = [[LSTableView alloc] initWithFrame:[UIScreen mainScreen].bounds style:[self preferredTableViewStyle]];
    self.view = _tableView;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
