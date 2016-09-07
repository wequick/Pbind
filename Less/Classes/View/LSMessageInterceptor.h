//
//  LSMessageInterceptor.h
//  Less
//
//  Created by galen on 15/2/28.
//  Copyright (c) 2015年 galen. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LSMessageInterceptor : NSObject

@property (nonatomic, strong) id receiver;
@property (nonatomic, strong) id middleMan;

@end
