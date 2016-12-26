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

@pbactions(@"addrow")
- (void)run:(PBActionState *)state {
    if (state.context == nil || state.data == nil) {
        return;
    }
    
    if (![state.context conformsToProtocol:@protocol(PBRowMapping)]) {
        return;
    }
    
    UIView<PBRowMapping> *mappingView = (id) state.context;
    [mappingView.rowDataSource addRowData:state.data];
}

@end
