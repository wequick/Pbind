//
//  PBCollectionViewController.h
//  Pods
//
//  Created by Galen Lin on 2016/10/18.
//
//

#import <UIKit/UIKit.h>
#import "PBViewController.h"
#import "PBCollectionView.h"

@interface PBCollectionViewController : PBViewController<UICollectionViewDelegate, UICollectionViewDataSource>

@property (nonatomic, strong) PBCollectionView *collectionView;

@end
