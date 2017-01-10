//
//  PBLayoutConstraint.h
//  Pbind
//
//  Created by Galen Lin on 07/01/2017.
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface PBLayoutConstraint : NSLayoutConstraint

+ (void)addConstraintsWithPbindFormats:(NSArray<NSString *> *)formats metrics:(nullable NSDictionary<NSString *,id> *)metrics views:(NSDictionary<NSString *, id> *)views forParentView:(UIView *)parentView;

+ (void)removeAllConstraintsOfSubview:(UIView *)subview fromParentView:(UIView *)parentView;

@end
