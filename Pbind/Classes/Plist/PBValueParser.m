//
//  PBValueParser.m
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by galen on 15/2/25.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import <UIKit/UIKit.h>

#import "PBValueParser.h"
#import "PBForm.h"
#import "PBInline.h"

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
        const char *str = [aString UTF8String];
        if (*(str + 1) == '#') {
            UIColor *color = [self colorWithUTF8String:str + 2];
            if (color != nil) {
                return (id) [color CGColor];
            }
        } else {
            UIColor *color =  [self colorWithUTF8String:str + 1];
            if (color != nil) {
                return color;
            }
        }
    }
    // Enum
    if (initial == ':') {
        aString = [aString substringFromIndex:1];
        int enumValue = 0;
        if ([aString isEqualToString:@"nil"]) {
            return nil;
        } else if ([aString isEqualToString:@"null"]) {
            return [NSNull null];
        } else if ([aString isEqualToString:@"none"]) {
            // 0
        }
        // Text alignment
        else if ([aString isEqualToString:@"left"]) {
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
        } else if ([aString isEqualToString:@"value2"]) {
            enumValue = UITableViewCellStyleValue2;
        } else if ([aString isEqualToString:@"subtitle"]) {
            enumValue = UITableViewCellStyleSubtitle;
        }
        // Cell style
        else if ([aString isEqualToString:@"normalStyle"]) {
            enumValue = UITableViewRowActionStyleNormal;
        } else if ([aString isEqualToString:@"deleteStyle"]) {
            enumValue = UITableViewRowActionStyleDestructive;
        }
        // Cell height
        else if ([aString isEqualToString:@"auto"]) {
            enumValue = UITableViewAutomaticDimension;
        }
        // UIBarButtonSystemItem
        else if ([aString isEqualToString:@"done"]) {
            enumValue = UIBarButtonSystemItemDone;
        } else if ([aString isEqualToString:@"cancel"]) {
            enumValue = UIBarButtonSystemItemCancel;
        } else if ([aString isEqualToString:@"edit"]) {
            enumValue = UIBarButtonSystemItemEdit;
        } else if ([aString isEqualToString:@"save"]) {
            enumValue = UIBarButtonSystemItemSave;
        } else if ([aString isEqualToString:@"add"]) {
            enumValue = UIBarButtonSystemItemAdd;
        } else if ([aString isEqualToString:@"compose"]) {
            enumValue = UIBarButtonSystemItemCompose;
        } else if ([aString isEqualToString:@"reply"]) {
            enumValue = UIBarButtonSystemItemReply;
        } else if ([aString isEqualToString:@"share"]) {
            enumValue = UIBarButtonSystemItemAction;
        } else if ([aString isEqualToString:@"organize"]) {
            enumValue = UIBarButtonSystemItemOrganize;
        } else if ([aString isEqualToString:@"bookmarks"]) {
            enumValue = UIBarButtonSystemItemBookmarks;
        } else if ([aString isEqualToString:@"search"]) {
            enumValue = UIBarButtonSystemItemSearch;
        } else if ([aString isEqualToString:@"refresh"]) {
            enumValue = UIBarButtonSystemItemRefresh;
        } else if ([aString isEqualToString:@"stop"]) {
            enumValue = UIBarButtonSystemItemStop;
        } else if ([aString isEqualToString:@"camera"]) {
            enumValue = UIBarButtonSystemItemCamera;
        } else if ([aString isEqualToString:@"trash"]) {
            enumValue = UIBarButtonSystemItemTrash;
        } else if ([aString isEqualToString:@"play"]) {
            enumValue = UIBarButtonSystemItemPlay;
        } else if ([aString isEqualToString:@"pause"]) {
            enumValue = UIBarButtonSystemItemPause;
        } else if ([aString isEqualToString:@"rewind"]) {
            enumValue = UIBarButtonSystemItemRewind;
        } else if ([aString isEqualToString:@"fastforward"]) {
            enumValue = UIBarButtonSystemItemFastForward;
        } else if ([aString isEqualToString:@"undo"]) {
            enumValue = UIBarButtonSystemItemUndo;
        } else if ([aString isEqualToString:@"redo"]) {
            enumValue = UIBarButtonSystemItemRedo;
        } else if ([aString isEqualToString:@"pagecurl"]) {
            enumValue = UIBarButtonSystemItemPageCurl;
        }
        // UIBarButtonItemStyle
        else if ([aString isEqualToString:@"plainStyle"]) {
            enumValue = UIBarButtonItemStylePlain;
        } else if ([aString isEqualToString:@"doneStyle"]) {
            enumValue = UIBarButtonItemStyleDone;
        }
        // PBFormIndicating
        else if ([aString isEqualToString:@"focus"]) {
            enumValue = PBFormIndicatingMaskInputFocus;
        } else if ([aString isEqualToString:@"invalid"]) {
            enumValue = PBFormIndicatingMaskInputInvalid;
        }
        // PBFormValidating
        else if ([aString isEqualToString:@"changed"]) {
            enumValue = PBFormValidatingChanged;
        }
        // UIViewContentMode
        else if ([aString isEqualToString:@"fit"]) {
            enumValue = UIViewContentModeScaleAspectFit;
        } else if ([aString isEqualToString:@"fill"]) {
            enumValue = UIViewContentModeScaleAspectFill;
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
            return [self fontWithUTF8String:[aString UTF8String]];
        } else {
            NSArray *components = [aString componentsSeparatedByString:@"@"];
            CGFloat sketchWidth = 0;
            if (components.count == 2) {
                sketchWidth = [[components lastObject] floatValue];
            }
            aString = [components firstObject];
            
            if (second == '{') { // e.g. {{0, 0}, {320, 480}}
                CGRect rect = CGRectFromString(aString);
                return [NSValue valueWithCGRect:PBRect2(rect, sketchWidth)];
            } else {
                NSArray *components = [aString componentsSeparatedByString:@","];
                switch (components.count) {
                    case 2: // e.g. {320, 480}
                    {
                        CGSize size = CGSizeFromString(aString);
                        return [NSValue valueWithCGSize:PBSize2(size, sketchWidth)];
                    }
                    case 4: // e.g. {0, 1, 2, 3}
                    {
                        UIEdgeInsets insets = UIEdgeInsetsFromString(aString);
                        return [NSValue valueWithUIEdgeInsets:PBEdgeInsets2(insets, sketchWidth)];
                    }
                    default:
                        break;
                }
            }
        }
    }
    
    // NSIndexPath
    if (initial == '[') {
        if (second >= '0' && second <= '9') {
            NSInteger section = second - '0';
            const char *str = [aString UTF8String];
            char *p = (char *)str + 2;
            while (*p != '\0' && (*p >= '0' && *p <= '9')) {
                section = section * 10 + *p - '0';
                p++;
            }
            if (*p == '-') {
                p++;
                NSInteger row = 0;
                while (*p != '\0' && (*p >= '0' && *p <= '9')) {
                    row = row * 10 + *p - '0';
                    p++;
                }
                if (*p == ']') {
                    return [NSIndexPath indexPathForRow:row inSection:section];
                }
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

static int ctohex(char c) {
    if (c >= 'a' && c <= 'f') {
        return c - 'a' + 10;
    }
    if (c >= 'A' && c <= 'F') {
        return c - 'A' + 10;
    }
    return c - '0';
}

static float readcolor(char **str, int len) {
    char *p = *str;
    float max = 15.f;
    int value = ctohex(*p++);
    if (len == 2) {
        value = value * 16 + ctohex(*p++);
        max = 255.f;
    }
    *str = p;
    return value / max;
}

+ (UIColor *)colorWithUTF8String:(const char *)str {
    CGFloat a, r, g, b;
    char *p = (char *)str;
    size_t len = strlen(p);
    switch (len) {
        case 3: // RGB
            a = 1.f;
            r = readcolor(&p, 1);
            g = readcolor(&p, 1);
            b = readcolor(&p, 1);
            break;
        case 6: // RRGGBB
            a = 1.f;
            r = readcolor(&p, 2);
            g = readcolor(&p, 2);
            b = readcolor(&p, 2);
            break;
        case 8: // RRGGBBAA
            r = readcolor(&p, 2);
            g = readcolor(&p, 2);
            b = readcolor(&p, 2);
            a = readcolor(&p, 2);
            break;
        default:
//            NSLog(@"PBValueParser: Invalid color format '%s'", str);
            return nil;
    }
    
    return [UIColor colorWithRed:r green:g blue:b alpha:a];
}

#pragma mark - UIFont

+ (UIFont *)fontWithUTF8String:(const char *)str {
    // {F:[name][bold|italic][size]}
    int size = [UIFont systemFontSize];
    UIFont *systemFont = [UIFont systemFontOfSize:size];
    
    char *p = (char *)str;
    size_t len = strlen(str);
    if (len < 4 || *p != '{' || *(p+1) != 'F' || *(p+2) != ':' || *(p+len-1) != '}') {
        NSLog(@"PBValueParser: Font expression should with format '{F:[name][bold|italic][size]}'");
        return systemFont;
    }
    
    char *components[3]; // $family, bold|italic, $size
    char *p2;
    p += 3;
    int i = 0;
    while (*p != '}') {
        p2 = components[i++] = (char *)malloc(len - (p - str));
        while (*p != ',' && *p != '}') {
            *p2++ = *p++;
        }
        *p2 = '\0';
        if (*p == ',') {
            p++;
        }
    }
    
    UIFontDescriptorSymbolicTraits traits = 0;
    NSString *name = nil;
    char *temp;
    
    switch (i) {
        case 3:
            name = [NSString stringWithUTF8String:components[0]];
            size = PBPixelFromUTF8String(components[2]);
            temp = components[1];
            if (strcmp(temp, "bold") == 0) {
                traits = UIFontDescriptorTraitBold;
            } else if (strcmp(temp, "italic") == 0) {
                traits = UIFontDescriptorTraitItalic;
            } else if (strcmp(temp, "bold|italic") == 0) {
                traits = UIFontDescriptorTraitBold | UIFontDescriptorTraitItalic;
            }
            break;
        case 2:
            temp = components[1];
            if (*temp >= '0' && *temp <= '9') {
                size = PBPixelFromUTF8String(temp);
                temp = components[0];
                if (strcmp(temp, "bold") == 0) {
                    traits = UIFontDescriptorTraitBold;
                } else if (strcmp(temp, "italic") == 0) {
                    traits = UIFontDescriptorTraitItalic;
                } else if (strcmp(temp, "bold|italic") == 0) {
                    traits = UIFontDescriptorTraitBold | UIFontDescriptorTraitItalic;
                } else {
                    name = [NSString stringWithUTF8String:temp];
                }
            } else {
                if (strcmp(temp, "bold") == 0) {
                    traits = UIFontDescriptorTraitBold;
                } else if (strcmp(temp, "italic") == 0) {
                    traits = UIFontDescriptorTraitItalic;
                } else if (strcmp(temp, "bold|italic") == 0) {
                    traits = UIFontDescriptorTraitBold | UIFontDescriptorTraitItalic;
                }
                name = [NSString stringWithUTF8String:components[0]];
            }
            break;
        case 1:
            temp = components[0];
            if (*temp >= '0' && *temp <= '9') {
                size = PBPixelFromUTF8String(temp);
            } else if (strcmp(temp, "bold") == 0) {
                traits = UIFontDescriptorTraitBold;
            } else if (strcmp(temp, "italic") == 0) {
                traits = UIFontDescriptorTraitItalic;
            } else if (strcmp(temp, "bold|italic") == 0) {
                traits = UIFontDescriptorTraitBold | UIFontDescriptorTraitItalic;
            } else {
                name = [NSString stringWithUTF8String:temp];
            }
        default:
            break;
    }
    
    for (int j = 0; j < i; j++) {
        free(components[j]);
    }
    
    NSDictionary *defaultAttributes = systemFont.fontDescriptor.fontAttributes;
    NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithDictionary:defaultAttributes];
    if (name != nil) {
        [attributes removeObjectForKey:@"NSCTFontUIUsageAttribute"];
        attributes[UIFontDescriptorNameAttribute] = name;
    }
    if (traits != 0) {
        attributes[UIFontDescriptorTraitsAttribute] = @{UIFontSymbolicTrait: @(traits)};
    }
    UIFontDescriptor *fontDescriptor = [UIFontDescriptor fontDescriptorWithFontAttributes:attributes];
    return [UIFont fontWithDescriptor:fontDescriptor size:size];
}

@end
