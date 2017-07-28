//
//  PBLayoutMapper.h
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by Galen Lin on 2016/11/1.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "PBMapper.h"

/**
 The PBLayoutMapper is one of the base component of Pbind.
 
 @discussion We use this mapper to render the layout from Plist by Auto-layout constraint formats.
 */
@interface PBLayoutMapper : PBMapper

#pragma mark - Constraint
///=============================================================================
/// @name Constraint
///=============================================================================

/**
 The subviews to create.
 
 @discussion Each view(dictionary) is parsed to a `PBRowMapper'.
 */
@property (nonatomic, strong) NSDictionary *views;

/**
 The metrics for auto-layout.
 
 @discussion Each metric will be re-calculated by `PBPixel()'.
 */
@property (nonatomic, strong) NSDictionary *metrics;

/**
 The official format constraints for auto-layout. Using visual format language.
 */
@property (nonatomic, strong) NSArray *formats;

/**
 The Pbind-way format constraints for auto-layout.
 
 @discussion Support constraints like Masonry but more convinent:
 
 - Explicit format                  : icon.width=icon.height*2+20@1000
 - Aspect ratio format              : R:icon=4:3
 - Edge insets format               : E:inner={20,30,20,30}
 - Merge center horizontally format : C:|-left-[/[label1-label2]/(==height)]-icon-|
 - Merge center vertically format   : M:|-left-[/[label1-label2]/(==width)]-icon-|
 */
@property (nonatomic, strong) NSArray *constraints;

#pragma mark - Caching
///=============================================================================
/// @name Caching
///=============================================================================

/** The layout name */
@property (nonatomic, strong) NSString *name;

/**
 Create all the subviews and add to the parent view.

 @param view The parent view.
 */
- (void)renderToView:(UIView *)view;

/**
 Reload the mapper with the initial layout plist.
 */
- (void)reload;

@end
