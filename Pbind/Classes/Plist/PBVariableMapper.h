//
//  PBVariableMapper.h
//  Pbind
//
//  Created by galen on 15/3/13.
//  Copyright (c) 2015年 galen. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PBVariableMapper : NSObject

+ (void)registerTag:(char)tag withMapper:(id (^)(id data, id target, int index))mapper;

+ (NSArray *)allTags;
+ (id (^)(id data, id target, int index))mapperForTag:(NSString *)tag;

@end
