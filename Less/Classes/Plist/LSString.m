//
//  LSString.m
//  Less
//
//  Created by galen on 15/4/25.
//  Copyright (c) 2015年 galen. All rights reserved.
//

#import "LSString.h"
#import "LSStringFormatter.h"

#ifndef objc_malloc
#define objc_malloc(size) (char *)malloc(size)
#endif
#ifndef objc_free
#define objc_free(p) free(p)
#endif

@implementation LSString

+ (NSString *)stringWithFormat:(NSString *)format array:(NSArray *)arguments
{
    if ([arguments count] == 0) {
        return format;
    }
#if (TARGET_IPHONE_SIMULATOR)
    return [[self alloc] initWithFormat:format locale:nil array:arguments];
#else
    NSRange range = NSMakeRange(0, [arguments count]);
    NSMutableData *data = [NSMutableData dataWithLength:sizeof(id) * [arguments count]];
    [arguments getObjects:(__unsafe_unretained id *)data.mutableBytes range:range];
    NSString *result = [[self alloc] initWithFormat:format arguments:data.mutableBytes];
    return result;
#endif
}

+ (NSString *)stringWithFormat:(NSString *)format object:(id)object
{
    if ([format rangeOfString:@"%@"].length != 0) {
        return [NSString stringWithFormat:format, object];
    } else {
        if ([object isKindOfClass:[NSNumber class]]) {
            const char *ctype = [object objCType];
            if (strcmp(ctype, @encode(int)) == 0
                || strcmp(ctype, @encode(char)) == 0) {
                return [NSString stringWithFormat:format, [object intValue]];
            } else if (strcmp(ctype, @encode(long)) == 0) {
                return [NSString stringWithFormat:format, [object longValue]];
            } else if (strcmp(ctype, @encode(float)) == 0) {
                return [NSString stringWithFormat:format, [object floatValue]];
            } else if (strcmp(ctype, @encode(double)) == 0) {
                return [NSString stringWithFormat:format, [object doubleValue]];
            }
        }
    }
    return format;
}

#if (TARGET_IPHONE_SIMULATOR)

void appendCStrWithFormat(char **pFormat_to_go, NSMutableString *result, NSArray *arguments, NSInteger *pArgIndex)
{
    char *format_to_go = *pFormat_to_go;
    char *formatter_pos;
    if((formatter_pos = strchr(format_to_go, '%')))
    { // Skip arguments already processed by last vasprintf().
        char *spec_pos; 			// Position of conversion specifier.
        if(*(formatter_pos+1) == '%')
        {
            format_to_go = formatter_pos+2;
            [result appendString:@"%"];
            appendCStrWithFormat(pFormat_to_go, result, arguments, pArgIndex);	// skip %%
        }
        // FIXME: somehow handle %C, %S and other new specifiers!
        spec_pos = strpbrk(formatter_pos+1, "dioxXucsfeEgGpn");	// Specifiers from K&R C 2nd ed.
        if(*(spec_pos - 1) == '*')
        {
#if 0
            fprintf(stderr, " -initWithFormat: %%* specifier found\n");
#endif
            (*pArgIndex)++;	// handle %*s, %.*f etc.
        }
        // FIXME: handle %*.*s, %*.123s
#if 0
        fprintf(stderr, "spec=%c\n", *spec_pos);
#endif
        switch (*spec_pos)
        {
            case 'd': case 'i': case 'o':
            case 'x': case 'X': case 'u': case 'c':
                [result appendFormat:[[NSString alloc] initWithBytes:format_to_go length:spec_pos-format_to_go+1 encoding:NSUTF8StringEncoding], [[arguments objectAtIndex:(*pArgIndex)++] longLongValue]];
                break;
            case 's':
                [result appendFormat:[[NSString alloc] initWithBytes:format_to_go length:spec_pos-format_to_go+1 encoding:NSUTF8StringEncoding], [[arguments objectAtIndex:(*pArgIndex)++] UTF8String]];
                break;
            case 'f': case 'e': case 'E': case 'g': case 'G':
                [result appendFormat:[[NSString alloc] initWithBytes:format_to_go length:spec_pos-format_to_go+1 encoding:NSUTF8StringEncoding], [[arguments objectAtIndex:(*pArgIndex)++] doubleValue]];
                break;
            case 'p':
                [result appendFormat:[[NSString alloc] initWithBytes:format_to_go length:spec_pos-format_to_go+1 encoding:NSUTF8StringEncoding], [arguments objectAtIndex:(*pArgIndex)++]];
                break;
            case 'n':
                [result appendFormat:[[NSString alloc] initWithBytes:format_to_go length:spec_pos-format_to_go+1 encoding:NSUTF8StringEncoding], [[arguments objectAtIndex:(*pArgIndex)++] length]];
                break;
            case '\0':							// Make sure loop exits on
                spec_pos--;						// next iteration
                break;
            default:
                fprintf(stderr, "NSString -initWithFormat:... unknown format specifier %%%c\n", *spec_pos);
        }
        format_to_go = spec_pos+1;
        *pFormat_to_go = format_to_go;
        appendCStrWithFormat(pFormat_to_go, result, arguments, pArgIndex);
    }
}

- (instancetype)initWithFormat:(NSString *)format locale:(NSLocale *)locale array:(NSArray *)arguments
{
    const char *format_cp = [format UTF8String];
    int format_len = (int)strlen (format_cp);
    char *format_cp_copy = objc_malloc(format_len+1);	// buffer for a mutable copy of the format string
    char *format_to_go = format_cp_copy;				// pointer into the format string while processing
    NSMutableString *result=[[NSMutableString alloc] initWithCapacity:2*format_len+20];	// this assumes some minimum result size
    self = nil;	// we return a (mutable!) replacement object - to be really correct, we should autorelease the result and return [self initWithString:result];
    if(!format_cp_copy)
        [NSException raise: NSMallocException format: @"Unable to allocate"];
    strcpy(format_cp_copy, format_cp);		// make local copy for tmp editing
    //	fprintf(stderr, "fmtcopy=%p\n", format_cp_copy);
    //	fprintf(stderr, "result=%p\n", result);
    
    NSInteger argIndex = 0;
    
    // FIXME: somehow handle %S and other specifiers!
    
    while(YES)
    { // Loop once for each `%@' in the format string
        char *atsign_pos;				// points to a location of an %@ inside format_cp_copy
        char *formatter_pos;			// a position for formatter
        id arg;
        int mode=0;
        char *usertag_pos = NULL; // ++ for user tag
        for(atsign_pos=format_to_go; *atsign_pos != 0; atsign_pos++)
        { // scan for special formatters that can't be handled by vsfprint
            if(atsign_pos[0] == '%')
            {
                switch(atsign_pos[1])
                {
                    case '@':
                    case 'C':
                    case 'J': // json format
                        mode=atsign_pos[1];
                        *atsign_pos = '\0';		// tmp terminate the string before the next `%@'
                        break;
                    case '#': // number format
                    {
                        mode=atsign_pos[1];
                        *atsign_pos = '\0';
                        char *spec_pos = strpbrk(atsign_pos+2, "dioxXucsfeEgGpn");
                        if (*spec_pos != 0) {
                            long len = spec_pos - atsign_pos + 1;
                            usertag_pos = (char *)malloc(len);
                            usertag_pos[0] = '%';
                            strncpy(usertag_pos+1, atsign_pos+2, len);
                            usertag_pos[len-1] = '\0';
                            *spec_pos = '\0';
                            atsign_pos += len-2;
                            break;
                        }
                    }
                    case '<': // user formatter
                        mode=atsign_pos[1];
                        *atsign_pos = '\0';
                        usertag_pos = atsign_pos+2;
                        atsign_pos++;
                        while (*atsign_pos != '>' && *atsign_pos != 0) {
                            atsign_pos++;
                        }
                        if (*atsign_pos == 0) {
                            continue;
                        }
                        *(atsign_pos) = '\0';
                        break;
                    default:
                        continue;
                }
                break;
            }
        }
#if 0
        fprintf(stderr, "fmt2go=%s\n", format_to_go);
#endif
        formatter_pos = strchr(format_to_go, '%');
        if (formatter_pos == NULL) {
            if (strlen(format_to_go) > 0) {
                [result appendFormat:@"%@", [NSString stringWithUTF8String:format_to_go]];
            }
        } else {
            // c formatters
            appendCStrWithFormat(&format_to_go, result, arguments, &argIndex);
        }
        if(!mode) {
            objc_free(format_cp_copy);
            return (id)result;	// we return a (mutable!) replacement object - to be correct, autorelease the result and return [self initWithString:result];
        }
        int skip_len = 2;
        switch(mode)
        {
            case '@':
            {
                arg=[arguments objectAtIndex:argIndex++];
                //		fprintf(stderr, "arg.1=%p\n", arg);
                if(arg && ![arg isKindOfClass:[NSString class]])
                { // not yet a string
                    if(locale && [arg respondsToSelector:@selector(descriptionWithLocale:)])
                        arg=[arg descriptionWithLocale:locale];
                    else
                        arg=[arg description];
                }
                if(!arg)
                    arg=@"<nil>";	// nil object or description
                break;
            }
            case 'C':
            {
                unichar c=[[arguments objectAtIndex:argIndex++] intValue];
                arg=[NSString stringWithCharacters:&c length:1];	// single character
                break;
            }
            case '#':
            {
                arg=[arguments objectAtIndex:argIndex++];
                if (arg && [arg isKindOfClass:[NSNumber class]]) {
                    NSString *numberFormat = [[NSString alloc] initWithUTF8String:usertag_pos];
                    switch (usertag_pos[strlen(usertag_pos)-1]) {
                        case 'd': case 'i': case 'o':
                        case 'x': case 'X': case 'u': case 'c':
                            arg=[NSString stringWithFormat:numberFormat, [arg integerValue]];
                            break;
                        case 'f': case 'e': case 'E': case 'g': case 'G':
                            arg=[NSString stringWithFormat:numberFormat, [arg doubleValue]];
                            break;
                        default:
                            arg=@"number format error";
                            break;
                    }
                }
                break;
            }
            case 'J':
            {
                arg=[arguments objectAtIndex:argIndex++];
                //		fprintf(stderr, "arg.1=%p\n", arg);
                if(arg && ![arg isKindOfClass:[NSString class]])
                { // not yet a string
                    NSError *error = nil;
                    NSData *data = [NSJSONSerialization dataWithJSONObject:arg options:0 error:&error];
                    if (error == nil) {
                        arg = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                    } else {
                        arg = @"json error";
                    }
                }
                if(!arg)
                    arg=@"<nil>";	// nil object or description
                break;
            }
            case '<': // %<UserTag:UserFormat>
            {
                skip_len = 1;
                arg=[arguments objectAtIndex:argIndex++];
                if(arg)
                {
                    NSString *userFormat = nil;
                    char *userformat_pos;
                    for (userformat_pos = usertag_pos; *userformat_pos != 0; userformat_pos++) {
                        if (*userformat_pos == ':') {
                            break;
                        }
                    }
                    if (*userformat_pos == ':') {
                        *userformat_pos = '\0';
                        userformat_pos++;
                        userFormat = [[NSString alloc] initWithUTF8String:userformat_pos];
                    }
                    
                    NSString *tag = [[NSString alloc] initWithUTF8String:usertag_pos];
                    NSString *(^formatter)(NSString *format, id value) = [LSStringFormatter formatterForTag:tag];
                    if (formatter != nil) {
                        arg = formatter(userFormat, arg);
                    } else {
                        arg = [NSString stringWithFormat:@"unknown tag `%@'", tag];
                    }
                    //                    printf("tag:%s, format:%s", usertag_pos, userformat_pos);
                }
                if(!arg)
                    arg=@"<nil>";	// nil object or description
                break;
            }
            default:
                arg=@"formatter error";
        }
        //		fprintf(stderr, "arg.2=%p\n", arg);
        [result appendString:arg];
        format_to_go = atsign_pos + skip_len;				// Skip over this `%@', and look for another one.
    }
}

#else
- (id) initWithFormat:(NSString*)format
               locale:(NSDictionary*)locale
            arguments:(va_list)arg_list
{
    const char *format_cp = [format UTF8String];
    int format_len = (int)strlen (format_cp);
    char *format_cp_copy = objc_malloc(format_len+1);	// buffer for a mutable copy of the format string
    char *format_to_go = format_cp_copy;				// pointer into the format string while processing
    NSMutableString *result=[[NSMutableString alloc] initWithCapacity:2*format_len+20];	// this assumes some minimum result size
    self = nil;	// we return a (mutable!) replacement object - to be really correct, we should autorelease the result and return [self initWithString:result];
    if(!format_cp_copy)
        [NSException raise: NSMallocException format: @"Unable to allocate"];
    strcpy(format_cp_copy, format_cp);		// make local copy for tmp editing
    //	fprintf(stderr, "fmtcopy=%p\n", format_cp_copy);
    //	fprintf(stderr, "result=%p\n", result);
    
    // FIXME: somehow handle %S and other specifiers!
    
    while(YES)
    { // Loop once for each `%@' in the format string
        char *atsign_pos;				// points to a location of an %@ inside format_cp_copy
        char *formatter_pos;			// a position for formatter
        char *buffer;					// vasprintf() buffer return
        int len;						// length of vasprintf() result
        id arg;
        int mode=0;
        char *usertag_pos = NULL; // ++ for user tag
        for(atsign_pos=format_to_go; *atsign_pos != 0; atsign_pos++)
        { // scan for special formatters that can't be handled by vsfprint
            if(atsign_pos[0] == '%')
            {
                switch(atsign_pos[1])
                {
                    case '@':
                    case 'C':
                    case 'J': // json format
                        mode=atsign_pos[1];
                        *atsign_pos = '\0';		// tmp terminate the string before the next `%@'
                        break;
                    case '#': // number format
                    {
                        mode=atsign_pos[1];
                        *atsign_pos = '\0';
                        char *spec_pos = strpbrk(atsign_pos+2, "dioxXucsfeEgGpn");
                        if (*spec_pos != 0) {
                            long len = spec_pos - atsign_pos + 1;
                            usertag_pos = (char *)malloc(len);
                            usertag_pos[0] = '%';
                            strncpy(usertag_pos+1, atsign_pos+2, len);
                            usertag_pos[len-1] = '\0';
                            *spec_pos = '\0';
                            atsign_pos += len-2;
                            break;
                        }
                    }
                    case '<': // user formatter
                        mode=atsign_pos[1];
                        *atsign_pos = '\0';
                        usertag_pos = atsign_pos+2;
                        atsign_pos++;
                        while (*atsign_pos != '>' && *atsign_pos != 0) {
                            atsign_pos++;
                        }
                        if (*atsign_pos == 0) {
                            continue;
                        }
                        *(atsign_pos) = '\0';
                        break;
                    default:
                        continue;
                }
                break;
            }
        }
#if 0
        fprintf(stderr, "fmt2go=%s\n", format_to_go);
#endif
        if(*format_to_go)
        { // if there is anything to print...
            len=vasprintf(&buffer, format_to_go, arg_list);	// Print the part before the '%@' - will be malloc'ed
            //			fprintf(stderr, "buffer=%p\n", buffer);
            if(len > 0)
            {
                NSString *str = [[NSString alloc] initWithBytes:buffer length:len encoding:NSUTF8StringEncoding];
                [result appendString:str];
            }
            else if(len < 0)
            { // error
                free(buffer);
                objc_free(format_cp_copy);
                result = nil;
                return nil;
            }
            free(buffer);
        }
        if(!mode) {
            objc_free(format_cp_copy);
            return (id)result;	// we return a (mutable!) replacement object - to be correct, autorelease the result and return [self initWithString:result];
        }
        while((formatter_pos = strchr(format_to_go, '%')))
        { // Skip arguments already processed by last vasprintf().
            char *spec_pos; 			// Position of conversion specifier.
            if(*(formatter_pos+1) == '%')
            {
                format_to_go = formatter_pos+2;
                continue;	// skip %%
            }
            // FIXME: somehow handle %C, %S and other new specifiers!
            spec_pos = strpbrk(formatter_pos+1, "dioxXucsfeEgGpn");	// Specifiers from K&R C 2nd ed.
            if(*(spec_pos - 1) == '*')
            {
#if 0
                fprintf(stderr, " -initWithFormat: %%* specifier found\n");
#endif
                (void) va_arg(arg_list, int);	// handle %*s, %.*f etc.
            }
            // FIXME: handle %*.*s, %*.123s
#if 0
            fprintf(stderr, "spec=%c\n", *spec_pos);
#endif
            switch (*spec_pos)
            {
                case 'd': case 'i': case 'o':
                case 'x': case 'X': case 'u': case 'c':
                    (void) va_arg(arg_list, int);
                    break;
                case 's':
                    (void) va_arg(arg_list, char *);
                    break;
                case 'f': case 'e': case 'E': case 'g': case 'G':
                    (void) va_arg(arg_list, double);
                    break;
                case 'p':
                    (void) va_arg(arg_list, void *);
                    break;
                case 'n':
                    (void) va_arg(arg_list, int *);
                    break;
                case '\0':							// Make sure loop exits on
                    spec_pos--;						// next iteration
                    break;
                default:
                    fprintf(stderr, "NSString -initWithFormat:... unknown format specifier %%%c\n", *spec_pos);
            }
            format_to_go = spec_pos+1;
        }
        int skip_len = 2;
        switch(mode)
        {
            case '@':
            {
                arg=(id) va_arg(arg_list, id);
                //		fprintf(stderr, "arg.1=%p\n", arg);
                if(arg && ![arg isKindOfClass:[NSString class]])
                { // not yet a string
                    if(locale && [arg respondsToSelector:@selector(descriptionWithLocale:)])
                        arg=[arg descriptionWithLocale:locale];
                    else
                        arg=[arg description];
                }
                if(!arg)
                    arg=@"<nil>";	// nil object or description
                break;
            }
            case 'C':
            {
                unichar c=va_arg(arg_list, int);
                arg=[NSString stringWithCharacters:&c length:1];	// single character
                break;
            }
            case '#':
            {
                arg=(id) va_arg(arg_list, id);
                if (arg && [arg isKindOfClass:[NSNumber class]]) {
                    NSString *numberFormat = [[NSString alloc] initWithUTF8String:usertag_pos];
                    switch (usertag_pos[strlen(usertag_pos)-1]) {
                        case 'd': case 'i': case 'o':
                        case 'x': case 'X': case 'u': case 'c':
                            arg=[NSString stringWithFormat:numberFormat, [arg integerValue]];
                            break;
                        case 'f': case 'e': case 'E': case 'g': case 'G':
                            arg=[NSString stringWithFormat:numberFormat, [arg doubleValue]];
                            break;
                        default:
                            arg=@"number format error";
                            break;
                    }
                }
                break;
            }
            case 'J':
            {
                arg=(id) va_arg(arg_list, id);
                //		fprintf(stderr, "arg.1=%p\n", arg);
                if(arg && ![arg isKindOfClass:[NSString class]])
                { // not yet a string
                    NSError *error = nil;
                    NSData *data = [NSJSONSerialization dataWithJSONObject:arg options:0 error:&error];
                    if (error == nil) {
                        arg = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                    } else {
                        arg = @"json error";
                    }
                }
                if(!arg)
                    arg=@"<nil>";	// nil object or description
                break;
            }
            case '<':
            {
                skip_len = 1;
                arg=(id) va_arg(arg_list, id);
                //		fprintf(stderr, "arg.1=%p\n", arg);
                if(arg && ![arg isKindOfClass:[NSString class]])
                { // not yet a string
                    NSString *userFormat = nil;
                    char *userformat_pos;
                    for (userformat_pos = usertag_pos; *userformat_pos != 0; userformat_pos++) {
                        if (*userformat_pos == ':') {
                            break;
                        }
                    }
                    if (*userformat_pos == ':') {
                        *userformat_pos = '\0';
                        userformat_pos++;
                        userFormat = [[NSString alloc] initWithUTF8String:userformat_pos];
                    }
                    
                    NSString *tag = [[NSString alloc] initWithUTF8String:usertag_pos];
                    NSString *(^formatter)(NSString *format, id value) = [LSStringFormatter formatterForTag:tag];
                    if (formatter != nil) {
                        arg = formatter(userFormat, arg);
                    } else {
                        arg = [NSString stringWithFormat:@"unknown tag `%@'", tag];
                    }
                    //                    printf("tag:%s, format:%s", usertag_pos, userformat_pos);
                }
                if(!arg)
                    arg=@"<nil>";	// nil object or description
                break;
            }
            default:
                arg=@"formatter error";
        }
        //		fprintf(stderr, "arg.2=%p\n", arg);
        [result appendString:arg];
        format_to_go = atsign_pos + skip_len;				// Skip over this `%@', and look for another one.
    }
}
#endif

@end
