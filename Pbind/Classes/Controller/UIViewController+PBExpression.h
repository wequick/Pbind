//
//  UIViewController+PBExpression.h
//  Pbind
//
//  Created by galen on 2018/3/9.
//

#import <UIKit/UIKit.h>

@class PBDictionary;

@interface UIViewController (PBExpression)

@property (nonatomic, strong) PBDictionary *pb_temporaries;

@end
