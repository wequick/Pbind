//
//  NSInputStream+Reader.m
//  Pchat
//
//  Created by Galen Lin on 15/03/2017.
//  Copyright © 2017 galen. All rights reserved.
//

#import "NSInputStream+Reader.h"

#if (PBLIVE_ENABLED && !(TARGET_IPHONE_SIMULATOR))

@implementation NSInputStream (Reader)

- (int)readInt {
    uint8_t bytes[4];
    [self read:bytes maxLength:4];
    int intData = *((int *)bytes);
    return NSSwapInt(intData);
}

- (NSData *)readData {
    int length = [self readInt];
    if (length < 0) {
        return nil;
    }
    uint8_t *bytes = malloc(length);
    NSInteger len = [self read:bytes maxLength:length];
    while (len < length) {
        len += [self read:bytes + len maxLength:length - len];
    }
    if (len != length) {
        NSLog(@"Failed to read data in length %i, only got %i bytes", length, (int)len);
        return nil;
    }
    return [NSData dataWithBytes:bytes length:len];
}

- (NSString *)readString {
    NSData *data = [self readData];
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

@end

#endif
