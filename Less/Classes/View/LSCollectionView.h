//
//  LSCollectionView.h
//  Less
//
//  Created by galen on 15/5/27.
//  Copyright (c) 2015年 galen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LSRowMapper.h"
#import "LSMessageInterceptor.h"

@interface LSCollectionView : UICollectionView <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>
{
    LSRowMapper *_itemMapper;
    Class _registedCellClass;
    
    LSMessageInterceptor *_dataSourceInterceptor;
    LSMessageInterceptor *_delegateInterceptor;
    struct {
        unsigned int deallocing:1;
        unsigned int autoResize:1;
    } _lsCollectionViewFlags;
}

@property (nonatomic, strong) NSDictionary *item;
@property (nonatomic, strong) NSArray *items;     // LSRowMapper
@property (nonatomic, strong) NSArray *sections; // LSSectionMapper

@property (nonatomic, assign) CGSize itemSize;
@property (nonatomic, assign) UIEdgeInsets itemInsets;
@property (nonatomic, assign) CGSize spacingSize;

@property (nonatomic, assign, getter=isAutoResize) BOOL autoResize; // auto resize the frame with it's content size, default is NO.

@end
