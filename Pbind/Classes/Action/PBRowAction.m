//
//  PBRowAction.m
//  Pbind
//
//  Created by Galen Lin on 22/12/2016.
//
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
    
    UIView<PBRowMapping> *mappingView = (id) state.context.supercontroller.view;
    if (![mappingView conformsToProtocol:@protocol(PBRowMapping)]) {
        return;
    }
    
    if ([self.type isEqualToString:@"addRow"]) {
        if (state.data == nil) {
            return;
        }
        
        [mappingView.rowDataSource addRowData:state.data];
    } else if ([self.type isEqualToString:@"deleteRow"]) {
        NSIndexPath *indexPath = mappingView.editingIndexPath ?: state.params[@"indexPath"];
        if (indexPath == nil) {
            return;
        }
        [mappingView.rowDataSource deleteRowDataAtIndexPath:indexPath];
    }
}

@end
