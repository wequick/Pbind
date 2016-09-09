//
//  PBFormAccessory.h
//  Pbind
//
//  Created by galen on 15/2/27.
//  Copyright (c) 2015年 galen. All rights reserved.
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
