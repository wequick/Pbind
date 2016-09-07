//
//  Less+API.h
//  Less
//
//  Created by Galen Lin on 16/8/31.
//  Copyright © 2016年 galen. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface Less : NSObject

+ (void)setSketchWidth:(CGFloat)sketchWidth; // The width pixel of the sketch provided by UI designer.
+ (CGFloat)valueScale; // The scale calculated with the `sketchWidth' and current device screen width. Less will use this to adjust all the sizes specified in Plist.

@end
