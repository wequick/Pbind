//
//  PBInline.h
//  Pbind
//
//  Created by galen on 15/4/9.
//  Copyright (c) 2015年 galen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PBValueParser.h"

FOUNDATION_STATIC_INLINE UIColor *PBColorMake(NSString *hexString)
{
    if ([hexString characterAtIndex:0] != '#') {
        hexString = [@"#" stringByAppendingString:hexString];
    }
    return [PBValueParser valueWithString:hexString];
}
