//
//  PBAlertAction.m
//  Pods
//
//  Created by Galen Lin on 2016/12/15.
//
//

#import "PBAlertAction.h"
#import "UIView+Pbind.h"

@implementation PBAlertAction

@pbactions(@"alert", @"sheet")
- (void)run {
    NSString *title = self.params[@"title"];
    NSString *message = self.params[@"message"];
    NSArray *buttons = self.params[@"buttons"];
    
    UIAlertControllerStyle alertStyle = [self.type isEqualToString:@"alert"] ? UIAlertControllerStyleAlert : UIAlertControllerStyleActionSheet;
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:alertStyle];
    
    for (NSInteger index = 0; index < buttons.count; index++) {
        NSString *buttonTitle = buttons[index];
        void (^ handler)(UIAlertAction *action) = nil;
        PBActionMapper *mapper = [self.nextMappers objectForKey:[NSString stringWithFormat:@"%i", (int)index]];
        if (mapper != nil) {
            handler = ^(UIAlertAction *action) {
                [PBAction dispatchActionWithActionMapper:mapper from:self];
            };
        }
        
        UIAlertActionStyle actionStyle = index == 0 ? UIAlertActionStyleCancel : UIAlertActionStyleDefault;
        UIAlertAction *alertAction = [UIAlertAction actionWithTitle:buttonTitle style:actionStyle handler:handler];
        [alert addAction:alertAction];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.context.supercontroller presentViewController:alert animated:YES completion:nil];
    });
    
}

@end
