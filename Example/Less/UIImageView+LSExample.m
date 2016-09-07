//
//  UIImageView+LSExample.m
//  Less
//
//  Created by Galen Lin on 16/9/7.
//  Copyright © 2016年 galenlin. All rights reserved.
//

#import "UIImageView+LSExample.h"
#import "UIImageView+WebCache.h"

@implementation UIImageView (LSExample)

- (void)setAvatarUrl:(NSString *)url {
    [self sd_setImageWithURL:[NSURL URLWithString:url]];
}

@end
