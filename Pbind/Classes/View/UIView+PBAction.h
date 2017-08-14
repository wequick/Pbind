//
//  UIView+PBAction.h
//  Pods
//
//  Created by galen on 17/8/14.
//
//

#import <UIKit/UIKit.h>

@interface UIView (PBAction)

- (void)pb_registerAction:(NSDictionary *)action forEvent:(NSString *)event;
- (NSDictionary *)pb_actionForEvent:(NSString *)event;

- (void)pb_unbindActionMappers;

@end
