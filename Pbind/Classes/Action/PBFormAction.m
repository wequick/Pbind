//
//  PBFormAction.m
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by Galen Lin on 2016/12/20.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "PBFormAction.h"
#import "UIView+Pbind.h"
#import "PBFormController.h"

@implementation PBFormAction

@pbaction(@"submit")
- (void)run:(PBActionState *)state {
    PBFormController *controller = (id) [state.context supercontroller];
    if (![controller isKindOfClass:[PBFormController class]]) {
        return;
    }
    
    [controller.form verify:^(BOOL passed, NSDictionary *parameters) {
        if (passed) {
            state.params = parameters;
            [self dispatchNext:@"done"];
        }
    }];
}

@end
