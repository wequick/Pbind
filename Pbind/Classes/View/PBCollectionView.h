//
//  PBCollectionView.h
//  Pbind
//
//  Created by galen on 15/5/27.
//  Copyright (c) 2015年 galen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PBRowMapper.h"
#import "PBMessageInterceptor.h"

@interface PBCollectionView : UICollectionView <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>
{
    PBRowMapper *_itemMapper;
    Class _registedCellClass;
    
    PBMessageInterceptor *_dataSourceInterceptor;
    PBMessageInterceptor *_delegateInterceptor;
    struct {
        unsigned int deallocing:1;
        unsigned int autoResize:1;
    } _pbCollectionViewFlags;
}

@property (nonatomic, strong) NSDictionary *item;
@property (nonatomic, strong) NSArray *items;     // PBRowMapper
@property (nonatomic, strong) NSArray *sections; // PBSectionMapper

@property (nonatomic, assign) CGSize itemSize;
@property (nonatomic, assign) UIEdgeInsets itemInsets;
@property (nonatomic, assign) CGSize spacingSize;

@property (nonatomic, assign, getter=isAutoResize) BOOL autoResize; // auto resize the frame with it's content size, default is NO.

@end
