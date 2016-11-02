//
//  Pbind+API.h
//  Pbind
//
//  Created by Galen Lin on 16/8/31.
//  Copyright © 2016年 galen. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface Pbind : NSObject

/**
 The width pixel of the sketch provided by UI designer.
 */
+ (void)setSketchWidth:(CGFloat)sketchWidth;

/**
 The scaled value calculated by the scale of `sketchWidth' and current device screen width.
 */
+ (CGFloat)valueScale;

/**
 Add a resources bundle who contains `*.plist', `*.xib', `*.png'.
 
 @discussion: The added bundle will be inserted to the top of `allResourcesBundles', 
 so the resources inside it will consider to be load by first order.
 
 */
+ (void)addResourcesBundle:(NSBundle *)bundle;

/**
 Returns all the loaded resources bundles.
 */
+ (NSArray<NSBundle *> *)allResourcesBundles;

@end

/**
 Calculate the scaled value.
 
 @discussion Round the decimal value as follow:
 
 * <= 0.3   downto  0
 * >= 0.7   upto    1
 * 0.4-0.6  as      0.5
 
 */
UIKIT_STATIC_INLINE CGFloat PBValueByScale(CGFloat value, CGFloat scale) {
    if (value == 0) {
        return 0;
    }
    
    value *= scale;
    if (value < 0) {
        return value;
    }
    
    int integer = (int) value;
    int decimal = (value - integer) * 10;
    if (decimal <= 3) {
        return integer;
    } else if (decimal >= 7) {
        return integer + 1.f;
    } else {
        return integer + .5f;
    }
}

UIKIT_STATIC_INLINE CGFloat PBValue2(CGFloat value, CGFloat sketchWidth) {
    CGFloat scale = [Pbind valueScale];
    if (sketchWidth != 0) {
        scale = [UIScreen mainScreen].bounds.size.width / sketchWidth;
    }
    return PBValueByScale(value, scale);
}

UIKIT_STATIC_INLINE CGFloat PBValue(CGFloat value) {
    return PBValueByScale(value, [Pbind valueScale]);
}

UIKIT_STATIC_INLINE CGPoint PBPoint(CGPoint point) {
    return CGPointMake(PBValue(point.x),
                       PBValue(point.y));
}

UIKIT_STATIC_INLINE CGPoint PBPoint2(CGPoint point, CGFloat sketchWidth) {
    return CGPointMake(PBValue2(point.x, sketchWidth),
                       PBValue2(point.y, sketchWidth));
}

UIKIT_STATIC_INLINE CGPoint PBPointMake(CGFloat x, CGFloat y) {
    return CGPointMake(PBValue(x), PBValue(y));
}

UIKIT_STATIC_INLINE CGSize PBSize(CGSize size) {
    return CGSizeMake(PBValue(size.width),
                      PBValue(size.height));
}

UIKIT_STATIC_INLINE CGSize PBSize2(CGSize size, CGFloat sketchWidth) {
    return CGSizeMake(PBValue2(size.width, sketchWidth),
                      PBValue2(size.height, sketchWidth));
}

UIKIT_STATIC_INLINE CGSize PBSizeMake(CGFloat w, CGFloat h) {
    return CGSizeMake(PBValue(w), PBValue(h));
}

UIKIT_STATIC_INLINE CGRect PBRect(CGRect rect) {
    return CGRectMake(PBValue(rect.origin.x),
                      PBValue(rect.origin.y),
                      PBValue(rect.size.width),
                      PBValue(rect.size.height));
}

UIKIT_STATIC_INLINE CGRect PBRect2(CGRect rect, CGFloat sketchWidth) {
    return CGRectMake(PBValue2(rect.origin.x, sketchWidth),
                      PBValue2(rect.origin.y, sketchWidth),
                      PBValue2(rect.size.width, sketchWidth),
                      PBValue2(rect.size.height, sketchWidth));
}

UIKIT_STATIC_INLINE CGRect PBRectMake(CGFloat x, CGFloat y, CGFloat w, CGFloat h) {
    return CGRectMake(PBValue(x), PBValue(y), PBValue(w), PBValue(h));
}

UIKIT_STATIC_INLINE UIEdgeInsets PBEdgeInsets(UIEdgeInsets insets) {
    return UIEdgeInsetsMake(PBValue(insets.top),
                            PBValue(insets.left),
                            PBValue(insets.bottom),
                            PBValue(insets.right));
}

UIKIT_STATIC_INLINE UIEdgeInsets PBEdgeInsets2(UIEdgeInsets insets, CGFloat sketchWidth) {
    return UIEdgeInsetsMake(PBValue2(insets.top, sketchWidth),
                            PBValue2(insets.left, sketchWidth),
                            PBValue2(insets.bottom, sketchWidth),
                            PBValue2(insets.right, sketchWidth));
}

UIKIT_STATIC_INLINE UIEdgeInsets PBEdgeInsetsMake(CGFloat t, CGFloat l, CGFloat b, CGFloat r) {
    return UIEdgeInsetsMake(PBValue(t), PBValue(l), PBValue(b), PBValue(r));
}

UIKIT_STATIC_INLINE NSURL *PBResourceURL(NSString *resource, NSString *extension) {
    NSArray *preferredBundles = [Pbind allResourcesBundles];
    for (NSBundle *bundle in preferredBundles) {
        NSURL *url = [bundle URLForResource:resource withExtension:extension];
        if (url != nil) {
            return url;
        }
    }
    return nil;
}

UIKIT_STATIC_INLINE NSDictionary *PBPlist(NSString *plistName) {
    NSURL *url = PBResourceURL(plistName, @"plist");
    if (url == nil) {
        return nil;
    }
    return [NSDictionary dictionaryWithContentsOfURL:url];
}
