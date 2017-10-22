//
//  PBRowMapper.h
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by galen on 15/2/17.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import <Foundation/Foundation.h>
#import "PBMapper.h"
#import "PBLayoutMapper.h"
#import "PBRowActionMapper.h"

@class PBRowDataSource;
@class _PBRowHolder;

//______________________________________________________________________________
// PBRowMapperDelegate
@class PBRowMapper;
@protocol PBRowMapperDelegate <NSObject>

- (void)rowMapper:(PBRowMapper *)mapper didChangeValue:(id)value forKey:(NSString *)key;

@end

//______________________________________________________________________________

typedef NS_ENUM(NSUInteger, PBRowFloating)
{
    PBRowFloatingNone = 0,
    PBRowFloatingTop,       // :ft
    PBRowFloatingLeft,      // :fl
    PBRowFloatingBottom,    // :fb
    PBRowFloatingRight      // :fr
};

/**
 The PBRowMapper is one of the base components of Pbind.
 
 @dicussion It provides the ability of configuring row elements like:
 
 - UITableViewCell
 - UICollectionViewCell
 
 for PBTableView, PBCollectionView and PBScrollView.
 */
@interface PBRowMapper : PBMapper
{
    struct {
        unsigned char mapping:1;
        unsigned char widthExpressive:1;
        unsigned char heightExpressive:1;
        unsigned char hiddenExpressive:1;
        unsigned char widthUnset:1;
        unsigned char heightUnset:1;
    } _pbFlags;
}

#pragma mark - Creating
///=============================================================================
/// @name Creating
///=============================================================================

/** The class name of the view in the row. Default is UITableViewCell */
@property (nonatomic, strong) NSString *clazz;

/** The xib file name for the view in the row. Default to `clazz` */
@property (nonatomic, strong) NSString *nib;

/**
 The style for the cell in the row.
 
 @discussion If set, the default `clazz` turns to be PBTalbViewCell.
 */
@property (nonatomic, assign) UITableViewCellStyle style;

/**
 The identifier for the view in the row.
 
 @discussion This property is only for PBTableView and PBCollectionView
 */
@property (nonatomic, strong) NSString *id;

/**
 The layout file to create subviews and add to the view in the row.
 
 @discussion The layout file with Plist will be parsed by PBLayoutMapper.
 */
@property (nonatomic, strong) NSString *layout;

/**
 The parent view alias name.
 
 @discussion This is used for `PBLayoutMapper`.
 */
@property (nonatomic, strong) NSString *parent;

/**
 The order adds to parent view, lower order will be added firstly.
 */
@property (nonatomic, assign) NSInteger order;

#pragma mark - Styling
///=============================================================================
/// @name Styling
///=============================================================================

/**
 The height for the row. Default is -1 (auto-height).
 */
@property (nonatomic, assign) CGFloat height;

/**
 The estimated height for the row. Default is -1 (do not estimated).
 
 @discussion This property is only for PBTableView and PBCollectionView.
 If the `height` is explicitly set as `:auto`(-1) then estimates the height as 44.
 */
@property (nonatomic, assign) CGFloat estimatedHeight;

/**
 The width for the item(UICollectionViewCell). Default is -1 (auto-width).
 
 @discussion This property if only for PBCollectionView.
 */
@property (nonatomic, assign) CGFloat width;

/**
 The estimated width for the item. Default is -1 (do not estimated).
 
 @discussion This property is only for PBCollectionView.
 If the `width` is explicitly set as `:auto`(-1) then estimates the width as 44.
 */
@property (nonatomic, assign) CGFloat estimatedWidth;

/** Whether the `width' is explicitly set as `:auto' */
- (BOOL)isAutoWidth;

/** Whether the `height' is explicitly set as `:auto' */
- (BOOL)isAutoHeight;

/** `isAutoWidth' or `isAutoHeight' */
- (BOOL)isAutofit;

/**
 The additional height from with. 
 
    item.size.height = item.size.width + additionalHeight;
 
 @discussion Takes effect while the section specified `numberOfColumns`.
 */
@property (nonatomic, assign) CGFloat additionalHeight;

/**
 The size ratio.
 
    item.size.ratio = item.size.width / ratio + additionalHeight;
 
 @discussion Takes effect while the section specified `numberOfColumns`.
 */
@property (nonatomic, assign) CGFloat ratio;

/**
 Whether hides the row. Default is NO.
 
 @discussion For PBTableView and PBCollection, this will cause the delegate method
 `heightForCell` returns 0. For PBScrollView we just set adjust the frame of the view in the row.
 */
@property (nonatomic, assign) BOOL hidden;

/**
 The outer margin for the row.
 
 @discussion This property is only for PBScrollView.
 The function of margin is same as the CSS margin.
 */
@property (nonatomic, assign) UIEdgeInsets margin;

/**
 The inner margin for the row.
 
 @discussion This property is only for PBScrollView.
 The function of padding is same as the CSS padding.
 */
@property (nonatomic, assign) UIEdgeInsets padding;

/**
 The floating style for the row.
 
 @discussion This property is only for PBScrollView.
 */
@property (nonatomic, assign) PBRowFloating floating;

#pragma mark - Behavior
///=============================================================================
/// @name Behavior
///=============================================================================

@property (nonatomic, assign) id<PBRowMapperDelegate> delegate;

/**
 The actions for row, each value is a dictionary which parse as `PBActionMapper'.
 
 @discussion accept keys:
 
 - willSelect   : the cell willSelect action
 - select       : the cell didSelect action
 - willDeselect : the cell willDeselect action
 - deselect     : the cell didDeselect action
 - delete       : the editing(swipe-to-left) cell delete button action
 - edits        : the editing(swipe-to-left) cell custom edit actions
 */
@property (nonatomic, strong) NSDictionary *actions;

#pragma mark - Caching
///=============================================================================
/// @name Caching
///=============================================================================

/** The mapper created from `layout` */
@property (nonatomic, strong) PBLayoutMapper *layoutMapper;

/** The class initialized from `clazz` */
@property (nonatomic, assign) Class viewClass;

/** The mapper created from `actions`.willSelect */
@property (nonatomic, strong) PBActionMapper *willSelectActionMapper;

/** The mapper created from `actions`.select */
@property (nonatomic, strong) PBActionMapper *selectActionMapper;

/** The mapper created from `actions`.willDeselect */
@property (nonatomic, strong) PBActionMapper *willDeselectActionMapper;

/** The mapper created from `actions`.deselect */
@property (nonatomic, strong) PBActionMapper *deselectActionMapper;

/**
 The action mappers which map to UITableViewRowAction for editing UITableViewCell.
 
 @discussion If the `actions' were specified, use it, otherwise use `deleteAction' if there was.
 */
@property (nonatomic, strong) NSArray<PBRowActionMapper *> *editActionMappers;

/**
 Whether the height is defined by an expression.
 */
@property (nonatomic, assign, readonly, getter=isHeightExpressive) BOOL heightExpressive;

/**
 Whether the height is undefined.
 */
@property (nonatomic, assign, readonly, getter=isHeightUnset) BOOL heightUnset;

/**
 Whether the width is undefined.
 */
@property (nonatomic, assign, readonly, getter=isWidthUnset) BOOL widthUnset;

/** The view alias */
@property (nonatomic, strong) NSString *alias;

- (BOOL)hiddenForView:(id)view withData:(id)data;
- (CGFloat)heightForView:(id)view withData:(id)data;

- (CGFloat)heightForData:(id)data withRowDataSource:(PBRowDataSource *)dataSource indexPath:(NSIndexPath *)indexPath;
- (CGFloat)heightForData:(id)data;

- (CGFloat)widthForData:(id)data withRowDataSource:(PBRowDataSource *)dataSource indexPath:(NSIndexPath *)indexPath;

- (UIView *)createView;

#pragma mark - JIT
///=============================================================================
/// @name JIT
///=============================================================================

- (void)compileWithHolder:(_PBRowHolder *)holder rows:(NSSet *)rows owner:(UIView *)owner;

- (void)updatePropertiesForTarget:(id)target withRowHolder:(_PBRowHolder *)rowHolder;

- (void)mapPropertiesToTarget:(id)target withData:(id)data owner:(UIView *)owner context:(UIView *)context rowHolder:(_PBRowHolder *)rowHolder;

@end
