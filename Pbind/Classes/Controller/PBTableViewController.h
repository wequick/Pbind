//
//  PBTableViewController.h
//  Pbind
//
//  Created by galen on 15/4/27.
//  Copyright (c) 2015年 galen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PBTableView.h"
#import "PBViewController.h"

@interface PBTableViewController : PBViewController<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) PBTableView *tableView;

@property (nonatomic, assign) BOOL grouped;

- (UITableViewStyle)preferredTableViewStyle; // TO IMPLEMENT, Default is UITableViewStylePlain

@end
