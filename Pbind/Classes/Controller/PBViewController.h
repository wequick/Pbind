//
//  PBViewController.h
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by Galen Lin on 16/9/20.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import <UIKit/UIKit.h>

@interface PBViewController : UIViewController

/**
 The plist file name, will be set to the content view.
 */
@property (nonatomic, strong) NSString *plist;

/**
 The data, will be set the content view.
 */
@property (nonatomic, strong) id data;

/**
 Reload data on next `viewWillAppear` loop.
 */
- (void)setNeedsReloadData;

@end
