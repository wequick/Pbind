//
//  UIView+LSLayout.h
//  Less
//
//  Created by galen on 15/3/8.
//  Copyright (c) 2015年 galen. All rights reserved.
//

#ifndef UIVIEW_LSLAYOUT
#define UIVIEW_LSLAYOUT

#import <UIKit/UIKit.h>

@interface UIView (LSLayout)

@property (nonatomic, strong) NSDictionary *LSConstantProperties;
@property (nonatomic, strong) NSDictionary *LSDynamicProperties;
@property (nonatomic, strong) NSMutableDictionary *LSAutoheightSubviews;
@property (nonatomic, strong) NSNumber *LSAutoheightSubviewMaxDepth;
@property (nonatomic, strong) NSArray *LSBindingKeyPaths;

@property (nonatomic, strong) NSArray *visualFormats; // visual format language

- (void)pr_initData; // Init constant properties
- (void)pr_mapData:(id)data; // Init dynamic properties by data
- (void)pr_initConstraintForAutoheight;

+ (UIView *)viewWithLayout:(NSString *)layout bundle:(NSBundle *)bundle;

@end

UIKIT_EXTERN NSString *const LSViewWillRemoveFromSuperviewNotification;
UIKIT_EXTERN NSString *const LSViewDidChangeSizeNotification;

#endif
