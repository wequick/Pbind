//
//  PBFormAction.m
//  Pbind
//
//  Created by Galen Lin on 2016/12/20.
//
//

#import "PBFormAction.h"
#import "UIView+Pbind.h"
#import "PBFormController.h"

@implementation PBFormAction

@pbaction(@"submit")
- (void)run:(PBActionState *)state {
    PBFormController *controller = [state.context supercontroller];
    if (![controller isKindOfClass:[PBFormController class]]) {
        return;
    }
    
    NSDictionary *params = [controller.form verifiedParamsForSubmit];
    if (params != nil && [self haveNext:@"done"]) {
        state.params = params;
        [self dispatchNext:@"done"];
    }
}

@end
