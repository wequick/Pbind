//
//  LSExampleGroupMemberAvatarCell.m
//  Less
//
//  Created by Galen Lin on 16/8/29.
//  Copyright © 2016年 Galen Lin. All rights reserved.
//

#import "LSExampleGroupMemberAvatarCell.h"

@implementation LSExampleGroupMemberAvatarCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    
    UIImageView *imageView = (id) [self.contentView viewWithTag:1];
    imageView.clipsToBounds = YES;
    imageView.layer.cornerRadius = 13.f;
}

@end
