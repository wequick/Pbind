//
//  PBRowMapper.m
//  Pbind
//
//  Created by galen on 15/2/17.
//  Copyright (c) 2015年 galen. All rights reserved.
//

#import "PBRowMapper.h"
#import "Pbind+API.h"
#import "PBTableViewCell.h"

static const CGFloat kHeightUnset = -2;

@interface PBMapper (Private)

- (void)_mapValuesForKeysWithData:(id)data andView:(UIView *)view;

@end

@implementation PBRowMapper

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    if (self = [super initWithDictionary:dictionary]) {
        if ([dictionary objectForKey:@"estimatedHeight"] == nil) {
            _estimatedHeight = UITableViewAutomaticDimension;
        }
        
        NSString *heightString = [dictionary objectForKey:@"height"];
        if (heightString == nil) {
            _height = kHeightUnset; // default as automatic
        } else {
            _pbFlags.heightExpressive = [_properties isExpressiveForKey:@"height"];
            if (!_pbFlags.heightExpressive) {
                NSArray *components = nil;
                if ([heightString isKindOfClass:[NSString class]]) {
                    components = [heightString componentsSeparatedByString:@"@"];
                }
                if (components.count == 2) {
                    _height = PBValue2([components[0] floatValue], [components[1] floatValue]);
                } else {
                    if (_height == UITableViewAutomaticDimension) {
                        if (_estimatedHeight <= 0) {
                            _estimatedHeight = 44.f; // initialize default estimated height
                        }
                    } else if (_height > 0) {
                        _height = PBValue(_height);
                    }
                }
            }
        }
        
        _pbFlags.hiddenExpressive = [_properties isExpressiveForKey:@"hidden"];
        
        if (_clazz == nil) {
            if (_style == 0) {
                _clazz = @"UITableViewCell";
                _viewClass = [UITableViewCell class];
            } else {
                _clazz = @"PBTableViewCell";
                _viewClass = [PBTableViewCell class];
            }
        }
    }
    return self;
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

- (BOOL)hiddenForView:(id)view withData:(id)data
{
    [self _mapValuesForKeysWithData:data andView:view];
    return _hidden;
}

- (CGFloat)heightForView:(id)view withData:(id)data
{
    [self _mapValuesForKeysWithData:data andView:view];
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
        
        if (/*[[[UIDevice currentDevice] systemVersion] floatValue] < 8.f && */[view isKindOfClass:[UITableViewCell class]]) {
            height = [[(UITableViewCell *)view contentView] systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height + .5f;
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

- (void)_mapValuesForKeysWithData:(id)data andView:(UIView *)view
{
    _pbFlags.mapping = YES;
    [super _mapValuesForKeysWithData:data andView:view];
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
        [self updateValueForKey:@"hidden" withData:data andView:nil];
    }
    if (self.hidden) {
        return 0;
    }
    
    if (_pbFlags.heightExpressive) {
        [self updateValueForKey:@"height" withData:data andView:nil];
    }
    return self.height;
}

- (CGFloat)heightForData:(id)data rowDataSource:(id<PBRowDataSource>)dataSource atIndexPath:(NSIndexPath *)indexPath
{
    if (!_pbFlags.hiddenExpressive) {
        if (self.hidden) {
            return 0;
        } else if (!_pbFlags.heightExpressive) {
            return self.height;
        }
    }
    
    id rowViewWrapper;
    id rowData = [dataSource dataAtIndexPath:indexPath];
    if (rowData != nil) {
        rowViewWrapper = @{@"data": rowData};
    }
    [self updateValueForKey:@"hidden" withData:data andView:rowData];
    if (self.hidden) {
        return 0;
    }
    
    if (_pbFlags.heightExpressive) {
        [self updateValueForKey:@"height" withData:data andView:rowData];
    }
    return self.height;
}

@end
