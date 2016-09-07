//
//  LSString.h
//  Less
//
//  Created by galen on 15/4/25.
//  Copyright (c) 2015年 galen. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LSString : NSString

+ (NSString *)stringWithFormat:(NSString *)format array:(NSArray *)arguments;
+ (NSString *)stringWithFormat:(NSString *)format object:(id)object;

@end
