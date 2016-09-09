//
//  PBValueParser.h
//  Pbind
//
//  Created by galen on 15/2/25.
//  Copyright (c) 2015年 galen. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PBValueParser : NSObject

+ (id)valueWithString:(NSString *)aString;

+ (void)registerEnums:(NSDictionary *)enums; // <NSString *, NSNumber *>

@end
