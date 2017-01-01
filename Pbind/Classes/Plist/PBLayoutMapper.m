//
//  PBLayoutMapper.m
//  Pods
//
//  Created by Galen Lin on 2016/11/1.
//
//

#import "PBLayoutMapper.h"
#import "PBRowMapper.h"
#import "UIView+Pbind.h"
#import "Pbind+API.h"
#import "PBValueParser.h"

@implementation PBLayoutMapper

- (void)collectSubviewAliases:(NSMutableArray *)aliases ofView:(UIView *)view {
    NSArray *subviews = view.subviews;
    NSString *alias = view.alias;
    if (alias != nil) {
        [aliases addObject:alias];
    }
    for (UIView *subview in subviews) {
        [self collectSubviewAliases:aliases ofView:subview];
    }
}

- (void)renderToView:(UIView *)view {
    NSLog(@"layout to %p", view);
    NSInteger viewCount = self.views.count;
    if (viewCount == 0) {
        return;
    }
    
    if ([view isKindOfClass:[UITableViewCell class]] || [view isKindOfClass:[UICollectionViewCell class]]) {
        view = [(id)view contentView];
    }
    
    // Check if any view be removed.
    NSArray *aliases = [self.views allKeys];
    NSMutableArray *addedAliases = [NSMutableArray arrayWithCapacity:aliases.count];
    [self collectSubviewAliases:addedAliases ofView:view];
    NSArray *removedAliases = [addedAliases filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"NOT SELF IN %@", aliases]];
    if (removedAliases.count > 0) {
        for (NSString *alias in removedAliases) {
            UIView *subview = [view viewWithAlias:alias];
            [subview removeFromSuperview];
        }
    }
    
    NSMutableDictionary *views = [NSMutableDictionary dictionaryWithCapacity:viewCount];
    [views setObject:view forKey:@"super"];
    NSMutableArray *originalViews = [NSMutableArray arrayWithCapacity:viewCount];
    BOOL needsReset = NO;
    
    for (NSString *alias in self.views) {
        NSDictionary *properties = [self.views objectForKey:alias];
        PBRowMapper *mapper = [PBRowMapper mapperWithDictionary:properties owner:nil];
        UIView *subview = [view viewWithAlias:alias];
        
        // Support for instant updating.
        BOOL needsCreate = NO;
        if (subview == nil) {
            needsCreate = YES;
        } else if (subview.class != mapper.viewClass) {
            needsCreate = YES;
            [subview removeFromSuperview];
        }
        
        if (needsCreate) {
            subview = [[mapper.viewClass alloc] init];
            subview.translatesAutoresizingMaskIntoConstraints = NO;
            subview.alias = alias;
            [view addSubview:subview];
            
            needsReset = YES;
        } else {
            [originalViews addObject:subview];
        }
        
        [mapper initDataForView:subview];
        [views setObject:subview forKey:alias];
    }
    
    // Remove the related constraints if needed.
    if (originalViews.count > 0) {
        NSArray *constraints = view.constraints;
        for (NSLayoutConstraint *constraint in constraints) {
            if ([originalViews containsObject:constraint.firstItem]
                || [originalViews containsObject:constraint.secondItem]) {
                [view removeConstraint:constraint];
            }
        }
    }
    
    // Calculate metrics.
    NSDictionary *metrics = nil;
    if (self.metrics != nil) {
        NSMutableDictionary *temp = [NSMutableDictionary dictionaryWithCapacity:self.metrics.count];
        for (NSString *key in self.metrics) {
            [temp setObject:@(PBValue([self.metrics[key] floatValue])) forKey:key];
        }
        metrics = temp;
    }
    
    // VFL (Official Visual Format Language)
    for (NSString *format in self.formats) {
        @try {
            NSArray *constraints = [NSLayoutConstraint constraintsWithVisualFormat:format options:0 metrics:metrics views:views];
            [view addConstraints:constraints];
        } @catch (NSException *exception) {
            NSLog(@"Pbind: %@", exception);
            continue;
        }
    }
    
    // PVFL (Pbind Visual Format Language)
    for (NSString *format in self.constraints) {
        @try {
            [self addConstraintsWithPbindVisualFormat:format metrics:metrics views:views forParentView:view];
        } @catch (NSException *exception) {
            NSLog(@"Pbind: %@", exception);
            continue;
        }
    }
}

- (void)addConstraintsWithPbindVisualFormat:(NSString *)format metrics:(NSDictionary *)metrics views:(NSDictionary *)views forParentView:(UIView *)parentView {
    const char *str = [format UTF8String];
    char *p = (char *) str;
    char *temp, *p2;
    size_t len = strlen(str) + 1;
    if (len < 3) {
        NSLog(@"Pbind: Too short for a PFVL.");
        return;
    }
    
    if (*(p+1) == ':') {
        if (*p == 'R') {
            p += 2;
            [self addConstraintWithAspectRatioFormat:p views:views forParentView:parentView];
        } else if (*p == 'E') {
            p += 2;
            [self addConstraintsWithEdgeInsetsFormat:p views:views forParentView:parentView];
        } else if (*p == 'C' || *p == 'M') {
            // Merge and align
            BOOL horizontal = (*p == 'C');
            p += 2;
            [self addConstraintsWithMergeCenterFormat:p horizontal:horizontal metrics:metrics views:views forParentView:parentView];
        }
    } else {
        [self addConstraintWithExplicitFormat:p metrics:metrics views:views forParentView:parentView];
    }
}

#pragma mark - PVFL (Pbind Visual Format Language)

- (void)addConstraintWithAspectRatioFormat:(const char *)str views:(NSDictionary *)views forParentView:(UIView *)parentView {
    char *p = (char *) str;
    char *p2, *temp;
    size_t len = strlen(str) + 1;
    
    p2 = temp = (char *) malloc(len);
    while (*p != '=' && *p != '\0') {
        *p2++ = *p++;
    }
    if (*p == '\0') {
        //
        free(temp);
        return;
    }
    p++;
    *p2 = '\0';
    
    NSString *viewName = [[NSString alloc] initWithUTF8String:temp];
    free(temp);
    UIView *targetView = views[viewName];
    if (targetView == nil) {
        //
        return;
    }
    
    int width = 0;
    int height = 0;
    while (*p != ':' && *p != '\0') {
        if (*p < '0' || *p > '9') {
            // TODO: ratio should be number
            return;
        }
        width = width * 10 + *(p++) - '0';
    }
    if (*p == ':') {
        p++;
        while (*p != '\0') {
            if (*p < '0' || *p > '9') {
                // TODO: ratio should be number
                return;
            }
            height = height * 10 + *(p++) - '0';
        }
    }
    
    CGFloat ratio;
    if (height == 0) {
        ratio = width;
    } else {
        ratio = (float)width / (float)height;
    }
    [parentView addConstraint:[NSLayoutConstraint constraintWithItem:targetView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:targetView attribute:NSLayoutAttributeHeight multiplier:ratio constant:0]];
}

- (void)addConstraintsWithEdgeInsetsFormat:(const char *)str views:(NSDictionary *)views forParentView:(UIView *)parentView {
    char *p = (char *) str;
    char *p2, *temp;
    size_t len = strlen(str) + 1;
    UIView *outerView;
    UIView *innerView;
    NSString *viewName;
    
    p2 = temp = (char *) malloc(len);
    while (*p != '-' && *p != '=' && *p != '\0') {
        *p2++ = *p++;
    }
    if (*p == '\0') {
        //
        free(temp);
        return;
    }
    *p2 = '\0';
    viewName = [[NSString alloc] initWithUTF8String:temp];
    free(temp);
    
    if (*p == '=') {
        p++;
        outerView = parentView;
        innerView = views[viewName];
    } else {
        p++;
        outerView = views[viewName];
        
        p2 = temp = (char *) malloc(len + p - str);
        while (*p != '=' && *p != '\0') {
            *p2++ = *p++;
        }
        if (*p == '\0') {
            //
            free(temp);
            return;
        }
        p++;
        *p2 = '\0';
        
        viewName = [[NSString alloc] initWithUTF8String:temp];
        free(temp);
        innerView = views[viewName];
    }
    
    if (outerView == nil || innerView == nil) {
        //
        return;
    }
    
    if (*p != '{') {
        //
        return;
    }
    UIEdgeInsets inset = UIEdgeInsetsFromString([NSString stringWithUTF8String:p]);
    inset = PBEdgeInsets(inset);
    NSLayoutConstraint *constraint;
    constraint = [NSLayoutConstraint constraintWithItem:innerView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:outerView attribute:NSLayoutAttributeLeading multiplier:1 constant:inset.left];
    [parentView addConstraint:constraint];
    constraint = [NSLayoutConstraint constraintWithItem:outerView attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:innerView attribute:NSLayoutAttributeTrailing multiplier:1 constant:inset.right];
    [parentView addConstraint:constraint];
    constraint = [NSLayoutConstraint constraintWithItem:innerView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:outerView attribute:NSLayoutAttributeTop multiplier:1 constant:inset.top];
    [parentView addConstraint:constraint];
    constraint = [NSLayoutConstraint constraintWithItem:outerView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:innerView attribute:NSLayoutAttributeBottom multiplier:1 constant:inset.bottom];
    [parentView addConstraint:constraint];
}

- (void)addConstraintsWithMergeCenterFormat:(const char *)str horizontal:(BOOL)horizontal metrics:(NSDictionary *)metrics views:(NSDictionary *)views forParentView:(UIView *)parentView {
    char *p = (char *) str;
    char *p2, *temp;
    size_t len = strlen(str) + 1;
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
        //
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
        //
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
        
        [innerViewNames addObject:[[NSString alloc] initWithUTF8String:name]];
        free(name);
    }
    
    NSString *innerFormat = [NSString stringWithFormat:@"%c:|%s|", innerOrientation, temp];
    free(temp);
    
    UIView *mergedContainerView = [[UIView alloc] init];
    mergedContainerView.translatesAutoresizingMaskIntoConstraints = NO;
    [parentView addSubview:mergedContainerView];
    
    for (NSString *viewName in innerViewNames) {
        UIView *view = views[viewName];
        if (view == nil) {
            //
            free(containerFormatStr);
            return;
        }
        
        [view removeFromSuperview];
        [mergedContainerView addSubview:view];
        
        // Fill inner view
        [mergedContainerView addConstraint:[NSLayoutConstraint constraintWithItem:view attribute:innerStartPosAttribute relatedBy:NSLayoutRelationEqual toItem:mergedContainerView attribute:innerStartPosAttribute multiplier:1 constant:0]];
        [mergedContainerView addConstraint:[NSLayoutConstraint constraintWithItem:view attribute:innerEndPosAttribute relatedBy:NSLayoutRelationEqual toItem:mergedContainerView attribute:innerEndPosAttribute multiplier:1 constant:0]];
    }
    
    // Container outer margin
    NSString *containerFormat = [NSString stringWithFormat:@"%c:%s", outerOrientation, containerFormatStr];
    NSMutableDictionary *newViews = [NSMutableDictionary dictionaryWithDictionary:views];
    newViews[mergedContainerViewName] = mergedContainerView;
    [parentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:containerFormat options:0 metrics:metrics views:newViews]];
    
    // Container outer alignment
    [parentView addConstraint:[NSLayoutConstraint constraintWithItem:mergedContainerView attribute:outerAlignmentAttribute relatedBy:NSLayoutRelationEqual toItem:parentView attribute:outerAlignmentAttribute multiplier:1 constant:0]];
    
    // Inner view constraints
    [mergedContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:innerFormat options:0 metrics:metrics views:views]];
}

- (void)addConstraintWithExplicitFormat:(const char *)str metrics:(NSDictionary *)metrics views:(NSDictionary *)views forParentView:(UIView *)parentView {
    //
    // firstItem.firstAttr = secondItem.secondAttr * multiplier + constant
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
    
    // firstItem
    p2 = temp = (char *) malloc(len);
    while (*p != '.' && *p != '\0') {
        *p2++ = *p++;
    }
    if (*p == '\0') {
        // error
        return;
    }
    p++;
    *p2 = '\0';
    viewName = [[NSString alloc] initWithUTF8String:temp];
    free(temp);
    firstItem = views[viewName];
    if (firstItem == nil) {
        // error
        return;
    }
    
    // firstAttr
    p2 = temp = (char *) malloc(len + p - str);
    while (*p != '=' && *p != '<' && *p != '>' && *p != '\0') {
        *p2++ = *p++;
    }
    if (*p == '\0') {
        // error
        free(temp);
        return;
    }
    if (*p == '=') {
        p++;
        if (*p == '=') {
            p++;
        }
        relation = NSLayoutRelationEqual;
    } else if (*p == '<') {
        p++;
        if (*p != '=') {
            // error
            free(temp);
            return;
        }
        p++;
        relation = NSLayoutRelationLessThanOrEqual;
    } else if (*p == '>') {
        p++;
        if (*p != '=') {
            // error
            free(temp);
            return;
        }
        p++;
        relation = NSLayoutRelationGreaterThanOrEqual;
    }
    *p2 = '\0';
    firstAttr = [self layoutAttributeFromUTF8String:temp];
    free(temp);
    if (firstAttr < 0) {
        // error
        return;
    }
    
    // secondItem
    p2 = temp = (char *) malloc(len + p - str);
    while (*p != '.' && *p != '\0') {
        *p2++ = *p++;
    }
    if (*p == '\0') {
        // error
        return;
    }
    p++;
    *p2 = '\0';
    viewName = [[NSString alloc] initWithUTF8String:temp];
    free(temp);
    secondItem = views[viewName];
    if (secondItem == nil) {
        // error
        return;
    }
    
    // secondAttr
    p2 = temp = (char *) malloc(len + p - str);
    while (*p != '*' && *p != '+' && *p != '@' && *p != '\0') {
        *p2++ = *p++;
    }
    if (*p == '*') {
        // multiplier
        char *temp2, *p2;
        p2 = temp2 = (char *) malloc(len + p - str);
        p++;
        while (*p != '+' && *p != '\0') {
            *p2++ = *p++;
        }
        char *endStr;
        *p2 = '\0';
        multiplier = strtof(temp2, &endStr);
        if (*endStr != '\0') {
            // error
            free(temp2);
            free(temp);
            return;
        }
        free(temp2);
    }
    if (*p == '+') {
        // constant
        char *temp2, *p2;
        p2 = temp2 = (char *) malloc(len);
        p++;
        while (*p != '@' && *p != '\0') {
            *p2++ = *p++;
        }
        char *endStr;
        *p2 = '\0';
        constant = strtof(temp2, &endStr);
        if (*endStr != '\0') {
            // error
            free(temp2);
            free(temp);
            return;
        }
        free(temp2);
        if (constant != 0) {
            constant = PBValue(constant);
        }
    }
    if (*p == '@') {
        // priority
        p++;
        while (*p != '\0') {
            if (*p < '0' || *p > '9') {
                // error
                free(temp);
                return;
            }
            priority = priority * 10 + (*p++) - '0';
        }
    }
    
    *p2 = '\0';
    secondAttr = [self layoutAttributeFromUTF8String:temp];
    free(temp);
    if (secondAttr < 0) {
        // error
        return;
    }
    
    if (multiplier == 0) {
        multiplier = 1;
    }
    if (priority == 0) {
        priority = UILayoutPriorityRequired;
    }
    NSLog(@"-- * %.2f + %.2f @ %d", multiplier, constant, (int)priority);
    NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:firstItem attribute:firstAttr relatedBy:relation toItem:secondItem attribute:secondAttr multiplier:multiplier constant:constant];
    constraint.priority = priority;
    [parentView addConstraint:constraint];
}

- (NSLayoutAttribute)layoutAttributeFromUTF8String:(const char *)str {
    // Well, we don't check the spell but fastly matching by characters.
    char *p = (char *) str;
    if (*p == 'l') {
        p++;
        if (*p == '\0') {
            return NSLayoutAttributeLeft;
        }
        if (*p == 'e') {
            p++;
            if (*p == 'f') {
                return NSLayoutAttributeLeft;
            }
            if (*p == 'a') {
                return NSLayoutAttributeLeading;
            }
        }
    } else if (*p == 'r') {
        return NSLayoutAttributeRight;
    } else if (*p == 't') {
        p++;
        if (*p == '\0' || *p == 'o') {
            return NSLayoutAttributeTop;
        }
        if (*p == 'r') {
            return NSLayoutAttributeTrailing;
        }
    } else if (*p == 'b') {
        p++;
        if (*p == '\0' || *p == 'o') {
            return NSLayoutAttributeBottom;
        }
        if (*p == 'a') {
            return NSLayoutAttributeBaseline;
        }
    } else if (*p == 'w') {
        return NSLayoutAttributeWidth;
    } else if (*p == 'h') {
        return NSLayoutAttributeHeight;
    } else if (*p == 'c') {
        p++;
        if (*p == 'x') {
            return NSLayoutAttributeCenterX;
        }
        if (*p == 'y') {
            return NSLayoutAttributeCenterY;
        }
        if (*p++ == 'e') {
            if (*p++ == 'n') {
                if (*p++ == 't') {
                    if (*p++ == 'e') {
                        if (*p++ = 'r') {
                            if (*p++ == 'X') {
                                return NSLayoutAttributeCenterX;
                            }
                            return NSLayoutAttributeCenterY;
                        }
                    }
                }
            }
        }
    }
    return -1;
}

@end
