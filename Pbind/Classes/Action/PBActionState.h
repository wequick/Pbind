//
//  PBActionState.h
//  Pods
//
//  Created by Galen Lin on 2016/12/15.
//
//

#import <Foundation/Foundation.h>

@interface PBActionState : NSObject

@property (nonatomic, assign) BOOL passed;
@property (nonatomic, strong) id data;
@property (nonatomic, strong) NSError *error;

@end
