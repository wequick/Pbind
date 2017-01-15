//
//  PBTableViewCell.m
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by Galen Lin on 16/9/5.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "PBTableViewCell.h"
#import "PBRowMapper.h"

@interface PBTableViewCell ()
{
    PBRowMapper *_accessoryMapper;
}

@end

@implementation PBTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (style == UITableViewCellStyleDefault) {
        // If has register a class for table view by [tableView registerClass:class reuseIdentifier:id],
        // then the [table dequeueReusableCellWithIdentifier:id] will alaways call current selector with
        // a UITableViewCellStyleDefautl style, so we should resolve the real cell style by reuseIdentifier.
        if (reuseIdentifier != nil) {
            int preferedStyle = [reuseIdentifier characterAtIndex:reuseIdentifier.length - 1] - '0';
            if (preferedStyle >= UITableViewCellStyleDefault && preferedStyle <= UITableViewCellStyleSubtitle) {
                style = preferedStyle;
            }
        }
    }
    return [super initWithStyle:style reuseIdentifier:reuseIdentifier];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if (!CGSizeEqualToSize(self.imageSize, CGSizeZero)) {
        // Image view
        UIEdgeInsets margin = self.imageMargin;
        CGRect frame = CGRectMake(margin.left, margin.top, self.imageSize.width, self.imageSize.height);
        self.imageView.frame = frame;
        
        // Text labels
        CGFloat textLeft = margin.left + self.imageSize.width + margin.right;
        frame = self.textLabel.frame;
        frame.origin.x = textLeft;
        self.textLabel.frame = frame;
        
        frame = self.detailTextLabel.frame;
        frame.origin.x = textLeft;
        self.detailTextLabel.frame = frame;
        
        // Separator
        UIEdgeInsets insets = self.separatorInset;
        if (insets.left > textLeft) {
            insets.left = textLeft;
            self.separatorInset = insets;
        }
    }
}

- (void)setAccessoryView:(UIView *)accessoryView {
    if ([accessoryView isKindOfClass:[NSDictionary class]]) {
        PBRowMapper *mapper = [PBRowMapper mapperWithDictionary:(id) accessoryView owner:self];
        _accessoryMapper = mapper;
        UIView *view = [[mapper.viewClass alloc] init];
        [mapper initDataForView:view];
        [super setAccessoryView:view];
    } else {
        [super setAccessoryView:accessoryView];
    }
}

@end
