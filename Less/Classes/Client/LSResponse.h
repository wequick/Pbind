//
//  LSResponse.h
//  Less
//
//  Created by galen on 15/2/12.
//  Copyright (c) 2015年 galen. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface LSResponse : NSObject

@property (nonatomic, strong) id        data;
@property (nonatomic, strong) NSError  *error;

@end
