//
//  Pbind+API.h
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by Galen Lin on 16/8/31.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import <UIKit/UIKit.h>
#import <JavaScriptCore/JavaScriptCore.h>

typedef void(^PBPlistReloader)(UIView *rootView, UIView *view, NSString *changedPlist, BOOL *stop);
typedef id(^PBViewValueSetter)(UIView *view, NSString *keyPath, id value, BOOL *canceld, UIView *contextView, NSString *contextKeyPath);
typedef void(^PBViewValueAsyncSetter)(UIView *view, NSString *keyPath, id value, CGSize viewSize, UIView *contextView, NSString *contextKeyPath);

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

/**
 Reload all the views who are using the `plist`.

 @param plist the path of the plist
 */
+ (void)reloadViewsOnPlistUpdate:(NSString *)plist;

+ (void)registerPlistReloader:(PBPlistReloader)reloader;

/**
 Reload all the views who are using the API(`action`).

 @param action the action of the API
 */
+ (void)reloadViewsOnAPIUpdate:(NSString *)action;

+ (void)registerViewValueSetter:(PBViewValueSetter)setter;

+ (void)registerViewValueAsyncSetter:(PBViewValueAsyncSetter)asyncSetter;

+ (void)registerJSContextInitializer:(void (^)(JSContext *context))initializer;

@end
