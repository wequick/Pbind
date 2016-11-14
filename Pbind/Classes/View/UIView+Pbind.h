//
//  UIView+Pbind.h
//  Pbind
//
//  Created by galen on 15/2/12.
//  Copyright (c) 2015年 galen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PBClient.h"

//______________________________________________________________________________

@protocol PBViewLoadingDelegate <NSObject>

@optional
- (BOOL)view:(UIView *)view shouldLoadRequest:(PBRequest *)request;
- (void)view:(UIView *)view didFinishLoading:(PBResponse *)response handledError:(BOOL *)handledError;

@end

//______________________________________________________________________________

@protocol PBViewMappingDelegate <NSObject>

@optional
- (void)pb_resetMappers;

@end

//______________________________________________________________________________

@interface UIView (Pbind) <PBViewLoadingDelegate, PBViewMappingDelegate>

@property (nonatomic, strong) NSDictionary *PBConstantProperties;
@property (nonatomic, strong) NSDictionary *PBDynamicProperties;

@property (nonatomic, strong) NSString *plist;

@property (nonatomic, strong) NSArray *clients;
@property (nonatomic, strong) NSDictionary *actions;

@property (nonatomic, strong) NSString *client;
@property (nonatomic, strong) NSString *clientAction;
@property (nonatomic, strong) NSDictionary *clientParams;

@property (nonatomic, strong) NSString *href;
@property (nonatomic, strong) NSDictionary *hrefParams;
@property (nonatomic, strong, readonly, getter=rootData) id rootData;
@property (nonatomic, strong) id data;
@property (nonatomic, assign) id<PBViewLoadingDelegate> loadingDelegate;
@property (nonatomic, assign) BOOL needsLoad;

@property (nonatomic, assign, readonly) BOOL pb_loading;
@property (nonatomic, assign) BOOL pb_interrupted;
@property (nonatomic, assign) BOOL showsLoadingCover;

@property (nonatomic, assign) void (^pb_preparation)(void);
@property (nonatomic, assign) id (^pb_transformation)(id data, NSError *error);

/**
 The alias name for the view.
 
 @discussion you can use [view viewWithAlias:] to get the specify aliased subview.
 */
@property (nonatomic, strong) NSString *alias;

- (void)setMappable:(BOOL)mappable forKeyPath:(NSString *)keyPath;
- (BOOL)mappableForKeyPath:(NSString *)keyPath;

- (void)setExpression:(NSString *)expression forKeyPath:(NSString *)keyPath;
- (BOOL)hasExpressionForKeyPath:(NSString *)keyPath;

- (UIViewController *)supercontroller;
- (id)superviewWithClass:(Class)clazz;

- (void)pb_clickHref:(NSString *)href;

/**
 Reload the plist.
 
 @discussion This will search the plist from `[Pbind allResourcesBundles]' and reload it.
 */
- (void)pb_reloadPlist;
- (void)pb_initData; // Init constant properties
- (void)pb_mapData:(id)data; // Init dynamic properties by data
- (void)pb_mapData:(id)data forKey:(NSString *)key;
- (void)pb_pullData;
- (void)pb_pullDataWithPreparation:(void (^)(void))preparation transformation:(id (^)(id data, NSError *error))transformation;
- (void)pb_repullData; // repull with previous `preparation' and `transformation'
- (void)pb_loadData:(id)data;
- (void)pb_cancelPull;

/**
 Reload data from clients.
 
 @discussion This will introduce the instant updating feature since you specify a debug server by:
 [PBClient registerDebugServer:]
 */
- (void)pb_reloadClient;

/**
 Find subview with alias.
 
 @discussion If the alias is an integer, use [viewWithTag:] instead.

 @param alias the alias for the view

 @return the subview with the alias.
 */
- (UIView *)viewWithAlias:(NSString *)alias;

- (void)pb_setValue:(id)value forKeyPath:(NSString *)keyPath;

@end

@interface UIView (PBAdditionProperties)

- (void)setValue:(id)value forAdditionKey:(NSString *)key;
- (id)valueForAdditionKey:(NSString *)key;

@end

UIKIT_EXTERN NSString *const PBViewDidStartLoadNotification;
UIKIT_EXTERN NSString *const PBViewDidFinishLoadNotification;
UIKIT_EXTERN NSString *const PBViewHasHandledLoadErrorKey;

UIKIT_EXTERN NSString *const PBViewDidClickHrefNotification;
UIKIT_EXTERN NSString *const PBViewHrefKey;
UIKIT_EXTERN NSString *const PBViewHrefParamsKey;

UIKIT_EXTERN NSString *const PBViewWillRemoveFromSuperviewNotification;

UIKIT_STATIC_INLINE NSString *PBHrefEncode(NSString *href)
{
    return (NSString *)
    CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                              (CFStringRef)href,
                                                              (CFStringRef)@"!$&'()*+,-./:;=?@_~%#[]",
                                                              NULL,
                                                              kCFStringEncodingUTF8));
}

UIKIT_STATIC_INLINE NSString *PBHrefDecode(NSString *href)
{
    return (__bridge_transfer NSString *)
    CFURLCreateStringByReplacingPercentEscapesUsingEncoding(NULL,
                                                            (__bridge CFStringRef)href,
                                                            CFSTR(""),
                                                            CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding));
}

UIKIT_STATIC_INLINE NSString *PBParameterJson(id object)
{
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:object options:0 error:nil];
    NSString *json = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    json = PBHrefEncode(json);
    json = [json stringByReplacingOccurrencesOfString:@"&" withString:@"<amp>"];
    return json;
}

UIKIT_STATIC_INLINE id PBParameterDejson(NSString *json)
{
    NSString *decodedJson = PBHrefDecode(json);
    decodedJson = [decodedJson stringByReplacingOccurrencesOfString:@"<amp>" withString:@"&"];
    return [NSJSONSerialization JSONObjectWithData:[decodedJson dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
}

typedef void (*PBCallControllerFunc)(id, SEL, id);

UIKIT_STATIC_INLINE void PBViewClickHref(UIView *view, NSString *href)
{
    [view pb_clickHref:href];
}

