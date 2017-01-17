//
//  Pbind.m
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by Galen Lin on 16/8/31.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "PBInline.h"
#import "UIView+Pbind.h"

@implementation Pbind : NSObject

static const CGFloat kDefaultSketchWidth = 320.f;
static CGFloat kValueScale = 0;
static NSMutableArray *kResourcesBundles = nil;

+ (void)setSketchWidth:(CGFloat)sketchWidth {
    kValueScale = [UIScreen mainScreen].bounds.size.width / sketchWidth;
}

+ (CGFloat)valueScale {
    if (kValueScale == 0) {
        kValueScale = [UIScreen mainScreen].bounds.size.width / kDefaultSketchWidth;
    }
    return kValueScale;
}

+ (void)addResourcesBundle:(NSBundle *)bundle {
    if (kResourcesBundles == nil) {
        kResourcesBundles = [[NSMutableArray alloc] init];
        [kResourcesBundles addObject:[NSBundle mainBundle]];
    }
    
    if ([kResourcesBundles indexOfObject:bundle] != NSNotFound) {
        return;
    }
    [kResourcesBundles insertObject:bundle atIndex:0];
}

+ (NSArray<NSBundle *> *)allResourcesBundles {
    if (kResourcesBundles == nil) {
        kResourcesBundles = [[NSMutableArray alloc] init];
        [kResourcesBundles addObject:[NSBundle mainBundle]];
    }
    return kResourcesBundles;
}

+ (void)enumerateControllersUsingBlock:(void (^)(UIViewController *controller))block {
    UIViewController *rootViewController = [[UIApplication sharedApplication].delegate window].rootViewController;
    [self enumerateControllersUsingBlock:block withController:rootViewController];
}

+ (void)enumerateControllersUsingBlock:(void (^)(UIViewController *controller))block withController:(UIViewController *)controller {
    
    block(controller);
    
    UIViewController *presentedController = [controller presentedViewController];
    if (presentedController != nil) {
        [self enumerateControllersUsingBlock:block withController:presentedController];
    }
    
    if ([controller isKindOfClass:[UINavigationController class]]) {
        UINavigationController *nav = (id) controller;
        for (UIViewController *vc in nav.viewControllers) {
            [self enumerateControllersUsingBlock:block withController:vc];
        }
    } else if ([controller isKindOfClass:[UITabBarController class]]) {
        UITabBarController *tc = (id) controller;
        for (UIViewController *vc in tc.viewControllers) {
            [self enumerateControllersUsingBlock:block withController:vc];
        }
    }
}

+ (void)reloadViewsOnPlistUpdate:(NSString *)plist {
    // Reload the specify views that using the plist.
    NSArray *pathComponents = [plist componentsSeparatedByString:@"/"];
    NSString *changedPlist = [[pathComponents lastObject] stringByReplacingOccurrencesOfString:@".plist" withString:@""];
    [self enumerateControllersUsingBlock:^(UIViewController *controller) {
        NSString *usingPlist = controller.view.plist;
        if (usingPlist == nil) {
            return;
        }
        
        if ([changedPlist isEqualToString:usingPlist]) {
            [controller.view pb_reloadPlist];
        }
        
        // TODO: check the layout configured in the plist
    }];
}

+ (void)reloadViewsOnAPIUpdate:(NSString *)action {
    // TODO: reload the specify views that using the API.
    UIViewController *controller = PBTopController();
    [controller.view pb_reloadClient];
}

@end
