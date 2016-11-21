//
//  PBMessageInterceptor.h
//  Pbind
//
//  Created by galen on 15/2/28.
//  Copyright (c) 2015年 galen. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PBMessageInterceptor : NSObject

@property (nonatomic, weak) id receiver;
@property (nonatomic, weak) id middleMan;

@end
