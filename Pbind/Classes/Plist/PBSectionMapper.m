//
//  PBSectionMapper.m
//  Pbind
//
//  Created by galen on 15/2/17.
//  Copyright (c) 2015年 galen. All rights reserved.
//

#import "PBSectionMapper.h"
#import "PBRowMapper.h"
#import "Pbind+API.h"

@implementation PBSectionMapper

- (NSInteger)rowCount {
    NSInteger rowCount = 0;
    if (self.row != nil) {
        rowCount = [self.data count];
        if (rowCount == 0 && self.emptyRow != nil) {
            rowCount = 1;
        }
    } else {
        rowCount = [self.rows count];
    }
    return rowCount;
}

- (void)setItem:(id)item {
    self.row = item;
}

- (id)item {
    return self.row;
}

- (void)setItems:(NSArray *)items {
    self.rows = items;
}

- (NSArray *)items {
    return self.rows;
}

@end
