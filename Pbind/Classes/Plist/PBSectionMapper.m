//
//  PBSectionMapper.m
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by galen on 15/2/17.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "PBSectionMapper.h"
#import "PBRowMapper.h"
#import "Pbind+API.h"
#import "PBMutableExpression.h"

@interface PBRowMapper (Private)

- (void)initDefaultViewClass;

@end

@implementation PBSectionMapper

- (void)setPropertiesWithDictionary:(NSDictionary *)dictionary {
    self.inner = CGSizeMake(-1, -1);
    _alignment = NSTextAlignmentCenter;
    
    NSMutableArray *conditions = nil;
    NSMutableArray *conditionKeys = nil;
    NSArray *keys = [dictionary allKeys];
    for (NSString *key in keys) {
        if ([key hasPrefix:@"row@"]) {
            NSMutableDictionary *condition = [NSMutableDictionary dictionaryWithCapacity:2];
            condition[@"if"] = [key substringFromIndex:4];
            condition[@"row"] = dictionary[key];
            if (conditions == nil) {
                conditions = [[NSMutableArray alloc] init];
            }
            [conditions addObject:condition];
            
            if (conditionKeys == nil) {
                conditionKeys = [[NSMutableArray alloc] init];
            }
            [conditionKeys addObject:key];
        }
    }
    if (conditions != nil) {
        self.rowConditions = conditions;
        NSMutableDictionary *temp = [NSMutableDictionary dictionaryWithDictionary:dictionary];
        [temp removeObjectsForKeys:conditionKeys];
        dictionary = temp;
    }
    
    [super setPropertiesWithDictionary:dictionary];
}

- (void)initDefaultViewClass {
    if ([self.owner isKindOfClass:[UICollectionView class]]) {
        self.clazz = @"UICollectionReusableView";
    } else {
        self.clazz = @"UIView";
    }
}

- (NSInteger)rowCount {
    if (self.hidden) {
        return 0;
    }
    
    NSInteger rowCount = 0;
    if (self.row != nil || _rowConditions != nil) {
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

- (void)unbind {
    [super unbind];
    
    // TODO: save the rowMapper to another property and remove this class checker
    if (_row != nil && [_row isKindOfClass:[PBRowMapper class]]) {
        [_row unbind];
    }
    if (_rows != nil) {
        for (PBRowMapper *row in _rows) {
            if ([row isKindOfClass:[PBRowMapper class]]) {
                [row unbind];
            }
        }
    }
    if (_rowConditions != nil) {
        for (NSDictionary *condition in _rowConditions) {
            PBRowMapper *row = condition[@"rowMapper"];
            [row unbind];
        }
    }
}

@end
