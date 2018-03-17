//
//  PBExpression.m
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by galen on 15/2/26.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
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
#import "PBActionStore.h"
#import "PBPropertyUtils.h"
#import "UIViewController+PBExpression.h"
#import <objc/runtime.h>

const unsigned char PBDataTagUnset = 0xFF;

@interface PBForm (Private)

- (PBDictionary *)inputTexts;
- (PBDictionary *)inputValues;
- (PBDictionary *)inputErrorTips;

@end

@interface PBMutableExpression (Private)

- (id)valueByUpdatingObservedValue:(id)value fromChild:(PBExpression *)child;

@end

@interface PBExpression ()

@property (nonatomic, weak) id bindingOwner;
@property (nonatomic, weak) id bindingData;
@property (nonatomic, weak) id originalBindingOwner;

@end

@implementation PBExpression
{
    NSArray *_variableKeys;
}

+ (instancetype)expressionWithString:(NSString *)aString
{
    return [[self alloc] initWithString:aString];
}

- (instancetype)initWithString:(NSString *)aString
{
    if ([aString length] == 0 || [aString isEqual:[NSNull null]]) {
        return nil;
    }
    
    _flags.dataTag = PBDataTagUnset;
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
            
            if (*p == '\0') {
                _flags.mapToContext = 1;
                return self;
            }
            
            if (*p == '^') {
                _flags.mapToActiveController = 1;
            } else if (*p == '>') {
                _flags.mapToForm = 1;
            } else if (*p == '~') {
                _flags.mapToTemporary = 1;
            } else if (*p == '.') {
                _flags.mapToContext = 1;
            } else {
                p2 = temp = (char *)malloc(len - (p - str));
                while (*p != '\0'
                       && *p != '.'
                       && ((*p >= 'a' && *p <= 'z')
                           || (*p >= 'A' && *p <= 'Z')
                           || (*p >= '0' && *p <= '9')
                           || (*p == '_'))) {
                    *p2++ = *p++;
                }
                if (*p != '.' && *p != '\0') {
                    free(temp);
                    return nil; // should format as '@xx.xx'
                }
                
                *p2 = '\0';
                _alias = [[NSString alloc] initWithUTF8String:temp];
                free(temp);
                _flags.mapToAliasView = 1;
                if (*p == '\0') {
                    return self;
                }
            }
            p++;
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
            } else if (*(p + 1) == '\0') {
                if (*p >= '0' && *p <= '9') {
                    _flags.dataTag = *p - '0';
                    p++;
                }
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
            if (*p == '$') {
                _flags.mapToFormFieldValue = 1;
                p++;
            } else if (*p == '!') {
                _flags.mapToFormFieldError = 1;
                p++;
            } else {
                char *pBak = p;
                p2 = temp = (char *)malloc(len - (p - str));
                while (*p != '\0' && *p != '.') {
                    *p2++ = *p++;
                }
                if (*p != '.') {
                    free(temp);
                    _flags.mapToFormFieldText = 1;
                    p = pBak;
                } else {
                    *p2 = '\0';
                    _alias = [[NSString alloc] initWithUTF8String:temp];
                    free(temp);
                    _flags.mapToFormField = 1;
                    p++;
                }
            }
            break;
        case '#':
            p++;
            if (*p == '.') {
                _flags.mapToActionState = 1;
                p++;
            } else if (*p == '$') {
                _flags.mapToActionStateData = 1;
                p++;
            } else {
                return nil;
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
        free(temp);
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
    _variableKeys = [_variable componentsSeparatedByString:@"."];
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
                    free(temp);
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

- (id)valueWithData:(id)data target:(id)target owner:(UIView *)owner context:(UIView *)context
{
    return [self valueWithData:data keyPath:nil target:target owner:owner context:context];
}

- (id)valueWithData:(id)data keyPath:(NSString *)keyPath target:(id)target owner:(UIView *)owner context:(UIView *)context
{
    id dataSource = [self _dataSourceWithData:data target:target owner:owner context:context];
    return [self _valueWithData:dataSource];
}

- (id)_dataSourceWithData:(id)data target:(id)target owner:(UIView *)owner context:(UIView *)context {
    if (_flags.mapToData) {
        int dataIndex = 0;
        if (_flags.dataTag >= 0 && _flags.dataTag <= 9) {
            dataIndex = _flags.dataTag;
        } else if (_flags.dataTag != PBDataTagUnset) {
            id (^mapper)(id data, id target, UIView *context) = [PBVariableMapper mapperForTag:_flags.dataTag];
            return mapper(data, target, context);
        }
        
        return [self _dataSourceWithData:data atIndex:dataIndex];
    } else if (_flags.mapToActionState) {
        return [PBActionStore defaultStore].state;
    } else if (_flags.mapToActionStateData) {
        return [PBActionStore defaultStore].state.data;
    } else if (_flags.mapToOwnerView) {
        return owner;
    } else if (_flags.mapToOwnerViewData) {
        return [self _dataSourceWithData:[owner data] atIndex:0];
    } else if (_flags.mapToActiveController) {
        return [context supercontroller];
    } else if (_flags.mapToTemporary) {
        UIViewController *owningVC = [context supercontroller];
        if (owningVC == nil) {
            return nil;
        }
        return owningVC.pb_temporaries;
    } else if (_flags.mapToForm) {
        PBForm *form = [self _formOfView:context];
        return form;
    } else if (_flags.mapToFormField) {
        PBForm *form = [self _formOfView:context];
        if (form == nil) {
            return nil;
        }
        return [form inputForName:_alias];
    } else if (_flags.mapToFormFieldText) {
        PBForm *form = [self _formOfView:context];
        if (form == nil) {
            return nil;
        }
        return [form inputTexts];
    } else if (_flags.mapToFormFieldValue) {
        PBForm *form = [self _formOfView:context];
        if (form == nil) {
            return nil;
        }
        return [form inputValues];
    } else if (_flags.mapToFormFieldError) {
        PBForm *form = [self _formOfView:context];
        if (form == nil) {
            return nil;
        }
        return [form inputErrorTips];
    } else if (_flags.mapToAliasView) {
        UIView *aliasView = [owner viewWithAlias:_alias];
        if (aliasView != nil) {
            return aliasView;
        }
        
        aliasView = [self _viewAliased:_alias inSuperviewWithoutSubview:owner];
        if (aliasView != nil) {
            return aliasView;
        }
        
        UIView *rootView = [context supercontroller].view;
        if (rootView != nil && ![aliasView isDescendantOfView:rootView]) {
            return [rootView viewWithAlias:_alias];
        }
    } else if (_flags.mapToContext) {
        return context;
    }
    return nil;
}

- (UIView *)_viewAliased:(NSString *)alias inSuperviewWithoutSubview:(UIView *)ignoringSubview {
    UIView *superview = ignoringSubview.superview;
    if (superview == nil) {
        return nil;
    }
    
    for (UIView *subview in superview.subviews) {
        if (subview == ignoringSubview) {
            continue;
        }
        
        UIView *aliasView = [subview viewWithAlias:alias];
        if (aliasView != nil) {
            return aliasView;
        }
    }
    return [self _viewAliased:alias inSuperviewWithoutSubview:superview];
}

- (PBForm *)_formOfView:(UIView *)view {
    Class formClass = [PBForm class];
    if ([view isKindOfClass:formClass]) {
        return (id) view;
    }
    return [view superviewWithClass:formClass];
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
    return [self valueWithData:data target:target owner:nil context:nil];
}

- (id)valueWithData:(id)data
{
    return [self valueWithData:data target:nil];
}

- (id)_valueWithData:(id)data
{
    id value = data;
    if (value != nil && _variableKeys != nil) {
        for (NSString *key in _variableKeys) {
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
    
    return [PBPropertyUtils valueForKeyPath:key ofObject:object failure:nil];
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

- (void)bindData:(id)data toTarget:(id)target forKeyPath:(NSString *)targetKeyPath withOwner:(UIView *)owner inContext:(UIView *)context
{
    if (_flags.disabled) {
        return;
    }
    
    if (_bindingOwner != nil) {
        return;
    }
    
    if (_variable == nil) {
        return;
    }
    
    if (_flags.duplexBinding || _flags.onewayBinding) {
        id dataSource = [self _dataSourceWithData:data target:target owner:owner context:context];
        if (dataSource == nil) {
            return;
        }
        self.originalBindingOwner = target;
        if ([targetKeyPath hasPrefix:@"@"] && [target isKindOfClass:[UIView class]]) {
            NSInteger dotIndex = [targetKeyPath rangeOfString:@"."].location;
            if (dotIndex != NSNotFound) {
                NSString *prefix = [targetKeyPath substringToIndex:dotIndex];
                targetKeyPath = [targetKeyPath substringFromIndex:dotIndex + 1];
                target = [target viewWithAlias:[prefix substringFromIndex:1]];
            }
        }
        _bindingKeyPath = targetKeyPath;
        self.bindingData = dataSource;
        self.bindingOwner = target;
        _initialDataSourceValue = [PBPropertyUtils valueForKeyPath:_variable ofObject:dataSource failure:nil];
        [dataSource addObserver:self forKeyPath:_variable options:NSKeyValueObservingOptionNew context:nil];
        if (_flags.duplexBinding) {
            [target addObserver:self forKeyPath:targetKeyPath options:NSKeyValueObservingOptionNew context:nil];
        }
    }
}

- (BOOL)matchesType:(PBMapType)type dataTag:(unsigned char)dataTag {
    if (_flags.mapToData) {
        if ((type & PBMapToData) == 0) {
            return NO;
        }
        if (dataTag == PBDataTagUnset) {
            return YES;
        }
        return _flags.dataTag == dataTag;
    }
    if (_flags.mapToOwnerView) {
        return (type & PBMapToOwnerView) != 0;
    }
    if (_flags.mapToOwnerViewData) {
        return (type & PBMapToOwnerViewData) != 0;
    }
    if (_flags.mapToFormFieldText) {
        return (type & PBMapToFormFieldText) != 0;
    }
    if (_flags.mapToFormFieldValue) {
        return (type & PBMapToFormFieldValue) != 0;
    }
    if (_flags.mapToFormFieldError) {
        return (type & PBMapToFormFieldError) != 0;
    }
    if (_flags.mapToFormField) {
        return (type & PBMapToFormField) != 0;
    }
    if (_flags.mapToForm) {
        return (type & PBMapToForm) != 0;
    }
    if (_flags.mapToActiveController) {
        return (type & PBMapToActiveController) != 0;
    }
    if (_flags.mapToTemporary) {
        return (type & PBMapToTemporary) != 0;
    }
    if (_flags.mapToAliasView) {
        return (type & PBMapToAliasView) != 0;
    }
    if (_flags.mapToContext) {
        return (type & PBMapToContext) != 0;
    }
    if (_flags.mapToActionState) {
        return (type & PBMapToActionState) != 0;
    }
    if (_flags.mapToActionStateData) {
        return (type & PBMapToActionStateData) != 0;
    }
    return NO;
}

- (void)mapData:(id)data toTarget:(id)target forKeyPath:(NSString *)targetKeyPath withOwner:(UIView *)owner inContext:(UIView *)context
{
    if (_flags.disabled) {
        return;
    }
    
    char flag = [targetKeyPath characterAtIndex:0];
    switch (flag) {
        case '+': {
            NSString *keyPath = [targetKeyPath substringFromIndex:1];
            [self setValueToTarget:target forKeyPath:keyPath withData:data owner:owner context:context]; // map value
            [self bindData:data toTarget:target forKeyPath:keyPath withOwner:owner inContext:context]; // binding data
        }
            break;
        default: {
            [self setValueToTarget:target forKeyPath:targetKeyPath withData:data owner:owner context:context]; // map value
            [self bindData:data toTarget:target forKeyPath:targetKeyPath withOwner:owner inContext:context]; // binding data
        }
            break;
    }
}

#pragma mark - KVC

- (void)setValueToTarget:(id)target forKeyPath:(NSString *)targetKeyPath withData:(id)data owner:(UIView *)owner context:(UIView *)context {
    id value = [self valueWithData:data keyPath:targetKeyPath target:target owner:owner context:context];
    [self setValue:value toTarget:target forKeyPath:targetKeyPath];
}

- (void)setValue:(id)value toTarget:(id)target forKeyPath:(NSString *)targetKeyPath {
    value = [self validatingValue:value forKeyPath:targetKeyPath];
    if ([target respondsToSelector:@selector(pb_setValue:forKeyPath:)]) {
        [target pb_setValue:value forKeyPath:targetKeyPath];
    } else {
        [PBPropertyUtils setValue:value forKeyPath:targetKeyPath toObject:target failure:nil];
    }
}

- (id)valueForKeyPath:(NSString *)keyPath ofTarget:(id)target {
    if ([target respondsToSelector:@selector(pb_valueForKeyPath:)]) {
        return [target pb_valueForKeyPath:keyPath];
    }
    return [PBPropertyUtils valueForKeyPath:keyPath ofObject:target failure:nil];
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    id newValue = [change objectForKey:NSKeyValueChangeNewKey];
    if ([newValue isEqual:[NSNull null]]) {
        newValue = nil;
    }
    id contextObject;
    NSString *contextKeyPath;
    if ([keyPath isEqualToString:_variable]) {
        // Data source value changed
        contextKeyPath = _bindingKeyPath;
        contextObject = _bindingOwner;
        newValue = [self valueByOperatingValue:newValue];
        if (self.parent != nil) {
            PBMutableExpression *parent = (id) self.parent;
            newValue = [parent valueByUpdatingObservedValue:newValue fromChild:self];
        }
    } else {
        contextKeyPath = _variable;
        contextObject = _bindingData;
    }
    
    id oldValue = [self valueForKeyPath:contextKeyPath ofTarget:contextObject];
    if ((oldValue == nil && newValue == nil) || [oldValue isEqual:newValue]) {
        return;
    }
    
    if (_flags.duplexBinding) {
        [contextObject removeObserver:self forKeyPath:contextKeyPath context:nil];
    }
    [self setValue:newValue toTarget:contextObject forKeyPath:contextKeyPath];
//    NSLog(@"%@->%@, %@->%@", keyPath, contextKeyPath, [[object class] description], [[contextObject class] description]);
    if (_flags.duplexBinding) {
        [contextObject addObserver:self forKeyPath:contextKeyPath options:NSKeyValueObservingOptionNew context:nil];
    }
}

- (void)viewWillRemoveFromSuperview:(NSNotification *)notification {
    [self unbind:notification.object forKeyPath:nil];
}

- (void)unbind:(id)target forKeyPath:(NSString *)keyPath {
    if (_originalBindingOwner != target && _bindingOwner != target) {
        return;
    }
    
    if (_flags.duplexBinding) {
        // Reset to the initial value for the key of the data source, with the duplex data binding, this would also reset the value of the binding owner.
        BOOL isMapToCustomData = (_flags.mapToData && (_flags.dataTag > 9 && _flags.dataTag != PBDataTagUnset));
        if (!isMapToCustomData) {
            if ([_bindingData respondsToSelector:@selector(pb_setValue:forKeyPath:)]) {
                [_bindingData pb_setValue:_initialDataSourceValue forKeyPath:_variable];
            } else {
                [PBPropertyUtils setValue:_initialDataSourceValue forKeyPath:_variable toObject:_bindingData failure:nil];
            }
            _initialDataSourceValue = nil;
        }
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

#pragma mark - Properties

- (BOOL)isEnabled {
    return !_flags.disabled;
}

- (void)setEnabled:(BOOL)enabled {
    _flags.disabled = !enabled;
}

#pragma mark - Debug

- (id)source {
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
        } else if (_flags.dataTag != PBDataTagUnset) {
            [s appendFormat:@"$%c.", _flags.dataTag];
        } else {
            [s appendString:@"$"];
        }
    } else if (_flags.mapToOwnerView) {
        [s appendString:@"."];
    } else if (_flags.mapToOwnerViewData) {
        [s appendString:@".$"];
    } else if (_flags.mapToActiveController) {
        [s appendString:@"@^"];
    } else if (_flags.mapToTemporary) {
        [s appendString:@"@~"];
    } else if (_flags.mapToForm) {
        [s appendString:@"@>"];
    } else if (_flags.mapToFormFieldText) {
        [s appendString:@">"];
    } else if (_flags.mapToFormFieldValue) {
        [s appendString:@">$"];
    } else if (_flags.mapToFormFieldError) {
        [s appendString:@">!"];
    } else if (_flags.mapToFormField) {
        [s appendFormat:@">%@.", _alias];
    } else if (_flags.mapToAliasView) {
        [s appendFormat:@"@%@.", _alias];
    } else if (_flags.mapToContext) {
        [s appendString:@"@."];
    } else if (_flags.mapToActionState) {
        [s appendString:@"#."];
    } else if (_flags.mapToActionStateData) {
        [s appendString:@"#$"];
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

- (NSString *)stringValue {
    id source = [self source];
    if ([source isKindOfClass:[NSString class]]) {
        return source;
    }
    return [NSString stringWithFormat:@"%@", source];
}

- (NSString *)debugDescription
{
    return [NSString stringWithFormat:@"<%@: %p>\n - \"%@\"", [[self class] description], self, [self stringValue]];
}

@end
