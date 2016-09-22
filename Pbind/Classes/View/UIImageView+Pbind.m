//
//  UIImageView+Pbind.m
//  Pods
//
//  Created by Galen Lin on 16/9/13.
//
//

#import "UIImageView+Pbind.h"
#import "UIView+Pbind.h"
#import "Pbind+API.h"

@implementation UIImageView (Pbind)

- (void)setImageName:(NSString *)imageName {
    UIImage *image = nil;
    NSArray *preferredBundles = [Pbind allResourcesBundles];
    for (NSBundle *bundle in preferredBundles) {
        image = [UIImage imageNamed:imageName inBundle:bundle compatibleWithTraitCollection:nil];
        if (image != nil) {
            break;
        }
    }
    [self setImage:image];
}

@end
