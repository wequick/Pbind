//
//  PBExpression.h
//  Pbind
//
//  Created by galen on 15/2/26.
//  Copyright (c) 2015年 galen. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 This class is used to parse the expressions configure in Plist.
 
 @discussion Each expression is composed by `[unary op][tag][flag][key][multi op][right value]`.
 
 The [unary op] is optional, supports:
 
 * '!'      -> logic not
 * '-'      -> negative
 
 The [tag] is required, declares the binding data source, supports:
 
 * '$'      -> value for the key of the root view data
 * '$[0-9]' -> value for the key of the root view data's element at the index
 * '.'      -> value for the key of the owner view
 * '.$'     -> value for the key of the owner view data
 * '@'      -> value for the key of the owner view controller
 
 The [flag] is optional, supports:
 
 * '~'      -> animated while setting the value for a key of the view
 * '_'      -> oneway binding, notifys view to update while the data source value changed
 * '__'     -> duplex binding, notifys each other to update while the view or the data source value changed.
 
 The [multi op] is optional, supports:
 
 * '+', '-', '*', '/'                       -> arithmetic operators
 * '>', '<', '=', '==', '>=', '<=', '!='    -> logic operators
 * '?:', '? .. : .. '                       -> test operators
 
 The [right value] is optional, follows by [multi op] only, and only supports constant now.
 
 */
@interface PBExpression : NSObject
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
        
        // flags
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
    
    NSString *_bindingKeyPath;  // the owner's keyPath binding with `_variable'
    id _bindingOwner;
    id _bindingData;
}

+ (instancetype)expressionWithString:(NSString *)aString;

/**
 The parent expression, usually is an instance of PBMutableExpression.
 
 @discussion On binding mode, use to notify the parent expression re-calculated.
 
 Example: suppose current expression is `$name` and parent is `%(hello %@!),$name`, 
 if the `$name` changed to be 'someone', then the parent value should be 'hello someone!'.
 */
@property (nonatomic, strong) PBExpression *parent;

- (instancetype)initWithString:(NSString *)aString;

- (id)valueWithData:(id)data;
- (id)valueWithData:(id)data andOwner:(id)owner;
- (void)bindData:(id)data withOwner:(id)owner forKeyPath:(NSString *)ownerKeyPath;
- (void)mapData:(id)data toOwner:(id)owner forKeyPath:(NSString *)ownerKeyPath;

@end
