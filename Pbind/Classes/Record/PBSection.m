//
//  PBSection.m
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by galen on 13-7-5.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "PBSection.h"
#import <UIKit/UIKit.h>

@implementation PBSection

- (id)initWithArray:(NSArray *)array titleKey:(NSString *)titleKey sortKey:(NSString *)sortKey
{
    return [self initWithArray:array titleKey:titleKey sortKey:sortKey ascending:YES];
}

- (id)initWithArray:(NSArray *)array titleKey:(NSString *)titleKey sortKey:(NSString *)sortKey ascending:(BOOL)ascending
{
    return [self initWithArray:array sortKey:sortKey ascending:ascending titleBlock:^NSString *(NSDictionary *record) {
        return [record objectForKey:titleKey];
    }];
}

- (id)initWithArray:(NSArray *)array sortKey:(NSString *)sortKey titleBlock:(CYDataSectionGetTitleBlock)block
{
    return [self initWithArray:array sortKey:sortKey ascending:YES titleBlock:block];
}

- (id)initWithArray:(NSArray *)array sortKey:(NSString *)sortKey ascending:(BOOL)ascending titleBlock:(CYDataSectionGetTitleBlock)block
{
    if (self = [super init]) {
        NSArray *sortedArray = nil;
        if (sortKey != nil) {
            sortedArray = [self sortArray:array withKey:sortKey ascending:ascending];
        } else {
            sortedArray = array;
        }
        
        self.sectionIndexTitles = [[NSMutableArray alloc] init];
        self.sectionRecords = [[NSMutableDictionary alloc] init];
        //
        for (id o in sortedArray) {
            if (![o isKindOfClass:[NSDictionary class]]) {
                NSLog(@"Failed to init PullDataSection");
                assert(0);
            }
            NSDictionary *record = o;
            NSString *title = block(record);
            [self addSection:title withRecord:record];
        }
    }
    return self;
}

- (id)initWithDictionary:(NSDictionary *)dictionary
{
    NSArray *sectionIndexTitles = [dictionary objectForKey:@"sectionIndexTitles"];
    NSDictionary *sectionRecords = [dictionary objectForKey:@"sectionRecords"];
    if (sectionIndexTitles == nil || sectionRecords == nil) {
        return nil;
    }
    
    if (self = [super init]) {
        self.sectionIndexTitles = [[NSMutableArray alloc] initWithArray:sectionIndexTitles];
        self.sectionRecords = [[NSMutableDictionary alloc] initWithDictionary:sectionRecords];
    }
    return self;
}

- (void)insertSection:(NSString *)sectionTitle withRecord:(id)record atIndex:(NSInteger)index
{
    if (self.sectionRecords == nil) {
        self.sectionRecords = [[NSMutableDictionary alloc] init];
    }
    if (self.sectionIndexTitles == nil) {
        self.sectionIndexTitles = [[NSMutableArray alloc] init];
    }
    
    NSMutableArray *recordDatas = [self.sectionRecords objectForKey:sectionTitle];
    if (!recordDatas) { // set to the dictionary only once.
        recordDatas = [[NSMutableArray alloc] init];
        [self.sectionRecords setObject:recordDatas forKey:sectionTitle];
        //add title
        if (index >= 0 && index < [self.sectionIndexTitles count]) {
            [self.sectionIndexTitles insertObject:sectionTitle atIndex:index];
        } else {
            [self.sectionIndexTitles addObject:sectionTitle];
        }
    }
    //add record
    [recordDatas addObject:record];
}

- (void)addSection:(NSString *)sectionTitle withRecord:(id)record
{
    [self insertSection:sectionTitle withRecord:record atIndex:-1];
}

- (void)insertRecord:(id)record atIndexPath:(NSIndexPath *)indexPath
{
    NSString *title = [self.sectionIndexTitles objectAtIndex:indexPath.section];
    [self insertRecord:record forTitle:title atIndex:indexPath.row];
}

- (void)insertRecord:(id)record forTitle:(NSString *)title atIndex:(NSInteger)index
{
    if (title) {
        NSArray *records = [self.sectionRecords objectForKey:title];
        if ([records isKindOfClass:[NSMutableArray class]]) {
            NSMutableArray *array = (id)records;
            [array insertObject:record atIndex:index];
        } else {
            NSMutableArray *array = [NSMutableArray arrayWithArray:records];
            [array insertObject:record atIndex:index];
            [self.sectionRecords setObject:array forKey:title];
        }
    }
}

- (void)insertRecords:(NSArray *)records atIndexPaths:(NSArray *)indexPaths
{
    // 0, 1; 0, 2 ->
    // 0-[1,2]
    NSMutableDictionary *sections = [[NSMutableDictionary alloc] init];
    for (int i = 0; i < [records count]; i++) {
        NSIndexPath *indexPath = [indexPaths objectAtIndex:i];
        id record = [records objectAtIndex:i];
        NSDictionary *data = [sections objectForKey:@(indexPath.section)];
        NSMutableIndexSet *indexes = nil;
        NSMutableArray *records = nil;
        if (!data) {
            indexes = [[NSMutableIndexSet alloc] init];
            records = [[NSMutableArray alloc] init];
            data = @{@"indexes": indexes,
                     @"records": records};
            [sections setObject:data forKey:@(indexPath.section)];
        } else {
            indexes = [data objectForKey:@"indexes"];
            records = [data objectForKey:@"records"];
        }
        [indexes addIndex:indexPath.row];
        [records addObject:record];
    }
    
    NSArray *keys = [sections allKeys];
    for (NSNumber *section in keys) {
        NSDictionary *data = [sections objectForKey:section];
        NSMutableIndexSet *indexes = [data objectForKey:@"indexes"];
        NSArray *datas = [data objectForKey:@"records"];
        NSString *title = [self.sectionIndexTitles objectAtIndex:[section integerValue]];
        if (title) {
            NSArray *records = [self.sectionRecords objectForKey:title];
            if ([records isKindOfClass:[NSMutableArray class]]) {
                NSMutableArray *array = (id)records;
                [array insertObjects:datas atIndexes:indexes];
            } else {
                NSMutableArray *array = [NSMutableArray arrayWithArray:records];
                [array insertObjects:datas atIndexes:indexes];
                [self.sectionRecords setObject:array forKey:title];
            }
        }
    }
}

- (void)removeRecordAtIndexPath:(NSIndexPath *)indexPath
{
    [self removeRecordsAtIndexPaths:@[indexPath]];
}

- (void)removeRecordsAtIndexPaths:(NSArray *)indexPaths
{
    // 0, 1; 0, 2 ->
    // 0, 1-2
    NSMutableDictionary *sections = [[NSMutableDictionary alloc] init];
    for (NSIndexPath *indexPath in indexPaths) {
        NSMutableIndexSet *indexes = [sections objectForKey:@(indexPath.section)];
        if (!indexes) {
            indexes = [[NSMutableIndexSet alloc] init];
            [sections setObject:indexes forKey:@(indexPath.section)];
        }
        
        [indexes addIndex:indexPath.row];
    }
    
    NSArray *keys = [sections allKeys];
    for (NSNumber *section in keys) {
        NSMutableIndexSet *indexes = [sections objectForKey:section];
        NSString *title = [self.sectionIndexTitles objectAtIndex:[section integerValue]];
        if (title) {
            NSArray *records = [self.sectionRecords objectForKey:title];
            if ([records isKindOfClass:[NSMutableArray class]]) {
                NSMutableArray *array = (id)records;
                [array removeObjectsAtIndexes:indexes];
            } else {
                NSMutableArray *array = [NSMutableArray arrayWithArray:records];
                [array removeObjectsAtIndexes:indexes];
                [self.sectionRecords setObject:array forKey:title];
            }
        }
    }
}

- (void)updateRecord:(id)record atIndexPath:(NSIndexPath *)indexPath
{
    NSString *title = [self.sectionIndexTitles objectAtIndex:indexPath.section];
    if (title) {
        NSArray *records = [self.sectionRecords objectForKey:title];
        if ([records isKindOfClass:[NSMutableArray class]]) {
            NSMutableArray *array = (id)records;
            [array replaceObjectAtIndex:indexPath.row withObject:record];
        } else {
            NSMutableArray *array = [NSMutableArray arrayWithArray:records];
            [array replaceObjectAtIndex:indexPath.row withObject:record];
            [self.sectionRecords setObject:array forKey:title];
        }
    }
}

- (NSDictionary *)recordOfPart:(NSDictionary *)part fuzzy:(BOOL)fuzzy
{
    NSDictionary *findRecord = nil;

    for (NSArray *key in self.sectionRecords) {
        NSArray *records = [self.sectionRecords objectForKey:key];
        for (NSDictionary *record in records) {
            //判断record 是否包含 part
            for (NSString *part_key in part) {
                NSString *part_value = [part objectForKey:part_key];
                NSString *main_value = [record objectForKey:part_key];
                BOOL find = FALSE;
                if (fuzzy) {
                    find = [self isLikeToString:part_value withString:main_value];
                } else {
                    find = [part_value isEqualToString:main_value];
                }
                if (find) {
                    findRecord = record;
                    break;
                }
            }
        }
    }
    
    return findRecord;
}

- (BOOL)isLikeToString:(NSString *)string withString:(NSString *)aString
{
    //FIXME: !self never happend
    if (!aString && !string) {
        return YES;
    } else if (self && string) {
        if ([aString length] < [string length]) {
            return ([string rangeOfString:aString].length != 0);
        } else {
            return ([aString rangeOfString:string].length != 0);
        }
    }
    return NO;
}

#pragma mark - for UITableView data source

- (NSArray *)recordsInSection:(NSInteger)section
{
    NSString *title = [self.sectionIndexTitles objectAtIndex:section];
    if (!title) {
        NSLog(@"[%@] section=%d, titles=%@",[self.class description],(int)section,self.sectionIndexTitles);
        //assert(0);
        return nil;
    }
    NSArray *records = [self.sectionRecords objectForKey:title];
    return records;
}

- (NSInteger)sectionOfTitle:(NSString *)title
{
    NSInteger count = 0;
    for (NSString *aTitle in self.sectionIndexTitles) {
        if ([aTitle isEqualToString:title]) {
            return count;
        }
        count ++;
    }
    return count;
}

- (NSString *)titleOfSection:(NSInteger)section
{
    return [self.sectionIndexTitles objectAtIndex:section];
}

- (id)recordAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *records = [self recordsInSection:indexPath.section];
    if (records == nil) {
        return nil;
    }
    
    NSInteger n = [records count];
    if (indexPath.row >= n) {
        return nil;
    }
    
    return [records objectAtIndex:indexPath.row];
}

- (void)visit:(CYDataSectionVisitBlock)visitBlock
{
    for (NSUInteger section = 0; section < [self.sectionIndexTitles count]; section ++) {
        NSString *title = [self.sectionIndexTitles objectAtIndex:section];
        NSArray *pRecords = [self.sectionRecords objectForKey:title];
        for (NSUInteger row = 0; row < [pRecords count]; row ++) {
            id record = [pRecords objectAtIndex:row];
            if (visitBlock(section, row, record)) {
                break;
            }
        }
    }
}

#pragma mark - Local method

- (NSArray *)sortArray:(NSArray *)array withKey:key ascending:(BOOL)ascending
{
    if (key == nil) {
        return array;
    }
    NSSortDescriptor *sorter = [[NSSortDescriptor alloc] initWithKey:key ascending:ascending];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:&sorter count:1];
    NSArray *sortedArray = [array sortedArrayUsingDescriptors:sortDescriptors];
    return sortedArray;
}

#pragma mark - NSCoding

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.sectionIndexTitles forKey:@"titles"];
    [aCoder encodeObject:self.sectionRecords forKey:@"records"];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init]) {
        self.sectionIndexTitles = [aDecoder decodeObjectForKey:@"titles"];
        self.sectionRecords = [aDecoder decodeObjectForKey:@"records"];
    }
    return self;
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    PBSection *copy = [[[self class] allocWithZone:zone] init];
    copy.sectionIndexTitles = [[NSMutableArray allocWithZone:zone] initWithArray:self.sectionIndexTitles copyItems:YES];
    copy.sectionRecords = [[NSMutableDictionary allocWithZone:zone] initWithDictionary:self.sectionRecords copyItems:YES];
    return copy;
}

@end
