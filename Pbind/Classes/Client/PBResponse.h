//
//  PBResponse.h
//  Pbind
//
//  Created by galen on 15/2/12.
//  Copyright (c) 2015年 galen. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum : NSUInteger {
    PBResponseStatusOK = 200, // GET|POST done
    PBResponseStatusCreated = 201, // POST but has been created
    PBResponseStatusNoModified = 304, // GET but no modified
    PBResponseStatusNoContent = 204, // DELETE done
} PBResponseStatus;

@interface PBResponse : NSObject

@property (nonatomic, strong) id        data;
@property (nonatomic, strong) NSError  *error;
@property (nonatomic, strong) NSString *tips;
@property (nonatomic, assign) PBResponseStatus status;

@end
