//
//  PBTableHeaderView.m
//  Pods
//
//  Created by Galen Lin on 16/9/9.
//
//

#import "PBTableHeaderView.h"

@implementation PBTableHeaderView

- (void)setContentSize:(CGSize)contentSize {
    if (contentSize.height == 0) {
        contentSize.height = CGFLOAT_MIN;
    }
    [super setContentSize:contentSize];
}

@end
