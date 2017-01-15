//
//  PBNavigationAction.m
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by Galen Lin on 2016/12/15.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "PBNavigationAction.h"
#import "UIView+Pbind.h"
#import "PBMessageInterceptor.h"

@interface PBNavigationAction () <UINavigationControllerDelegate>
{
    NSTimer *_viewLoadedDetectionTimer;
}

@end

@implementation PBNavigationAction

static NSString *const DONE = @"done";
static NSString *const kUserInfoTargetControllerKey = @"target";
static NSString *const kUserInfoTargetLoadedValueKey = @"loaded";

@pbactions(@"push", @"pop", @"present", @"dismiss")
- (void)run:(PBActionState *)state {
    if (state.context == nil) {
        return;
    }
    
    UIViewController *controller = [state.context supercontroller];
    if (controller == nil) {
        return;
    }
    
    if ([self.type isEqualToString:@"push"]) {
        UIViewController *nextController = [self targetController];
        if (nextController == nil) {
            return;
        }
        [self initPropertiesForController:nextController];
        
        if ([self haveNext:DONE]) {
            // We need to dispatch next action after the target controller `viewDidLoad`,
            // sadly, the UINavigationControllerDelegate takes no effect while I try:
            //
            //      controller.navigationController.delegate = self;
            //
            // the callback `navigationController:didShowViewController:animated:` never be triggered.
            // What's more, the observing of UIViewController's `viewLoaded` property also failed.
            // Hereby, we have to start a timer to detect the `viewLoaded` property.
            //
            // FIXME: Detect `viewDidLoad`.
            NSDictionary *userInfo = @{kUserInfoTargetControllerKey: nextController};
            _viewLoadedDetectionTimer = [NSTimer timerWithTimeInterval:.5 target:self selector:@selector(viewLoadedDetectionTimerTick:) userInfo:userInfo repeats:YES];
            [[NSRunLoop currentRunLoop] addTimer:_viewLoadedDetectionTimer forMode:NSDefaultRunLoopMode];
            [_viewLoadedDetectionTimer fire];
        }
        [controller.navigationController pushViewController:nextController animated:YES];
    } else if ([self.type isEqualToString:@"pop"]) {
        if (controller.navigationController == nil) {
            return;
        }
        
        UIViewController *targetController = nil;
        if (self.target != nil) {
            NSArray *targetControllers = [controller.navigationController.viewControllers filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"class.description = %@", self.target]];
            if (targetControllers.count == 0) {
                NSLog(@"Pbind: Failed to pop to view controller %@.", self.target);
                return;
            }
            
            targetController = [targetControllers lastObject];
        } else {
            NSArray *controllers = controller.navigationController.viewControllers;
            if (controllers.count >= 2) {
                targetController = [controllers objectAtIndex:controllers.count - 2];
            }
        }
        
        if ([self haveNext:DONE]) {
            // FIXME: Detect `viewDidUnload`.
            NSDictionary *userInfo = @{kUserInfoTargetControllerKey: controller};
            _viewLoadedDetectionTimer = [NSTimer timerWithTimeInterval:.5 target:self selector:@selector(viewUnloadedDetectionTimerTick:) userInfo:userInfo repeats:YES];
            [[NSRunLoop currentRunLoop] addTimer:_viewLoadedDetectionTimer forMode:NSDefaultRunLoopMode];
            [_viewLoadedDetectionTimer fire];
        }
        
        id newContext = nil;
        if (targetController != nil) {
            [self initPropertiesForController:targetController];
            newContext = targetController.view;
            [controller.navigationController popToViewController:targetController animated:YES];
        } else {
            [controller.navigationController popViewControllerAnimated:YES];
        }
        
        // the current context would be deallocated while it's parent controller pop,
        // so replace it with an active one or set to nil.
        // FIXME: Be careful to use the context.
        state.context = newContext;
    } else if ([self.type isEqualToString:@"present"]) {
        UIViewController *nextController = [self targetController];
        if (nextController == nil) {
            return;
        }
        [self initPropertiesForController:nextController];
        
        [controller presentViewController:nextController animated:YES completion:^{
            [self dispatchNext:DONE];
        }];
    } else if ([self.type isEqualToString:@"dismiss"]) {
        UIViewController *presentingController = controller.presentingViewController;
        if (presentingController == nil) {
            return;
        }
        
        if ([presentingController isKindOfClass:[UINavigationController class]]) {
            presentingController = [[(id)presentingController viewControllers] lastObject];
        }
        [self initPropertiesForController:presentingController];
        
        [controller dismissViewControllerAnimated:YES completion:^{
            [self dispatchNext:DONE];
        }];
    }
}

- (void)viewLoadedDetectionTimerTick:(NSTimer *)sender {
    UIViewController *targetController = sender.userInfo[kUserInfoTargetControllerKey];
    if (targetController.viewLoaded) {
        [sender invalidate];
        _viewLoadedDetectionTimer = nil;
        [self dispatchNext:DONE];
    }
}

- (void)viewUnloadedDetectionTimerTick:(NSTimer *)sender {
    UIViewController *targetController = sender.userInfo[kUserInfoTargetControllerKey];
    if (targetController.navigationController == nil) {
        // We assert that while the navigationController was set to nil, the poping is finish.
        // FIXME: is this always works or we need to manually trigger this after a MAGIC time?
        [sender invalidate];
        _viewLoadedDetectionTimer = nil;
        [self dispatchNext:DONE];
    }
}

- (UIViewController *)targetController {
    if (self.target == nil) {
        return nil;
    }
    
    Class nextControllerClass = NSClassFromString(self.target);
    if (nextControllerClass == nil) {
        return nil;
    }
    
    return [[nextControllerClass alloc] init];
}

- (void)initPropertiesForController:(UIViewController *)controller {
    if (controller == nil || self.params == nil || self.params.count == 0) {
        return;
    }
    
    for (NSString *key in self.params) {
        id value = [self.params objectForKey:key];
        @try {
            [controller setValue:value forKey:key];
        } @catch (NSException *exception) {
            NSLog(@"Pbind: Failed to set value(%@) for key(%@) to controller(%@).", value, key, self.target);
        }
    }
}

@end
