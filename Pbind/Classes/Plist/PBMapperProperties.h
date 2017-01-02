//
//  PBMapperProperties.h
//  Pbind
//
//  Created by galen on 15/2/25.
//  Copyright (c) 2015年 galen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "PBExpression.h"

/**
 An instance of PBMapperProperties stores the parsing result of the PBMapper's 
 `properties`, `tagproperties` and `subproperties`.
 
 @discussion Each properties contains:
 
 * constants    -> as `UIColor`, `CGRect`, will be set while the view move to window.
 * expressions  -> data binding feature, will be set while the data source is ready.
 
 */
@interface PBMapperProperties : NSObject

+ (instancetype)propertiesWithDictionary:(NSDictionary *)dictionary;

- (BOOL)initPropertiesForOwner:(id)owner; // UIView

- (void)initDataForOwner:(id)owner;

- (BOOL)matchesType:(PBMapType)type dataTag:(unsigned char)dataTag;
- (void)mapData:(id)data toTarget:(id)target withContext:(UIView *)context;
- (void)mapData:(id)data toTarget:(id)target forKeyPath:(NSString *)keyPath withContext:(UIView *)context;

- (BOOL)isExpressiveForKey:(NSString *)key;

/**
 The initial dictionary count, also is the sum of the parsed constants count and expressions count
 */
- (NSInteger)count;

/**
 The initial dictionay description
 */
- (NSString *)description;

/**
 Unobserve keyed-value of the target.

 @param target the observed target
 */
- (void)unbind:(id)target;

@end
