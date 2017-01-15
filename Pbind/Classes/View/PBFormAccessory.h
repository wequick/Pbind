//
//  PBFormAccessory.h
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by galen on 15/2/27.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import <UIKit/UIKit.h>

//______________________________________________________________________________
@protocol PBFormAccessoryDelegate;
@protocol PBFormAccessoryDataSource;

@interface PBFormAccessory : UIView

@property (nonatomic, assign) id<PBFormAccessoryDelegate> delegate;
@property (nonatomic, assign) id<PBFormAccessoryDataSource> dataSource;

@property (nonatomic, assign) NSInteger toggledIndex;

- (void)reloadData;

@end

//______________________________________________________________________________
@protocol PBFormAccessoryDelegate <NSObject>
@optional
- (BOOL)accessoryShouldReturn:(PBFormAccessory *)accessory;

@end

//______________________________________________________________________________
@protocol PBFormAccessoryDataSource <NSObject>
@required
- (UIResponder *)accessory:(PBFormAccessory *)accessory responderForToggleAtIndex:(NSInteger)index;
- (NSInteger)responderCountForAccessory:(PBFormAccessory *)accessory;
@optional
- (NSArray *)accessory:(PBFormAccessory *)accessory barButtonItemsForResponderAtIndex:(NSInteger)index;

@end
