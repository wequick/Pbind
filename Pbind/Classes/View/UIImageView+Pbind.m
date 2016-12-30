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
    [self setImage:PBImage(imageName)];
}

@end
