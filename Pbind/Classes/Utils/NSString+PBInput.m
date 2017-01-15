//
//  NSString+PBInput.m
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by galen on 15/6/10.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "NSString+PBInput.h"

@implementation NSString (PBInput)

- (NSUInteger)charaterLength
{
    NSUInteger length = 0;
    char *p = (char *)[self cStringUsingEncoding:NSUnicodeStringEncoding];
    for (NSUInteger i = 0; i < [self lengthOfBytesUsingEncoding:NSUnicodeStringEncoding]; i++) {
        if (*p) {
            p++;
            length++;
        } else {
            p++;
        }
    }
    return length;
}

@end
