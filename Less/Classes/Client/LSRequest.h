//
//  LSRequest.h
//  Less
//
//  Created by galen on 15/2/12.
//  Copyright (c) 2015年 galen. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LSRequest : NSObject

@property (nonatomic, strong) NSString *action; // Interface action.
@property (nonatomic, strong) NSString *method; // Interface action.
@property (nonatomic, strong) NSDictionary *params; // Major params.
@property (nonatomic, strong) NSDictionary *extParams; // Minor params.

@end
