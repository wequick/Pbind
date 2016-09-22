//
//  UIImageView+PBExample.m
//  Pbind
//
//  Created by Galen Lin on 16/9/7.
//  Copyright © 2016年 galenlin. All rights reserved.
//

#import "UIImageView+PBExample.h"
#import "UIImageView+WebCache.h"
#import <Pbind/Pbind.h>

@implementation UIImageView (PBExample)

- (void)setAvatarUrl:(NSString *)url {
    __weak UIImageView *wSelf = self;
    [self sd_setImageWithURL:[NSURL URLWithString:url] placeholderImage:[UIImage imageNamed:@"icon_user_portrait"] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
        __strong UIImageView *sSelf = wSelf;
        if (cacheType == SDImageCacheTypeNone) {
            [UIView transitionWithView:sSelf duration:0.4f options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
                sSelf.image = image;
            } completion:NULL];
        }
    }];
}

@end
