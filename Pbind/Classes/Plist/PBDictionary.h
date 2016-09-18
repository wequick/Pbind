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

- (instancetype)initWithDictionary:(NSDictionary *)dict;

- (id)objectForKeyedSubscript:(id)key NS_AVAILABLE(10_8, 6_0);
- (void)setObject:(id)obj forKeyedSubscript:(id <NSCopying>)key NS_AVAILABLE(10_8, 6_0);

@end
