//
//  NSString+LSInput.m
//  Less
//
//  Created by galen on 15/6/10.
//  Copyright (c) 2015年 galen. All rights reserved.
//

#import "NSString+LSInput.h"

@implementation NSString (LSInput)

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
