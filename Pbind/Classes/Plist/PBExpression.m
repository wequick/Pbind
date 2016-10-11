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
#import "PBForm.h"
#import "PBDictionary.h"
#import "PBMutableExpression.h"

static const int kDataTagUnset = 0xFF;

@interface PBForm (Private)

- (PBDictionary *)inputTexts;
- (PBDictionary *)inputValues;

@end

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
    
    _flags.dataTag = kDataTagUnset;
    return [self initWithUTF8String:[aString UTF8String]];
}

- (instancetype)initWithUTF8String:(const char *)str {
    char *p = (char *)str;
    NSUInteger len = strlen(str) + 1;
    
    // Unary operator
    switch (*p) {
        case '!': _flags.unaryNot = 1; p++; break;
        case '-': _flags.negative = 1; p++; break;
        case '~': _flags.animated = 1; p++; break;
        default: break;
    }
    
    // Tag
    switch (*p) {
        case '@':
            p++;
            if (*p == '[' || *p == ']') {
                return nil; // constant tag for subscript
            }
            _flags.mapToActiveController = 1;
            break;
        case '$':
            p++;
            _flags.mapToData = 1;
            if (*(p + 1) == '.') {
                if (*p >= '0' && *p <= '9') {
                    _flags.dataTag = *p - '0';
                } else {
                    _flags.dataTag = *p; // variable tag for `user-defined'
                    if (![PBVariableMapper registersTag:*p]) {
                        NSLog(@"<%@> Unregistered Tag: %c", [[self class] description], *p);
                        return nil;
                    }
                }
                p += 2;
            }
            break;
        case '.':
            p++;
            if (*p == '$') {
                _flags.mapToTargetData = 1;
                p++;
            } else {
                _flags.mapToTarget = 1;
            }
            break;
        case '>':
            p++;
            if (*p == '@') {
                _flags.mapToFormFieldValue = 1;
                p++;
            } else {
                _flags.mapToFormFieldText = 1;
            }
            break;
        default:
            return nil;
    }
    
    // Flag
    switch (*p) {
        case '_':
            // Binding flag
            p++;
            if (*p == '_') {
                _flags.duplexBinding = 1;
                p++;
            } else {
                _flags.onewayBinding = 1;
            }
            break;
        default:
            break;
    }
    
    // Variable
    char *temp = (char *)malloc(len - (p - str));
    char *p2 = temp;
    // first char should be [a-z][A-Z]
    if ((*p >= 'a' && *p <= 'z') || (*p >= 'A' && *p <= 'Z')) {
        *p2++ = *p++;
    } else {
        NSLog(@"<%@> Variable should be start with [a-z] or [A-Z].", [[self class] description]);
        return nil;
    }
    
    while ((*p >= 'a' && *p <= 'z') || (*p >= 'A' && *p <= 'Z') || (*p == '_')
           || (*p == '.' /* allows nested key */)) {
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
        case '!':
            p++;
            _flags.multiNot = 1;
            if (*p == '=') {
                _flags.equal = 1;
            } else {
                NSLog(@"<%@> '!' should together with '=' as '!='.", [[self class] description]);
                return nil;
            }
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
                while (*p != ':' && *p != '\0') {
                    *p2++ = *p++;
                }
                if (*p == '\0') {
                    NSLog(@"<%@> Missing ':' after '?', should as '?*:*'.", [[self class] description]);
                    return nil;
                }
                *p2 = '\0';
                _rvalue = [NSString stringWithUTF8String:temp];
                
                p++;
                p2 = temp = (char *)malloc(len - (p - str));
                while (*p != '\0') {
                    *p2++ = *p++;
                }
                *p2 = '\0';
                _rvalueOfNot = [NSString stringWithUTF8String:temp];
                
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

- (id)valueWithData:(id)data target:(id)target context:(UIView *)context
{
    id dataSource = [self _dataSourceWithData:data target:target context:context];
    if (dataSource == nil) {
        return nil;
    }
    
    return [self _valueWithData:dataSource];
}

- (id)_dataSourceWithData:(id)data target:(id)target context:(UIView *)context {
    if (_flags.mapToData) {
        int dataIndex = 0;
        if (_flags.dataTag >= 0 && _flags.dataTag <= 9) {
            dataIndex = _flags.dataTag;
        } else if (_flags.dataTag != kDataTagUnset) {
            id (^mapper)(id data, id target, UIView *context) = [PBVariableMapper mapperForTag:_flags.dataTag];
            return mapper(data, target, context);
        }
        
        return [self _dataSourceWithData:data atIndex:dataIndex];
    } else if (_flags.mapToTarget) {
        return target;
    } else if (_flags.mapToTargetData) {
        return [target data];
    } else if (_flags.mapToActiveController) {
        return [context supercontroller];
    } else if (_flags.mapToFormFieldText) {
        PBForm *form = [context superviewWithClass:[PBForm class]];
        if (form == nil) {
            return nil;
        }
        return [form inputTexts];
    } else if (_flags.mapToFormFieldValue) {
        PBForm *form = [context superviewWithClass:[PBForm class]];
        if (form == nil) {
            return nil;
        }
        return [form inputValues];
    }
    return nil;
}

- (id)_dataSourceWithData:(id)data atIndex:(int)index {
    if (![data respondsToSelector:@selector(objectAtIndexedSubscript:)]) return data;
    
    if (index >= [data count]) return nil;
    id value = data[index];
    if ([value isEqual:[NSNull null]]) {
        return nil;
    }
    return value;
}

- (id)valueWithData:(id)data target:(id)target
{
    return [self valueWithData:data target:target context:nil];
}

- (id)valueWithData:(id)data
{
    return [self valueWithData:data target:nil];
}

- (id)_valueWithData:(id)data
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

- (id)valueByOperatingValue:(id)value
{
    // Unary operators
    if (_flags.unaryNot) {
        BOOL temp = [value intValue] == 0;
        value = [NSNumber numberWithBool:temp];
    }
    
    if (_flags.negative) {
        CGFloat temp = -[value floatValue];
        value = [NSNumber numberWithFloat:temp];
    }
    
    // Arithmetic operators
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
    
    // Comparision operators
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
        
        if (_flags.multiNot) {
            temp = !temp;
        }
        return [NSNumber numberWithBool:temp];
    }
    
    // Conditional operators
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

- (void)bindData:(id)data toTarget:(id)target forKeyPath:(NSString *)targetKeyPath inContext:(UIView *)context
{
    if (_bindingOwner != nil) {
        return;
    }
    
    if (_flags.duplexBinding || _flags.onewayBinding) {
        id dataSource = [self _dataSourceWithData:data target:target context:context];
        if (dataSource == nil) {
            return;
        }
        _bindingKeyPath = targetKeyPath;
        _bindingData = dataSource;
        _bindingOwner = target;
        [dataSource addObserver:self forKeyPath:_variable options:NSKeyValueObservingOptionNew context:(__bridge void *)target];
        if (_flags.duplexBinding) {
            [target addObserver:self forKeyPath:targetKeyPath options:NSKeyValueObservingOptionNew context:(__bridge void *)dataSource];
        }
    }
}

- (void)mapData:(id)data toTarget:(id)target forKeyPath:(NSString *)targetKeyPath inContext:(UIView *)context
{
    char flag = [targetKeyPath characterAtIndex:0];
    switch (flag) {
        case '!': { // Event
            if (![target isKindOfClass:[UIControl class]]) {
                return;
            }
            id actionTarget = [self _dataSourceWithData:data target:target context:context];
            if (actionTarget == nil) {
                return;
            }
            NSString *act = _variable;
            if ([act characterAtIndex:[act length] - 1] != ':') {
                act = [act stringByAppendingString:@":"];
            }
            SEL action = NSSelectorFromString(act);
            if (![actionTarget respondsToSelector:action]) {
                return;
            }
            NSString *event = [targetKeyPath substringFromIndex:1];
            if ([event isEqualToString:@"click"]) {
                [target addTarget:actionTarget action:action forControlEvents:UIControlEventTouchUpInside];
            } else if ([event isEqualToString:@"change"]) {
                [target addTarget:actionTarget action:action forControlEvents:UIControlEventValueChanged];
            }
        }
            break;
        case '+': {
            NSString *keyPath = [targetKeyPath substringFromIndex:1];
            [self setValueToTarget:target forKeyPath:keyPath withData:data context:context]; // map value
            [self bindData:data toTarget:target forKeyPath:keyPath inContext:context]; // binding data
        }
            break;
        default: {
            [self setValueToTarget:target forKeyPath:targetKeyPath withData:data context:context]; // map value
            [self bindData:data toTarget:target forKeyPath:targetKeyPath inContext:context]; // binding data
        }
            break;
    }
}

- (void)setValueToTarget:(id)target forKeyPath:(NSString *)targetKeyPath withData:(id)data context:(UIView *)context {
    id value = [self valueWithData:data target:target context:context];
    value = [self validatingValue:value forKeyPath:targetKeyPath];
    [target setValue:value forKeyPath:targetKeyPath]; // map value
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    id newValue = [change objectForKey:NSKeyValueChangeNewKey];
    if ([newValue isEqual:[NSNull null]]) {
        if ([object isKindOfClass:[UIView class]]) {
            return;
        }
        newValue = nil;
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

- (NSString *)stringValue {
    NSMutableString *s = [[NSMutableString alloc] init];
    // Unary operators
    if (_flags.unaryNot) {
        [s appendString:@"!"];
    }
    if (_flags.negative) {
        [s appendString:@"-"];
    }
    if (_flags.animated) {
        [s appendString:@"~"];
    }
    
    // Tag
    if (_flags.mapToData) {
        if (_flags.dataTag >= 0 && _flags.dataTag <= 9) {
            [s appendFormat:@"$%d.", _flags.dataTag];
        } else if (_flags.dataTag != kDataTagUnset) {
            [s appendFormat:@"$%c.", _flags.dataTag];
        } else {
            [s appendString:@"$"];
        }
    } else if (_flags.mapToTarget) {
        [s appendString:@"."];
    } else if (_flags.mapToTargetData) {
        [s appendString:@".$"];
    } else if (_flags.mapToActiveController) {
        [s appendString:@"@"];
    } else if (_flags.mapToFormFieldText) {
        [s appendString:@">"];
    } else if (_flags.mapToFormFieldValue) {
        [s appendString:@">@"];
    }
    
    [s appendString:_variable];
    
    if (_rvalue == nil) {
        return s;
    }
    
    if (_flags.test) {
        if (_flags.unaryTest) {
            [s appendString:@"?:"];
            [s appendString:_rvalue];
        } else {
            [s appendFormat:@"?%@:%@",_rvalue,_rvalueOfNot];
        }
    } else {
        if (_flags.lesser) {
            [s appendString:@"<"];
        }
        if (_flags.greater) {
            [s appendString:@">"];
        }
        if (_flags.multiNot) {
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
        
        [s appendString:_rvalue];
    }
    return s;
}

- (NSString *)debugDescription
{
    return [NSString stringWithFormat:@"<%@: %p>\n - \"%@\"", [[self class] description], self, [self stringValue]];
}

@end