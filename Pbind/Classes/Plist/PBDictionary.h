//
//  PBDictionary.h
//  Pbind
//
//  Created by galen on 15/5/27.
//  Copyright (c) 2015年 galen. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 This class is used to extends the Key-Value Observing ability of NSDictionary
 */
@interface PBDictionary : NSObject <NSCopying>
{
    NSMutableDictionary *_dictionary;
}

+ (instancetype)dictionaryWithCapacity:(NSUInteger)capacity;
+ (instancetype)dictionaryWithDictionary:(NSDictionary *)dict;

@property (nonatomic, strong, readonly) NSDictionary *dictionary;

/**
 Notify Keyed-value change events to the owner, default is nil and just notify to self.
 */
@property (nonatomic, weak) id owner;

@property (readonly) NSUInteger count;

- (instancetype)initWithDictionary:(NSDictionary *)dict;

- (id)objectForKey:(id)aKey;
- (void)setObject:(id)anObject forKey:(id <NSCopying>)aKey;

- (id)objectForKeyedSubscript:(id)key NS_AVAILABLE(10_8, 6_0);
- (void)setObject:(id)obj forKeyedSubscript:(id <NSCopying>)key NS_AVAILABLE(10_8, 6_0);

- (void)removeObjectForKey:(id)aKey;

@end
