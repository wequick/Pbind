//
//  PBInline.h
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by galen on 15/4/9.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import <Foundation/Foundation.h>
#import "PBValueParser.h"
#import "Pbind+API.h"
#import "PBRowMapper.h"

/**
 Create the color with hex string

 @param hexString the hex string describes a color
 @return the color created with hex string
 */
FOUNDATION_STATIC_INLINE UIColor *PBColorMake(NSString *hexString)
{
    if ([hexString characterAtIndex:0] != '#') {
        hexString = [@"#" stringByAppendingString:hexString];
    }
    return [PBValueParser valueWithString:hexString];
}

/**
 Calculate the scaled value.
 
 @discussion This will round the decimal value with following rules:
 
 * <= 0.3   down to  0
 * >= 0.7   up to    1
 * 0.4-0.6  as       0.5
 
 @param value the original value
 @scale the scale coefficient
 @return the scaled value
 */
UIKIT_STATIC_INLINE CGFloat PBValueByScale(CGFloat value, CGFloat scale) {
    return value;
//    if (value == 0) {
//        return 0;
//    }
//    
//    value *= scale;
//    if (value < 0) {
//        return value;
//    }
//    
//    int integer = (int) value;
//    int decimal = (value - integer) * 10;
//    if (decimal <= 3) {
//        return integer;
//    } else if (decimal >= 7) {
//        return integer + 1.f;
//    } else {
//        return integer + .5f;
//    }
}

/**
 Calculate the scaled value by the given sketch width

 @param value the value to be scaled
 @param sketchWidth the base sketch width
 @return the scaled value
 */
UIKIT_STATIC_INLINE CGFloat PBValue2(CGFloat value, CGFloat sketchWidth) {
    CGFloat scale = [Pbind valueScale];
    if (sketchWidth != 0) {
        scale = [UIScreen mainScreen].bounds.size.width / sketchWidth;
    }
    return PBValueByScale(value, scale);
}

/**
 Calculate the scaled value by default sketch width

 @param value the valued to be scaled
 @return the scaled value
 */
UIKIT_STATIC_INLINE CGFloat PBValue(CGFloat value) {
    return PBValueByScale(value, [Pbind valueScale]);
}

/**
 Scale all the metrics in CGPoint

 @param point the point to be scaled
 @return the scaled point
 */
UIKIT_STATIC_INLINE CGPoint PBPoint(CGPoint point) {
    return CGPointMake(PBValue(point.x),
                       PBValue(point.y));
}

/**
 Scale all the metrics in CGPoint with a sketch width

 @param point the point to be scaled
 @param sketchWidth the base sketch width
 @return the scaled point
 */
UIKIT_STATIC_INLINE CGPoint PBPoint2(CGPoint point, CGFloat sketchWidth) {
    return CGPointMake(PBValue2(point.x, sketchWidth),
                       PBValue2(point.y, sketchWidth));
}

/**
 Create a scaled CGPoint

 @param x the original x
 @param y the original y
 @return the scaled CGPoint
 */
UIKIT_STATIC_INLINE CGPoint PBPointMake(CGFloat x, CGFloat y) {
    return CGPointMake(PBValue(x), PBValue(y));
}

/**
 Scale all the metrics in CGSize
 
 @param size the size to be scaled
 @return the scaled size
 */
UIKIT_STATIC_INLINE CGSize PBSize(CGSize size) {
    return CGSizeMake(PBValue(size.width),
                      PBValue(size.height));
}

/**
 Scale all the metrics in CGSize with a sketch width
 
 @param size the size to be scaled
 @param sketchWidth the base sketch width
 @return the scaled size
 */
UIKIT_STATIC_INLINE CGSize PBSize2(CGSize size, CGFloat sketchWidth) {
    return CGSizeMake(PBValue2(size.width, sketchWidth),
                      PBValue2(size.height, sketchWidth));
}

/**
 Create a scaled CGSize
 
 @param w the original width
 @param h the original height
 @return the scaled CGSize
 */
UIKIT_STATIC_INLINE CGSize PBSizeMake(CGFloat w, CGFloat h) {
    return CGSizeMake(PBValue(w), PBValue(h));
}

/**
 Scale all the metrics in CGRect
 
 @param rect the rect to be scaled
 @return the scaled rect
 */
UIKIT_STATIC_INLINE CGRect PBRect(CGRect rect) {
    return CGRectMake(PBValue(rect.origin.x),
                      PBValue(rect.origin.y),
                      PBValue(rect.size.width),
                      PBValue(rect.size.height));
}

/**
 Scale all the metrics in CGRect with a sketch width
 
 @param rect the rect to be scaled
 @param sketchWidth the base sketch width
 @return the scaled rect
 */
UIKIT_STATIC_INLINE CGRect PBRect2(CGRect rect, CGFloat sketchWidth) {
    return CGRectMake(PBValue2(rect.origin.x, sketchWidth),
                      PBValue2(rect.origin.y, sketchWidth),
                      PBValue2(rect.size.width, sketchWidth),
                      PBValue2(rect.size.height, sketchWidth));
}

/**
 Create a scaled CGRect
 
 @param x the original x
 @param y the original y
 @param w the original width
 @param h the original height
 @return the scaled CGRect
 */
UIKIT_STATIC_INLINE CGRect PBRectMake(CGFloat x, CGFloat y, CGFloat w, CGFloat h) {
    return CGRectMake(PBValue(x), PBValue(y), PBValue(w), PBValue(h));
}

/**
 Scale all the metrics in UIEdgeInsets
 
 @param insets the insets to be scaled
 @return the scaled insets
 */
UIKIT_STATIC_INLINE UIEdgeInsets PBEdgeInsets(UIEdgeInsets insets) {
    return UIEdgeInsetsMake(PBValue(insets.top),
                            PBValue(insets.left),
                            PBValue(insets.bottom),
                            PBValue(insets.right));
}

/**
 Scale all the metrics in UIEdgeInsets with a sketch width
 
 @param insets the insets to be scaled
 @param sketchWidth the base sketch width
 @return the scaled insets
 */
UIKIT_STATIC_INLINE UIEdgeInsets PBEdgeInsets2(UIEdgeInsets insets, CGFloat sketchWidth) {
    return UIEdgeInsetsMake(PBValue2(insets.top, sketchWidth),
                            PBValue2(insets.left, sketchWidth),
                            PBValue2(insets.bottom, sketchWidth),
                            PBValue2(insets.right, sketchWidth));
}

/**
 Create a scaled UIEdgeInsets
 
 @param t the original top
 @param l the original left
 @param b the original bottom
 @param r the original right
 @return the scaled UIEdgeInsets
 */
UIKIT_STATIC_INLINE UIEdgeInsets PBEdgeInsetsMake(CGFloat t, CGFloat l, CGFloat b, CGFloat r) {
    return UIEdgeInsetsMake(PBValue(t), PBValue(l), PBValue(b), PBValue(r));
}

/**
 Resolve the resource URL
 
 @discussion This will search the resource in `allResourcesBundles`

 @param resource the name of the resource
 @param extension the extension of the resource
 @return the URL for the resource
 */
UIKIT_STATIC_INLINE NSURL *PBResourceURL(NSString *resource, NSString *extension) {
    NSArray *preferredBundles = [Pbind allResourcesBundles];
    for (NSBundle *bundle in preferredBundles) {
        NSURL *url = [bundle bundleURL];
        if ([url isFileURL]) {
            // If the resource is in file system, while something recently added to the bundle,
            // the bundle would not recognize it, which means:
            //      [bundle URLForResource:resource withExtension:extension]
            // return nil.
            // So we had to manually check if the file exists and return the correct URL.
            NSString *name = [NSString stringWithFormat:@"%@.%@", resource, extension];
            NSString *path = [[bundle bundlePath] stringByAppendingPathComponent:name];
            if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
                return [NSURL URLWithString:name relativeToURL:url];
            }
        } else {
            url = [bundle URLForResource:resource withExtension:extension];
            if (url != nil) {
                return url;
            }
        }
    }
    return nil;
}

/**
 Resolve the content from a plist
 
 @discussion This will search the plist in `allResourcesBundles`

 @param plistName the name of the plist file
 @return the dictionary parsed from the plist
 */
UIKIT_STATIC_INLINE NSDictionary *PBPlist(NSString *plistName) {
    NSURL *url = PBResourceURL(plistName, @"plist");
    if (url == nil) {
        return nil;
    }
    return [NSDictionary dictionaryWithContentsOfURL:url];
}

/**
 Create an image from the given image name
 
 @discussion This will search the image in `allResourcesBundles`
 
 @param imageName the image name
 @return the image for the name
 */
UIKIT_STATIC_INLINE UIImage *PBImage(NSString *imageName) {
    if (imageName == nil) {
        return nil;
    }
    
    NSArray *preferredBundles = [Pbind allResourcesBundles];
    UIImage *image = nil;
    for (NSBundle *bundle in preferredBundles) {
        image = [UIImage imageNamed:imageName inBundle:bundle compatibleWithTraitCollection:nil];
        if (image != nil) {
            break;
        }
    }
    return image;
}

/**
 Get the localized string for the given key.
 
 @discussion This will search the localization in `allResourcesBundles`
 
 @param key the key in the default string table: `Localizable.strings`
 @return the first found localized string for the key
 */
UIKIT_STATIC_INLINE NSString *PBLocalizedString(NSString *key) {
    if (key == nil) {
        return nil;
    }
    
    NSArray *preferredBundles = [Pbind allResourcesBundles];
    NSString *localeString = nil;
    for (NSBundle *bundle in preferredBundles) {
        localeString = [bundle localizedStringForKey:key value:nil table:nil];
        if (localeString != nil) {
            break;
        }
    }
    return localeString;
}

/**
 Create a nib object from the given xib file
 
 @discussion This will search the xib file in `allResourcesBundles`

 @param nibName the name of the xib file
 @return the nib object
 */
UIKIT_STATIC_INLINE UINib *PBNib(NSString *nibName) {
    if (nibName == nil) {
        return nil;
    }
    
    NSArray *preferredBundles = [Pbind allResourcesBundles];
    UINib *nib = nil;
    for (NSBundle *bundle in preferredBundles) {
        if ([bundle pathForResource:nibName ofType:@"nib"] != nil) {
            nib = [UINib nibWithNibName:nibName bundle:bundle];
            break;
        }
    }
    return nib;
}

/**
 Look up the visible controller from the given controller
 
 @param controller current controller
 
 @return the visible controller
 */
UIKIT_STATIC_INLINE UIViewController *PBVisibleController(UIViewController *controller) {
    UIViewController *presentedController = [controller presentedViewController];
    if (presentedController != nil) {
        if (presentedController.popoverPresentationController != nil) {
            return controller;
        }
        return PBVisibleController(presentedController);
    }
    
    if ([controller isKindOfClass:[UINavigationController class]]) {
        return PBVisibleController([(id)controller topViewController]);
    }
    
    if ([controller isKindOfClass:[UITabBarController class]]) {
        return PBVisibleController([(id)controller selectedViewController]);
    }
    
    return controller;
}

/**
 Look up the visible controller for the application
 
 @return the top visible controller
 */
UIKIT_STATIC_INLINE UIViewController *PBTopController() {
    UIViewController *rootController = [[UIApplication sharedApplication].delegate window].rootViewController;
    return PBVisibleController(rootController);
}

/**
 Create a view from plist

 @param plist the plist for PBRowMapper
 @return the view created
 */
UIKIT_STATIC_INLINE UIView *PBView(NSString *plist) {
    NSDictionary *viewInfo = PBPlist(plist);
    if (viewInfo == nil) {
        return nil;
    }
    
    PBRowMapper *mapper = [PBRowMapper mapperWithDictionary:viewInfo];
    UIView *view = [mapper createView];
    
    // Initilize constants and expressions for the view.
    // FIXME: the context was not ready now, maybe we should do it later.
    [mapper initDataForView:view];
    
    return view;
}

#pragma mark - Pixel
///=============================================================================
/// @name Pixel
///=============================================================================

/**
 Calculate the scaled value.
 
 @discussion This will round the decimal value with following rules:
 
 * <= 0.3   down to  0
 * >= 0.7   up to    1
 * 0.4-0.6  as       0.5
 
 @param value the original value
 @scale the scale coefficient
 @return the scaled value
 */
UIKIT_STATIC_INLINE CGFloat PBPixelByScale(CGFloat value, CGFloat scale) {
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

UIKIT_STATIC_INLINE CGFloat PBPixel(CGFloat value) {
    return PBPixelByScale(value, [Pbind valueScale]);
}

UIKIT_STATIC_INLINE CGFloat PBPixelFromUTF8String(const char *str) {
    BOOL needsScale = NO;
    char *p = (char *) str;
    if (*p == '~') {
        needsScale = YES;
        p++;
    }
    
    CGFloat value = atof(p);
    if (needsScale) {
        return PBPixel(value);
    }
    return value;
}

UIKIT_STATIC_INLINE CGFloat PBPixelFromString(NSString *string) {
    if ([string isKindOfClass:[NSNumber class]]) {
        return [string doubleValue];
    }
    
    if (string == nil || string.length == 0) {
        return 0;
    }
    
    const char *str = [string UTF8String];
    return PBPixelFromUTF8String(str);
}
