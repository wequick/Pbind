//
//  PBExpressionTests.m
//  Pbind
//
//  Created by Galen Lin on 16/9/18.
//  Copyright © 2016年 galenlin. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <Pbind/Pbind.h>

@interface PBExpressionTests : XCTestCase

@end

@implementation PBExpressionTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)shouldParse:(NSString *)source toValue:(id)result withData:(id)data {
    return [self shouldParse:source toValue:result withData:data target:nil];
}

- (void)shouldParse:(NSString *)source toValue:(id)result withData:(id)data target:(id)target {
    PBExpression *exp = [PBMutableExpression expressionWithString:source];
    XCTAssert([source isEqualToString:[exp stringValue]]);
    
    id value = [exp valueWithData:data target:target];
    XCTAssert((result == nil && value == nil) || [result isEqual:value]);
}

- (void)testCanParseData {
    [self shouldParse:@"$hello"
              toValue:@"Pbind"
             withData:@{@"hello": @"Pbind"}];
}

- (void)testCanParseViewData {
    UIView *view = [[UIView alloc] init];
    view.data = @{@"hello": @"Pbind"};
    
    [self shouldParse:@".$hello"
              toValue:@"Pbind"
             withData:nil
              target:view];
}

- (void)testCanParseViewProperties {
    PBExpression *exp = [PBExpression expressionWithString:@".frame"];
    
    CGRect frame = CGRectMake(1, 2, 3, 4);
    UIView *view = [[UIView alloc] initWithFrame:frame];
    id value = [exp valueWithData:nil target:view];
    
    XCTAssert([[exp stringValue] isEqualToString:@".frame"]);
    XCTAssert(CGRectEqualToRect(frame, [value CGRectValue]));
}

- (void)testCanParseImplictDataElements {
    NSMutableArray *data = [NSMutableArray arrayWithCapacity:1];
    id data0 = @{@"repo_owner": @"wequick"};
    [data addObject:data0];
    
    PBExpression *explicitExp = [PBMutableExpression expressionWithString:@"$0.repo_owner"];
    PBExpression *implicitExp = [PBMutableExpression expressionWithString:@"$repo_owner"];
    id explicitValue = [explicitExp valueWithData:data];
    id implicitValue = [implicitExp valueWithData:data];
    XCTAssertEqual(explicitValue, implicitValue);
}

- (void)testCanParseDataElements {
    [self shouldParse:@"%(https://github.com/%@/%@),$0.repo_owner,$1.repo_name"
              toValue:@"https://github.com/wequick/Pbind"
             withData:@[@{@"repo_owner": @"wequick"}, @{@"repo_name": @"Pbind"}]];
}

- (void)testCanParseJSDictionary {
    id target = @{@"awesome": @1, @"repo": @"wequick/Pbind"};
    id data = @{@"repo": @"wequick/Pbind"};
    [self shouldParse:@"%JS({awesome:1, repo:$1}),$repo" toValue:target withData:data];
    [self shouldParse:@"%JS:dictionary({awesome:1, repo:$1}),$repo" toValue:target withData:data];
    [self shouldParse:@"%JS:dictionary(var t={awesome:1, repo:$1};t;),$repo" toValue:target withData:data];
}

- (void)testCanParseJSArray {
    id target = @[@"awesome", @"wequick/Pbind"];
    id data = @{@"repo": @"wequick/Pbind"};
    [self shouldParse:@"%JS(['awesome', $1]),$repo" toValue:target withData:data];
    [self shouldParse:@"%JS:array(['awesome', $1]),$repo" toValue:target withData:data];
    [self shouldParse:@"%JS:array(var t=['awesome', $1];t;),$repo" toValue:target withData:data];
}

- (void)testCanParseJSArrayWithDictionary {
    id target = @[@"awesome", @{@"repo": @"wequick/Pbind"}];
    id data = @{@"repo": @"wequick/Pbind"};
    [self shouldParse:@"%JS(['awesome', {repo: $1}]),$repo" toValue:target withData:data];
    [self shouldParse:@"%JS:array(['awesome', {repo: $1}]),$repo" toValue:target withData:data];
    [self shouldParse:@"%JS:array(var t=['awesome', {repo: $1}];t;),$repo" toValue:target withData:data];
}

- (void)testCanParseEmpty {
    [self shouldParse:@"%!(hello %@!),$greet" toValue:nil withData:nil];
    [self shouldParse:@"%!(hello %@!),$greet" toValue:@"hello Pbind!" withData:@{@"greet": @"Pbind"}];
}

- (void)testCanParseAttributedText {
    CGFloat fontSize = PBValue(14);
    NSDictionary *attr1 = @{NSFontAttributeName: [UIFont systemFontOfSize:fontSize]};
    NSDictionary *attr2 = @{NSForegroundColorAttributeName: [UIColor colorWithRed:1 green:1 blue:1 alpha:1]};
    NSDictionary *attr3 = @{NSFontAttributeName: [UIFont systemFontOfSize:fontSize],
                            NSForegroundColorAttributeName: [UIColor colorWithRed:1 green:1 blue:1 alpha:1]};
    NSString *text = @"Hello wequick Pbind";
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:text attributes:nil];
    [attributedString addAttributes:attr1 range:NSMakeRange(0, 6)];
    [attributedString addAttributes:attr2 range:NSMakeRange(6, 7)];
    [attributedString addAttributes:attr3 range:NSMakeRange(13, 6)];
    [self shouldParse:@"%AT(Hello |%@| %@),$owner,$repo;{F:14}|#FFFFFF|#FFFFFF-{F:14}"
              toValue:attributedString
             withData:@{@"owner": @"wequick", @"repo": @"Pbind"}];
}

@end
