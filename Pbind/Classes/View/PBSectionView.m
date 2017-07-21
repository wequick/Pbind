//
//  PBSectionView.m
//  Pods
//
//  Created by galen on 17/7/21.
//
//

#import "PBSectionView.h"
#import "UIView+Pbind.h"

@implementation PBSectionView

- (void)pb_reloadLayout {
    [super pb_reloadLayout];
    
    UITableView *tableView = [self superviewWithClass:[UITableView class]];
    if (tableView == nil) {
        return;
    }
    
    [tableView reloadSections:[NSIndexSet indexSetWithIndex:_section] withRowAnimation:UITableViewRowAnimationAutomatic];
}

@end
