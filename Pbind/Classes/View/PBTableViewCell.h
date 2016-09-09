//
//  PBTableViewCell.h
//  Pbind
//
//  Created by Galen Lin on 16/9/5.
//  Copyright © 2016年 galen. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PBTableViewCell : UITableViewCell

@property (nonatomic, assign) CGSize imageSize; // Size of cell.imageView
@property (nonatomic, assign) UIEdgeInsets imageMargin; // Outside margins of cell.imageView

@end
