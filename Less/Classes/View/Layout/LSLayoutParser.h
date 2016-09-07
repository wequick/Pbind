//
//  LSLayoutParser.h
//  Less
//
//  Created by galen on 15/3/8.
//  Copyright (c) 2015年 galen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "LSCompat.h"

@interface LSLayoutParser : NSObject

AS_SINGLETON(sharedParser)

- (UIView *)viewFromLayout:(NSString *)layout bundle:(NSBundle *)bundle;
- (UIView *)viewFromLayoutURL:(NSURL *)layoutURL;

//- (UIViewController *)controllerFromLayout:(NSString *)layout bundle:(NSBundle *)bundle;
//- (UIViewController *)controllerFromLayoutURL:(NSURL *)layoutURL;

@end
