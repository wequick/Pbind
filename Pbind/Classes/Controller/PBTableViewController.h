//
//  PBTableViewController.h
//  Pbind
//
//  Created by galen on 15/4/27.
//  Copyright (c) 2015年 galen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PBTableView.h"

@interface PBTableViewController : UIViewController<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) PBTableView *tableView;

- (UITableViewStyle)preferredTableViewStyle; // TO IMPLEMENT, Default is UITableViewStylePlain

@end