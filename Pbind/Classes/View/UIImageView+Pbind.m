//
//  UIImageView+Pbind.m
//  Pods
//
//  Created by Galen Lin on 16/9/13.
//
//

#import "UIImageView+Pbind.h"
#import "UIView+Pbind.h"

@implementation UIImageView (Pbind)

- (void)setImageName:(NSString *)imageName {
    UIImage *image = nil;
    // TODO: Add patch bundle
    NSArray *preferredBundles = @[[NSBundle bundleForClass:self.supercontroller.class],
                                 [NSBundle mainBundle]
                                 /* Patch bundle */];
    for (NSBundle *bundle in preferredBundles) {
        image = [UIImage imageNamed:imageName inBundle:bundle compatibleWithTraitCollection:nil];
        if (image != nil) {
            break;
        }
    }
    [self setImage:image];
}

@end
