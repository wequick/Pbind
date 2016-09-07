//
//  LSExpression.h
//  Less
//
//  Created by galen on 15/2/26.
//  Copyright (c) 2015年 galen. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LSExpression : NSObject
{
    struct {
        // operators
        unsigned int plus:1;    // '+'
        unsigned int minus:1;   // '-'
        unsigned int times:1;   // '*'
        unsigned int divide:1;  // '/'
        
        unsigned int no:1;     // '!'
        unsigned int lesser:1;  // '<'
        unsigned int greater:1; // '>'
        unsigned int equal:1;   // '='
        
        unsigned int test:1;        // '?'
        unsigned int unaryTest:1;   // '?:'
        
        // accessories
        unsigned int animated:1;        // '~'
        unsigned int onewayBinding:1;   // '_'
        unsigned int duplexBinding:1;   // '__'
    } _flags;
    
    NSString *_format;
    NSString *_tag;         // '$', '@' etc, used to map to the data source
    int       _tagIndex;    // only for '$' tag, map to the specify element of the data source, [0-9]
    NSString *_variable;    // the key of the data source
    NSString *_rvalue;      // right value, accepts constants only
    NSString *_rvalueOfNot; // for `?:' expression, value after ':', accepts constants only
    
    NSInteger _offset;  // position in mutable expressions
    
    NSString *_bindingKeyPath;  // the owner's keyPath binding with `_variable'
    id _bindingOwner;
    id _bindingData;
}

+ (instancetype)expressionWithString:(NSString *)aString;

@property (nonatomic, strong) LSExpression *parent;

- (instancetype)initWithString:(NSString *)aString;

- (id)valueWithData:(id)data;
- (id)valueWithData:(id)data andOwner:(id)owner;
- (void)bindData:(id)data withOwner:(id)owner forKeyPath:(NSString *)ownerKeyPath;
- (void)mapData:(id)data toOwner:(id)owner forKeyPath:(NSString *)ownerKeyPath;

@end
