//
//  PBInline.h
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by galen on 15/4/9.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
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
