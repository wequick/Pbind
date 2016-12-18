//
//  UINavigationItem+Pbind.h
//  Pods
//
//  Created by Galen Lin on 2016/12/18.
//
//

#import <UIKit/UIKit.h>

@interface UINavigationItem (Pbind)

- (void)setRight:(NSDictionary *)right;
- (void)setRights:(NSArray *)rights;

- (void)setLeft:(NSDictionary *)left;
- (void)setLefts:(NSArray *)lefts;

@end
