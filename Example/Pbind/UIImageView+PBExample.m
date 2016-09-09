//
//  UIImageView+PBExample.m
//  Pbind
//
//  Created by Galen Lin on 16/9/7.
//  Copyright © 2016年 galenlin. All rights reserved.
//

#import "UIImageView+PBExample.h"
#import "UIImageView+WebCache.h"

@implementation UIImageView (PBExample)

- (void)setAvatarUrl:(NSString *)url {
    [self sd_setImageWithURL:[NSURL URLWithString:url]];
}

@end
