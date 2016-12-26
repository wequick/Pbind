//
//  PBRowActionMapper.h
//  Pbind
//
//  Created by Galen Lin on 26/12/2016.
//
//

#import <UIKit/UIKit.h>
#import "PBActionMapper.h"

@interface PBRowActionMapper : PBActionMapper

@property (nonatomic, assign) UITableViewRowActionStyle style;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) UIColor *backgroundColor;

@end
