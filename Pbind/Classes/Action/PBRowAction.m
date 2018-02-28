//
//  PBRowAction.m
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by Galen Lin on 22/12/2016.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "PBRowAction.h"
#import "PBTableView.h"
#import "UIView+Pbind.h"
#import "PBArray.h"
#import "PBRowMapping.h"

@implementation PBRowAction

@pbactions(@"addRow", @"deleteRow")
- (void)run:(PBActionState *)state {
    if (state.context == nil) {
        return;
    }
    
    UIView<PBRowMapping> *mappingView = [self mappableParentViewOfSubview:state.context];
    if (mappingView == nil) {
        return;
    }
    
    if ([self.type isEqualToString:@"addRow"]) {
        if (state.data == nil) {
            return;
        }
        
        [mappingView.rowDataSource addRowData:state.data];
    } else if ([self.type isEqualToString:@"deleteRow"]) {
        if (state.status != PBResponseStatusNoContent) {
            return;
        }
        
        NSIndexPath *indexPath = mappingView.editingIndexPath ?: state.params[@"indexPath"];
        if (indexPath == nil) {
            return;
        }
        [mappingView.rowDataSource deleteRowDataAtIndexPath:indexPath];
    }
}

- (UIView<PBRowMapping> *)mappableParentViewOfSubview:(UIView *)view {
    if (view == nil) {
        return nil;
    }
    
    if ([view conformsToProtocol:@protocol(PBRowMapping)]) {
        return (id) view;
    }
    
    return [self mappableParentViewOfSubview:view.superview];
}

@end
