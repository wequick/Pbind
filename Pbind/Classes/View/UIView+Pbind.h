//
//  UIView+Pbind.h
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by galen on 15/2/12.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import <UIKit/UIKit.h>
#import "PBClient.h"
#import "PBActionMapper.h"
#import "PBLayoutMapper.h"

//______________________________________________________________________________

@protocol PBViewLoadingDelegate <NSObject>

@optional
- (BOOL)view:(UIView *)theView shouldLoadRequest:(PBRequest *)request;
- (void)view:(UIView *)theView didFinishLoading:(PBResponse *)response handledError:(BOOL *)handledError;

@end

//______________________________________________________________________________

@protocol PBViewMappingDelegate <NSObject>

@optional
- (void)pb_resetMappers;

@end

//______________________________________________________________________________

/**
 This category provides the ability of initializing a view with a Pbind-way Plist.
 */
@interface UIView (Pbind) <PBViewLoadingDelegate, PBViewMappingDelegate>

#pragma mark - Initializing
///=============================================================================
/// @name Initializing
///=============================================================================

/**
 The file name of a plist used to initialize the view.
 */
@property (nonatomic, strong) NSString *plist;

/**
 The alias name for the view.
 
 @discussion you can use [view viewWithAlias:] to get the specify aliased subview.
 */
@property (nonatomic, strong) NSString *alias;

#pragma mark - Fetching
///=============================================================================
/// @name Fetching
///=============================================================================

/**
 The data of the view.
 
 @discussion This is set after the fetching done.
 */
@property (nonatomic, strong) id data;

/**
 The data of the owner controller's root view.
 */
@property (nonatomic, strong, readonly, getter=rootData) id rootData;

/** The delegate triggered by loading */
@property (nonatomic, weak) id<PBViewLoadingDelegate> loadingDelegate;

#pragma mark - Caching
///=============================================================================
/// @name Caching
///=============================================================================

/** The constant properties from the parsed plist */
@property (nonatomic, strong, readonly) NSDictionary *pb_constants;

/** The dynamic expressions from the parsed plist */
@property (nonatomic, strong, readonly) NSDictionary *pb_expressions;

/** The plist layout file name */
@property (nonatomic, strong) NSString *pb_layoutName;

/** The plist layout mapper */
@property (nonatomic, strong) PBLayoutMapper *pb_layoutMapper;

#pragma mark - Mapping
///=============================================================================
/// @name Mapping
///=============================================================================

- (void)pb_setConstants:(NSDictionary *)constants fromPlist:(NSString *)plist;

- (void)pb_setExpressions:(NSDictionary *)expressions fromPlist:(NSString *)plist;

/**
 Set mappable for the key path. 
 
 @discussion As default all the key paths allows to be map with the `pb_expressions`.
 If sets to NO then will ignores the expression mapping.

 @param mappable YES if allows property mapping
 @param keyPath the key path for the property
 */
- (void)setMappable:(BOOL)mappable forKeyPath:(NSString *)keyPath;

/**
 Check if a key path is allows to be map.

 @param keyPath the key path to be checked
 @return YES if allows to be map.
 */
- (BOOL)mappableForKeyPath:(NSString *)keyPath;

/**
 Bind an expression for the key path.

 @param expression the expression string
 @param keyPath the key path to be bind
 */
- (void)setExpression:(NSString *)expression forKeyPath:(NSString *)keyPath;

/**
 Check if a key path has been bind to an expression

 @param keyPath the key path to be checked
 @return YES if bind
 */
- (BOOL)hasExpressionForKeyPath:(NSString *)keyPath;

/**
 Find the owner controller for the view

 @return the super controller
 */
- (UIViewController *)supercontroller;

/**
 Find a super view with the specify class

 @param clazz the searching class
 @return the super view with the class
 */
- (UIView *)superviewWithClass:(Class)clazz;

/**
 Check if self is or find a super view with the specify class
 
 @param clazz the searching class
 @return self or the super view with the class
 */
- (UIView *)selfOrSuperviewWithClass:(Class)clazz;

/**
 Layout the subviews with plist

 @param layoutName The layout plist file name
 */
- (void)pb_layout:(NSString *)layoutName;

/**
 Reload the plist.
 
 @discussion This will search the plist from `[Pbind allResourcesBundles]' and reload it.
 */
- (void)pb_reloadPlist;
- (void)pb_reloadLayout;
- (void)pb_initData; // Init constant properties
- (void)pb_mapData:(id)data; // Init dynamic properties by data
- (void)pb_mapData:(id)data forKey:(NSString *)key;
- (void)pb_mapData:(id)data withContext:(UIView *)context;
- (void)pb_mapData:(id)data withOwner:(UIView *)owner context:(UIView *)context;
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
- (id)pb_valueForKeyPath:(NSString *)key failure:(void (^)(void))failure;

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
