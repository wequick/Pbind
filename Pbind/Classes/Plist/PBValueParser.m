//
//  PBValueParser.m
//  Pbind
//
//  Created by galen on 15/2/25.
//  Copyright (c) 2015年 galen. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "PBValueParser.h"
#import "Pbind+API.h"

static NSMutableDictionary *kEnums = nil;

@implementation PBValueParser

+ (id)valueWithString:(NSString *)aString
{
    if (![aString isKindOfClass:[NSString class]]) {
        return aString;
    }
    if ([aString length] < 2) {
        return aString;
    }
    
    unichar initial = [aString characterAtIndex:0];
    unichar second = [aString characterAtIndex:1];
    // Subscript
    if (initial == '@') {
        if (second == '[') { // Array
            aString = [aString substringFromIndex:2]; // bypass `@['
            aString = [aString substringToIndex:aString.length-1]; // bypass `]'
            NSArray *comps = [aString componentsSeparatedByString:@","];
            NSMutableArray *array = [NSMutableArray arrayWithCapacity:comps.count];
            for (NSString *s in comps) {
                [array addObject:[self valueWithString:s]];
            }
            return array;
        } else if (second == '{') { // Dictionary
            aString = [aString substringFromIndex:2]; // bypass `@{'
            aString = [aString substringToIndex:aString.length-1]; // bypass `}'
            NSArray *comps = [aString componentsSeparatedByString:@","];
            NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithCapacity:comps.count];
            for (NSString *s in comps) {
                NSArray *dictComps = [s componentsSeparatedByString:@":"];
                NSString *key = [dictComps firstObject];
                id value = [self valueWithString:[dictComps objectAtIndex:1]];
                [dictionary setObject:value forKey:key];
            }
            return dictionary;
        }
    }
    // Color
    if (initial == '#') {
        UIColor *color = [self colorWithHexString:aString];
        if (color != nil) {
            if (second == '#') {
                return (id)color.CGColor;
            }
            return color;
        }
        return aString;
    }
    // Enum
    if (initial == ':') {
        aString = [aString substringFromIndex:1];
        int enumValue = 0;
        // Text alignment
        if ([aString isEqualToString:@"left"]) {
            enumValue = NSTextAlignmentLeft;
        } else if ([aString isEqualToString:@"right"]) {
            enumValue = NSTextAlignmentRight;
        } else if ([aString isEqualToString:@"center"]) {
            enumValue = NSTextAlignmentCenter;
        }
        // Cell accessory type
        else if ([aString isEqualToString:@"/"]) {
            enumValue = UITableViewCellAccessoryCheckmark;
        } else if ([aString isEqualToString:@"i"]) {
            enumValue = UITableViewCellAccessoryDetailButton;
        } else if ([aString isEqualToString:@">"]) {
            enumValue = UITableViewCellAccessoryDisclosureIndicator;
        }
        // Cell style
        else if ([aString isEqualToString:@"value1"]) {
            enumValue = UITableViewCellStyleValue1;
        }
        else if ([aString isEqualToString:@"value2"]) {
            enumValue = UITableViewCellStyleValue2;
        }
        else if ([aString isEqualToString:@"subtitle"]) {
            enumValue = UITableViewCellStyleSubtitle;
        }
        // User defined enums
        else {
            NSNumber *number = [kEnums objectForKey:aString];
            if (number != nil) {
                return number;
            }
        }
        return [NSNumber numberWithInt:enumValue];
    }
    // Struct or Object
    if (initial == '{') {
        if (second == 'F') {
            return [self fontWithString:aString];
        } else if (second == '{') { // e.g. {{0, 0}, {320, 480}}
            CGRect rect = CGRectFromString(aString);
            return [NSValue valueWithCGRect:PBRect(rect)];
        } else {
            NSArray *components = [aString componentsSeparatedByString:@","];
            switch (components.count) {
                case 2: // e.g. {320, 480}
                {
                    CGSize size = CGSizeFromString(aString);
                    return [NSValue valueWithCGSize:PBSize(size)];
                }
                case 4: // e.g. {0, 1, 2, 3}
                {
                    UIEdgeInsets insets = UIEdgeInsetsFromString(aString);
                    return [NSValue valueWithUIEdgeInsets:PBEdgeInsets(insets)];
                }
                default:
                    break;
            }
        }
    }
    
    // Replace '\n'
    return [aString stringByReplacingOccurrencesOfString:@"\\n" withString:@"\n"];
}

+ (void)registerEnums:(NSDictionary *)enums
{
    if (kEnums == nil) {
        kEnums = [[NSMutableDictionary alloc] initWithDictionary:enums];
    } else {
        [kEnums setValuesForKeysWithDictionary:enums];
    }
}

#pragma mark - UIColor

+ (UIColor *)colorWithHexString: (NSString *) hexString {
    NSString *colorString = [[hexString stringByReplacingOccurrencesOfString: @"#" withString: @""] uppercaseString];
    CGFloat alpha, red, blue, green;
    switch ([colorString length]) {
        case 3: // #RGB
            alpha = 1.0f;
            red   = [self colorComponentFrom: colorString start: 0 length: 1];
            green = [self colorComponentFrom: colorString start: 1 length: 1];
            blue  = [self colorComponentFrom: colorString start: 2 length: 1];
            break;
        case 4: // #ARGB
            alpha = [self colorComponentFrom: colorString start: 0 length: 1];
            red   = [self colorComponentFrom: colorString start: 1 length: 1];
            green = [self colorComponentFrom: colorString start: 2 length: 1];
            blue  = [self colorComponentFrom: colorString start: 3 length: 1];
            break;
        case 6: // #RRGGBB
            alpha = 1.0f;
            red   = [self colorComponentFrom: colorString start: 0 length: 2];
            green = [self colorComponentFrom: colorString start: 2 length: 2];
            blue  = [self colorComponentFrom: colorString start: 4 length: 2];
            break;
        case 8: // #AARRGGBB
            alpha = [self colorComponentFrom: colorString start: 0 length: 2];
            red   = [self colorComponentFrom: colorString start: 2 length: 2];
            green = [self colorComponentFrom: colorString start: 4 length: 2];
            blue  = [self colorComponentFrom: colorString start: 6 length: 2];
            break;
        default:
            return nil;
    }
    return [UIColor colorWithRed: red green: green blue: blue alpha: alpha];
}

+ (CGFloat) colorComponentFrom: (NSString *) string start: (NSUInteger) start length: (NSUInteger) length {
    NSString *substring = [string substringWithRange: NSMakeRange(start, length)];
    NSString *fullHex = length == 2 ? substring : [NSString stringWithFormat: @"%@%@", substring, substring];
    unsigned hexComponent;
    [[NSScanner scannerWithString: fullHex] scanHexInt: &hexComponent];
    return hexComponent / 255.0;
}

#pragma mark - UIFont

+ (UIFont *)fontWithString:(NSString *)aString {
    NSString *name = nil;
    CGFloat size = [UIFont systemFontSize];
    BOOL bold = NO;
    BOOL italic = NO;
    // family, weight|style, size
    NSString *pattern = @"\\{F:([^\\d]+)?(\\d+)\\}";
    NSError *error = nil;
    NSRegularExpression *regex = [[NSRegularExpression alloc] initWithPattern:pattern options:0 error:&error];
    if (error == nil) {
        NSTextCheckingResult *result = [regex firstMatchInString:aString options:0 range:NSMakeRange(0, aString.length)];
        NSRange range = [result rangeAtIndex:2];
        if (range.length != 0) {
            size = [[aString substringWithRange:range] floatValue];
            size = PBValue(size);
            range = [result rangeAtIndex:1];
            if (range.length != 0) {
                name = [aString substringWithRange:range];
                range = [name rangeOfString:@"bold"];
                if (range.length != 0) {
                    bold = YES;
                    name = [name substringToIndex:range.location];
                } else {
                    range = [name rangeOfString:@"italic"];
                    if (range.length != 0) {
                        italic = YES;
                        name = [name substringToIndex:range.location];
                    }
                }
                if (![name isEqualToString:@""]) {
                    name = [name stringByReplacingOccurrencesOfString:@"," withString:@""];
                }
            }
        }
        //
    }
    
    // family, size
    // weight|style, size
    // size
    UIFont *font = nil;
    if (name != nil) {
        font = [UIFont fontWithName:name size:size];
    }
    if (font == nil) {
        if (bold) {
            font = [UIFont boldSystemFontOfSize:size];
        } else if (italic) {
            font = [UIFont italicSystemFontOfSize:size];
        } else {
            font = [UIFont systemFontOfSize:size];
        }
    }
    return font;
}

@end
