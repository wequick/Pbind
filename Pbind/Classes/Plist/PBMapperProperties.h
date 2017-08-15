//
//  PBMapperProperties.h
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by galen on 15/2/25.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "PBExpression.h"

@class PBMapper;

/**
 An instance of PBMapperProperties stores the parsing result of the PBMapper's 
 `properties`, `tagproperties` and `subproperties`.
 
 @discussion Each properties contains:
 
 * constants    -> as `UIColor`, `CGRect`, will be set while the view move to window.
 * expressions  -> data binding feature, will be set while the data source is ready.
 
 */
@interface PBMapperProperties : NSObject

#pragma mark - Creating
///=============================================================================
/// @name Creating
///=============================================================================

+ (instancetype)propertiesWithDictionary:(NSDictionary *)dictionary;
+ (instancetype)propertiesWithDictionary:(NSDictionary *)dictionary mapper:(PBMapper *)mapper;

#pragma mark - Caching
///=============================================================================
/// @name Caching
///=============================================================================

@property (nonatomic, weak) PBMapper *mapper;

#pragma mark - API
///=============================================================================
/// @name API
///=============================================================================

- (BOOL)initPropertiesForOwner:(id)owner; // UIView

/**
 Initialize the properties of the owner by KVC

 @param owner the owner to be initialized
 */
- (void)initDataForOwner:(id)owner;

- (void)initDataForOwner:(id)owner transform:(id (^)(NSString *key, id value))transform;

/**
 Initialize the properties of the owner by setter method
 
 @param owner the owner to be initialized
 */
- (void)setDataToOwner:(id)owner;

- (BOOL)matchesType:(PBMapType)type dataTag:(unsigned char)dataTag;
- (void)mapData:(id)data toTarget:(id)target withOwner:(UIView *)owner context:(UIView *)context;
- (void)mapData:(id)data toTarget:(id)target forKeyPath:(NSString *)keyPath withOwner:(UIView *)owner context:(UIView *)context;
- (void)mapData:(id)data toTarget:(id)target forKeyPaths:(NSArray *)keyPaths withOwner:(UIView *)owner context:(UIView *)context;

/**
 Unobserve keyed-value of the target.
 
 @param target the observed target
 */
- (void)unbind:(id)target;

#pragma mark - Properties
///=============================================================================
/// @name Properties
///=============================================================================

/**
 The initial dictionary count, also is the sum of the parsed constants count and expressions count
 */
- (NSInteger)count;

- (id)constantForKey:(NSString *)key;

- (BOOL)isExpressiveForKey:(NSString *)key;

/**
 The switch to enable the mapping for the key.
 */
- (void)setMappable:(BOOL)mappable forKey:(NSString *)key;

#pragma mark - Debugging
///=============================================================================
/// @name Debugging
///=============================================================================

/**
 The source dictionary
 */
- (NSDictionary *)source;

/**
 The description of the `source'
 */
- (NSString *)description;

@end
