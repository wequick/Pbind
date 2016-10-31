//
//  PBMutableExpression.m
//  Pbind
//
//  Created by galen on 15/3/13.
//  Copyright (c) 2015年 galen. All rights reserved.
//

#import "PBMutableExpression.h"
#import "PBValueParser.h"
#import "PBString.h"
#import "PBVariableEvaluator.h"
#import <JavascriptCore/JavascriptCore.h>
#import "Pbind+API.h"

typedef id (*JSValueConvertorFunc)(id, SEL);

@interface PBExpression (Private)

- (instancetype)initWithUTF8String:(const char *)str;
- (void)setValueToTarget:(id)target forKeyPath:(NSString *)targetKeyPath withData:(id)data context:(UIView *)context;

@end

@implementation PBMutableExpression

+ (JSContext *)sharedJSContext {
    static JSContext *context = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        context = [[JSContext alloc] init];
    });
    return context;
}

- (instancetype)initWithUTF8String:(const char *)str {
    if (*str != '%') {
        return [super initWithUTF8String:str];
    }
    
    // Format tag
    char *p = (char *)(str + 1);
    NSUInteger len = strlen(str) + 1;
    char *temp;
    char *p2;
    
    if (*p != '(') {
        char *tag_pos = NULL;
        p2 = temp = (char *)malloc(len - (p - str));
        while (*p != '\0' && *p != '(') {
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
                NSLog(@"Unknown format tag:`%@'", tag);
                return self;
            }
        }
    }
    
    // Format text
    p++;
    p2 = temp = (char *)malloc(len - (p - str));
    while (*p != '\0' && !(*p == ')' && *(p + 1) == ',')) {
        *p2++ = *p++;
    }
    if (*p == '\0') return nil;
    
    *p2 = '\0';
    _format = [NSString stringWithUTF8String:temp];
    free(temp);
    
    // Variable args
    p += 2;
    p2 = temp = (char *)malloc(len - (p - str));
    while (*p != '\0' && *p != ';') {
        *p2++ = *p++;
    }
    *p2 = '\0';
    NSString *args =[NSString stringWithUTF8String:temp];
    free(temp);
    [self initExpressionsWithString:args];
    
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

- (void)bindData:(id)data toTarget:(id)target forKeyPath:(NSString *)targetKeyPath inContext:(UIView *)context
{
    if (_expressions == nil) {
        return [super bindData:data toTarget:target forKeyPath:targetKeyPath inContext:context];
    }
    
    for (PBExpression *exp in _expressions) {
        [exp bindData:data toTarget:target forKeyPath:targetKeyPath inContext:context];
    }
}

- (void)mapData:(id)data toTarget:(id)target forKeyPath:(NSString *)targetKeyPath inContext:(UIView *)context
{
    if (_format != nil) {
        [self setValueToTarget:target forKeyPath:targetKeyPath withData:data context:context];
        [self bindData:data toTarget:target forKeyPath:targetKeyPath inContext:context];
    } else {
        [super mapData:data toTarget:target forKeyPath:targetKeyPath inContext:context];
    }
}

- (id)valueWithData:(id)data target:(id)target context:(UIView *)context
{
    if (_format != nil) {
        NSMutableArray *arguments = [[NSMutableArray alloc] init];
        for (PBExpression *exp in _expressions) {
            id value = [exp valueWithData:data target:target context:context];
            if (value == nil) {
                if (_formatFlags.testEmpty) {
                    return nil;
                }
                value = @"";
            }
            [arguments addObject:value];
        }
        return [self formatedValueWithArguments:arguments];
    } else if (_properties != nil) {
        NSMutableDictionary *value = [[NSMutableDictionary alloc] initWithCapacity:_properties.count];
        [_properties initDataForOwner:value];
        [_properties mapData:data forOwner:value withTarget:target context:context];
        return value;
    }
    return [super valueWithData:data target:target context:context];
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
        char c = [_format characterAtIndex:0];
        switch (c) {
            case '{': // suppose as a dictionary
                result = [context evaluateScript:[NSString stringWithFormat:@"var _=%@;_;", _format]];
                return [result toDictionary];
            case '[': // suppose as a array
                result = [context evaluateScript:[NSString stringWithFormat:@"var _=%@;_;", _format]];
                return [result toArray];
            default:
                result = [context evaluateScript:_format];
        }
        
        // Resolve return value
        if (_formatterTag == nil) {
            return [result toString];
        }
        
        // Wrap non-object values (atomic, struct)
        if ([_formatterTag isEqualToString:@"bool"]) {
            return [NSNumber numberWithBool:[result toBool]];
        } else if ([_formatterTag isEqualToString:@"float"]) {
            return [NSNumber numberWithFloat:[result toDouble]];
        } else if ([_formatterTag isEqualToString:@"double"]) {
            return [NSNumber numberWithDouble:[result toDouble]];
        } else if ([_formatterTag isEqualToString:@"int"]
                   || [_formatterTag isEqualToString:@"int32"]) {
            return [NSNumber numberWithInt:[result toInt32]];
        } else if ([_formatterTag isEqualToString:@"uint"]
                   || [_formatterTag isEqualToString:@"uint32"]) {
            return [NSNumber numberWithInt:[result toUInt32]];
        } else if ([_formatterTag isEqualToString:@"point"]) {
            return [NSValue valueWithCGPoint:[result toPoint]];
        } else if ([_formatterTag isEqualToString:@"range"]) {
            return [NSValue valueWithRange:[result toRange]];
        } else if ([_formatterTag isEqualToString:@"rect"]) {
            return [NSValue valueWithCGRect:[result toRect]];
        } else if ([_formatterTag isEqualToString:@"size"]) {
            return [NSValue valueWithCGSize:[result toSize]];
        }
        
        // Return object values (number, date, array, dictionary)
        NSString *selName = [NSString stringWithFormat:@"to%c%@", toupper([_formatterTag characterAtIndex:0]), [_formatterTag substringFromIndex:1]];
        SEL convertor = NSSelectorFromString(selName);
        if (![result respondsToSelector:convertor]) {
            return [result toString];
        }
        
        IMP imp = [result methodForSelector:convertor];
        JSValueConvertorFunc func = (JSValueConvertorFunc) imp;
        return func(result, convertor);
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
        
        [_formatedArguments replaceObjectAtIndex:index withObject:value];
        return [self formatedValueWithArguments:_formatedArguments];
    }
    return value;
}

#pragma mark - Debug

- (NSString *)stringValue {
    if (_format == nil) {
        if (_properties == nil) {
            return [super stringValue];
        }
        
        return [_properties description];
    }
    
    NSMutableString *s = [NSMutableString stringWithString:@"%"];
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
    [s appendString:@"("];
    [s appendString:_format];
    [s appendString:@")"];
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
