//
//  PBSection.h
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by galen on 13-7-5.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

//  <NSArray> sectionIndexTitles
//      - title1
//      - ...
//      - titleN
//  <NSDictionary> sectionRecords
//      - key=title1    value=<NSArray>rowDatas1
//      - ...
//      - key=titleN    value=<NSArray>rowDatasN
//

#import <Foundation/Foundation.h>

typedef NSString *(^PBSectionGetTitleBlock)(NSDictionary *record);
typedef BOOL(^PBSectionVisitBlock)(NSUInteger section, NSUInteger row, id record);

/**
 This class used convert an array to section by what we can display it in PBTableView with a section UI.
 */
@interface PBSection : NSObject<NSCoding, NSCopying>

@property (nonatomic, strong) NSMutableArray *sectionIndexTitles;
@property (nonatomic, strong) NSMutableDictionary *sectionRecords;

- (id)initWithArray:(NSArray *)array titleKey:(NSString *)titleKey sortKey:(NSString *)sortKey;

- (id)initWithArray:(NSArray *)array titleKey:(NSString *)titleKey sortKey:(NSString *)sortKey ascending:(BOOL)ascending;

- (id)initWithArray:(NSArray *)array sortKey:(NSString *)sortKey titleBlock:(PBSectionGetTitleBlock)block;

- (id)initWithArray:(NSArray *)array sortKey:(NSString *)sortKey ascending:(BOOL)ascending titleBlock:(PBSectionGetTitleBlock)block;

- (id)initWithDictionary:(NSDictionary *)dictionary;

- (void)insertSection:(NSString *)sectionTitle withRecord:(id)record atIndex:(NSInteger)index;

- (void)addSection:(NSString *)sectionTitle withRecord:(id)record;

- (void)removeRecordAtIndexPath:(NSIndexPath *)indexPath;
- (void)removeRecordsAtIndexPaths:(NSArray *)indexPaths;

- (void)updateRecord:(id)record atIndexPath:(NSIndexPath *)indexPath;

- (void)insertRecord:(id)record atIndexPath:(NSIndexPath *)indexPath;
- (void)insertRecord:(id)record forTitle:(NSString *)title atIndex:(NSInteger)index;
- (void)insertRecords:(NSArray *)records atIndexPaths:(NSArray *)indexPaths;

- (NSDictionary *)recordOfPart:(NSDictionary *)part fuzzy:(BOOL)fuzzy;

- (NSArray *)recordsInSection:(NSInteger)section;

- (NSInteger)sectionOfTitle:(NSString *)title;

- (NSString *)titleOfSection:(NSInteger)section;

- (id)recordAtIndexPath:(NSIndexPath *)indexPath;

- (void)visit:(PBSectionVisitBlock)visitBlock;

@end
