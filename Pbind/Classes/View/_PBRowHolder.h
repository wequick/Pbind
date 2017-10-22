//
//  _PBRowHolder.h
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by galen on 2017/8/27.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import <Foundation/Foundation.h>
#import "PBExpression.h"

@interface _PBPropertyPath : NSObject

@property (nonatomic, assign) unsigned char targetIndex;
@property (nonatomic, assign) unsigned char keyIndex;
@property (nonatomic, strong) id value;
@property (nonatomic, strong) PBExpression *expression;

@end

@interface _PBMetaProperty : NSObject

- (instancetype)initWithTarget:(id)target key:(NSString *)key;

- (id)valueOfTarget:(id)target;
- (void)setValue:(id)value toTarget:(id)target;

@property (nonatomic, strong) NSString *key;

@end

@interface _PBTargetHolder : NSObject

@property (nonatomic, strong) id target;
@property (nonatomic, strong) NSString *keyPath;
@property (nonatomic, strong) NSString *parentAlias;
@property (nonatomic, strong) NSString *parentOutletKey;
@property (nonatomic, strong) NSMutableArray<_PBMetaProperty *> *properties;

- (instancetype)copyWithOwner:(id)owner;

@end

@interface _PBViewHolder : NSObject

@property (nonatomic, strong) NSArray<_PBTargetHolder *> *targets;

- (void)updateProperty:(_PBPropertyPath *)property;
- (void)updateProperties:(NSArray *)properties withBaseProperties:(NSArray *)baseProperties;
- (void)mapProperty:(_PBPropertyPath *)property withData:(id)data owner:(id)owner context:(UIView *)context;

@end

@interface _PBRowHolder : _PBViewHolder

@property (nonatomic, strong) NSArray *initialProperties;

@property (nonatomic, strong) NSArray *constantPaths;
@property (nonatomic, strong) NSArray *variablePaths;

@end

@interface _PBRowCompiledInfo : NSObject

@property (nonatomic, strong) NSString *identifier;
@property (nonatomic, strong) NSArray *constantPaths;
@property (nonatomic, strong) NSArray *variablePaths;

@end

@interface UIView (PBViewHolder)

@property (nonatomic, strong) _PBViewHolder *pb_viewHolder;

@end

