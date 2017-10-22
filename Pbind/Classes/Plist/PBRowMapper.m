//
//  PBRowMapper.m
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by galen on 15/2/17.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "PBRowMapper.h"
#import "PBInline.h"
#import "PBTableViewCell.h"
#import "PBRowDataSource.h"
#import "PBCollectionView.h"
#import "_PBRowHolder.h"
#import "PBPropertyUtils.h"
#import "_PBRowDataWrapper.h"

static const CGFloat kHeightUnset = -2;

@interface _PBPropertyIndexPath : NSObject

@property (nonatomic, assign) NSInteger targetIndex;
@property (nonatomic, assign) NSInteger keyIndex;
@property (nonatomic, assign) NSInteger repeatCount;

@end

@implementation _PBPropertyIndexPath

@end

@interface UIView (Private)

- (UIView *)viewWithAlias:(NSString *)alias;

@end

@interface PBMapperProperties (Private)

@property (nonatomic, strong) NSMutableDictionary *constants;
@property (nonatomic, strong) NSMutableDictionary *expressions;

@end

@interface PBMapper (Private)

- (void)_mapValuesForKeysWithData:(id)data owner:(UIView *)owner context:(UIView *)context;

@end

@implementation PBRowMapper
{
    NSMutableArray<PBRowActionMapper *> *_editActionMappers;
    NSString *_identifier;
    NSString *_id;
    NSMutableDictionary *_compiledInfos;
}

@synthesize editActionMappers = _editActionMappers;

- (void)setPropertiesWithDictionary:(NSDictionary *)dictionary {
    _estimatedHeight = UITableViewAutomaticDimension;
    _height = UITableViewAutomaticDimension;
    _width = UITableViewAutomaticDimension;
    
    [super setPropertiesWithDictionary:dictionary];
    
    NSString *heightString = [dictionary objectForKey:@"height"];
    if (heightString != nil) {
        _pbFlags.heightExpressive = [_properties isExpressiveForKey:@"height"];
        if (!_pbFlags.heightExpressive) {
            NSArray *components = nil;
            if ([heightString isKindOfClass:[NSString class]]) {
                components = [heightString componentsSeparatedByString:@"@"];
            }
            if (components.count == 2) {
                _height = PBPixelByScale([components[0] floatValue], [components[1] floatValue]);
            } else {
                if (_height == UITableViewAutomaticDimension) {
                    if (_estimatedHeight <= 0) {
                        _estimatedHeight = 44.f; // initialize default estimated height
                    }
                }
            }
        }
    } else {
        _pbFlags.heightUnset = 1;
    }
    
    NSString *widthString = [dictionary objectForKey:@"width"];
    if (widthString != nil) {
        _pbFlags.widthExpressive = [_properties isExpressiveForKey:@"width"];
    } else {
        _pbFlags.widthUnset = 1;
    }
    
    if (_clazz == nil) {
        [self initDefaultViewClass];
    }
}

- (void)initDefaultViewClass {
    if (_style == 0) {
        if ([self.owner isKindOfClass:[UICollectionView class]]) {
            _clazz = @"UICollectionViewCell";
            _viewClass = [UICollectionViewCell class];
        } else {
            _clazz = @"UITableViewCell";
            _viewClass = [UITableViewCell class];
        }
    } else {
        _clazz = @"PBTableViewCell";
        _viewClass = [PBTableViewCell class];
    }
}

- (void)setClazz:(NSString *)clazz {
    _clazz = clazz;
    _viewClass = NSClassFromString(clazz);
    _identifier = nil;
}

- (void)setStyle:(UITableViewCellStyle)style {
    _style = style;
    _identifier = nil;
}

- (void)setId:(NSString *)anId {
    _id = anId;
    _identifier = nil;
}

- (NSString *)id
{
    if (_identifier == nil) {
        NSMutableString *identifier = [[NSMutableString alloc] init];
        if (_id != nil) {
            [identifier appendString:_id];
        } else {
            [identifier appendString:_clazz];
            if (_layout != nil) {
                [identifier appendFormat:@"@%@", _layout];
            }
        }
        
        [identifier appendFormat:@"%d", (int)_style];
        _identifier = identifier;
    }
    return _identifier;
}

- (NSString *)nib
{
    if (_nib == nil) {
        return _clazz;
    }
    return _nib;
}

- (void)initPropertiesForTarget:(UIView *)view {
    [self initPropertiesForTarget:view withViewHolder:view.pb_viewHolder rowHolder:nil];
}

- (void)updatePropertiesForTarget:(UIView *)view withRowHolder:(_PBRowHolder *)rowHolder {
    [self initPropertiesForTarget:view withViewHolder:view.pb_viewHolder rowHolder:rowHolder];
}

- (void)initPropertiesForTarget:(UIView *)view withViewHolder:(_PBViewHolder *)viewHolder rowHolder:(_PBRowHolder *)rowHolder {
    if (_height == UITableViewAutomaticDimension) {
        if ([view respondsToSelector:@selector(setAutoResize:)]) {
            [(id)view setAutoResize:YES];
        }
    }
    
    NSArray *baseProperties = rowHolder.initialProperties;
    if (self.constantPaths != nil) {
        if (baseProperties == nil) {
            for (_PBPropertyPath *property in self.constantPaths) {
                [viewHolder updateProperty:property];
            }
            return;
        }
        
        [viewHolder updateProperties:self.constantPaths withBaseProperties:baseProperties];
        return;
    } else if (baseProperties != nil) {
        for (_PBPropertyPath *property in baseProperties) {
            [viewHolder updateProperty:property];
        }
        return;
    }
    
    [super initPropertiesForTarget:view];
}

- (void)mapPropertiesToTarget:(id)target withData:(id)data owner:(UIView *)owner context:(UIView *)context rowHolder:(_PBRowHolder *)rowHolder {
    if (self.variablePaths != nil) {
        _PBViewHolder *viewHolder = owner.pb_viewHolder;
        if (viewHolder != nil) {
            for (_PBPropertyPath *property in self.variablePaths) {
                [viewHolder mapProperty:property withData:data owner:owner context:context];
            }
        }
        return;
    }
    
    [super mapPropertiesToTarget:target withData:data owner:owner context:context];
}

- (BOOL)hiddenForView:(id)view withData:(id)data
{
    [self _mapValuesForKeysWithData:data owner:view context:view];
    return _hidden;
}

- (CGFloat)heightForView:(id)view withData:(id)data
{
    [self _mapValuesForKeysWithData:data owner:view context:view];
    CGFloat height = _height;
    if (height == UITableViewAutomaticDimension) {
        // Auto layout
        CGFloat additionHeight = 0;
        for (NSInteger index = 1; index <= 20/* 20 tagged views should be enough */; index++) {
            UIView *tagview = [view viewWithTag:index];
            if (tagview == nil) {
                break;
            }
            if ([tagview isKindOfClass:[UILabel class]]) {
                [(UILabel *)tagview setPreferredMaxLayoutWidth:[tagview bounds].size.width];
                if ([[[UIDevice currentDevice] systemVersion] floatValue] < 8.f) {
                    // Compat for iOS7.x
                    [tagview setNeedsLayout];
                    [tagview layoutIfNeeded];
                }
            } else if ([tagview isKindOfClass:[UITextView class]]) {
                additionHeight = MAX(additionHeight, [tagview sizeThatFits:CGSizeMake(tagview.bounds.size.width, FLT_MAX)].height);
            }
        }
        
        if ([view respondsToSelector:@selector(contentView)]) {
            UIView *contentView = [view contentView];
            height = [contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height + .5f;
        } else {
            height = [view systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
        }
        if (height == 0) {
            if ([view respondsToSelector:@selector(contentSize)]) {
                height = [view contentSize].height;
            }
        }
        if (height < additionHeight) {
            height += additionHeight;
        }
    } else if (height == kHeightUnset) {
        height = [view frame].size.height;
        if (height == 0) {
            height = 44;
        }
    }
    return height;
}

- (CGFloat)height {
    CGFloat height = _height;
    if (height == kHeightUnset) {
        height = UITableViewAutomaticDimension;
    }
    return height;
}

- (BOOL)isHeightExpressive {
    return _pbFlags.heightExpressive;
}

- (BOOL)isAutoWidth {
    return _estimatedWidth > 0;
}

- (BOOL)isAutoHeight {
    return _estimatedHeight > 0;
}

- (BOOL)isWidthUnset {
    return _pbFlags.widthUnset;
}

- (BOOL)isHeightUnset {
    return _pbFlags.heightUnset;
}

- (BOOL)isAutofit {
    return [self isAutoHeight] || [self isAutoWidth];
}

- (void)_mapValuesForKeysWithData:(id)data owner:(UIView *)owner context:(UIView *)context
{
    _pbFlags.mapping = YES;
    [super _mapValuesForKeysWithData:data owner:owner context:context];
    _pbFlags.mapping = NO;
}

- (void)setValue:(id)value forKeyPath:(NSString *)keyPath
{
    [super setValue:value forKeyPath:keyPath];
    if (!_pbFlags.mapping && [self.delegate respondsToSelector:@selector(rowMapper:didChangeValue:forKey:)]) {
        [self.delegate rowMapper:self didChangeValue:value forKey:keyPath];
    }
}

- (CGFloat)heightForData:(id)data
{
    if (_pbFlags.hiddenExpressive) {
        [self updateValueForKey:@"hidden" withData:data owner:nil context:nil];
    }
    if (self.hidden) {
        return 0;
    }
    
    if (_pbFlags.heightExpressive) {
        [self updateValueForKey:@"height" withData:data owner:nil context:nil];
    }
    return self.height;
}

- (CGFloat)widthForData:(id)data withRowDataSource:(PBRowDataSource *)dataSource indexPath:(NSIndexPath *)indexPath
{
    return [self metricOfHorizontal:YES withData:data rowDataSource:dataSource indexPath:indexPath];
}

- (CGFloat)heightForData:(id)data withRowDataSource:(PBRowDataSource *)dataSource indexPath:(NSIndexPath *)indexPath
{
    return [self metricOfHorizontal:NO withData:data rowDataSource:dataSource indexPath:indexPath];
}

- (CGFloat)metricOfHorizontal:(BOOL)horizontal withData:(id)data rowDataSource:(PBRowDataSource *)dataSource indexPath:(NSIndexPath *)indexPath
{
    BOOL expressive = horizontal ? _pbFlags.widthExpressive : _pbFlags.heightExpressive;
    if (!_pbFlags.hiddenExpressive) {
        if (self.hidden) {
            return 0;
        } else if (!expressive) {
            return horizontal ? self.width : self.height;
        }
    }
    
    id rowViewWrapper = nil;
    id rowData = [dataSource dataAtIndexPath:indexPath];
    if (rowData != nil) {
        rowViewWrapper = [[_PBRowDataWrapper alloc] initWithData:rowData indexPath:indexPath];
    }
    [self updateValueForKey:@"hidden" withData:data owner:rowViewWrapper context:dataSource.owner];
    if (self.hidden) {
        return 0;
    }
    
    NSString *key = horizontal ? @"width" : @"height";
    if (expressive) {
        [self updateValueForKey:key withData:data owner:rowViewWrapper context:dataSource.owner];
    }
    return horizontal ? self.width : self.height;
}

- (void)setLayout:(NSString *)layout {
    if (_layout != nil && [_layout isEqualToString:layout]) {
        return;
    }
    
    _layout = layout;
    _layoutMapper = [PBLayoutMapper mapperNamed:layout];
    _identifier = nil;
}

- (void)setActions:(NSDictionary *)as {
    
    NSDictionary *a;
    
    a = as[@"willSelect"];
    _willSelectActionMapper   = (a == nil) ? nil : [PBActionMapper mapperWithDictionary:a];
    a = as[@"select"];
    _selectActionMapper       = (a == nil) ? nil : [PBActionMapper mapperWithDictionary:a];
    a = as[@"willDeselect"];
    _willDeselectActionMapper = (a == nil) ? nil : [PBActionMapper mapperWithDictionary:a];
    a = as[@"deselect"];
    _deselectActionMapper     = (a == nil) ? nil : [PBActionMapper mapperWithDictionary:a];
    
    NSArray *edits = as[@"edits"];
    if (edits != nil) {
        _editActionMappers = [NSMutableArray arrayWithCapacity:edits.count];
        for (a in edits) {
            PBRowActionMapper *actionMapper = [PBRowActionMapper mapperWithDictionary:a];
            [_editActionMappers addObject:actionMapper];
        }
    } else {
        a = as[@"delete"];
        if (a != nil) {
            PBRowActionMapper *deleteActionMapper = [PBRowActionMapper mapperWithDictionary:a];
            deleteActionMapper.title = deleteActionMapper.title ?: PBLocalizedString(@"Delete");
            _editActionMappers = [NSMutableArray arrayWithCapacity:1];
            [_editActionMappers addObject:deleteActionMapper];
        } else {
            _editActionMappers = nil;
        }
    }
}

- (UIView *)createView {
    UIView *view = nil;
    
    // Try to instantiate from nib.
    if (self.nib != nil) {
        UINib *nib = PBNib(self.nib);
        if (nib != nil) {
            NSArray *views = [nib instantiateWithOwner:nil options:nil];
            if (views.count > 0) {
                for (id object in views) {
                    if ([object isKindOfClass:[UIView class]]) {
                        view = object;
                        break;
                    }
                }
            }
        }
    }
    
    // Create from the view class.
    if (view == nil) {
        view = [[self.viewClass alloc] init];
        if (self.layoutMapper != nil) {
            [self.layoutMapper renderToView:view];
        }
    }
    
    return view;
}

- (void)unbind {
    [super unbind];
    
    if (_layoutMapper != nil) {
        [_layoutMapper unbind];
    }
    
    if (_willSelectActionMapper != nil) {
        [_willSelectActionMapper unbind];
    }
    if (_selectActionMapper != nil) {
        [_selectActionMapper unbind];
    }
    if (_willDeselectActionMapper != nil) {
        [_willDeselectActionMapper unbind];
    }
    if (_deselectActionMapper != nil) {
        [_deselectActionMapper unbind];
    }
    if (_editActionMappers != nil) {
        for (PBMapper *mapper in _editActionMappers) {
            [mapper unbind];
        }
    }
}

#pragma mark - JIT

- (void)collectPropertyPaths:(NSMutableArray *)paths holders:(NSMutableArray<_PBTargetHolder *> *)targetHolders withProperties:(PBMapperProperties *)properties expressive:(BOOL)expressive rootObject:(id)rootObject alias:(NSString *)alias outletKey:(NSString *)outletKey {
    NSDictionary *values = expressive ? properties.expressions : properties.constants;
    for (NSString *keyPath in values) {
        id target;
        NSString *prefixKey, *suffixKey;
        [self getTarget:&target prefix:&prefixKey suffix:&suffixKey fromKeyPath:keyPath ofObject:rootObject];
        if (target == nil || suffixKey == nil) {
            continue;
        }
        
        // Add target
        _PBTargetHolder *targetHolder;
        NSInteger targetIndex = NSNotFound;
        for (NSInteger index = 0; index < targetHolders.count; index++) {
            if ([targetHolders objectAtIndex:index].target == target) {
                targetIndex = index;
                break;
            }
        }
        if (targetIndex == NSNotFound) {
            targetIndex = targetHolders.count;
            targetHolder = [[_PBTargetHolder alloc] init];
            targetHolder.target = target;
            targetHolder.keyPath = prefixKey;
            targetHolder.parentAlias = alias;
            targetHolder.parentOutletKey = outletKey;
            targetHolder.properties = [[NSMutableArray alloc] init];
            [targetHolders addObject:targetHolder];
        } else {
            targetHolder = [targetHolders objectAtIndex:targetIndex];
        }
        
        // Add meta
        NSInteger keyIndex = NSNotFound;
        for (NSInteger index = 0; index < targetHolder.properties.count; index++) {
            if ([[targetHolder.properties objectAtIndex:index].key isEqualToString:suffixKey]) {
                keyIndex = index;
                break;
            }
        }
        if (keyIndex == NSNotFound) {
            keyIndex = targetHolder.properties.count;
            _PBMetaProperty *property = [[_PBMetaProperty alloc] initWithTarget:target key:suffixKey];
            [targetHolder.properties addObject:property];
        }
        
        _PBPropertyPath *path = nil;
        for (_PBPropertyPath *temp in paths) {
            if (temp.targetIndex == targetIndex && temp.keyIndex == keyIndex) {
                path = temp;
                break;
            }
        }
        
        if (path == nil) {
            path = [[_PBPropertyPath alloc] init];
            path.targetIndex = targetIndex;
            path.keyIndex = keyIndex;
            [paths addObject:path];
        }
        
        if (expressive) {
            path.expression = [values objectForKey:keyPath];
        } else {
            path.value = [values objectForKey:keyPath];
        }
    }
}

- (NSArray *)constantPaths {
    if (_compiledInfos == nil) {
        return nil;
    }
    
    _PBRowCompiledInfo *compiledInfo = [_compiledInfos objectForKey:self.id];
    return compiledInfo.constantPaths;
}

- (NSArray *)variablePaths {
    if (_compiledInfos == nil) {
        return nil;
    }
    
    _PBRowCompiledInfo *compiledInfo = [_compiledInfos objectForKey:self.id];
    return compiledInfo.variablePaths;
}

- (void)compileWithHolder:(_PBRowHolder *)holder rows:(NSArray *)rows owner:(UIView *)owner {
    if (holder.targets == nil) {
        NSMutableArray<_PBTargetHolder *> *targetHolders = [[NSMutableArray alloc] init];
        NSMutableArray *allPaths = [[NSMutableArray alloc] init];
        NSInteger repeatRowCount = 0;
        NSString *identifier = self.id;
        
        for (PBRowMapper *row in rows) {
            NSString *rowIdentifier = row.id;
            if (![rowIdentifier isEqualToString:identifier]) {
                continue;
            }
            
            repeatRowCount++;
            
            NSMutableArray *constantPaths = [[NSMutableArray alloc] init];
            NSMutableArray *variablePaths = [[NSMutableArray alloc] init];
            PBMapperProperties *properties = row->_viewProperties;
            [self collectPropertyPaths:constantPaths holders:targetHolders withProperties:properties expressive:NO rootObject:owner alias:nil outletKey:nil];
            [self collectPropertyPaths:variablePaths holders:targetHolders withProperties:properties expressive:YES rootObject:owner alias:nil outletKey:nil];
            
            // Aliases
            NSDictionary *aliasProperties = row->_aliasProperties;
            for (NSString *key in aliasProperties) {
                UIView *subview = [owner viewWithAlias:key];
                PBMapperProperties *subproperties = [aliasProperties objectForKey:key];
                [self collectPropertyPaths:constantPaths holders:targetHolders withProperties:subproperties expressive:NO rootObject:subview alias:key outletKey:nil];
                [self collectPropertyPaths:variablePaths holders:targetHolders withProperties:subproperties expressive:YES rootObject:subview alias:key outletKey:nil];
            }
            
            // Outlets
            NSDictionary *outletProperties = row->_outletProperties;
            for (NSString *key in outletProperties) {
                UIView *subview = [PBPropertyUtils valueForKey:key ofObject:owner failure:nil];
                if (subview == nil) {
                    continue;
                }
                
                PBMapperProperties *subproperties = [outletProperties objectForKey:key];
                [self collectPropertyPaths:constantPaths holders:targetHolders withProperties:subproperties expressive:NO rootObject:subview alias:nil outletKey:key];
                [self collectPropertyPaths:variablePaths holders:targetHolders withProperties:subproperties expressive:YES rootObject:subview alias:nil outletKey:key];
            }
            
            if (row->_compiledInfos == nil) {
                row->_compiledInfos = [[NSMutableDictionary alloc] init];
            }
            _PBRowCompiledInfo *compiledInfo = [[_PBRowCompiledInfo alloc] init];
            compiledInfo.identifier = rowIdentifier;
            compiledInfo.constantPaths = constantPaths;
            compiledInfo.variablePaths = variablePaths;
            [row->_compiledInfos setObject:compiledInfo forKey:rowIdentifier];
            
            for (_PBPropertyPath *path in constantPaths) {
                BOOL added = NO;
                for (_PBPropertyIndexPath *indexPath in allPaths) {
                    if (indexPath.targetIndex == path.targetIndex && indexPath.keyIndex == path.keyIndex) {
                        indexPath.repeatCount++;
                        added = YES;
                        break;
                    }
                }
                if (!added) {
                    _PBPropertyIndexPath *indexPath = [[_PBPropertyIndexPath alloc] init];
                    indexPath.targetIndex = path.targetIndex;
                    indexPath.keyIndex = path.keyIndex;
                    indexPath.repeatCount = 1;
                    [allPaths addObject:indexPath];
                }
            }
            for (_PBPropertyPath *path in variablePaths) {
                BOOL added = NO;
                for (_PBPropertyIndexPath *indexPath in allPaths) {
                    if (indexPath.targetIndex == path.targetIndex && indexPath.keyIndex == path.keyIndex) {
                        indexPath.repeatCount++;
                        added = YES;
                        break;
                    }
                }
                if (!added) {
                    _PBPropertyIndexPath *indexPath = [[_PBPropertyIndexPath alloc] init];
                    indexPath.targetIndex = path.targetIndex;
                    indexPath.keyIndex = path.keyIndex;
                    indexPath.repeatCount = 1;
                    [allPaths addObject:indexPath];
                }
            }
        }
        
        NSMutableArray *initialProperties = [[NSMutableArray alloc] init];
        for (_PBPropertyIndexPath *path in allPaths) {
            if (path.repeatCount == repeatRowCount) {
                // No need to record the value which would be rewrite by every one
                continue;
            }
            
            _PBTargetHolder *targetHolder = [targetHolders objectAtIndex:path.targetIndex];
            _PBMetaProperty *property = [targetHolder.properties objectAtIndex:path.keyIndex];
            id value = [property valueOfTarget:targetHolder.target];
            
            _PBPropertyPath *meta = [[_PBPropertyPath alloc] init];
            meta.targetIndex = path.targetIndex;
            meta.keyIndex = path.keyIndex;
            meta.value = value;
            [initialProperties addObject:meta];
        }
        holder.initialProperties = initialProperties;
        
        _PBViewHolder *viewHolder = [[_PBViewHolder alloc] init];
        viewHolder.targets = targetHolders;
        owner.pb_viewHolder = viewHolder;
        
        NSMutableArray *copyTargets = [NSMutableArray arrayWithCapacity:targetHolders.count];
        for (_PBTargetHolder *temp in targetHolders) {
            _PBTargetHolder *copy = [[_PBTargetHolder alloc] init];
            copy.keyPath = temp.keyPath;
            copy.parentAlias = temp.parentAlias;
            copy.parentOutletKey = temp.parentOutletKey;
            copy.properties = temp.properties;
            [copyTargets addObject:copy];
        }
        holder.targets = copyTargets;
        return;
    }
    
    if (owner.pb_viewHolder == nil) {
        _PBViewHolder *viewHolder = [[_PBViewHolder alloc] init];
        NSMutableArray *copyTargetHolders = [NSMutableArray arrayWithCapacity:holder.targets.count];
        for (_PBTargetHolder *temp in holder.targets) {
            _PBTargetHolder *copy = [temp copyWithOwner:owner];
            [copyTargetHolders addObject:copy];
        }
        viewHolder.targets = copyTargetHolders;
        owner.pb_viewHolder = viewHolder;
    }
}

- (void)getTarget:(id *)outTarget prefix:(NSString **)outPrefix suffix:(NSString **)outSuffix fromKeyPath:(NSString *)keyPath ofObject:(id)object {
    NSArray *keys = [keyPath componentsSeparatedByString:@"."];
    if (keys.count <= 1) {
        *outTarget = object;
        *outPrefix = nil;
        *outSuffix = keyPath;
        return;
    }
    
    id target = object;
    NSInteger index = 0;
    for (; index < keys.count - 1; index++) {
        NSString *key = [keys objectAtIndex:index];
        target = [self valueForKey:key ofObject:target];
        if (target == nil) {
            return;
        }
    }
    
    *outTarget = target;
    *outSuffix = [keys objectAtIndex:index];
    NSMutableArray *temp = [NSMutableArray arrayWithArray:keys];
    [temp removeLastObject];
    *outPrefix = [temp componentsJoinedByString:@"."];
}

- (id)valueForKey:(NSString *)key ofObject:(id)object {
    char initial = [key characterAtIndex:0];
    if (initial == '@') {
        NSString *alias = [key substringFromIndex:1];
        return [object viewWithAlias:alias];
    } else {
        return [PBPropertyUtils valueForKey:key ofObject:object failure:nil];
    }
}

@end
