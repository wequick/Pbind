//
//  LSInline.h
//  Less
//
//  Created by galen on 15/4/9.
//  Copyright (c) 2015年 galen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LSValueParser.h"

FOUNDATION_STATIC_INLINE UIColor *LSColorMake(NSString *hexString)
{
    if ([hexString characterAtIndex:0] != '#') {
        hexString = [@"#" stringByAppendingString:hexString];
    }
    return [LSValueParser valueWithString:hexString];
}
