//
//  PBLayoutMapper.m
//  Pods
//
//  Created by Galen Lin on 2016/11/1.
//
//

#import "PBLayoutMapper.h"

@implementation PBLayoutMapper

- (void)addtoParent:(UIView *)view {
    NSInteger viewCount = self.views.count;
    if (viewCount == 0) {
        return;
    }
    
    NSMutableDictionary *views = [NSMutableDictionary dictionaryWithCapacity:viewCount];
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
    
    // Add all the constraints from configuration.
    NSDictionary *metrics = nil;
    if (self.metrics != nil) {
        NSMutableDictionary *temp = [NSMutableDictionary dictionaryWithCapacity:self.metrics.count];
        for (NSString *key in self.metrics) {
            [temp setObject:@(PBValue([self.metrics[key] floatValue])) forKey:key];
        }
        metrics = temp;
    }
    
    for (NSString *format in self.constraints) {
        [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:format options:0 metrics:metrics views:views]];
    }
}

@end
