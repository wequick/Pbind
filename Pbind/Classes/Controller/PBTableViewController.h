//
//  PBTableViewController.h
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by galen on 15/4/27.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import <UIKit/UIKit.h>
#import "PBTableView.h"
#import "PBViewController.h"

@interface PBTableViewController : PBViewController<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) PBTableView *tableView;

@property (nonatomic, assign) BOOL grouped;

- (UITableViewStyle)preferredTableViewStyle; // TO IMPLEMENT, Default is UITableViewStylePlain

@end
