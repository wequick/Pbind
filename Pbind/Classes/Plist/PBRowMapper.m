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
#import "_PBRowDataWrapper.h"

static const CGFloat kHeightUnset = -2;

@interface PBMapper (Private)

- (void)_mapValuesForKeysWithData:(id)data owner:(UIView *)owner context:(UIView *)context;

@end

@implementation PBRowMapper
{
    NSMutableArray<PBRowActionMapper *> *_editActionMappers;
}

@synthesize editActionMappers = _editActionMappers;

- (void)setPropertiesWithDictionary:(NSDictionary *)dictionary {
    _estimatedWidth = UITableViewAutomaticDimension;
    _estimatedHeight = UITableViewAutomaticDimension;
    _height = UITableViewAutomaticDimension;
    _width = UITableViewAutomaticDimension;
    
    [super setPropertiesWithDictionary:dictionary];
    
    NSString *heightString = [dictionary objectForKey:@"height"];
    if (heightString != nil) {
        _pbFlags.heightExpressive = [_properties isExpressiveForKey:@"height"];
        if (!_pbFlags.heightExpressive) {
            if (_height == 0 && [heightString isKindOfClass:[NSString class]] && [heightString hasPrefix:@"~"]) {
                // TODO: PBValueParser parse `~number` to constant ahead
                _height = PBPixelFromString(heightString);
            }
            
            if (_height == UITableViewAutomaticDimension) {
                if (_estimatedHeight <= 0) {
                    _estimatedHeight = 44.f; // initialize default estimated height
                }
            } else if (_height > 0) {
                _height = PBValue(_height);
            }
        }
    } else {
        _pbFlags.heightUnset = 1;
    }
    
    NSString *widthString = [dictionary objectForKey:@"width"];
    if (widthString != nil) {
        _pbFlags.widthExpressive = [_properties isExpressiveForKey:@"width"];
        if (!_pbFlags.widthExpressive) {
            NSArray *components = nil;
            if ([heightString isKindOfClass:[NSString class]]) {
                components = [heightString componentsSeparatedByString:@"@"];
            }
            if (components.count == 2) {
                _width = PBPixelByScale([components[0] floatValue], [components[1] floatValue]);
            } else {
                if (_width == UITableViewAutomaticDimension) {
                    if (_estimatedWidth <= 0) {
                        _estimatedWidth = 44.f; // initialize default estimated height
                    }
                } else if (_width > 0) {
                    _width = PBValue(_width);
                }
            }
        }
    } else {
        _pbFlags.widthUnset = 1;
    }
    
    _pbFlags.dataUnset = [dictionary objectForKey:@"data"] == nil;
    
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
}

- (NSString *)id
{
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
    return identifier;
}

- (NSString *)nib
{
    if (_nib == nil) {
        return _clazz;
    }
    return _nib;
}

- (void)initPropertiesForTarget:(UIView *)view {
    if (_height == UITableViewAutomaticDimension) {
        if ([view respondsToSelector:@selector(setAutoResize:)]) {
            [(id)view setAutoResize:YES];
        }
    }
    [super initPropertiesForTarget:view];
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

- (BOOL)isDataUnset {
    return _pbFlags.dataUnset;
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

@end
