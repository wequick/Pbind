//
//  PBViewResizingDelegate.h
//  Pbind
//
//  Created by Galen Lin on 2016/11/14.
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol PBViewResizingDelegate <NSObject>

- (void)viewDidChangeFrame:(UIView *)view;

@end
