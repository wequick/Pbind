//
//  PBTableViewCell.h
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by Galen Lin on 16/9/5.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import <UIKit/UIKit.h>

/**
 An instance of PBTableViewCell extends the ability of configuration the image size and margin for the cell.
 */
@interface PBTableViewCell : UITableViewCell

/**
 The size for the image of the cell's imageView.
 */
@property (nonatomic, assign) CGSize imageSize;

/**
 The margin for the image of the cell's imageView.
 */
@property (nonatomic, assign) UIEdgeInsets imageMargin;

@end
