//
//  Less.m
//  Less
//
//  Created by Galen Lin on 16/8/31.
//  Copyright © 2016年 galen. All rights reserved.
//

#import "Less+API.h"

@implementation Less : NSObject

static const CGFloat kDefaultSketchWidth = 1080.f;
static CGFloat kValueScale = 0;

+ (void)setSketchWidth:(CGFloat)sketchWidth {
    kValueScale = [UIScreen mainScreen].bounds.size.width / sketchWidth;
}

+ (CGFloat)valueScale {
    if (kValueScale == 0) {
        kValueScale = [UIScreen mainScreen].bounds.size.width / kDefaultSketchWidth;
    }
    return kValueScale;
}

@end
