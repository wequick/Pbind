//
//  PBCollectionViewController.h
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by Galen Lin on 2016/10/18.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import <UIKit/UIKit.h>
#import "PBViewController.h"
#import "PBCollectionView.h"

@interface PBCollectionViewController : PBViewController<UICollectionViewDelegate, UICollectionViewDataSource>

@property (nonatomic, strong) PBCollectionView *collectionView;

@end
