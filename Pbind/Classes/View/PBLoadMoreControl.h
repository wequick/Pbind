//
//  PBLoadMoreControl.h
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by Galen Lin on 2017/8/20.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import <UIKit/UIKit.h>
#import "PBButton.h"

@interface PBLoadMoreControl : PBButton

/** whether is loading more data */
@property (nonatomic, assign, getter=isLoading) BOOL loading;

/** whether has reached the ending, namely no more data to be loaded */
@property (nonatomic, assign, getter=isEnding) BOOL ending;

/** The distance-from-bottom to begin loading */
@property (nonatomic, assign) CGFloat beginDistance;

- (void)beginLoading;

- (void)endLoading;

@end
