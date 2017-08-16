//
//  PBAlertAction.m
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by Galen Lin on 2016/12/15.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "PBAlertAction.h"
#import "UIView+Pbind.h"

@implementation PBAlertAction

@pbactions(@"alert", @"sheet")
- (void)run:(PBActionState *)state {
    UIViewController *controller = [state.context supercontroller];
    if (controller == nil) {
        return;
    }
    
    NSString *title = self.params[@"title"];
    NSString *message = self.params[@"message"];
    NSArray *buttons = self.params[@"buttons"];
    if (title == nil && message == nil && buttons == nil) {
        // UIAlertController must have a title, a message or an action to display
        return;
    }
    
    if (title != nil && ![title isKindOfClass:[NSString class]]) {
        title = [title description];
    }
    if (message != nil && ![message isKindOfClass:[NSString class]]) {
        message = [message description];
    }
    if (buttons == nil) {
        buttons = @[@"OK"];
    }
    
    UIAlertControllerStyle alertStyle = [self.type isEqualToString:@"sheet"] ? UIAlertControllerStyleActionSheet : UIAlertControllerStyleAlert;
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:alertStyle];
    
    for (NSInteger index = 0; index < buttons.count; index++) {
        NSString *buttonTitle = buttons[index];
        void (^ handler)(UIAlertAction *action) = nil;
        NSString *nextActionKey = [NSString stringWithFormat:@"%i", (int)index];
        if ([self hasNext:nextActionKey]) {
            handler = ^(UIAlertAction *action) {
                [self dispatchNext:nextActionKey];
            };
        }
        
        UIAlertActionStyle actionStyle = index == 0 ? UIAlertActionStyleCancel : UIAlertActionStyleDefault;
        UIAlertAction *alertAction = [UIAlertAction actionWithTitle:buttonTitle style:actionStyle handler:handler];
        [alert addAction:alertAction];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [controller presentViewController:alert animated:YES completion:nil];
    });
}

@end
