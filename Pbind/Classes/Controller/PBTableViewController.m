//
//  PBTableViewController.m
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by galen on 15/4/27.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "PBTableViewController.h"

@implementation PBTableViewController

- (UITableViewStyle)preferredTableViewStyle {
    return _grouped ? UITableViewStyleGrouped : UITableViewStylePlain;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _tableView = [[PBTableView alloc] initWithFrame:[UIScreen mainScreen].bounds style:[self preferredTableViewStyle]];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    
    self.view = _tableView;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return -1;
}

// Row display. Implementers should *always* try to reuse cells by setting each cell's reuseIdentifier and querying for available reusable cells with dequeueReusableCellWithIdentifier:
// Cell gets various attributes set automatically based on table (separators) and data source (accessory views, editing controls)

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    return nil;
}

@end
