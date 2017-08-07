//
//  PBMutableExpression.m
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by galen on 15/3/13.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "PBMutableExpression.h"
#import "PBValueParser.h"
#import "PBString.h"
#import "PBVariableEvaluator.h"
#import <JavascriptCore/JavascriptCore.h>
#import "Pbind+API.h"
#import "PBDictionary.h"

@interface Pbind (Private)

+ (void (^)(JSContext *))jsContextInitializer;

@end

@interface PBExpression (Private)

- (instancetype)initWithUTF8String:(const char *)str;
- (void)setValueToTarget:(id)target forKeyPath:(NSString *)targetKeyPath withData:(id)data context:(UIView *)context;
- (id)_dataSourceWithData:(id)data target:(id)target context:(UIView *)context;

@end

@implementation PBMutableExpression

+ (JSContext *)sharedJSContext {
    static JSContext *context = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        context = [[JSContext alloc] init];
        void (^initializer)(JSContext *) = [Pbind jsContextInitializer];
        if (initializer != nil) {
            initializer(context);
        }
    });
    return context;
}

- (instancetype)initWithUTF8String:(const char *)str {
    char *p = (char *)str;
    char fmtStart = 0, fmtEnd = 0;
    switch (*str) {
        case '%':
            p++;
            if (*p == '=') {
                // Mutable variable binding
                p++;
                if (*p == '=') {
                    p++;
                    _flags.duplexBinding = 1;
                } else {
                    _flags.onewayBinding = 1;
                }
            } else {
                fmtStart = '(';
                fmtEnd = ')';
            }
            break;
        case '`':
            p++;
            fmtEnd = '`';
            _keywordFlags.backticks = 1;
            _formatFlags.javascript = 1;
            break;
        case '@':
            p++;
            if (*p != '"') {
                return [super initWithUTF8String:str];
            }
            p++;
            fmtEnd = '"';
            _keywordFlags.string = 1;
            break;
        default:
            return [super initWithUTF8String:str];
    }
    
    NSUInteger len = strlen(str) + 1;
    char *temp;
    char *p2;
    
    if (fmtStart != 0) {
        if (*p != fmtStart) {
            // Parse format tag before `fmtStart'
            char *tag_pos = NULL;
            p2 = temp = (char *)malloc(len - (p - str));
            while (*p != '\0' && *p != fmtStart) {
                if (*p == ':') {
                    tag_pos = p2;
                }
                *p2++ = *p++;
            }
            if (*p == '\0') return nil;
            
            *p2 = '\0';
            if (tag_pos != NULL) {
                *tag_pos = '\0';
                tag_pos++;
                _formatterTag = [NSString stringWithUTF8String:tag_pos];
            }
            NSString *tag = [NSString stringWithUTF8String:temp];
            free(temp);
            if ([tag isEqualToString:@"!"]) {
                _formatFlags.testEmpty = 1;
            } else if ([tag isEqualToString:@"JS"]) {
                _formatFlags.javascript = 1;
            } else if ([tag isEqualToString:@"AT"]) {
                _formatFlags.attributedText = 1;
            } else {
                _formatter = [PBVariableEvaluator evaluatorForTag:tag];
                if (_formatter != nil) {
                    _formatFlags.customized = 1;
                } else {
                    NSLog(@"PBMutableExpression: Unknown format tag:`%@'", tag);
                    return nil;
                }
            }
        }
        
        p++; // bypass `fmtStart'
    }
    
    if (fmtEnd != 0) {
        // Parse format text between `fmtStart' and `fmtEnd'
        p2 = temp = (char *)malloc(len - (p - str));
        while (*p != '\0' && !(*p == fmtEnd && *(p + 1) == ',')) {
            *p2++ = *p++;
        }
        if (*p == '\0') {
            if ([self requiresExpression]) {
                NSLog(@"Pbind: the expression %s should takes 1 expression as least.");
                return nil;
            } else if (*(p - 1) != fmtEnd) {
                NSLog(@"Pbind: the expression %s should ends with %c.", str, fmtEnd);
                return nil;
            } else {
                *(p2 - 1) = '\0';
                _format = [NSString stringWithUTF8String:temp];
                free(temp);
                return self;
            }
        }
        
        *p2 = '\0';
        _format = [NSString stringWithUTF8String:temp];
        free(temp);
        
        p += 2; // bypass `fmtEnd' and ','
    }
    
    char attrStart = ';';
    
    // Variable args
    p2 = temp = (char *)malloc(len - (p - str));
    while (*p != '\0' && *p != attrStart) {
        *p2++ = *p++;
    }
    *p2 = '\0';
    NSString *args =[NSString stringWithUTF8String:temp];
    free(temp);
    [self initExpressionsWithString:args];
    
    if ((_flags.onewayBinding || _flags.duplexBinding) && _expressions.count < 2) {
        NSLog(@"PBMutableExpression: '%%=' or '%%==' should keep up with as least as 2 expressions.");
        return nil;
    }
    
    if (*p == '\0' || _formatFlags.attributedText == 0) {
        return self;
    }
    
    // Attributes
    p++;
    NSMutableArray *attributes = [[NSMutableArray alloc] init];
    while (*p != '\0') {
        p2 = temp = (char *)malloc(len - (p - str));
        while (*p != '\0' && *p != '|') {
            *p2++ = *p++;
        }
        *p2 = '\0';
        NSDictionary *attribute = [self attributeFromUTF8String:temp];
        [attributes addObject:attribute];
        free(temp);
        
        if (*p != '\0') {
            p++;
        }
    }
    _attributes = attributes;
    
    return self;
}

- (instancetype)initWithProperties:(PBMapperProperties *)properties
{
    if (self = [super init]) {
        _properties = properties;
    }
    return self;
}

- (void)initExpressionsWithString:(NSString *)aString
{
    NSArray *components = [aString componentsSeparatedByString:@","];
    NSMutableArray *expressions = [[NSMutableArray alloc] initWithCapacity:[components count]];
    for (NSString *exp in components) {
        PBExpression *expression = [[PBExpression alloc] initWithString:exp];
        expression.parent = self;
        [expressions addObject:expression];
    }
    
    if ([expressions count] == 0) {
        _rvalue = aString;
    } else {
        _expressions = expressions;
    }
}

- (void)dealloc
{
    _properties = nil;
    _expressions = nil;
}

- (id)_dataSourceWithData:(id)data target:(id)target context:(UIView *)context
{
    if (_expressions != nil && (_flags.onewayBinding || _flags.duplexBinding)) {
        PBExpression *mainExpression = _expressions[0];
        id dataSource = [mainExpression _dataSourceWithData:data target:target context:context];
        if (mainExpression->_variable != nil) {
            return [dataSource valueForKeyPath:mainExpression->_variable];
        } else {
            return dataSource;
        }
    }
    
    return [super _dataSourceWithData:data target:target context:context];
}

- (BOOL)requiresExpression {
    return !_keywordFlags.backticks && !_formatFlags.customized;
}

- (BOOL)matchesType:(PBMapType)type dataTag:(unsigned char)dataTag
{
    if (_properties != nil) {
        return [_properties matchesType:type dataTag:dataTag];
    }
    
    if (_expressions != nil) {
        for (PBExpression *exp in _expressions) {
            if ([exp matchesType:type dataTag:dataTag]) {
                return YES;
            }
        }
        return NO;
    }
    
    if (![self requiresExpression]) {
        // Always match literals
        return YES;
    }
    
    return [super matchesType:type dataTag:dataTag];
}

- (void)bindData:(id)data toTarget:(id)target forKeyPath:(NSString *)targetKeyPath inContext:(UIView *)context
{
    if (_flags.disabled) {
        return;
    }
    
    if (_expressions == nil) {
        return [super bindData:data toTarget:target forKeyPath:targetKeyPath inContext:context];
    }
    
    if (_flags.onewayBinding || _flags.duplexBinding) {
        if (![self initMutableVariableWithData:data keyPath:targetKeyPath target:target context:context]) {
            return;
        }
        
        return [super bindData:data toTarget:target forKeyPath:targetKeyPath inContext:context];
    }
    
    for (PBExpression *exp in _expressions) {
        [exp bindData:data toTarget:target forKeyPath:targetKeyPath inContext:context];
    }
}

- (void)unbind:(id)target forKeyPath:(NSString *)keyPath
{
    if (_properties != nil) {
        target = [target valueForKey:keyPath];
        [_properties unbind:target];
        return;
    }
    
    if (_expressions != nil) {
        for (PBExpression *exp in _expressions) {
            [exp unbind:target forKeyPath:keyPath];
        }
        return;
    }
    
    return [super unbind:target forKeyPath:keyPath];
}

- (void)mapData:(id)data toTarget:(id)target forKeyPath:(NSString *)targetKeyPath inContext:(UIView *)context
{
    if (_flags.disabled) {
        return;
    }
    
    if (_format != nil) {
        [self setValueToTarget:target forKeyPath:targetKeyPath withData:data context:context];
        [self bindData:data toTarget:target forKeyPath:targetKeyPath inContext:context];
    } else {
        [super mapData:data toTarget:target forKeyPath:targetKeyPath inContext:context];
    }
}

- (id)valueWithData:(id)data keyPath:(NSString *)keyPath target:(id)target context:(UIView *)context
{
    if (_format != nil) {
        NSMutableArray *arguments = [[NSMutableArray alloc] init];
        for (PBExpression *exp in _expressions) {
            id value = [exp valueWithData:data target:target context:context];
            if (value == nil) {
                if (_formatFlags.testEmpty) {
                    value = [NSNull null];
                }
                value = @"";
            }
            [arguments addObject:value];
        }
        return [self formatedValueWithArguments:arguments];
    } else if (_properties != nil) {
        id value = [target valueForKeyPath:keyPath];
        if (value == nil) {
            value = [NSMutableDictionary dictionaryWithCapacity:_properties.count];
            [_properties initDataForOwner:value];
            [target setValue:value forKeyPath:keyPath];
        }
        
        [_properties mapData:data toTarget:value withContext:context];
        return value;
    } else if ((_flags.onewayBinding || _flags.duplexBinding) && _variable == nil) {
        if (![self initMutableVariableWithData:data keyPath:keyPath target:target context:context]) {
            return nil;
        }
    }
    return [super valueWithData:data keyPath:keyPath target:target context:context];
}

- (BOOL)initMutableVariableWithData:(id)data
                            keyPath:(NSString *)keyPath
                             target:(id)target
                            context:(UIView *)context {
    if (_variable != nil) {
        return YES;
    }
    
    NSInteger numberOfExpressions = _expressions.count;
    NSMutableArray *keys = [NSMutableArray arrayWithCapacity:numberOfExpressions - 1];
    for (NSInteger index = 1; index < numberOfExpressions; index++) {
        PBExpression *keyExpression = _expressions[index];
        NSString *key = [keyExpression valueWithData:data keyPath:keyPath target:target context:context];
        if (key == nil) {
            // Something was not ready, hold on...
            return NO;
        }
        
        [keys addObject:key];
    }
    
    _variable = [keys componentsJoinedByString:@"."];
    return YES;
}

#pragma mark - Helper

- (id)formatedValueWithArguments:(NSMutableArray *)arguments
{
    _formatedArguments = arguments;
    NSString *text = nil;
    if (_formatFlags.javascript) {
        JSContext *context = [[self class] sharedJSContext];
        int argCount = (int) arguments.count;
        
        // Map each argument to $1 ~ $N
        for (int argIndex = 0; argIndex < argCount; argIndex++) {
            id arg = [arguments objectAtIndex:argIndex];
            NSString *key = [NSString stringWithFormat:@"$%i", (argIndex + 1)];
            context[key] = arg;
        }
        
        // Evaluate by Javascript
        JSValue *result;
        NSString *js = _format;
        NSString *type = _formatterTag;
        char c = [js characterAtIndex:0];
        switch (c) {
            case '{': // suppose as a JS object
            case '[': // suppose as a JS array
                js = [NSString stringWithFormat:@"_=%@;_", js];
            default:
                break;
        }
        
        result = [context evaluateScript:js];
        
        // Wrap struct values
        if (type != nil && [result isObject]) {
            if ([type isEqualToString:@"point"]) {
                return [NSValue valueWithCGPoint:[result toPoint]];
            } else if ([type isEqualToString:@"range"]) {
                return [NSValue valueWithRange:[result toRange]];
            } else if ([type isEqualToString:@"rect"]) {
                return [NSValue valueWithCGRect:[result toRect]];
            } else if ([type isEqualToString:@"size"]) {
                return [NSValue valueWithCGSize:[result toSize]];
            }
        }
        
        // Return the automically converted value
        return [result toObject];
    } else if (_formatFlags.attributedText) {
        text = [PBString stringWithFormat:_format array:arguments];
        text = [text stringByReplacingOccurrencesOfString:@"\\n" withString:@"\n"];
        NSArray *texts = [text componentsSeparatedByString:@"|"];
        text = [texts componentsJoinedByString:@""];
        NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:text attributes:nil];
        NSInteger count = MIN(texts.count, _attributes.count);
        for (NSInteger index = 0; index < count; index++) {
            NSString *aText = [texts objectAtIndex:index];
            NSRange range = [text rangeOfString:aText];
            NSDictionary *attribute = [_attributes objectAtIndex:index];
            [attributedString addAttributes:attribute range:range];
//            NSLog(@"[%i] %@ - %@", (int)index, aText, [attribute objectForKey:NSForegroundColorAttributeName]);
        }
        return attributedString;
    } else if (_formatFlags.customized) {
        text = _formatter(_formatterTag, _format, arguments);
        return text;
    } else {
        if (_formatFlags.testEmpty) {
            for (id arg in arguments) {
                if (arg == nil || [arg isEqual:[NSNull null]]
                    || ([arg isKindOfClass:[NSString class]] && [arg length] == 0)) {
                    return nil;
                }
            }
        }
        NSString *format = [_format stringByReplacingOccurrencesOfString:@"\\n" withString:@"\n"];
        return [PBString stringWithFormat:format array:arguments];
    }
}

- (NSDictionary *)attributeFromUTF8String:(const char *)str
{
    // foregroundColor-font : #FFF-{F:13}
    NSMutableDictionary *attribute = [NSMutableDictionary dictionary];
    char *p = (char *)str;
    char *p2;
    char *temp;
    
    if (*p == '#') {
        // Parse color
        p2 = temp = (char *)malloc(strlen(str));
        while (*p != '\0' && *p != '-') {
            *p2++ = *p++;
        }
        *p2 = '\0';
        NSString *colorString = [NSString stringWithUTF8String:temp];
        free(temp);
        UIColor *color = [PBValueParser valueWithString:colorString];
        if (color != nil) {
            [attribute setObject:color forKey:NSForegroundColorAttributeName];
        }
        if (*p == '\0') {
            return attribute;
        }
        p++;
    }
    
    if (*p == '{') {
        // Parse font
        p2 = temp = (char *)malloc(strlen(str));
        while (*p != '\0') {
            *p2++ = *p++;
        }
        *p2 = '\0';
        NSString *fontString = [NSString stringWithUTF8String:temp];
        free(temp);
        UIFont *font = [PBValueParser valueWithString:fontString];
        if (font != nil) {
            [attribute setObject:font forKey:NSFontAttributeName];
        }
    }
    
    return attribute;
}

@end

#pragma mark - Private

@interface PBMutableExpression (Private)

- (id)valueByUpdatingObservedValue:(id)value fromChild:(PBExpression *)child;

@end

@implementation PBMutableExpression (Private)

- (id)valueByUpdatingObservedValue:(id)value fromChild:(PBExpression *)child
{
    if (_format != nil && _formatedArguments != nil) {
        NSInteger index = [_expressions indexOfObject:child];
        if (index == NSNotFound) {
            return value;
        }
        
        if (value == nil) {
            if (_formatFlags.testEmpty) {
                return nil;
            }
            value = [NSNull null];
        }
        [_formatedArguments replaceObjectAtIndex:index withObject:value];
        return [self formatedValueWithArguments:_formatedArguments];
    }
    return value;
}

#pragma mark - Debug

- (id)source {
    if (_format == nil) {
        if (_properties == nil) {
            return [super source];
        }
        
        return [_properties source];
    }
    
    NSMutableString *s = [NSMutableString string];
    NSString *fmtStart = nil;
    NSString *fmtEnd = nil;
    if (_keywordFlags.backticks) {
        fmtStart = fmtEnd = @"`";
    } else if (_keywordFlags.string) {
        [s appendString:@"@"];
        fmtStart = fmtEnd = @"\"";
    } else {
        [s appendString:@"%"];
        if (_formatFlags.testEmpty) {
            [s appendString:@"!"];
        } else if (_formatFlags.javascript) {
            [s appendString:@"JS"];
        } else if (_formatFlags.attributedText) {
            [s appendString:@"AT"];
        } else if (_formatFlags.customized) {
            NSArray *allTags = [PBVariableEvaluator allTags];
            for (NSString *tag in allTags) {
                if (_formatter == [PBVariableEvaluator evaluatorForTag:tag]) {
                    [s appendString:tag];
                    break;
                }
            }
        }
        if (_formatterTag != nil) {
            [s appendFormat:@":%@", _formatterTag];
        }
        
        fmtStart = @"(";
        fmtEnd = @")";
    }
    
    if (fmtStart != nil) {
        [s appendString:fmtStart];
    }
    [s appendString:_format];
    if (fmtEnd != nil) {
        [s appendString:fmtEnd];
    }
    
    for (PBExpression *exp in _expressions) {
        [s appendString:@","];
        [s appendString:[exp stringValue]];
    }
    if (_attributes != nil) {
        [s appendString:@";"];
        NSMutableArray *attrStrings = [NSMutableArray arrayWithCapacity:_attributes.count];
        for (NSDictionary *attr in _attributes) {
            NSMutableString *temp = [NSMutableString string];
            UIColor *color = [attr objectForKey:NSForegroundColorAttributeName];
            if (color != nil) {
                const CGFloat *components = CGColorGetComponents(color.CGColor);
                CGFloat r = components[0];
                CGFloat g = components[1];
                CGFloat b = components[2];
                NSString *hexString=[NSString stringWithFormat:@"#%02X%02X%02X", (int)(r * 255), (int)(g * 255), (int)(b * 255)];
                [temp appendString:hexString];
            }
            
            UIFont *font = [attr objectForKey:NSFontAttributeName];
            if (font != nil) {
                if (color != nil) {
                    [temp appendString:@"-"];
                }
                [temp appendFormat:@"{F:%i}", (int) (font.pointSize / [Pbind valueScale] + .5f)];
            }
            [attrStrings addObject:temp];
        }
        [s appendString:[attrStrings componentsJoinedByString:@"|"]];
    }
    
    return s;
}

@end
