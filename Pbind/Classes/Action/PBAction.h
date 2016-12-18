//
//  PBAction.h
//  Pbind
//
//  Created by Galen Lin on 2016/12/15.
//
//

#import <Foundation/Foundation.h>
#import "PBDictionary.h"
#import "PBActionState.h"
#import "PBActionMapper.h"

@class PBAction;

@protocol PBAction <NSObject>

- (BOOL)shouldRunAfterAction:(PBAction *)action;
- (void)run;

@end

@interface PBAction : NSObject<PBAction>

+ (void)registerType:(NSString *)type;
+ (void)registerTypes:(NSArray *)types;

+ (void)dispatchActionForView:(UIView *)view;
+ (void)dispatchActionWithActionMapper:(PBActionMapper *)mapper from:(PBAction *)lastAction;
+ (void)dispatchActionWithActionMapper:(PBActionMapper *)mapper context:(UIView *)context;

@property (nonatomic, strong) NSString *type;
@property (nonatomic, strong) id target;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSDictionary *params;
@property (nonatomic, strong) UIView *context;

@property (nonatomic, assign) BOOL disabled;

@property (nonatomic, strong) PBActionState *state;

@property (nonatomic, strong) PBAction *lastAction;
@property (nonatomic, strong) NSDictionary *nextMappers;

- (BOOL)haveNext:(NSString *)key;
- (void)dispatchNext:(NSString *)key;

@end

#define pbaction(__type__) \
synthesize type=_type; \
+ (void)load { \
    [self registerType:__type__]; \
}

#define pbactions(...) \
synthesize type=_type; \
+ (void)load { \
[self registerTypes:@[__VA_ARGS__]]; \
}
