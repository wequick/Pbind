//
//  PBRowMapper.m
//  Pbind
//
//  Created by galen on 15/2/17.
//  Copyright (c) 2015年 galen. All rights reserved.
//

#import "PBRowMapper.h"
#import "UIView+PBLayout.h"
#import "Pbind+API.h"

static const CGFloat kHeightUnset = -2;

@interface PBMapper (Private)

- (void)_mapValuesForKeysWithData:(id)data andView:(UIView *)view;

@end

@implementation PBRowMapper

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    if (self = [super initWithDictionary:dictionary]) {
        if (![[dictionary allKeys] containsObject:@"height"]) {
            _height = kHeightUnset; // default as automatic
        } else {
            if (![self isHeightExpressive]) {
                if (_height == UITableViewAutomaticDimension) {
                    if (_estimatedHeight == 0) {
                        _estimatedHeight = 44.f; // initialize default estimated height
                    }
                } else if (_height > 0) {
                    _height = PBValue(_height);
                }
            }
        }
        
        if (_clazz == nil) {
            _clazz = @"UITableViewCell";
            _viewClass = [UITableViewCell class];
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
    if (_id == nil) {
        return [NSString stringWithFormat:@"%@%d", _clazz, (int)_style];
    }
    return [NSString stringWithFormat:@"%@%d", _id, (int)_style];
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
    [self->_properties isExpressiveForKey:@"height"];
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

@end
