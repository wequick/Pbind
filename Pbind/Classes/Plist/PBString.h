//
//  PBString.h
//  Pbind
//
//  Created by galen on 15/4/25.
//  Copyright (c) 2015年 galen. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PBString : NSString

+ (NSString *)stringWithFormat:(NSString *)format array:(NSArray *)arguments;
+ (NSString *)stringWithFormat:(NSString *)format object:(id)object;

@end
