//
//  LSFormAccessory.h
//  Less
//
//  Created by galen on 15/2/27.
//  Copyright (c) 2015年 galen. All rights reserved.
//

#import <UIKit/UIKit.h>

//______________________________________________________________________________
@protocol LSFormAccessoryDelegate;
@protocol LSFormAccessoryDataSource;

@interface LSFormAccessory : UIView

@property (nonatomic, assign) id<LSFormAccessoryDelegate> delegate;
@property (nonatomic, assign) id<LSFormAccessoryDataSource> dataSource;

@property (nonatomic, assign) NSInteger toggledIndex;

- (void)reloadData;

@end

//______________________________________________________________________________
@protocol LSFormAccessoryDelegate <NSObject>
@optional
- (BOOL)accessoryShouldReturn:(LSFormAccessory *)accessory;

@end

//______________________________________________________________________________
@protocol LSFormAccessoryDataSource <NSObject>
@required
- (UIResponder *)accessory:(LSFormAccessory *)accessory responderForToggleAtIndex:(NSInteger)index;
- (NSInteger)responderCountForAccessory:(LSFormAccessory *)accessory;
@optional
- (NSArray *)accessory:(LSFormAccessory *)accessory barButtonItemsForResponderAtIndex:(NSInteger)index;

@end
