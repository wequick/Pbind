//
//  PBScrollView.h
//  Pbind
//
//  Created by galen on 15/3/1.
//  Copyright (c) 2015年 galen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PBRowMapper.h"
#import "PBMessageInterceptor.h"

@interface PBScrollView : UIScrollView <UIScrollViewDelegate, PBRowMapperDelegate>
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
    NSMutableArray *_rowViews;
    NSArray *_rowMappers;
    UIView *_footerView;
    NSMutableArray *_rowHeights;
    CGFloat _statusBarHeight;
}

@property (nonatomic, strong) id data;
@property (nonatomic, strong) NSArray *rows; // for plist, parse as `PRRowMapper'
@property (nonatomic, strong) NSDictionary *row; // for plist, parse as `PRRowMapper'

@property (nonatomic, assign, getter=isHorizontal) BOOL horizontal; // default is NO.
@property (nonatomic, assign, getter=isAutoResize) BOOL autoResize; // default is NO.
@property (nonatomic, assign, getter=isAnimatedOnRendering) BOOL animatedOnRendering; // default is YES.
@property (nonatomic, assign, getter=isAnimatedOnValueChanged) BOOL animatedOnValueChanged; // default is YES.

- (void)config;

- (UIView *)viewForRowAtIndex:(NSInteger)index;
- (NSInteger)indexForView:(UIView *)view;
- (NSInteger)indexForRowAtPoint:(CGPoint)point;
- (void)reloadRowAtIndexes:(NSIndexSet *)indexes animated:(BOOL)animated;

- (void)reloadData;

@end
