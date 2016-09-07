//
//  LSScrollView.h
//  Less
//
//  Created by galen on 15/3/1.
//  Copyright (c) 2015年 galen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LSRowMapper.h"
#import "LSMessageInterceptor.h"

@interface LSScrollView : UIScrollView <UIScrollViewDelegate, LSRowMapperDelegate>
{
    struct {
        unsigned int deallocing:1;
        unsigned int needsReloadData:1;
        unsigned int horizontal:1;
        unsigned int autoResize:1;
        unsigned int animatedOnRendering:1;
        unsigned int animatedOnValueChanged:1;
    } _lsFlags;
    LSMessageInterceptor *_delegateInterceptor;
    LSRowMapper *_rowMapper;
    NSMutableArray *_rowViews;
    NSArray *_rowMappers;
    UIView *_headerView;
    UIView *_footerView;
    UIView *_wrapperContentView;
    NSMutableArray *_heightConstraints;
    CGFloat _statusBarHeight;
}

@property (nonatomic, strong) id data;
@property (nonatomic, strong) NSArray *rows; // for plist, parse as `LSRowMapper'
@property (nonatomic, strong) NSDictionary *row; // for plist, parse as `LSRowMapper'

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
