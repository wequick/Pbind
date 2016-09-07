//
//  LSTableViewController.h
//  Less
//
//  Created by galen on 15/4/27.
//  Copyright (c) 2015年 galen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LSTableView.h"

@interface LSTableViewController : UIViewController

@property (nonatomic, strong) LSTableView *tableView;

- (UITableViewStyle)preferredTableViewStyle; // TO IMPLEMENT, Default is UITableViewStylePlain

@end
