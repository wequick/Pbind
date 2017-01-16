//
//  PBCollectionsCell.h
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by Galen Lin on 16/8/30.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import <UIKit/UIKit.h>

#import "PBCollectionView.h"

/**
 An instance of PBCollectionsCell add a PBCollectionView as it's content view.
 */
@interface PBCollectionsCell : UITableViewCell

@property (nonatomic, strong) PBCollectionView *collectionView;

@end
