//
//  PBLayoutMapper.h
//  Pods
//
//  Created by Galen Lin on 2016/11/1.
//
//

#import "PBMapper.h"

@interface PBLayoutMapper : PBMapper

/**
 The subviews to create.
 
 @discussion Each view(dictionary) is parsed to a `PBRowMapper'.
 */
@property (nonatomic, strong) NSDictionary *views;

/**
 The metrics for auto-layout.
 
 @discussion Each metric will be re-calculated by `PBValue()'.
 */
@property (nonatomic, strong) NSDictionary *metrics;

/**
 The format constraints for auto-layout. Using visual format language.
 */
@property (nonatomic, strong) NSArray *formats;

/**
 Create all the subviews and add to the parent view.

 @param view The parent view.
 */
- (void)renderToView:(UIView *)view;

@end
