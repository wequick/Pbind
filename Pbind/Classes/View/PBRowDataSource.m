//
//  PBRowDataSource.m
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by Galen Lin on 22/12/2016.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "PBRowDataSource.h"
#import "PBSection.h"
#import "PBTableView.h"
#import "PBCollectionView.h"
#import "PBArray.h"
#import "PBInline.h"
#import "UIView+Pbind.h"
#import "PBValueParser.h"

@implementation PBRowDataSource

@synthesize receiver;

#pragma mark - Base

- (NSArray *)listForData:(id)data key:(NSString *)listKey {
    id list = data;
    if ([list isKindOfClass:[NSArray class]]) {
        return list;
    }
    
    if ([list isKindOfClass:[PBArray class]]) {
        list = [list list];
    }
    
    if ([list isKindOfClass:[NSArray class]]) {
        return list;
    }
    
    if (listKey == nil || ![list isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    
    list = [list objectForKey:listKey];
    return list;
}

- (NSArray *)list {
    id list = self.owner.data;
    if ([list isKindOfClass:[NSArray class]]) {
        return list;
    }
    
    if ([list isKindOfClass:[PBArray class]]) {
        list = [list list];
    }
    
    if ([list isKindOfClass:[NSArray class]]) {
        return list;
    }
    
    if (self.owner.listKey == nil || ![list isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    
    list = [list objectForKey:self.owner.listKey];
    return list;
}

- (PBRowMapper *)rowAtIndexPath:(NSIndexPath *)indexPath
{
    [self initRowMapper];
    
    if (self.row != nil) {
        // Repeated row
        return self.row;
    } else if (self.rows != nil) {
        // Distinct row configured by `rows'
        return [self.rows objectAtIndex:indexPath.row];
    } else if (self.sections != nil) {
        // Distinct row configured by `sections'
        PBSectionMapper *section = [self.sections objectAtIndex:indexPath.section];
        if (section != nil) {
            if (section.row != nil) {
                if (section.emptyRow != nil && [self dataAtIndexPath:indexPath] == nil) {
                    return section.emptyRow;
                }
                return section.row;
            }
            return [section.rows objectAtIndex:indexPath.row];
        }
    }
    return nil;
}

- (id)dataAtIndexPath:(NSIndexPath *)indexPath
{
    [self initRowMapper];
    
    id _data = [self.owner data];
    if (_data == nil) {
        return nil;
    }
    
    if (self.row != nil) {
        // Repeated row
        id data = _data;
        if ([data isKindOfClass:[NSArray class]]) {
            return [data objectAtIndex:indexPath.row];
        } else if ([data isKindOfClass:[PBSection class]]) {
            return [(PBSection *)data recordAtIndexPath:indexPath];
        } else {
            return [self list][indexPath.row];
        }
    } else if (self.rows != nil) {
        // Distinct row configured by `rows'
        if ([_data isKindOfClass:[PBArray class]]) {
            return [_data list];
        }
        return _data;
    } else if (self.sections != nil) {
        // Distinct row configured by `sections'
        id data = _data;
        PBSectionMapper *mapper = [self.sections objectAtIndex:indexPath.section];
        if (mapper != nil && mapper.data != nil) {
            data = mapper.data;
        }
        
        if ([data isKindOfClass:[PBArray class]]) {
            data = [data list];
        }
        
        if ([data isKindOfClass:[NSArray class]]) {
            if ([data count] <= indexPath.row) {
                return nil;
            }
            data = [data objectAtIndex:indexPath.row];
        }
        
        return data;
    }
    
    return nil;
}

- (void)initRowMapper {
    if (self.row != nil || self.rows != nil || self.sections != nil) {
        return;
    }
    
    PBRowMapper *row = self.row;
    if (row != nil) {
        return;
    }
    
    NSDictionary *rowSource = self.owner.row;
    
    // Parsing rows: NSArray<NSDictionary> to NSArray<PBRowMapper>
    NSArray *rows = self.owner.rows;
    if ([rows count] > 0) {
        NSMutableArray *temp = [NSMutableArray arrayWithCapacity:[rows count]];
        for (NSInteger index = 0; index < [rows count]; index++) {
            NSDictionary *dict = [rows objectAtIndex:index];
            if (rowSource != nil) {
                // Take the `row' as base mapper
                dict = [self dictionaryByMergingDictionary:rowSource withAnother:dict];
            }
            PBRowMapper *aRow = [PBRowMapper mapperWithDictionary:dict owner:nil];
            [temp addObject:aRow];
        }
        _rows = temp;
        return;
    }
    
    // Parsing sections: NSArray<NSDcitionary> to NSArray<PBSectionMapper>
    NSArray *sections = self.owner.sections;
    if ([sections count] > 0) {
        NSMutableArray *temp = [NSMutableArray arrayWithCapacity:[sections count]];
        for (NSInteger section = 0; section < [sections count]; section++) {
            NSDictionary *dict = [sections objectAtIndex:section];
            PBSectionMapper *aSection = [PBSectionMapper mapperWithDictionary:dict owner:nil];
            NSDictionary *aRowSource = (id)aSection.row;
            
            if ([aSection.rows count] > 0) {
                NSMutableArray *rows = [NSMutableArray arrayWithCapacity:[aSection.rows count]];
                for (NSInteger index = 0; index < [aSection.rows count]; index++) {
                    NSDictionary *dict = [aSection.rows objectAtIndex:index];
                    if (aRowSource != nil) {
                        // Take the `row' as base mapper
                        dict = [self dictionaryByMergingDictionary:aRowSource withAnother:dict];
                        aSection.row = nil; // don't need any more.
                    }
                    PBRowMapper *aRow = [PBRowMapper mapperWithDictionary:dict owner:nil];
                    [rows addObject:aRow];
                }
                aSection.rows = rows;
            } else if (aRowSource != nil) {
                aSection.row = [PBRowMapper mapperWithDictionary:aRowSource owner:nil];
            }
            
            if (aSection.emptyRow != nil) {
                aSection.emptyRow = [PBRowMapper mapperWithDictionary:aSection.emptyRow owner:nil];
            }
            
            if (aSection.footer != nil) {
                aSection.footer = [PBRowMapper mapperWithDictionary:aSection.footer owner:nil];
            }
            [temp addObject:aSection];
        }
        _sections = temp;
        // Init section index titles
        NSMutableArray *titles = [NSMutableArray arrayWithCapacity:[temp count]];
        BOOL hasTitle = NO;
        for (PBSectionMapper *section in temp) {
            NSString *title;
            if (section.title == nil) {
                title = @"";
            } else {
                title = [section.title substringToIndex:1];
                hasTitle = YES;
            }
            [titles addObject:title];
        }
        if (hasTitle) {
            _sectionIndexTitles = titles;
        }
        return;
    }
    
    if (rowSource != nil) {
        self.row = [PBRowMapper mapperWithDictionary:rowSource owner:nil];
    }
    return;
}

- (void)updateSections {
    if (_sections != nil) {
        for (PBSectionMapper *mapper in _sections) {
            [mapper updateWithData:self.owner.data andView:nil];
        }
    }
}

- (NSInteger)numberOfRowsInSection:(NSInteger)section withData:(id)data key:(NSString *)key {
    [self initRowMapper];
    
    NSInteger count = 0;
    if (self.row != nil) {
        // response array
        if ([data isKindOfClass:[PBSection class]]) {
            count = [[(PBSection *)data recordsInSection:section] count];
        } else {
            count = [[self listForData:data key:key] count];
        }
    } else if (self.rows != nil) {
        count = [self.rows count];
    } else if (self.sections != nil) {
        PBSectionMapper *aSection = [self.sections objectAtIndex:section];
        count = aSection.rowCount;
    }
    return count;
}

- (void)reset {
    _row = nil;
    _rows = nil;
    _sections = nil;
}

#pragma mark - PBRowAction

- (void)processRowData:(id)data atIndexPath:(NSIndexPath *)indexPath withHandler:(void (^)(NSMutableArray *list, id newData, NSUInteger index))handler {
    // TODO: Parse PBSection
    NSUInteger index = indexPath.row;
    id list = self.owner.data;
    if ([list isKindOfClass:[NSArray class]]) {
        if ([list isKindOfClass:[NSMutableArray class]]) {
            NSMutableArray *mutableList = list;
            handler(mutableList, data, index);
        } else {
            NSMutableArray *mutableList = [NSMutableArray arrayWithArray:list];
            handler(mutableList, data, index);
            self.owner.data = list;
        }
        return;
    }
    
    PBArray *array = nil;
    if ([list isKindOfClass:[PBArray class]]) {
        array = list;
        list = [array list];
        if ([list isKindOfClass:[NSArray class]]) {
            if ([list isKindOfClass:[NSMutableArray class]]) {
                handler(list, data, index);
            } else {
                NSMutableArray *mutableList = [NSMutableArray arrayWithArray:list];
                handler(mutableList, data, index);
                array[array.listElementIndex] = mutableList;
            }
            return;
        }
    }
    
    if (self.owner.listKey == nil || ![list isKindOfClass:[NSDictionary class]]) {
        return;
    }
    
    NSDictionary *listContainer = list;
    list = [list objectForKey:self.owner.listKey];
    if (![list isKindOfClass:[NSArray class]]) {
        return;
    }
    
    if ([list isKindOfClass:[NSMutableArray class]]) {
        handler(list, data, index);
    } else {
        NSMutableArray *mutableList = [NSMutableArray arrayWithArray:list];
        handler(mutableList, data, index);
        
        if ([listContainer isKindOfClass:[NSMutableDictionary class]]) {
            [(NSMutableDictionary *)listContainer setObject:mutableList forKey:self.owner.listKey];
        } else {
            NSMutableDictionary *mutableContainer = [NSMutableDictionary dictionaryWithDictionary:listContainer];
            [mutableContainer setObject:mutableList forKey:self.owner.listKey];
            
            if (array != nil) {
                array[array.listElementIndex] = mutableContainer;
            } else {
                self.owner.data = mutableContainer;
            }
        }
    }
}

- (void)addRowData:(id)data {
    NSIndexPath *topIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [self insertRowData:data atIndexPath:topIndexPath];
}

- (void)insertRowData:(id)data atIndexPath:(NSIndexPath *)indexPath {
    // Process data
    [self processRowData:data atIndexPath:nil withHandler:^(NSMutableArray *list, id newData, NSUInteger index) {
        [list insertObject:newData atIndex:index];
    }];
    
    // Reload view
    if ([self.owner isKindOfClass:[UITableView class]]) {
        [(UITableView *)self.owner insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    } else {
        UICollectionView *collectionView = (id) self.owner;
        [collectionView performBatchUpdates:^{
            [collectionView insertItemsAtIndexPaths:@[indexPath]];
        } completion:nil];
    }
}

- (void)deleteRowDataAtIndexPath:(NSIndexPath *)indexPath {
    // Process data
    [self processRowData:nil atIndexPath:indexPath withHandler:^(NSMutableArray *list, id newData, NSUInteger index) {
        [list removeObjectAtIndex:index];
    }];
    
    // Reload view
    if ([self.owner isKindOfClass:[UITableView class]]) {
        [(UITableView *)self.owner deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    } else {
        UICollectionView *collectionView = (id) self.owner;
        [collectionView performBatchUpdates:^{
            [collectionView deleteItemsAtIndexPaths:@[indexPath]];
        } completion:nil];
    }
}

//- (void)removeRowData

#pragma mark - UITableView
#pragma mark - @required

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if ([self.receiver respondsToSelector:_cmd]) {
        return [self.receiver numberOfSectionsInTableView:tableView];
    }
    
    [self initRowMapper];
    
    if (self.sections != nil) {
        return [self.sections count];
    } else if (self.row != nil || self.rows != nil) {
        if ([tableView.data isKindOfClass:[PBSection class]]) {
            return [[(PBSection *)tableView.data sectionIndexTitles] count];
        }
    }
    return 1;
}

- (NSInteger)tableView:(PBTableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if ([self.receiver respondsToSelector:_cmd]) {
        NSInteger rowCount = [self.receiver tableView:tableView numberOfRowsInSection:section];
        if (rowCount >= 0) {
            return rowCount;
        }
    }
    
    return [self numberOfRowsInSection:section withData:tableView.data key:tableView.listKey];
}

// Row display. Implementers should *always* try to reuse cells by setting each cell's reuseIdentifier and querying for available reusable cells with dequeueReusableCellWithIdentifier:
// Cell gets various attributes set automatically based on table (separators) and data source (accessory views, editing controls)

- (UITableViewCell *)tableView:(PBTableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;
    if ([self.receiver respondsToSelector:@selector(tableView:cellForRowAtIndexPath:)]) {
        cell = [self.receiver tableView:tableView cellForRowAtIndexPath:indexPath];
        if (cell != nil) {
            return cell;
        }
    }
    
    PBRowMapper *row = [self rowAtIndexPath:indexPath];
    NSString *cellClazz = NSStringFromClass(row.viewClass);
    if (row.viewClass != [UITableViewCell class] && ![_registeredCellClasses containsObject:cellClazz]) {
        // Lazy register reusable cell
        UINib *nib = PBNib(row.nib);
        if (nib != nil) {
            [tableView registerNib:nib forCellReuseIdentifier:row.id];
        } else {
            [tableView registerClass:row.viewClass forCellReuseIdentifier:row.id];
        }
        [_registeredCellClasses addObject:cellClazz];
    }
    
    cell = [tableView dequeueReusableCellWithIdentifier:row.id];
    if (cell == nil) {
        cell = [[row.viewClass alloc] initWithStyle:row.style reuseIdentifier:row.id];
    }
    
    if (row.layoutMapper != nil) {
        [row.layoutMapper renderToView:cell.contentView];
    }
    
    // Default to non-selection
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    
    if ([tableView isHorizontal]) {
        [cell.contentView setTransform:CGAffineTransformMakeRotation(M_PI_2)];
    }
    
    // Init data for cell
    [cell setData:[self dataAtIndexPath:indexPath]];
    [row initDataForView:cell];
    [row mapData:tableView.data forView:cell];
    
    return cell;
}

#pragma mark - @optional

- (nullable NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if ([self.receiver respondsToSelector:_cmd]) {
        return [self.receiver tableView:tableView titleForHeaderInSection:section];
    }
    
    if (self.sections != nil) {
        PBSectionMapper *aSection = [self.sections objectAtIndex:section];
        return aSection.title;
    } else if ([tableView.data isKindOfClass:[PBSection class]]) {
        return [(PBSection *)tableView.data titleOfSection:section];
    }
    return nil;
}

- (nullable NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if ([self.receiver respondsToSelector:_cmd]) {
        return [self.receiver tableView:tableView titleForFooterInSection:section];
    }
    return nil;
}

#pragma mark - Editing

// Individual rows can opt out of having the -editing property set for them. If not implemented, all rows are assumed to be editable.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self.receiver respondsToSelector:_cmd]) {
        return [self.receiver tableView:tableView canEditRowAtIndexPath:indexPath];
    }
    
    PBRowMapper *row = [self rowAtIndexPath:indexPath];
    if (row.editActionMappers != nil) {
        return YES;
    }
    return NO;
}

#pragma mark - Moving/reordering

// Allows the reorder accessory view to optionally be shown for a particular row. By default, the reorder control will be shown only if the datasource implements -tableView:moveRowAtIndexPath:toIndexPath:
//- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
//    if ([self.receiver respondsToSelector:_cmd]) {
//        return [self.receiver tableView:tableView canMoveRowAtIndexPath:indexPath];
//    }
//    return NO;
//}

#pragma mark - Index

- (nullable NSArray<NSString *> *)sectionIndexTitlesForTableView:(PBTableView *)tableView __TVOS_PROHIBITED {
    if ([self.receiver respondsToSelector:_cmd]) {
        return [self.receiver sectionIndexTitlesForTableView:tableView];
    }
    
    if (tableView.indexViewHidden) {
        return nil;
    }
    if (self.sections) {
        return _sectionIndexTitles;
    } else if ([tableView.data isKindOfClass:[PBSection class]]) {
        return [(PBSection *)tableView.data sectionIndexTitles];
    }
    return nil;
}// return list of section titles to display in section index view (e.g. "ABCD...Z#")

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index __TVOS_PROHIBITED {
    if ([self.receiver respondsToSelector:_cmd]) {
        return [self.receiver tableView:tableView sectionForSectionIndexTitle:title atIndex:index];
    }
    
    if (self.sections != nil) {
        for (NSInteger index = 0; index < [self.sections count]; index++) {
            PBSectionMapper *section = [self.sections objectAtIndex:index];
            if ([section.title isEqualToString:title]) {
                return index;
            }
        }
    } else if ([tableView.data isKindOfClass:[PBSection class]]) {
        return [(PBSection *)tableView.data sectionOfTitle:title];
    }
    return 0;
}// tell table which section corresponds to section title/index (e.g. "B",1))

//#pragma mark - Data manipulation - insert and delete support
//
//// After a row has the minus or plus button invoked (based on the UITableViewCellEditingStyle for the cell), the dataSource must commit the change
//// Not called for edit actions using UITableViewRowAction - the action's handler will be invoked instead
//- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
//    if ([self.receiver respondsToSelector:_cmd]) {
//        [self.receiver tableView:tableView commitEditingStyle:editingStyle forRowAtIndexPath:indexPath];
//    }
//}
//
//#pragma mark - Data manipulation - reorder / moving support
//
//- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
//    if ([self.receiver respondsToSelector:_cmd]) {
//        [self.receiver tableView:tableView moveRowAtIndexPath:sourceIndexPath toIndexPath:destinationIndexPath];
//    }
//}

#pragma mark - UICollectionView

- (NSInteger)numberOfSectionsInCollectionView:(PBCollectionView *)collectionView {
    if ([self.receiver respondsToSelector:_cmd]) {
        return [self.receiver numberOfSectionsInCollectionView:collectionView];
    }
    
    [self initRowMapper];
    
    if (self.sections != nil) {
        return [self.sections count];
    } else if (self.row != nil || self.rows != nil) {
        if ([collectionView.data isKindOfClass:[PBSection class]]) {
            return [[(PBSection *)collectionView.data sectionIndexTitles] count];
        }
    }
    return 1;
}

- (NSInteger)collectionView:(PBCollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if ([self.receiver respondsToSelector:_cmd]) {
        NSInteger count = [self.receiver collectionView:collectionView numberOfItemsInSection:section];
        if (count >= 0) {
            return count;
        }
    }
    
    return [self numberOfRowsInSection:section withData:collectionView.data key:collectionView.listKey];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = nil;
    if ([self.receiver respondsToSelector:_cmd]) {
        cell = [self.receiver collectionView:collectionView cellForItemAtIndexPath:indexPath];
        if (cell != nil) {
            return cell;
        }
    }
    
    PBRowMapper *item = [self rowAtIndexPath:indexPath];
    if (![item.viewClass isSubclassOfClass:[UICollectionViewCell class]]) {
        [item setClazz:@"UICollectionViewCell"];
    }
    NSString *itemClazz = NSStringFromClass(item.viewClass);
    if (![_registeredCellClasses containsObject:itemClazz]) {
        // Lazy register reusable item
        UINib *nib = PBNib(item.nib);
        if (nib != nil) {
            [collectionView registerNib:nib forCellWithReuseIdentifier:item.id];
        } else {
            [collectionView registerClass:item.viewClass forCellWithReuseIdentifier:item.id];
        }
        [_registeredCellClasses addObject:itemClazz];
    }
    
    cell = [collectionView dequeueReusableCellWithReuseIdentifier:item.id forIndexPath:indexPath];
    if (item.layoutMapper != nil) {
        [item.layoutMapper renderToView:cell.contentView];
    }
    
    // Init data for cell
    [cell setData:[self dataAtIndexPath:indexPath]];
    [item initDataForView:cell];
    
    return cell;
}

#pragma mark - Helper

- (NSDictionary *)dictionaryByMergingDictionary:(NSDictionary *)oneDictionay withAnother:(NSDictionary *)anotherDictionay
{
    if (![anotherDictionay isKindOfClass:[NSDictionary class]]) {
        id anotherValue = [PBValueParser valueWithString:anotherDictionay];
        if (anotherValue == nil) {
            return nil;
        }
        return oneDictionay;
    }
    
    NSMutableDictionary *mergedDictionary = [NSMutableDictionary dictionary];
    NSMutableDictionary *valuesOnlyInOther = [NSMutableDictionary dictionaryWithDictionary:anotherDictionay];
    for (NSString *key in oneDictionay) {
        id oneValue = [oneDictionay objectForKey:key];
        id otherValue = [anotherDictionay objectForKey:key];
        if (otherValue == nil) {
            otherValue = oneValue;
        } else {
            if ([oneValue isKindOfClass:[NSDictionary class]]) {
                otherValue = [self dictionaryByMergingDictionary:oneValue withAnother:otherValue];
            }
            [valuesOnlyInOther removeObjectForKey:key];
        }
        
        if (otherValue == nil) {
            [mergedDictionary removeObjectForKey:key];
        } else {
            [mergedDictionary setObject:otherValue forKey:key];
        }
    }
    [mergedDictionary setValuesForKeysWithDictionary:valuesOnlyInOther];
    return mergedDictionary;
}

@end
