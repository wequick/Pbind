//
//  PBSection.h
//  MainWebsite
//
//  Created by galen on 13-7-5.
//  Copyright (c) 2013年 wequick. All rights reserved.
//
//  UITableView电话簿风格的数据
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

typedef NSString *(^CYDataSectionGetTitleBlock)(NSDictionary *record);
typedef BOOL(^CYDataSectionVisitBlock)(NSUInteger section, NSUInteger row, id record);

@interface PBSection : NSObject<NSCoding, NSCopying>

@property (nonatomic, strong) NSMutableArray *sectionIndexTitles;
@property (nonatomic, strong) NSMutableDictionary *sectionRecords;

/**
 * 数组:字典数组 eg:{[id=xx,title='A',spell='ABC',text="阿不错"]...}
 * titleKey: 标题字段名 eg:@"title"
 * sortKey: 排序字段名 eg:@"spell" 如果为空，不进行排序
 */
- (id)initWithArray:(NSArray *)array titleKey:(NSString *)titleKey sortKey:(NSString *)sortKey;

- (id)initWithArray:(NSArray *)array titleKey:(NSString *)titleKey sortKey:(NSString *)sortKey ascending:(BOOL)ascending;

- (id)initWithArray:(NSArray *)array sortKey:(NSString *)sortKey titleBlock:(CYDataSectionGetTitleBlock)block;

- (id)initWithArray:(NSArray *)array sortKey:(NSString *)sortKey ascending:(BOOL)ascending titleBlock:(CYDataSectionGetTitleBlock)block;

- (id)initWithDictionary:(NSDictionary *)dictionary;

/**
 * 插入一个section
 */
- (void)insertSection:(NSString *)sectionTitle withRecord:(id)record atIndex:(NSInteger)index;
/**
 * 追加一个section
 */
- (void)addSection:(NSString *)sectionTitle withRecord:(id)record;
/**
 * 删除一个record
 */
- (void)removeRecordAtIndexPath:(NSIndexPath *)indexPath;
/**
 * 删除多个record
 */
- (void)removeRecordsAtIndexPaths:(NSArray *)indexPaths;
/**
 * 更新一个record
 */
- (void)updateRecord:(id)record atIndexPath:(NSIndexPath *)indexPath;
/**
 * 插入一个record
 */
- (void)insertRecord:(id)record atIndexPath:(NSIndexPath *)indexPath;
- (void)insertRecord:(id)record forTitle:(NSString *)title atIndex:(NSInteger)index;
/**
 * 插入多个record
 */
- (void)insertRecords:(NSArray *)records atIndexPaths:(NSArray *)indexPaths;

/**
 * 查找一个record
 * part: 部分字典
 * fuzzy: 模糊匹配
 */
- (NSDictionary *)recordOfPart:(NSDictionary *)part fuzzy:(BOOL)fuzzy;

/**
 * 一个section下的记录数
 */
- (NSArray *)recordsInSection:(NSInteger)section;

- (NSInteger)sectionOfTitle:(NSString *)title;

- (NSString *)titleOfSection:(NSInteger)section;

- (id)recordAtIndexPath:(NSIndexPath *)indexPath;

/**
 * 遍历, return YES 跳出
 */
- (void)visit:(CYDataSectionVisitBlock)visitBlock;

@end
