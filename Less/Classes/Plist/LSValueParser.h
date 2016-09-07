//
//  LSValueParser.h
//  Less
//
//  Created by galen on 15/2/25.
//  Copyright (c) 2015年 galen. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LSValueParser : NSObject

+ (id)valueWithString:(NSString *)aString;

+ (void)registerEnums:(NSDictionary *)enums; // <NSString *, NSNumber *>

@end
