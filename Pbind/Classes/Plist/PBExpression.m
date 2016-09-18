//
//  PBExpression.m
//  Pbind
//
//  Created by galen on 15/2/26.
//  Copyright (c) 2015年 galen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PBExpression.h"
#import "PBVariableMapper.h"
#import "PBValueParser.h"
#import "UIView+PBLayout.h"
#import "UIView+Pbind.h"
#import "PBMutableExpression.h"

@interface PBMutableExpression (Private)

- (id)valueByUpdatingObservedValue:(id)value fromChild:(PBExpression *)child;

@end

@implementation PBExpression

+ (instancetype)expressionWithString:(NSString *)aString
{
    return [[self alloc] initWithString:aString];
}

- (instancetype)initWithString:(NSString *)aString
{
    if ([aString length] == 0 || [aString isEqual:[NSNull null]]) {
        return nil;
    }
    
    return [self initWithUTF8String:[aString UTF8String]];
}

- (instancetype)initWithUTF8String:(const char *)str {
    char *p = (char *)str;
    NSUInteger len = strlen(str) + 1;
    
    // Unary operator
    switch (*p) {
        case '!': _flags.no = 1; p++; break;
        case '-': _flags.minus = 1; p++; break;
        default: break;
    }
    
    // Tag
    switch (*p) {
        case '@':
            p++;
            if (*p == '[' || *p == ']') {
                return nil; // constant tag for subscript
            }
            _tag = @"@"; break; // variable tag for `active controller'
        case '$':
            p++;
            if (*p >= 'a' && *p <= 'z') {
                _tag = @"$"; // variable tag for `root data'
            } else {
                if (*(p + 1) == '.') {
                    if (*p >= '0' && *p <= '9') {
                        _tag = @"$";
                        _tagIndex = *p - '0';
                    } else {
                        _tag = [NSString stringWithFormat:@"$%c.", *p]; // variable tag for `user-defined'
                    }
                    p += 2;
                }
            }
            break;
        case '.':
            p++;
            if (*p == '$') {
                _tag = @".$"; // variable tag for `target data'
                p++;
            } else {
                _tag = @"."; // variable tag for `target property'
            }
            break;
        case '>':
            p++;
            if (*p == '@') {
                _tag = @">@"; // input value for `PRForm'
                p++;
            } else {
                _tag = @">"; // input text for `PRForm'
            }
            break;
        default:
            return nil;
    }
    
    if (![[PBVariableMapper allTags] containsObject:_tag]) {
        NSLog(@"Unknown Tag: %@", _tag);
        return nil;
    }
    
    // Flag
    switch (*p) {
        case '-':
            // Binding flag
            p++;
            if (*p == '_') {
                _flags.duplexBinding = 1;
                p++;
            } else {
                _flags.onewayBinding = 1;
            }
            break;
        case '~':
            // Animating flag
            p++;
            _flags.animated = 1;
            break;
        default:
            break;
    }
    
    // Variable
    char *temp = (char *)malloc(len - (p - str));
    char *p2 = temp;
    while ((*p >= 'a' && *p <= 'z') || (*p >= 'A' && *p <= 'Z') || (*p == '.')) {
        *p2++ = *p++;
    }
    *p2 = '\0';
    _variable = [NSString stringWithUTF8String:temp];
    free(temp);
    
    // Arithmetic operator
    switch (*p) {
        case '+': _flags.plus = 1;
        case '-': _flags.minus = 1;
        case '*': _flags.times = 1;
        case '/': _flags.divide = 1;
        case '=': _flags.equal = 1;
            p++;
            if (*p == '=') {
                _flags.equal = 1;
                p++;
            }
            
            p2 = temp = (char *)malloc(len - (p - str));
            while (*p != '\0') {
                *p2++ = *p++;
            }
            *p2 = '\0';
            _rvalue = [NSString stringWithUTF8String:temp];
            free(temp);
            break;
        case '?':
            _flags.test = 1;
            p++;
            if (*p == ':') {
                // $var ?: 0
                _flags.unaryTest = 1;
                p++;
                
                p2 = temp = (char *)malloc(len - (p - str));
                while (*p != '\0') {
                    *p2++ = *p++;
                }
                *p2 = '\0';
                _rvalue = [NSString stringWithUTF8String:temp];
                free(temp);
            } else {
                // $var ? 0 : 1
                p2 = temp = (char *)malloc(len - (p - str));
                while (*p != '\0') {
                    *p2++ = *p++;
                }
                *p2 = '\0';
                _rvalue = [NSString stringWithUTF8String:temp];
                
                p++;
                p2 = temp = (char *)malloc(len - (p - str));
                while (*p != '\0') {
                    *p2++ = *p++;
                }
                *p2 = '\0';
                _rvalue = [NSString stringWithUTF8String:temp];
                
                free(temp);
            }
            break;
        default: break;
    }
    
    return self;
}

- (void)dealloc
{
    if (_flags.duplexBinding) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:PBViewWillRemoveFromSuperviewNotification object:nil];
    }
}

- (id)valueWithData:(id)data
{
    if (_variable == nil) {
        return data;
    }
    
    id value = data;
    NSArray *keys = [_variable componentsSeparatedByString:@"."];
    for (NSString *key in keys) {
        value = [value valueForKeyPath:key];
    }
    return [self valueByOperatingValue:value];
}

- (id)valueWithData:(id)data andOwner:(id)owner
{
    if (_tag == nil) {
        return [PBValueParser valueWithString:_rvalue];
    }
    id (^mapper)(id data, id target, int index) = [PBVariableMapper mapperForTag:_tag];
    if (mapper == nil) {
        return nil;
    }
    id dataSource = mapper(data, owner, _tagIndex);
    if (dataSource == nil) {
        return nil;
    }
    
    return [self valueWithData:dataSource];
}

- (id)valueByOperatingValue:(id)value
{
    if (_flags.plus) {
        CGFloat temp = [value floatValue] + [_rvalue floatValue];
        return [NSNumber numberWithFloat:temp];
    }
    if (_flags.minus) {
        CGFloat temp = [value floatValue];
        if (_rvalue != nil) {
            temp -= [_rvalue floatValue];
        }
        return [NSNumber numberWithFloat:temp];
    }
    if (_flags.times) {
        CGFloat temp = [value floatValue] * [_rvalue floatValue];
        return [NSNumber numberWithFloat:temp];
    }
    if (_flags.divide) {
        CGFloat denominator = [_rvalue floatValue];
        CGFloat temp = [value floatValue];
        if (denominator != 0) {
            temp /= denominator;
        }
        return [NSNumber numberWithFloat:temp];
    }
    
    if (_flags.no) {
        BOOL temp = NO;
        if (_flags.equal) {
            temp = [value floatValue] != [_rvalue floatValue];
        } else {
            temp = [value intValue] == 0;
        }
        return [NSNumber numberWithBool:temp];
    }
    if (_flags.lesser) {
        BOOL temp = NO;
        if (_flags.equal) {
            temp = [value floatValue] <= [_rvalue floatValue];
        } else {
            temp = [value floatValue] < [_rvalue floatValue];
        }
        return [NSNumber numberWithBool:temp];
    }
    if (_flags.greater) {
        BOOL temp = NO;
        if (_flags.equal) {
            temp = [value floatValue] >= [_rvalue floatValue];
        } else {
            temp = [value floatValue] > [_rvalue floatValue];
        }
        return [NSNumber numberWithBool:temp];
    }
    if (_flags.equal) {
        BOOL temp = NO;
        float suffixValue = 0;
        NSScanner *scanner = [NSScanner scannerWithString:_rvalue];
        if ([scanner scanFloat:&suffixValue]) {
            temp = [value floatValue] == suffixValue;
        } else {
            temp = [value isEqualToString:_rvalue];
        }
        return [NSNumber numberWithBool:temp];
    }
    
    if (_flags.test) {
        BOOL pass = NO;
        BOOL isNumber = NO;
        if ([value isKindOfClass:[NSString class]]) {
            pass = (value != nil && ![value isEqual:[NSNull null]]);
        } else if ([value isKindOfClass:[NSNumber class]]) {
            pass = ([value floatValue] != 0);
            isNumber = YES;
        } else {
            pass = (value != nil);
        }
        if (_flags.unaryTest) {
            id rvalue = _rvalue;
            if (isNumber) {
                rvalue = [NSNumber numberWithFloat:[_rvalue floatValue]];
            }
            value = pass ? value : rvalue;
        } else {
            value = pass ? _rvalue : _rvalueOfNot;
        }
        return [PBValueParser valueWithString:value];
    }
    return value;
}

- (id)validatingValue:(id)value forKeyPath:(NSString *)keyPath {
    if ([keyPath isEqualToString:@"text"]) {
        if ([value isEqual:[NSNull null]]) {
            value = @"<null>";
        } else if (![value isKindOfClass:[NSString class]]) {
            value = [NSString stringWithFormat:@"%@", value];
        }
    }
    return value;
}

- (void)bindData:(id)data withOwner:(id)owner forKeyPath:(NSString *)ownerKeyPath
{
    if (_flags.duplexBinding || _flags.onewayBinding) {
        id (^mapper)(id data, id target, int index) = [PBVariableMapper mapperForTag:_tag];
        if (mapper == nil) {
            return;
        }
        id dataSource = mapper(data, owner, _tagIndex);
        if (dataSource == nil) {
            return;
        }
        _bindingKeyPath = ownerKeyPath;
        _bindingData = dataSource;
        _bindingOwner = owner;
        [dataSource addObserver:self forKeyPath:_variable options:NSKeyValueObservingOptionNew context:(__bridge void *)owner];
        if (_flags.duplexBinding) {
            [owner addObserver:self forKeyPath:ownerKeyPath options:NSKeyValueObservingOptionNew context:(__bridge void *)dataSource];
        }
    }
}

- (void)mapData:(id)data toOwner:(id)owner forKeyPath:(NSString *)ownerKeyPath
{
    char flag = [ownerKeyPath characterAtIndex:0];
    switch (flag) {
        case '!': { // Event
            if (![owner isKindOfClass:[UIControl class]]) {
                return;
            }
            id (^mapper)(id data, id target, int index) = [PBVariableMapper mapperForTag:_tag]; // default mapper to active controller
            id target = mapper(data, owner, _tagIndex);
            if (target == nil) {
                return;
            }
            NSString *act = _variable;
            if ([act characterAtIndex:[act length] - 1] != ':') {
                act = [act stringByAppendingString:@":"];
            }
            SEL action = NSSelectorFromString(act);
            if (![target respondsToSelector:action]) {
                return;
            }
            NSString *event = [ownerKeyPath substringFromIndex:1];
            if ([event isEqualToString:@"click"]) {
                [owner addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
            } else if ([event isEqualToString:@"change"]) {
                [owner addTarget:target action:action forControlEvents:UIControlEventValueChanged];
            }
        }
            break;
        case '+': {
            NSString *keyPath = [ownerKeyPath substringFromIndex:1];
            [self setValueOfOwner:owner forKeyPath:keyPath withData:data]; // map value
            [self bindData:data withOwner:owner forKeyPath:keyPath]; // binding data
        }
        default: {
            [self setValueOfOwner:owner forKeyPath:ownerKeyPath withData:data]; // map value
            [self bindData:data withOwner:owner forKeyPath:ownerKeyPath]; // binding data
        }
            break;
    }
}

- (void)setValueOfOwner:(id)owner forKeyPath:(NSString *)ownerKeyPath withData:(id)data {
    id value = [self valueWithData:data andOwner:owner];
    if (value == nil) {
        return;
    }
    
    value = [self validatingValue:value forKeyPath:ownerKeyPath];
    [owner setValue:value forKeyPath:ownerKeyPath]; // map value
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    id newValue = [change objectForKey:NSKeyValueChangeNewKey];
    if ([newValue isEqual:[NSNull null]]) {
        return;
    }
    id contextObject = (__bridge id)(context);
    NSString *contextKeyPath = nil;
    if ([keyPath isEqualToString:_variable]) {
        // Data source value changed
        contextKeyPath = _bindingKeyPath;
        newValue = [self valueByOperatingValue:newValue];
        if (self.parent != nil) {
            PBMutableExpression *parent = (id) self.parent;
            newValue = [parent valueByUpdatingObservedValue:newValue fromChild:self];
        }
    } else {
        contextKeyPath = _variable;
    }
    
    id oldValue = [contextObject valueForKeyPath:contextKeyPath];
    if ([oldValue isEqual:newValue]) {
        return;
    }
    
    if (_flags.duplexBinding) {
        [contextObject removeObserver:self forKeyPath:contextKeyPath context:(__bridge void *)(object)];
    }
    [contextObject setValue:newValue forKeyPath:contextKeyPath];
//    NSLog(@"%@->%@, %@->%@", keyPath, contextKeyPath, [[object class] description], [[contextObject class] description]);
    if (_flags.duplexBinding) {
        [contextObject addObserver:self forKeyPath:contextKeyPath options:NSKeyValueObservingOptionNew context:(__bridge void *)(object)];
    }
}

- (void)viewWillRemoveFromSuperview:(NSNotification *)notification {
    if ([_bindingOwner isEqual:notification.object]) {
        [_bindingData removeObserver:self forKeyPath:_variable];
        if (_flags.duplexBinding) {
            [_bindingOwner removeObserver:self forKeyPath:_bindingKeyPath];
        }
        
        _bindingKeyPath = nil;
        _bindingOwner = nil;
        _bindingData = nil;
    }
}

#pragma mark - Debug

- (NSString *)description
{
    NSMutableString *s = [NSMutableString stringWithFormat:@"%@: %@%@", [[self class] description], _tag, _variable];
    if (_flags.lesser) {
        [s appendString:@"<"];
    }
    if (_flags.greater) {
        [s appendString:@">"];
    }
    if (_flags.no) {
        [s appendString:@"!"];
    }
    if (_flags.equal) {
        [s appendString:@"="];
    }
    if (_flags.plus) {
        [s appendString:@"+"];
    }
    if (_flags.minus) {
        [s appendString:@"-"];
    }
    if (_flags.times) {
        [s appendString:@"*"];
    }
    if (_flags.divide) {
        [s appendString:@"/"];
    }
    
    if (_rvalue != nil) {
        [s appendString:_rvalue];
    }
    return s;
}

@end
