//
//  PBArray.h
//  Pbind
//
//  Created by Galen Lin on 16/9/5.
//  Copyright © 2016年 galen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Foundation/NSObject.h>

@interface PBArray : NSObject <NSCopying>
{
    NSMutableArray *_array;
}

+ (instancetype)arrayWithCapacity:(NSUInteger)capacity;
+ (instancetype)arrayWithArray:(NSArray *)array;

@property (nonatomic, strong, readonly) NSArray *array;
@property (readonly) NSUInteger count;

@property (nonatomic, assign) NSUInteger listElementIndex; // the index of list data for tableView
@property (nonatomic, strong, readonly) NSArray *list; // the list data for tableView

- (instancetype)initWithArray:(NSArray *)array;

- (id)objectAtIndexedSubscript:(NSUInteger)idx NS_AVAILABLE(10_8, 6_0);
- (void)setObject:(id)obj atIndexedSubscript:(NSUInteger)idx NS_AVAILABLE(10_8, 6_0);

- (void)addObject:(id)anObject;

@end
