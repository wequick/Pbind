//
//  PBActionMapper.h
//  Pbind
//
//  Created by Galen Lin on 2016/12/15.
//
//

#import "PBMapper.h"
#import "PBDictionary.h"

@interface PBActionMapper : PBMapper

@property (nonatomic, strong) NSString *type;
@property (nonatomic, strong) NSString *target;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) PBDictionary *params;

@property (nonatomic, assign) BOOL disabled;

@property (nonatomic, strong) NSDictionary *next;
@property (nonatomic, strong) NSDictionary *nextMappers;

@end
