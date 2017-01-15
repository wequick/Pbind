//
//  PBDictionary.h
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by galen on 15/5/27.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import <Foundation/Foundation.h>

/**
 This class is used to extends the Key-Value Observing ability of NSDictionary
 */
@interface PBDictionary : NSObject <NSCopying, NSFastEnumeration>
{
    NSMutableDictionary *_dictionary;
}

+ (instancetype)dictionaryWithCapacity:(NSUInteger)capacity;
+ (instancetype)dictionaryWithDictionary:(NSDictionary *)dict;

@property (nonatomic, strong, readonly) NSDictionary *dictionary;

/**
 The owner to be notified keyed-value change events. Default is nil and notify to self.
 */
@property (nonatomic, weak) id owner;

#pragma mark - Implementing
///=============================================================================
/// @name Implementing
///=============================================================================

@property (readonly) NSUInteger count;

- (instancetype)initWithDictionary:(NSDictionary *)dict;

- (id)objectForKey:(id)aKey;
- (void)setObject:(id)anObject forKey:(id <NSCopying>)aKey;

- (id)objectForKeyedSubscript:(id)key NS_AVAILABLE(10_8, 6_0);
- (void)setObject:(id)obj forKeyedSubscript:(id <NSCopying>)key NS_AVAILABLE(10_8, 6_0);

- (void)removeObjectForKey:(id)aKey;

@end
