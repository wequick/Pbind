//
//  UIView+Pbind.h
//  Pbind
//
//  Created by galen on 15/2/12.
//  Copyright (c) 2015年 galen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PBClient.h"
#import "PBActionMapper.h"

//______________________________________________________________________________

@protocol PBViewLoadingDelegate <NSObject>

@optional
- (BOOL)view:(UIView *)view shouldLoadRequest:(PBRequest *)request;
- (void)view:(UIView *)view didFinishLoading:(PBResponse *)response handledError:(BOOL *)handledError;

@end

//______________________________________________________________________________

@protocol PBViewMappingDelegate <NSObject>

@optional
- (void)pb_resetMappers;

@end

//______________________________________________________________________________

@interface UIView (Pbind) <PBViewLoadingDelegate, PBViewMappingDelegate>

@property (nonatomic, strong) NSString *plist;

/**
 The alias name for the view.
 
 @discussion you can use [view viewWithAlias:] to get the specify aliased subview.
 */
@property (nonatomic, strong) NSString *alias;

@property (nonatomic, strong) id data;
@property (nonatomic, strong, readonly, getter=rootData) id rootData;
@property (nonatomic, assign) id<PBViewLoadingDelegate> loadingDelegate;

@property (nonatomic, strong) NSDictionary *pb_constants;
@property (nonatomic, strong) NSDictionary *pb_expressions;

- (void)setMappable:(BOOL)mappable forKeyPath:(NSString *)keyPath;
- (BOOL)mappableForKeyPath:(NSString *)keyPath;

- (void)setExpression:(NSString *)expression forKeyPath:(NSString *)keyPath;
- (BOOL)hasExpressionForKeyPath:(NSString *)keyPath;

- (UIViewController *)supercontroller;
- (id)superviewWithClass:(Class)clazz;

/**
 Reload the plist.
 
 @discussion This will search the plist from `[Pbind allResourcesBundles]' and reload it.
 */
- (void)pb_reloadPlist;
- (void)pb_initData; // Init constant properties
- (void)pb_mapData:(id)data; // Init dynamic properties by data
- (void)pb_mapData:(id)data forKey:(NSString *)key;
- (void)pb_mapData:(id)data underType:(PBMapType)type dataTag:(unsigned char)tag;
- (void)pb_loadData:(id)data;

/**
 Reload data from clients.
 
 @discussion This will introduce the instant updating feature since you specify a debug server by:
 [PBClient registerDebugServer:]
 */
- (void)pb_reloadClient;

/**
 Find subview with alias.
 
 @discussion If the alias is an integer, use [viewWithTag:] instead.

 @param alias the alias for the view

 @return the subview with the alias.
 */
- (UIView *)viewWithAlias:(NSString *)alias;

- (void)pb_setValue:(id)value forKeyPath:(NSString *)keyPath;
- (id)pb_valueForKeyPath:(NSString *)keyPath;

/**
 Unbind all the observers from the view.
 */
- (void)pb_unbindAll;

/**
 The mappers for the view, default is nil.
 
 @discussion if there were, will unbind them in `pb_unbind' method.
 */
- (NSArray *)pb_mappersForBinding;

/**
 Reset all the temporary data after `pb_unbind'
 */
- (void)pb_didUnbind;

@end

@interface UIView (PBAdditionProperties)

- (void)setValue:(id)value forAdditionKey:(NSString *)key;
- (id)valueForAdditionKey:(NSString *)key;

@end

UIKIT_EXTERN NSString *const PBViewDidStartLoadNotification;
UIKIT_EXTERN NSString *const PBViewDidFinishLoadNotification;
UIKIT_EXTERN NSString *const PBViewHasHandledLoadErrorKey;
