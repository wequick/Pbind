//
//  PBRowDataSource.h
//  Pbind
//
//  Created by Galen Lin on 22/12/2016.
//
//

#import <UIKit/UIKit.h>

#import "PBMessageInterceptor.h"
#import "PBRowMapper.h"
#import "PBSectionMapper.h"

@protocol PBRowMapping;

@interface PBRowDataSource : NSObject <UITableViewDataSource, UICollectionViewDataSource>
{
    NSMutableArray *_registeredCellClasses;
    NSArray *_sectionIndexTitles;
}

@property (nonatomic, weak) UIView<PBRowMapping> *owner;
@property (nonatomic, weak) id receiver;

@property (nonatomic, strong) PBRowMapper *row;
@property (nonatomic, strong) NSArray<PBRowMapper *> *rows;
@property (nonatomic, strong) NSArray<PBSectionMapper *> *sections;

- (PBRowMapper *)rowAtIndexPath:(NSIndexPath *)indexPath;
- (id)dataAtIndexPath:(NSIndexPath *)indexPath;

- (NSArray *)list;

- (void)reset;

- (void)updateSections;

#pragma mark - for PBRowAction

- (void)addRowData:(id)data;
- (void)deleteRowDataAtIndexPath:(NSIndexPath *)indexPath;

@end
