//
//  UIView+PBLayout.h
//  Pbind
//
//  Created by galen on 15/3/8.
//  Copyright (c) 2015年 galen. All rights reserved.
//

#ifndef UIVIEW_PRLAYOUT
#define UIVIEW_PRLAYOUT

#import <UIKit/UIKit.h>

@interface UIView (PBLayout)

@property (nonatomic, strong) NSDictionary *PBConstantProperties;
@property (nonatomic, strong) NSDictionary *PBDynamicProperties;
@property (nonatomic, strong) NSMutableDictionary *PBAutoheightSubviews;
@property (nonatomic, strong) NSNumber *PBAutoheightSubviewMaxDepth;
@property (nonatomic, strong) NSArray *PBBindingKeyPaths;

@property (nonatomic, strong) NSArray *visualFormats; // visual format language

- (void)pb_initData; // Init constant properties
- (void)pb_mapData:(id)data; // Init dynamic properties by data
- (void)pb_initConstraintForAutoheight;

+ (UIView *)viewWithLayout:(NSString *)layout bundle:(NSBundle *)bundle;

@end

UIKIT_EXTERN NSString *const PBViewWillRemoveFromSuperviewNotification;
UIKIT_EXTERN NSString *const PBViewDidChangeSizeNotification;

#endif
