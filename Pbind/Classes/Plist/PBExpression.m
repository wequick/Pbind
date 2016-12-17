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
#import "UIView+Pbind.h"
#import "PBForm.h"
#import "PBDictionary.h"
#import "PBMutableExpression.h"
#import "PBArray.h"

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
    char *temp, *p2;
    NSUInteger len = strlen(str) + 1;
    
    // Binding flag
    if (*p == '=') {
        p++;
        if (*p == '=') {
            _flags.duplexBinding = 1;
            p++;
        } else {
            _flags.onewayBinding = 1;
        }
    }
    
    // Animation flag
    if (*p == '~') {
        p++;
        _flags.animated = 1;
    }
    
    // Unary operator
    switch (*p) {
        case '!':
            _flags.unaryNot = 1; p++;
            if (*p == '!') {
                _flags.unaryNot = 2; p++;
            }
            break;
        case '-': _flags.negative = 1; p++; break;
        default: break;
    }
    
    // Tag for data source
    switch (*p) {
        case '@':
            p++;
            if (*p == '[' || *p == '{') {
                return nil; // constant tag for subscript
            }
            if (*p == '^') {
                _flags.mapToActiveController = 1;
                p++;
            } else {
                p2 = temp = (char *)malloc(len - (p - str));
                while (*p != '\0' && *p != '.') {
                    *p2++ = *p++;
                }
                if (*p != '.') {
                    return nil; // should format as '@xx.xx'
                }
                *p2 = '\0';
                _alias = [[NSString alloc] initWithUTF8String:temp];
                free(temp);
                _flags.mapToAliasView = 1;
                p++;
            }
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
                _flags.mapToOwnerViewData = 1;
                p++;
            } else {
                _flags.mapToOwnerView = 1;
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
    
    if (*p == '\0') {
        return self;
    }
    
    // Variable
    p2 = temp = (char *)malloc(len - (p - str));
    // first char should be [a-z][A-Z] or '_'
    if ((*p >= 'a' && *p <= 'z') || (*p >= 'A' && *p <= 'Z') || *p == '_') {
        *p2++ = *p++;
    } else {
        NSLog(@"<%@> Variable should be start with alphabet or underline.", [[self class] description]);
        return nil;
    }
    
    while ((*p >= 'a' && *p <= 'z') || (*p >= 'A' && *p <= 'Z')
           || (*p >= '0' && *p <= '9')
           || (*p == '_')
           || (*p == '.' /* allows nested key */)) {
        *p2++ = *p++;
    }
    *p2 = '\0';
    _variable = [NSString stringWithUTF8String:temp];
    free(temp);
    
    // Arithmetic operator
    switch (*p) {
        case '+': _flags.plus = 1; p++; break;
        case '-': _flags.minus = 1; p++; break;
        case '*': _flags.times = 1; p++; break;
        case '/': _flags.divide = 1; p++; break;
        case '>': _flags.greater = 1; p++;
            if (*p == '=') {
                _flags.equal = 1;
                p++;
            }
            break;
        case '<': _flags.lesser = 1; p++;
            if (*p == '=') {
                _flags.equal = 1;
                p++;
            }
            break;
        case '=': _flags.equal = 1; p++;
            if (*p == '=') {
                _flags.equal = 2;
                p++;
            }
            break;
        case '!': _flags.multiNot = 1; p++;
            if (*p == '=') {
                _flags.equal = 1;
                p++;
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
            } else {
                // $var ? 0 : 1
                p2 = temp = (char *)malloc(len - (p - str));
                while (*p != ':' && *p != '\0') {
                    *p2++ = *p++;
                }
                if (*p != ':') {
                    NSLog(@"<%@> Missing ':' after '?', should as '?*:*'.", [[self class] description]);
                    return nil;
                }
                p++;
                *p2 = '\0';
                _rvalueForTrue = [NSString stringWithUTF8String:temp];
                
                free(temp);
            }
            break;
        default: return self;
    }
    
    // Parse right value
    p2 = temp = (char *)malloc(len - (p - str));
    while (*p != '\0') {
        *p2++ = *p++;
    }
    *p2 = '\0';
    _rvalue = [NSString stringWithUTF8String:temp];
    free(temp);
    
    return self;
}

- (void)dealloc
{
    if (_bindingOwner != nil) {
        [self unbind:_bindingOwner forKeyPath:nil];
    }
}

- (id)valueWithData:(id)data target:(id)target context:(UIView *)context
{
    return [self valueWithData:data keyPath:nil target:target context:context];
}

- (id)valueWithData:(id)data keyPath:(NSString *)keyPath target:(id)target context:(UIView *)context
{
    id dataSource = [self _dataSourceWithData:data target:target context:context];
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
    } else if (_flags.mapToOwnerView) {
        return context;
    } else if (_flags.mapToOwnerViewData) {
        return [self _dataSourceWithData:[context data] atIndex:0];
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
    } else if (_flags.mapToAliasView) {
        UIView *rootView = [context supercontroller].view;
        if (rootView == nil) {
            return nil;
        }
        
        UIView *taggedView = [rootView viewWithAlias:_alias];
        return taggedView;
    }
    return nil;
}

- (id)_dataSourceWithData:(id)data atIndex:(int)index {
    if (![data isKindOfClass:[PBArray class]]) return data;
    
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
    id value = data;
    if (value != nil && _variable != nil) {
        NSArray *keys = [_variable componentsSeparatedByString:@"."];
        for (NSString *key in keys) {
            value = [self _valueOfObject:value forKey:key];
        }
    }
    return [self valueByOperatingValue:value];
}

- (id)_valueOfObject:(id)object forKey:(NSString *)key {
    // Sometime, we needs to access methods but not properties.
    // e.g. `$datas.count==0`, the `count' here cannot access by KVC.
    if ([object isKindOfClass:[NSArray class]]) {
        if ([key isEqualToString:@"count"]) {
            return [NSNumber numberWithInteger:[object count]];
        }
    }
    
    return [object valueForKeyPath:key];
}

- (id)valueByOperatingValue:(id)value
{
    // Unary operators
    if (_flags.unaryNot) {
        BOOL temp;
        if ([value isKindOfClass:[NSNumber class]]) {
            temp = [value intValue] == 0;
        } else if ([value isKindOfClass:[NSString class]]) {
            temp = value == nil || [value length] == 0 || [value isEqualToString:@"0"];
        } else {
            temp = value == nil;
        }
        if (_flags.unaryNot == 2) {
            temp = !temp;
        }
        value = [NSNumber numberWithBool:temp];
    }
    
    if (_flags.negative) {
        double temp = -[value doubleValue];
        value = [NSNumber numberWithDouble:temp];
    }
    
    // Arithmetic operators
    if (_flags.plus) {
        double temp = [value doubleValue] + [_rvalue doubleValue];
        return [NSNumber numberWithDouble:temp];
    }
    
    if (_flags.minus) {
        double temp = [value doubleValue];
        if (_rvalue != nil) {
            temp -= [_rvalue doubleValue];
        }
        return [NSNumber numberWithDouble:temp];
    }
    
    if (_flags.times) {
        double temp = [value doubleValue] * [_rvalue doubleValue];
        return [NSNumber numberWithDouble:temp];
    }
    
    if (_flags.divide) {
        double denominator = [_rvalue doubleValue];
        double temp = [value doubleValue];
        if (denominator != 0) {
            temp /= denominator;
        }
        return [NSNumber numberWithDouble:temp];
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
            value = pass ? _rvalueForTrue : _rvalue;
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
    
    if (_variable == nil) {
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
    id value = [self valueWithData:data keyPath:targetKeyPath target:target context:context];
    [self setValue:value toTarget:target forKeyPath:targetKeyPath];
}

- (void)setValue:(id)value toTarget:(id)target forKeyPath:(NSString *)targetKeyPath {
    value = [self validatingValue:value forKeyPath:targetKeyPath];
    if ([target respondsToSelector:@selector(pb_setValue:forKeyPath:)]) {
        [target pb_setValue:value forKeyPath:targetKeyPath];
    } else {
        [target setValue:value forKeyPath:targetKeyPath]; // map value
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    id newValue = [change objectForKey:NSKeyValueChangeNewKey];
    if ([newValue isEqual:[NSNull null]]) {
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
    [self setValue:newValue toTarget:contextObject forKeyPath:contextKeyPath];
//    NSLog(@"%@->%@, %@->%@", keyPath, contextKeyPath, [[object class] description], [[contextObject class] description]);
    if (_flags.duplexBinding) {
        [contextObject addObserver:self forKeyPath:contextKeyPath options:NSKeyValueObservingOptionNew context:(__bridge void *)(object)];
    }
}

- (void)viewWillRemoveFromSuperview:(NSNotification *)notification {
    [self unbind:notification.object forKeyPath:nil];
}

- (void)unbind:(id)target forKeyPath:(NSString *)keyPath {
    if (![_bindingOwner isEqual:target]) {
        return;
    }
    
    // Free the property first if the data source is not from custom
    BOOL isMapToCustomData = (_flags.mapToData && (_flags.dataTag > 9 && _flags.dataTag != kDataTagUnset));
    if (!isMapToCustomData) {
        [_bindingData setValue:nil forKeyPath:_variable];
    }
    
    // Unobserve the property
    [_bindingData removeObserver:self forKeyPath:_variable];
    if (_flags.duplexBinding) {
        [_bindingOwner removeObserver:self forKeyPath:_bindingKeyPath];
    }
    
    _bindingKeyPath = nil;
    _bindingOwner = nil;
    _bindingData = nil;
}

#pragma mark - Debug

- (NSString *)stringValue {
    NSMutableString *s = [[NSMutableString alloc] init];
    
    // Binding flags
    if (_flags.onewayBinding) {
        [s appendString:@"="];
    } else if (_flags.duplexBinding) {
        [s appendString:@"=="];
    }
    
    // Animation flag
    if (_flags.animated) {
        [s appendString:@"~"];
    }
    
    // Unary operators
    if (_flags.unaryNot == 2) {
        [s appendString:@"!!"];
    } else if (_flags.unaryNot == 1) {
        [s appendString:@"!"];
    }
    if (_flags.negative) {
        [s appendString:@"-"];
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
    } else if (_flags.mapToOwnerView) {
        [s appendString:@"."];
    } else if (_flags.mapToOwnerViewData) {
        [s appendString:@".$"];
    } else if (_flags.mapToActiveController) {
        [s appendString:@"@"];
    } else if (_flags.mapToFormFieldText) {
        [s appendString:@">"];
    } else if (_flags.mapToFormFieldValue) {
        [s appendString:@">@"];
    } else if (_flags.mapToAliasView) {
        [s appendFormat:@"@%@.", _alias];
    }
    
    if (_variable == nil) {
        return s;
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
            [s appendFormat:@"?%@:%@",_rvalueForTrue,_rvalue];
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
        if (_flags.equal == 2) {
            [s appendString:@"=="];
        } else if (_flags.equal == 1) {
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
