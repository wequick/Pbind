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
    [self shouldParse:source toValue:result withData:data target:target context:nil];
}

- (void)shouldParse:(NSString *)source toValue:(id)result withData:(id)data target:(id)target context:(UIView *)context {
    PBExpression *exp = [PBMutableExpression expressionWithString:source];
    XCTAssert([source isEqualToString:[exp stringValue]]);
    
    id value = [exp valueWithData:data target:target context:context];
    XCTAssert((result == nil && value == nil) || [result isEqual:value]);
}

- (void)testCanParseData {
    [self shouldParse:@"$hello"
              toValue:@"Pbind"
             withData:@{@"hello": @"Pbind"}];
}

- (void)testCanParseContextData {
    UIView *context = [[UIView alloc] init];
    context.data = @{@"hello": @"Pbind"};
    
    [self shouldParse:@".$hello"
              toValue:@"Pbind"
             withData:nil
              target:nil
              context:context];
}

- (void)testCanParseContextProperties {
    PBExpression *exp = [PBExpression expressionWithString:@".frame"];
    
    CGRect frame = CGRectMake(1, 2, 3, 4);
    UIView *context = [[UIView alloc] initWithFrame:frame];
    id value = [exp valueWithData:nil target:nil context:context];
    
    XCTAssert([[exp stringValue] isEqualToString:@".frame"]);
    XCTAssert(CGRectEqualToRect(frame, [value CGRectValue]));
}

- (void)testCanParseImplictDataElements {
    PBArray *data = [[PBArray alloc] init];
    id data0 = @{@"repo_owner": @"wequick"};
    [data addObject:data0];
    
    PBExpression *explicitExp = [PBMutableExpression expressionWithString:@"$0.repo_owner"];
    PBExpression *implicitExp = [PBMutableExpression expressionWithString:@"$repo_owner"];
    id explicitValue = [explicitExp valueWithData:data];
    id implicitValue = [implicitExp valueWithData:data];
    XCTAssertEqual(explicitValue, implicitValue);
}

- (void)testCanParseDataElements {
    PBArray *data = [[PBArray alloc] init];
    [data addObject:@{@"repo_owner": @"wequick"}];
    [data addObject:@{@"repo_name": @"Pbind"}];
    [self shouldParse:@"%(https://github.com/%@/%@),$0.repo_owner,$1.repo_name"
              toValue:@"https://github.com/wequick/Pbind"
             withData:data];
}

#pragma mark -

#pragma mark - Arithmetic operators

- (void)testCanParseArithmeticOpertors {
    NSArray *list = @[@1, @2];
    [self shouldParse:@"$count+1" toValue:@(3) withData:list];
    [self shouldParse:@"$count-1" toValue:@(1) withData:list];
    [self shouldParse:@"$count*2" toValue:@(4) withData:list];
    [self shouldParse:@"$count/2" toValue:@(1) withData:list];
}

#pragma mark - Test operator

- (void)testCanParseTestOperator {
    NSArray *list = @[@1, @2];
    [self shouldParse:@"$count?A:B" toValue:@"A" withData:list];
    [self shouldParse:@"$count?:10" toValue:@(2) withData:list];
    list = @[];
    [self shouldParse:@"$count?A:B" toValue:@"B" withData:list];
    [self shouldParse:@"$count?:10" toValue:@(10) withData:list];
}

#pragma mark - Comparision operators

- (void)testCanParseComparisionOperators {
    NSArray *list = @[@1, @2];
    [self shouldParse:@"$count=2" toValue:@(YES) withData:list];
    [self shouldParse:@"$count==2" toValue:@(YES) withData:list];
    [self shouldParse:@"$count!=2" toValue:@(NO) withData:list];
    [self shouldParse:@"$count>=2" toValue:@(YES) withData:list];
    [self shouldParse:@"$count<=2" toValue:@(YES) withData:list];
    
    [self shouldParse:@"$count>1" toValue:@(YES) withData:list];
    [self shouldParse:@"$count<3" toValue:@(YES) withData:list];
    [self shouldParse:@"$count>2" toValue:@(NO) withData:list];
    [self shouldParse:@"$count<2" toValue:@(NO) withData:list];
}

- (void)testCanParseLogicOperators {
    id data = nil;
    [self shouldParse:@"!$" toValue:@(YES) withData:data];
    [self shouldParse:@"!!$" toValue:@(NO) withData:data];
}

#pragma mark -

#pragma mark - Javascript tag: '%JS'

- (void)testCanParseJSDictionary {
    id target = @{@"awesome": @1, @"repo": @"wequick/Pbind"};
    id data = @{@"repo": @"wequick/Pbind"};
    [self shouldParse:@"`{awesome:1, repo:$1}`,$repo" toValue:target withData:data];
    [self shouldParse:@"%JS({awesome:1, repo:$1}),$repo" toValue:target withData:data];
    [self shouldParse:@"%JS:dictionary({awesome:1, repo:$1}),$repo" toValue:target withData:data];
    [self shouldParse:@"%JS:dictionary(var t={awesome:1, repo:$1};t;),$repo" toValue:target withData:data];
}

- (void)testCanParseJSArray {
    id target = @[@"awesome", @"wequick/Pbind"];
    id data = @{@"repo": @"wequick/Pbind"};
    [self shouldParse:@"`['awesome', $1]`,$repo" toValue:target withData:data];
    [self shouldParse:@"%JS(['awesome', $1]),$repo" toValue:target withData:data];
    [self shouldParse:@"%JS:array(['awesome', $1]),$repo" toValue:target withData:data];
    [self shouldParse:@"%JS:array(var t=['awesome', $1];t;),$repo" toValue:target withData:data];
}

- (void)testCanParseJSArrayWithDictionary {
    id target = @[@"awesome", @{@"repo": @"wequick/Pbind"}];
    id data = @{@"repo": @"wequick/Pbind"};
    [self shouldParse:@"`['awesome', {repo: $1}]`,$repo" toValue:target withData:data];
    [self shouldParse:@"%JS(['awesome', {repo: $1}]),$repo" toValue:target withData:data];
    [self shouldParse:@"%JS:array(['awesome', {repo: $1}]),$repo" toValue:target withData:data];
    [self shouldParse:@"%JS:array(var t=['awesome', {repo: $1}];t;),$repo" toValue:target withData:data];
}

- (void)testCanParseJSRange {
    id target = [NSValue valueWithRange:NSMakeRange(1, 2)];
    id data = @{@"w": @(1), @"h": @(2)};
    [self shouldParse:@"%JS:range({location:$1, length:$2}),$w,$h" toValue:target withData:data];
}

- (void)testCanParseJSPoint {
    id target = [NSValue valueWithCGPoint:CGPointMake(1, 2)];
    id data = @{@"w": @(1), @"h": @(2)};
    [self shouldParse:@"%JS:point({x:$1, y:$2}),$w,$h" toValue:target withData:data];
}

- (void)testCanParseJSRect {
    id target = [NSValue valueWithCGRect:CGRectMake(1, 2, 3, 4)];
    id data = @{@"x": @(1), @"y": @(2), @"w": @(3), @"h": @(4)};
    [self shouldParse:@"%JS:rect({x:$1, y:$2, width:$3, height:$4}),$x,$y,$w,$h" toValue:target withData:data];
}

- (void)testCanParseJSSize {
    id target = [NSValue valueWithCGSize:CGSizeMake(1, 2)];
    id data = @{@"w": @(1), @"h": @(2)};
    [self shouldParse:@"%JS:size({width:$1, height:$2}),$w,$h" toValue:target withData:data];
}

- (void)testCanParseJSDate {
    long interval = 1477979504;
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:interval];
    id data = @{@"interval": @(interval * 1000)};
    [self shouldParse:@"%JS(new Date($1)),$interval" toValue:date withData:data];
}

#pragma mark - Test tag: '%!'

- (void)testCanParseEmpty {
    [self shouldParse:@"%!(hello %@!),$greet" toValue:nil withData:nil];
    [self shouldParse:@"%!(hello %@!),$greet" toValue:@"hello Pbind!" withData:@{@"greet": @"Pbind"}];
}

#pragma mrk - String format

- (void)testCanFormatString {
    id data = @{@"num": @(2.3f)};
    [self shouldParse:@"@\"num is %@\",$num" toValue:@"num is 2.3" withData:data];
    [self shouldParse:@"%(num is %@),$num" toValue:@"num is 2.3" withData:data];
    [self shouldParse:@"@\"num is %#.2f\",$num" toValue:@"num is 2.30" withData:data];
    [self shouldParse:@"%(num is %#.2f),$num" toValue:@"num is 2.30" withData:data];
}

#pragma mark - Attributed string tag: '%AT'

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
