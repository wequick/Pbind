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
    XCTAssert([result isEqual:[exp valueWithData:data target:target]]);
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

- (void)testCanParseDotToRootView {
    XCTAssert(TRUE);
}

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
