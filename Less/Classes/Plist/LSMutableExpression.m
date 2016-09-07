//
//  LSMutableExpression.m
//  Less
//
//  Created by galen on 15/3/13.
//  Copyright (c) 2015年 galen. All rights reserved.
//

#import "LSMutableExpression.h"
#import "LSValueParser.h"
#import "LSString.h"
#import "LSVariableEvaluator.h"

@interface LSExpression (Private)

- (instancetype)initWithUTF8String:(const char *)str;
- (void)setValueOfOwner:(id)owner forKeyPath:(NSString *)ownerKeyPath withData:(id)data;
- (void)bindData:(id)data withOwner:(id)owner forKeyPath:(NSString *)ownerKeyPath;

@end

@implementation LSMutableExpression

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
        if ([tag isEqualToString:@"AT"]) {
            _formatFlags.attributedText = 1;
        } else {
            _formatter = [LSVariableEvaluator evaluatorForTag:tag];
            if (_formatter != nil) {
                _formatFlags.custom = 1;
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
    while (*p != '\0') {
        *p2++ = *p++;
    }
    *p2 = '\0';
    free(temp);
    NSString *args =[NSString stringWithUTF8String:temp];
    [self initExpressionsWithString:args];
    return self;
}

- (void)initExpressionsWithString:(NSString *)aString
{
    NSArray *components = [aString componentsSeparatedByString:@","];
    NSMutableArray *expressions = [[NSMutableArray alloc] initWithCapacity:[components count]];
    for (NSString *exp in components) {
        LSExpression *expression = [[LSExpression alloc] initWithString:exp];
        expression.parent = self;
        [expressions addObject:expression];
    }
    
    if ([expressions count] == 0) {
        _rvalue = aString;
    } else {
        _expressions = expressions;
    }
}

- (void)mapData:(id)data toOwner:(id)owner forKeyPath:(NSString *)ownerKeyPath
{
    if (_format != nil) {
        [self setValueOfOwner:owner forKeyPath:ownerKeyPath withData:data];
        for (LSExpression *exp in _expressions) {
            [exp bindData:data withOwner:owner forKeyPath:ownerKeyPath];
        }
    } else {
        [super mapData:data toOwner:owner forKeyPath:ownerKeyPath];
    }
}

- (id)valueWithData:(id)data andOwner:(id)owner
{
    if (_format != nil) {
        NSMutableArray *arguments = [[NSMutableArray alloc] init];
        for (LSExpression *exp in _expressions) {
            id value = [exp valueWithData:data andOwner:owner];
            if (value == nil) {
                value = @"";
            }
            [arguments addObject:value];
        }
        return [self formatedValueWithArguments:arguments];
    }
    return [super valueWithData:data andOwner:owner];
}

- (id)valueWithData:(id)data
{
    if (_format != nil) {
        NSMutableArray *arguments = [[NSMutableArray alloc] init];
        for (LSExpression *exp in _expressions) {
            id value = [exp valueWithData:data];
            if (value == nil) {
                value = @"";
            }
            [arguments addObject:value];
        }
        return [self formatedValueWithArguments:arguments];
    }
    return [super valueWithData:data];
}

#pragma mark - Helper

- (id)formatedValueWithArguments:(NSMutableArray *)arguments
{
    _formatedArguments = arguments;
    NSString *text = nil;
    if (_formatFlags.attributedText) {
        text = [LSString stringWithFormat:_format array:arguments];
        text = [text stringByReplacingOccurrencesOfString:@"\\n" withString:@"\n"];
        NSArray *texts = [text componentsSeparatedByString:@"|"];
        text = [texts componentsJoinedByString:@""];
        NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:text attributes:nil];
        for (NSInteger index = 0; index < [texts count]; index++) {
            NSString *aText = [texts objectAtIndex:index];
            NSRange range = [text rangeOfString:aText];
            NSDictionary *attribute = [_attributes objectAtIndex:index];
            [attributedString addAttributes:attribute range:range];
            NSLog(@"[%i] %@ - %@", (int)index, aText, [attribute objectForKey:NSForegroundColorAttributeName]);
        }
        return attributedString;
    } else if (_formatFlags.custom) {
        text = _formatter(_formatterTag, _format, arguments);
    } else {
        text = [LSString stringWithFormat:_format array:arguments];
    }
    return [text stringByReplacingOccurrencesOfString:@"\\n" withString:@"\n"];
}

- (NSDictionary *)attributeFromFontString:(NSString *)fontString
{
    // {color,font,weight,size}
    NSString *pattern = @"\\{(#\\w+),(.+)\\}";
    NSError *error = nil;
    NSRegularExpression *regex = [[NSRegularExpression alloc] initWithPattern:pattern options:0 error:&error];
    if (error != nil) {
        return nil;
    }
    
    NSTextCheckingResult *result = [regex firstMatchInString:fontString options:0 range:NSMakeRange(0, fontString.length)];
    NSRange range = [result rangeAtIndex:1];
    if (range.length == 0) {
        return nil;
    }
    
    NSMutableDictionary *attribute = [[NSMutableDictionary alloc] initWithCapacity:2];
    NSString *colorString = [fontString substringWithRange:range];
    [attribute setObject:[LSValueParser valueWithString:colorString] forKey:NSForegroundColorAttributeName];
    range = [result rangeAtIndex:2];
    if (range.length != 0) {
        NSString *font = [NSString stringWithFormat:@"{F:%@}", [fontString substringWithRange:range]];
        [attribute setObject:[LSValueParser valueWithString:font] forKey:NSFontAttributeName];
    }
    return attribute;
}

@end

#pragma mark - Private

@interface LSMutableExpression (Private)

- (id)valueByUpdatingObservedValue:(id)value fromChild:(LSExpression *)child;

@end

@implementation LSMutableExpression (Private)

- (id)valueByUpdatingObservedValue:(id)value fromChild:(LSExpression *)child
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

@end
