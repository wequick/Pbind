//
//  PBScrollView.h
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by galen on 15/3/1.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import <UIKit/UIKit.h>
#import "PBRowMapper.h"
#import "PBMessageInterceptor.h"
#import "PBViewResizingDelegate.h"
#import "PBDataFetching.h"

/**
 The PBScrollView is one of the base components of Pbind. An instance of PBScrollView provides the ability of configuring a group of row views in linear layout.
 */
@interface PBScrollView : UIScrollView <UIScrollViewDelegate, PBRowMapperDelegate, PBViewResizingDelegate, PBDataFetching>
{
    struct {
        unsigned int deallocing:1;
        unsigned int needsReloadData:1;
        unsigned int horizontal:1;
        unsigned int autoResize:1;
        unsigned int animatedOnRendering:1;
        unsigned int animatedOnValueChanged:1;
    } _pbFlags;
    PBMessageInterceptor *_delegateInterceptor;
    PBRowMapper *_rowMapper;
    NSMutableArray *_rowMappers;
    NSMutableArray *_rowViews;
    NSMutableSet *_footerViews;
    NSMutableArray *_rowHeights;
    CGFloat _statusBarHeight;
    CGFloat _contentHeight;
    CGFloat _footerHeight;
}

@property (nonatomic, strong) id data;
@property (nonatomic, strong) NSArray *rows; // for plist, parse as `PRRowMapper'
@property (nonatomic, strong) NSDictionary *row; // for plist, parse as `PRRowMapper'

@property (nonatomic, assign, getter=isHorizontal) BOOL horizontal; // default is NO.
@property (nonatomic, assign, getter=isAutoResize) BOOL autoResize; // default is NO.
@property (nonatomic, assign, getter=isAnimatedOnRendering) BOOL animatedOnRendering; // default is YES.
@property (nonatomic, assign, getter=isAnimatedOnValueChanged) BOOL animatedOnValueChanged; // default is YES.

@property (nonatomic, weak) id<PBViewResizingDelegate> resizingDelegate;

- (void)config;

- (UIView *)viewForRowAtIndex:(NSInteger)index;
- (NSInteger)indexForView:(UIView *)view;
- (NSInteger)indexForRowAtPoint:(CGPoint)point;
- (void)reloadRowAtIndexes:(NSIndexSet *)indexes animated:(BOOL)animated;

- (void)reloadData;

@end
