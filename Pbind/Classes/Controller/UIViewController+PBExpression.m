//
//  UIViewController+PBExpression.m
//  Pbind
//
//  Created by galen on 2018/3/9.
//

#import "UIViewController+PBExpression.h"
#import "PBDictionary.h"
#import <objc/runtime.h>

@implementation UIViewController (PBExpression)

static NSString *kTemporaryKey;

- (void)setPb_temporaries:(PBDictionary *)pb_temporaries {
    objc_setAssociatedObject(self, &kTemporaryKey, pb_temporaries, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (PBDictionary *)pb_temporaries {
    PBDictionary *tempories = objc_getAssociatedObject(self, &kTemporaryKey);
    if (tempories == nil) {
        tempories = self.pb_temporaries = [[PBDictionary alloc] init];
    }
    return tempories;
}

@end
