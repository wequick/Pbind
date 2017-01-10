//
//  PBLayoutConstraint.m
//  Pbind
//
//  Created by Galen Lin on 07/01/2017.
//
//

#import "PBLayoutConstraint.h"
#import "Pbind+API.h"

#pragma mark -
#pragma mark - _PBMergedWrapperView

@interface _PBMergedWrapperView : UIView

@end

@implementation _PBMergedWrapperView

@end

#pragma mark -
#pragma mark - _PBLayoutError

@interface _PBLayoutError : NSObject

+ (instancetype)errorWithTips:(NSString *)tips pos:(int)pos;
- (void)print;

@end

@implementation _PBLayoutError
{
    NSString *_tips;
    int _pos;
}

+ (instancetype)errorWithTips:(NSString *)tips pos:(int)pos {
    _PBLayoutError *error = [[_PBLayoutError alloc] init];
    error->_tips = tips;
    error->_pos = pos;
    return error;
}

- (void)print {
    
}

@end

#pragma mark -
#pragma mark - PBLayoutConstraint

@implementation PBLayoutConstraint

+ (NSArray<__kindof NSLayoutConstraint *> *)constraintsWithVisualFormat:(NSString *)format options:(NSLayoutFormatOptions)opts metrics:(nullable NSDictionary<NSString *,id> *)metrics views:(NSDictionary<NSString *, id> *)views {
    NSArray *constraints = [super constraintsWithVisualFormat:format options:opts metrics:metrics views:views];
    for (NSLayoutConstraint *constraint in constraints) {
        constraint.identifier = format; // add an identifier for debug
    }
    return constraints;
}

+ (void)addConstraintsWithPbindFormats:(NSArray *)formats metrics:(NSDictionary *)metrics views:(NSDictionary *)views forParentView:(UIView *)parentView {
    NSInteger maxMergedViewsCount = views.count / 2; // one merged view requires two subviews as least.
    NSMutableSet *mergedViews = [NSMutableSet setWithCapacity:maxMergedViewsCount];
    for (NSString *key in views) {
        UIView *container = [views[key] superview];
        if (container != parentView && [container isKindOfClass:[_PBMergedWrapperView class]]) {
            [mergedViews addObject:container];
        }
    }
    NSMutableSet *newMergedViews = [NSMutableSet setWithCapacity:maxMergedViewsCount];
    
    for (NSString *format in formats) {
        @try {
            [self addConstraintsWithPbindVisualFormat:format metrics:metrics views:views forParentView:parentView mergedViews:mergedViews outMergedViews:newMergedViews];
        } @catch (NSException *exception) {
            NSLog(@"Pbind: %@", exception);
            continue;
        }
    }
    
    if (mergedViews.count > newMergedViews.count) {
        // Something unmerged.
        NSSet *removedMergingViews = [mergedViews filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"NOT SELF IN %@", newMergedViews]];
        for (UIView *container in removedMergingViews) {
            [container removeFromSuperview];
            NSArray *subviews = container.subviews;
            for (UIView *subview in subviews) {
                [parentView addSubview:subview];
            }
        }
    }
}

+ (void)addConstraintsWithPbindVisualFormat:(NSString *)format
                                    metrics:(NSDictionary *)metrics
                                      views:(NSDictionary *)views
                              forParentView:(UIView *)parentView
                                mergedViews:(NSMutableSet *)mergedViews
                             outMergedViews:(NSMutableSet *)outMergedViews {
    const char *str = [format UTF8String];
    char *p = (char *) str;
    size_t len = strlen(str) + 1;
    if (len < 3) {
        NSLog(@"Pbind: Too short to parse as a constraint format.\n%s", str);
        return;
    }
    
    if (*(p+1) == ':') {
        if (*p == 'R') {
            [self addConstraintWithAspectRatioFormat:p views:views forParentView:parentView];
        } else if (*p == 'E') {
            [self addConstraintsWithEdgeInsetsFormat:p views:views forParentView:parentView];
        } else if (*p == 'C' || *p == 'M') {
            // Merge and align
            BOOL horizontal = (*p == 'C');
            [self addConstraintsWithMergeCenterFormat:p horizontal:horizontal metrics:metrics views:views forParentView:parentView mergedViews:mergedViews outMergedViews:outMergedViews];
        }
    } else {
        [self addConstraintWithExplicitFormat:p metrics:metrics views:views forParentView:parentView];
    }
}

+ (void)removeAllConstraintsOfSubview:(UIView *)subview fromParentView:(UIView *)parentView {
    NSArray *constraints = parentView.constraints;
    for (NSLayoutConstraint *constraint in constraints) {
        if (subview == constraint.firstItem || subview == constraint.secondItem) {
            [parentView removeConstraint:constraint];
        }
    }
}

#pragma mark - PVFL

+ (void)addConstraintWithAspectRatioFormat:(const char *)str views:(NSDictionary *)views forParentView:(UIView *)parentView {
    char *p = (char *) str + 2;
    char *p2, *temp;
    size_t len = strlen(p) + 1;
    BOOL failed = NO;
    
    NSString *viewName = [self nameByReadingFormat:&p];
    if (viewName == nil) {
        [self printMissingViewErrorOnFormat:str pos:p];
        return;
    }
    
    UIView *targetView = views[viewName];
    if (targetView == nil) {
        [self printUndefinedViewError:viewName onFormat:str pos:p];
        return;
    }
    
    NSLayoutRelation relation = [self relationByReadingFormat:&p failed:&failed];
    if (failed) {
        [self printUnknownRelationErrorOnFormat:str pos:p];
        return;
    }
    
    int width = strtol(p, &p2, 0);
    if (p == p2) {
        [self printMissingIntegerErrorOnFormat:str pos:p];
        return;
    }
    if (width <= 0) {
        [self printInvalidValueError:@"aspect ratio" mustbe:@"an integer or integer:integer and the value should be greater than 0" onFormat:str pos:p];
        return;
    }
    
    int height = 0;
    if (*p2 != '\0') {
        if (*p2 != ':') {
            [self printExpectedSymbolError:':' usage:@"separate width and height" onFormat:str pos:p];
            return;
        }
        p = p2 + 1;
        
        height = strtol(p, &p2, 0);
        if (p == p2) {
            [self printMissingIntegerErrorOnFormat:str pos:p];
            return;
        }
        if (height <= 0) {
            [self printInvalidValueError:@"aspect ratio" mustbe:@"an integer or integer:integer and the value should be greater than 0" onFormat:str pos:p];
            return;
        }
        p = p2;
    }
    if (*p != '\0') {
        [self printRedundantErrorOnFormat:str pos:p];
        return;
    }
    
    CGFloat ratio;
    if (height == 0) {
        ratio = width;
    } else {
        ratio = (float)width / (float)height;
    }
    
    NSLayoutConstraint *constraint = [self constraintWithItem:targetView attribute:NSLayoutAttributeWidth relatedBy:relation toItem:targetView attribute:NSLayoutAttributeHeight multiplier:ratio constant:0];
    constraint.identifier = [NSString stringWithFormat:@"%s", str];
    [parentView addConstraint:constraint];
}

+ (void)addConstraintsWithEdgeInsetsFormat:(const char *)str views:(NSDictionary *)views forParentView:(UIView *)parentView {
    char *p = (char *) str + 2;
    char *p2, *temp;
    size_t len = strlen(p) + 1;
    UIView *outerView = parentView;
    UIView *innerView;
    NSString *viewName;
    
    viewName = [self nameByReadingFormat:&p];
    if (viewName == nil) {
        [self printMissingViewErrorOnFormat:str pos:p];
        return;
    }
    innerView = views[viewName];
    if (innerView == nil) {
        [self printUndefinedViewError:viewName onFormat:str pos:p];
        return;
    }
    
    if (*p == '-') {
        p++;
        outerView = innerView;
        
        viewName = [self nameByReadingFormat:&p];
        if (viewName == nil) {
            [self printMissingViewErrorOnFormat:str pos:p];
            return;
        }
        innerView = views[viewName];
        if (innerView == nil) {
            [self printUndefinedViewError:viewName onFormat:str pos:p];
            return;
        }
    }
    
    if (*p != '=') {
        [self printInvalidValueError:@"relation" mustbe:@"=" onFormat:str pos:p];
        return;
    }
    p++;
    
    if (*p != '{') {
        [self printInvalidEdgeInsetsErrorOnFormat:str pos:p];
        return;
    }
    p++;
    
    UIEdgeInsets inset = UIEdgeInsetsZero;
    
    // top
    inset.top = strtof(p, &p2);
    if (p == p2) {
        [self printMissingFloatErrorOnFormat:str pos:p];
        return;
    }
    if (*p2 != ',') {
        [self printMissingEdgeSeparatorErrorOnFormat:str pos:p2];
        return;
    }
    p = p2 + 1;
    
    // left
    inset.left = strtof(p, &p2);
    if (p == p2) {
        [self printMissingFloatErrorOnFormat:str pos:p];
        return;
    }
    if (*p2 != ',') {
        [self printMissingEdgeSeparatorErrorOnFormat:str pos:p2];
        return;
    }
    p = p2 + 1;
    
    // bottom
    inset.bottom = strtof(p, &p2);
    if (p == p2) {
        [self printMissingFloatErrorOnFormat:str pos:p];
        return;
    }
    if (*p2 != ',') {
        [self printMissingEdgeSeparatorErrorOnFormat:str pos:p2];
        return;
    }
    p = p2 + 1;
    
    // right
    inset.right = strtof(p, &p2);
    if (p == p2) {
        [self printMissingFloatErrorOnFormat:str pos:p];
        return;
    }
    if (*p2 != '}') {
        [self printMissingEdgeEndErrorOnFormat:str pos:p2];
        return;
    }
    if (*(p2 + 1) != '\0') {
        [self printRedundantErrorOnFormat:str pos:p2+1];
        return;
    }
    
    // Add inset constraints
    NSLayoutConstraint *constraint;
    constraint = [self constraintWithItem:innerView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:outerView attribute:NSLayoutAttributeLeading multiplier:1 constant:inset.left];
    constraint.identifier = [NSString stringWithFormat:@"%s ->left", str];
    [parentView addConstraint:constraint];
    constraint = [self constraintWithItem:outerView attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:innerView attribute:NSLayoutAttributeTrailing multiplier:1 constant:inset.right];
    constraint.identifier = [NSString stringWithFormat:@"%s ->right", str];
    [parentView addConstraint:constraint];
    constraint = [self constraintWithItem:innerView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:outerView attribute:NSLayoutAttributeTop multiplier:1 constant:inset.top];
    constraint.identifier = [NSString stringWithFormat:@"%s ->top", str];
    [parentView addConstraint:constraint];
    constraint = [self constraintWithItem:outerView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:innerView attribute:NSLayoutAttributeBottom multiplier:1 constant:inset.bottom];
    constraint.identifier = [NSString stringWithFormat:@"%s ->bottom", str];
    [parentView addConstraint:constraint];
}

+ (void)addConstraintsWithMergeCenterFormat:(const char *)str
                                 horizontal:(BOOL)horizontal
                                    metrics:(NSDictionary *)metrics
                                      views:(NSDictionary *)views
                              forParentView:(UIView *)parentView
                                mergedViews:(NSMutableSet *)mergedViews
                             outMergedViews:(NSMutableSet *)outMergedViews {
    char *p = (char *) str + 2;
    char *p2, *temp;
    size_t len = strlen(p) + 1;
    static char const mergedContainerViewTag = '_';
    static const NSString *mergedContainerViewName = @"_";
    char *containerFormatStr = (char *) malloc(len);
    char *pc = containerFormatStr;
    char outerOrientation, innerOrientation;
    NSLayoutAttribute innerStartPosAttribute,
    innerEndPosAttribute,
    outerAlignmentAttribute;
    if (horizontal) {
        innerOrientation = 'H';
        outerOrientation = 'V';
        innerStartPosAttribute = NSLayoutAttributeTop;
        innerEndPosAttribute = NSLayoutAttributeBottom;
        outerAlignmentAttribute = NSLayoutAttributeCenterX;
    } else {
        innerOrientation = 'V';
        outerOrientation = 'H';
        innerStartPosAttribute = NSLayoutAttributeLeading;
        innerEndPosAttribute = NSLayoutAttributeTrailing;
        outerAlignmentAttribute = NSLayoutAttributeCenterY;
    }
    
    // find first '/'
    while (*p != '/' && *p != '\0') {
        *pc++ = *p++;
    }
    if (*p == '\0') {
        NSLog(@"Pbind: Failed to parse PVFL: \"%s\", requires '/' region for Merge-Center-Format.", str);
        free(containerFormatStr);
        return;
    }
    p++;
    *pc++ = mergedContainerViewTag;
    
    // find merged views
    p2 = temp = (char *) malloc(len + p - str);
    while (*p != '/' && *p != '\0') {
        *p2++ = *p++;
    }
    if (*p == '\0') {
        NSLog(@"Pbind: Failed to parse PVFL: \"%s\", requires '/' region for Merge-Center-Format.", str);
        free(containerFormatStr);
        return;
    }
    p++;
    *p2 = '\0';
    
    while (*p != '\0') {
        *pc++ = *p++;
    }
    *pc = '\0';
    
    // Collect inner views
    NSMutableArray *innerViewNames = [NSMutableArray arrayWithCapacity:4];
    char *name;
    p = temp;
    len = strlen(p) + 1;
    while (true) {
        while (*p != '[' && *p != '\0') {
            p++;
        }
        if (*p == '\0') {
            break;
        }
        
        // got a view which starts with '['
        p++;
        p2 = name = (char *) malloc(len + p - temp);
        while (*p != ']' && *p != '(' && *p != '\0') {
            *p2++ = *p++;
        }
        if (*p == '\0') {
            break;
        }
        
        NSString *viewName = [[NSString alloc] initWithUTF8String:name];
        free(name);
        if (views[viewName] == nil) {
            [self printUndefinedViewError:viewName onFormat:str pos:p];
            return;
        }
        [innerViewNames addObject:viewName];
    }
    
    NSString *innerFormat = [NSString stringWithFormat:@"%c:|%s|", innerOrientation, temp];
    free(temp);
    
    // Check if has merged
    UIView *wrapperView = nil;
    NSArray *addedNames = nil;
    for (UIView *wrapper in mergedViews) {
        NSArray *mergedNames = [[wrapper subviews] valueForKey:@"alias"];
        addedNames = [mergedNames filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF IN %@", innerViewNames]];
        if (addedNames.count > 0) {
            wrapperView = wrapper;
            // Remove constraints for later re-add
            [self removeAllConstraintsOfSubview:wrapper fromParentView:parentView];
            for (NSString *name in addedNames) {
                UIView *view = views[name];
                [self removeAllConstraintsOfSubview:view fromParentView:wrapper];
            }
            
            // Check if something unmerged
            NSArray *removedNames = [mergedNames filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"NOT SELF IN %@", innerViewNames]];
            if (removedNames.count > 0) {
                // If unmerged, re-add the view to parent view
                for (NSString *name in removedNames) {
                    UIView *subview = views[name];
                    if (subview != nil) {
                        [subview removeFromSuperview];
                        [parentView addSubview:subview];
                    }
                }
            }
            break;
        }
    }
    if (wrapperView == nil) {
        wrapperView = [[_PBMergedWrapperView alloc] init];
        wrapperView.translatesAutoresizingMaskIntoConstraints = NO;
        [parentView addSubview:wrapperView];
    }
    
    for (NSString *name in innerViewNames) {
        UIView *view = views[name];
        if (![addedNames containsObject:name]) {
            [view removeFromSuperview];
            [wrapperView addSubview:view];
        }
        
        // Fill inner view
        [wrapperView addConstraint:[self constraintWithItem:view attribute:innerStartPosAttribute relatedBy:NSLayoutRelationEqual toItem:wrapperView attribute:innerStartPosAttribute multiplier:1 constant:0]];
        [wrapperView addConstraint:[self constraintWithItem:view attribute:innerEndPosAttribute relatedBy:NSLayoutRelationEqual toItem:wrapperView attribute:innerEndPosAttribute multiplier:1 constant:0]];
    }
    [outMergedViews addObject:wrapperView];
    
    // Container outer margin
    NSString *containerFormat = [NSString stringWithFormat:@"%c:%s", outerOrientation, containerFormatStr];
    NSMutableDictionary *newViews = [NSMutableDictionary dictionaryWithDictionary:views];
    newViews[mergedContainerViewName] = wrapperView;
    [parentView addConstraints:[self constraintsWithVisualFormat:containerFormat options:0 metrics:metrics views:newViews]];
    
    // Container outer alignment
    [parentView addConstraint:[self constraintWithItem:wrapperView attribute:outerAlignmentAttribute relatedBy:NSLayoutRelationEqual toItem:parentView attribute:outerAlignmentAttribute multiplier:1 constant:0]];
    
    // Inner view constraints
    [wrapperView addConstraints:[self constraintsWithVisualFormat:innerFormat options:0 metrics:metrics views:views]];
}

+ (void)addConstraintWithExplicitFormat:(const char *)str metrics:(NSDictionary *)metrics views:(NSDictionary *)views forParentView:(UIView *)parentView {
    //
    // firstItem.firstAttr = secondItem.secondAttr * multiplier + constant @ priority
    //
    char *p = (char *) str;
    char *p2, *temp;
    size_t len = strlen(str) + 1;
    NSString *viewName;
    UIView *firstItem, *secondItem;
    NSLayoutAttribute firstAttr, secondAttr;
    CGFloat multiplier = 0, constant = 0;
    NSLayoutRelation relation;
    UILayoutPriority priority = 0;
    BOOL failed = NO;
    
    // firstItem
    viewName = [self nameByReadingFormat:&p];
    if (viewName == nil) {
        [self printMissingViewErrorOnFormat:str pos:p];
        return;
    }
    firstItem = views[viewName];
    if (firstItem == nil) {
        [self printUndefinedViewError:viewName onFormat:str pos:p];
        return;
    }
    
    // firstAttr
    if (*p != '.') {
        [self printMissingAttributePrefixErrorOnFormat:str pos:p];
        return;
    }
    p++;
    firstAttr = [self attributeByReadingFormat:&p failed:&failed];
    if (failed) {
        [self printUnknownAttributeErrorOnFormat:str pos:p];
        return;
    }
    
    // relation
    relation = [self relationByReadingFormat:&p failed:&failed];
    if (failed) {
        [self printUnknownRelationErrorOnFormat:str pos:p];
        return;
    }
    
    // secondItem
    viewName = [self nameByReadingFormat:&p];
    if (viewName == nil) {
        [self printMissingViewErrorOnFormat:str pos:p];
        return;
    }
    secondItem = views[viewName];
    if (secondItem == nil) {
        [self printUndefinedViewError:viewName onFormat:str pos:p];
        return;
    }
    
    // secondAttr
    if (*p != '.') {
        [self printMissingAttributePrefixErrorOnFormat:str pos:p];
        return;
    }
    p++;
    secondAttr = [self attributeByReadingFormat:&p failed:&failed];
    if (failed) {
        [self printUnknownAttributeErrorOnFormat:str pos:p];
        return;
    }
    
    if (*p != '\0' && *p != '*' && *p != '+' && *p != '-' && *p != '@') {
        [self printInvalidValueError:@"operator" mustbe:@"* + - or @" onFormat:str pos:p];
        return;
    }
    
    if (*p == '*') {
        // multiplier
        p++;
        multiplier = strtof(p, &p2);
        if (p == p2 || multiplier <= 0) {
            [self printInvalidValueError:@"multiplier" mustbe:@"a float greater than 0" onFormat:str pos:p];
            return;
        }
        p = p2;
        if (*p != '\0' && *p != '+' && *p != '-' && *p != '@') {
            [self printInvalidValueError:@"operator" mustbe:@"+|-constant or @priority after multiplier" onFormat:str pos:p];
            return;
        }
    }
    if (*p == '+' || *p == '-') {
        // constant
        BOOL negative = *p == '-';
        p++;
        constant = strtof(p, &p2);
        if (p == p2) {
            [self printInvalidValueError:@"multiplier" mustbe:@"a float" onFormat:str pos:p];
            return;
        }
        p = p2;
        if (*p != '\0' && *p != '+' && *p != '@') {
            [self printInvalidValueError:@"operator" mustbe:@"@priority after constant" onFormat:str pos:p];
            return;
        }
        constant = PBValue(constant);
        if (negative) {
            constant = -constant;
        }
    }
    if (*p == '@') {
        // priority
        p++;
        priority = strtol(p, &p2, priority);
        if (p == p2) {
            [self printInvalidValueError:@"priority" mustbe:@"an integer" onFormat:str pos:p];
            return;
        }
        p = p2;
    }
    
    if (*p != '\0') {
        [self printRedundantErrorOnFormat:str pos:p];
        return;
    }
    
    if (multiplier == 0) {
        multiplier = 1;
    }
    if (priority == 0) {
        priority = UILayoutPriorityRequired;
    }
    NSLayoutConstraint *constraint = [self constraintWithItem:firstItem attribute:firstAttr relatedBy:relation toItem:secondItem attribute:secondAttr multiplier:multiplier constant:constant];
    constraint.priority = priority;
    constraint.identifier = [NSString stringWithFormat:@"%s", str];
    [parentView addConstraint:constraint];
}

#pragma mark - Partial parsing

+ (NSString *)nameByReadingFormat:(char **)inOutStr {
    char *p = *inOutStr;
    if (*p != '_' && !((*p >= 'A' && *p <= 'Z') || (*p >= 'a' && *p <= 'z'))) {
        return nil;
    }
    
    char *p2, *temp;
    NSString *name;
    size_t len = strlen(p) + 1;
    
    p2 = temp = (char *) malloc(len);
    *p2++ = *p++;
    while (*p != '\0' && (*p == '_' || (*p >= '0' && *p <= '9') || (*p >= 'a' && *p <= 'z') || (*p >= 'A' && *p <= 'Z'))) {
        *p2++ = *p++;
    }
    *p2 = '\0';
    *inOutStr = p;
    name = [[NSString alloc] initWithUTF8String:temp];
    free(temp);
    return name;
}

+ (NSLayoutRelation)relationByReadingFormat:(char **)inOutStr failed:(BOOL *)failed {
    NSLayoutRelation relation;
    char *p = *inOutStr;
    if (*p == '=') {
        p++;
        if (*p == '=') {
            p++;
        }
        *inOutStr = p;
        relation = NSLayoutRelationEqual;
    } else if (*p == '<') {
        p++;
        if (*p == '=') {
            p++;
            relation = NSLayoutRelationLessThanOrEqual;
        } else {
            *failed = YES;
        }
        *inOutStr = p;
    } else if (*p == '>') {
        p++;
        if (*p == '=') {
            p++;
            relation = NSLayoutRelationGreaterThanOrEqual;
        } else {
            *failed = YES;
        }
        *inOutStr = p;
    } else {
        *failed = YES;
    }
    
    return relation;
}

+ (NSLayoutAttribute)attributeByReadingFormat:(char **)inOutStr failed:(BOOL *)failed {
    char *p = *inOutStr;
    NSLayoutAttribute attr = NSLayoutAttributeNotAnAttribute;
    
    char *p2, *temp;
    size_t len = strlen(p) + 1;
    p2 = temp = (char *) malloc(len);
    while ((*p >= 'a' && *p <= 'z') || (*p >= 'A' && *p <= 'Z')) {
        *p2++ = *p++;
    }
    *p2 = '\0';
    len = p2 - temp;
    *inOutStr = p;
    
    // left, right, top, bottom, leading, trailing, baseline, centerX or centerY
    //  4      5     3     6        7        8         8         7          7
    
    switch (len) {
        case 3:
            if (strcmp(temp, "top") == 0) {
                attr = NSLayoutAttributeTop;
            }
            break;
        case 4:
            if (strcmp(temp, "left") == 0) {
                attr = NSLayoutAttributeLeft;
            }
            break;
        case 5:
            if (strcmp(temp, "right") == 0) {
                attr = NSLayoutAttributeRight;
            }
            break;
        case 6:
            if (strcmp(temp, "bottom") == 0) {
                attr = NSLayoutAttributeBottom;
            }
            break;
        case 7:
            if (*temp == 'l') {
                if (strcmp(temp + 1, "eading") == 0) {
                    attr = NSLayoutAttributeLeading;
                }
            } else if (*temp == 'c') {
                if (strncmp(temp + 1, "enter", 5) != 0) {
                    break;
                }
                char direction = *(temp + 6);
                if (direction == 'X') {
                    attr = NSLayoutAttributeCenterX;
                } else if (direction == 'Y') {
                    attr = NSLayoutAttributeCenterY;
                }
            }
            break;
        case 8:
            if (*temp == 't') {
                if (strcmp(temp + 1, "railing") == 0) {
                    attr = NSLayoutAttributeTrailing;
                }
            } else if (*temp == 'b') {
                if (strcmp(temp + 1, "aseline") == 0) {
                    attr = NSLayoutAttributeBaseline;
                }
            }
            break;
        default:
            break;
    }
    
    free(temp);
    *failed = (attr == NSLayoutAttributeNotAnAttribute);
    return attr;
}

#pragma mark - Error print

+ (void)printErrorWithTips:(NSString *)tips onFormat:(const char *)format pos:(const char *)pos {
    NSMutableString *error = [NSMutableString stringWithFormat:@"Pbind: Unable to parse constraint format: \n%@\n%s\n", tips, format];
    char *p = (char *) format;
    while (p++ != pos) {
        [error appendString:@" "];
    }
    [error appendString:@"^"];
    NSLog(error);
}

+ (void)printUnknownAttributeErrorOnFormat:(const char *)format pos:(const char *)pos {
    NSString *tips = @"Unknown attribute. Must be left, right, top, bottom, leading, trailing, baseline, centerX or centerY";
    [self printErrorWithTips:tips onFormat:format pos:pos];
}

+ (void)printMissingAttributeErrorOnFormat:(const char *)format pos:(const char *)pos {
    NSString *tips = @"Missing attribute. Requires .left, right, top, bottom, leading, trailing, baseline, centerX or centerY";
    [self printErrorWithTips:tips onFormat:format pos:pos];
}

+ (void)printUnknownRelationErrorOnFormat:(const char *)format pos:(const char *)pos {
    NSString *tips = @"Unknown relation. Must be =, ==, >= or <= ";
    [self printErrorWithTips:tips onFormat:format pos:pos];
}

+ (void)printUndefinedViewError:(NSString *)viewName onFormat:(const char *)format pos:(const char *)pos {
    NSString *tips = [NSString stringWithFormat:@"%@ is not a key in the views dictionary.", viewName];
    [self printErrorWithTips:tips onFormat:format pos:pos];
}

+ (void)printInvalidValueError:(NSString *)key mustbe:(NSString *)mustbe onFormat:(const char *)format pos:(const char *)pos {
    NSString *tips = [NSString stringWithFormat:@"Invalid %@. Must be %@", key, mustbe];
    [self printErrorWithTips:tips onFormat:format pos:pos];
}

+ (void)printMissingViewErrorOnFormat:(const char *)format pos:(const char *)pos {
    NSString *tips = @"Expected a view. View names must start with a letter or an underscore, then contain letters, numbers, and underscores.";
    [self printErrorWithTips:tips onFormat:format pos:pos];
}

+ (void)printMissingAttributePrefixErrorOnFormat:(const char *)format pos:(const char *)pos {
    NSString *tips = @"Expected a '.' here. That is how you give the start of an attribute.";
    [self printErrorWithTips:tips onFormat:format pos:pos];
}

+ (void)printInvalidEdgeInsetsErrorOnFormat:(const char *)format pos:(const char *)pos {
    NSString *tips = @"Invalid edge insets. Must be {top,left,bottom,right} and each as float.";
    [self printErrorWithTips:tips onFormat:format pos:pos];
}

+ (void)printRedundantErrorOnFormat:(const char *)format pos:(const char *)pos {
    NSString *tips = @"Redundant characters";
    [self printErrorWithTips:tips onFormat:format pos:pos];
}

+ (void)printMissingEdgeSeparatorErrorOnFormat:(const char *)format pos:(const char *)pos {
    NSString *tips = @"Expected a ',' here. That is how you separate an edge.";
    [self printErrorWithTips:tips onFormat:format pos:pos];
}

+ (void)printMissingEdgeEndErrorOnFormat:(const char *)format pos:(const char *)pos {
    NSString *tips = @"Expected a '}' here. That is how you give the end of an edge inset.";
    [self printErrorWithTips:tips onFormat:format pos:pos];
}

+ (void)printMissingFloatErrorOnFormat:(const char *)format pos:(const char *)pos {
    NSString *tips = @"Expected a float.";
    [self printErrorWithTips:tips onFormat:format pos:pos];
}

+ (void)printMissingIntegerErrorOnFormat:(const char *)format pos:(const char *)pos {
    NSString *tips = @"Expected an integer.";
    [self printErrorWithTips:tips onFormat:format pos:pos];
}

+ (void)printExpectedSymbolError:(char)symbol usage:(NSString *)usage onFormat:(const char *)format pos:(const char *)pos {
    NSString *tips = [NSString stringWithFormat:@"Expected a '%c' here. That is how you %@.", symbol, usage];
    [self printErrorWithTips:tips onFormat:format pos:pos];
}

@end
