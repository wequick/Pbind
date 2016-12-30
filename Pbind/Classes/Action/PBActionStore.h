//
//  PBActionStore.h
//  Pbind
//
//  Created by Galen Lin on 2016/12/20.
//
//

#import <Foundation/Foundation.h>
#import "PBActionMapper.h"
#import "PBAction.h"

@interface PBActionStore : NSObject

+ (instancetype)defaultStore;

@property (nonatomic, strong) PBActionState *state;

- (void)dispatchAction:(PBAction *)action;

- (void)dispatchActionWithActionMapper:(PBActionMapper *)mapper;
- (void)dispatchActionWithActionMapper:(PBActionMapper *)mapper context:(UIView *)context;

@end
