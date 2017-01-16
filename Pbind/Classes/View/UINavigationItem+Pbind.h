//
//  UINavigationItem+Pbind.h
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by Galen Lin on 2016/12/18.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import <UIKit/UIKit.h>

/**
 This category provides the ability of configuring the left and right items for the navigation item.
 */
@interface UINavigationItem (Pbind)

/**
 Initialize the right bar button item

 @param right the dictionary for creating the item
 */
- (void)setRight:(NSDictionary *)right;

/**
 Initialize the right bar button items

 @param rights the dictionary array for creating the items
 */
- (void)setRights:(NSArray<NSDictionary *> *)rights;

/**
 Initialize the left bar button item
 
 @param left the dictionary for creating the item
 */
- (void)setLeft:(NSDictionary *)left;

/**
 Initialize the left bar button items
 
 @param lefts the dictionary array for creating the items
 */
- (void)setLefts:(NSArray *)lefts;

@end
