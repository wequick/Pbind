//
//  PBValueParserTests.m
//  Pbind
//
//  Created by Galen Lin on 16/9/13.
//  Copyright © 2016年 galenlin. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <Pbind/Pbind.h>

@interface PBValueParserTests : XCTestCase

@end

@implementation PBValueParserTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testCanParseArray {
    id target = @[@"1", @"2"];
    XCTAssertTrue([[PBValueParser valueWithString:@"@[1,2]"] isEqual:target]);
}

- (void)testCanParseDictionary {
    id target = @{@"hello": @"wequick", @"world": @"Pbind"};
    XCTAssertTrue([[PBValueParser valueWithString:@"@{hello:wequick,world:Pbind}"] isEqual:target]);
}

- (void)testCanParseUIColor {
    XCTAssertTrue([[PBValueParser valueWithString:@"#FF00FF"] isEqual:[UIColor colorWithRed:1 green:0 blue:1 alpha:1]]);
}

- (void)testCanParseCGColor {
    XCTAssertTrue([[PBValueParser valueWithString:@"##FF00FF"] isEqual:(id)[UIColor colorWithRed:1 green:0 blue:1 alpha:1].CGColor]);
}

- (void)testCanParseEnum {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    XCTAssertEqual([[PBValueParser valueWithString:@":left"] intValue], NSTextAlignmentLeft);
    XCTAssertEqual([[PBValueParser valueWithString:@":right"] intValue], NSTextAlignmentRight);
    XCTAssertEqual([[PBValueParser valueWithString:@":center"] intValue], NSTextAlignmentCenter);
    // Cell accessory type
    XCTAssertEqual([[PBValueParser valueWithString:@":√"] intValue], UITableViewCellAccessoryCheckmark);
    XCTAssertEqual([[PBValueParser valueWithString:@":i"] intValue], UITableViewCellAccessoryDetailButton);
    XCTAssertEqual([[PBValueParser valueWithString:@":>"] intValue], UITableViewCellAccessoryDisclosureIndicator);
    // Cell style
    XCTAssertEqual([[PBValueParser valueWithString:@":value1"] intValue], UITableViewCellStyleValue1);
    XCTAssertEqual([[PBValueParser valueWithString:@":value2"] intValue], UITableViewCellStyleValue2);
    XCTAssertEqual([[PBValueParser valueWithString:@":subtitle"] intValue], UITableViewCellStyleSubtitle);
}

- (void)testCanDefineEnum {
    [PBValueParser registerEnums:@{@"hello": @1}];
    XCTAssertEqual([[PBValueParser valueWithString:@":hello"] intValue], UITableViewCellStyleValue1);
}

- (void)testCanParseCGSize {
    CGSize size = CGSizeMake(1, 2);
    CGFloat scale = [Pbind valueScale];
    size.width *= scale;
    size.height *= scale;
    XCTAssertTrue(CGSizeEqualToSize([[PBValueParser valueWithString:@"{1,2}"] CGSizeValue], size));
}

- (void)testCanParseCGRect {
    CGRect rect = CGRectMake(1, 2, 3, 4);
    CGFloat scale = [Pbind valueScale];
    rect.origin.x *= scale;
    rect.origin.y *= scale;
    rect.size.width *= scale;
    rect.size.height *= scale;
    XCTAssertTrue(CGRectEqualToRect([[PBValueParser valueWithString:@"{1,2,3,4}"] CGRectValue], rect));
    XCTAssertTrue(CGRectEqualToRect([[PBValueParser valueWithString:@"{{1,2},{3,4}}"] CGRectValue], rect));
}

- (void)testCanParseUIEdgeInsets {
    UIEdgeInsets insets = UIEdgeInsetsMake(1, 2, 3, 4);
    CGFloat scale = [Pbind valueScale];
    insets.top *= scale;
    insets.left *= scale;
    insets.bottom *= scale;
    insets.right *= scale;
    XCTAssertTrue(UIEdgeInsetsEqualToEdgeInsets([[PBValueParser valueWithString:@"{1,2,3,4}"] UIEdgeInsetsValue], insets));
}

- (void)testCanParseFont {
    XCTAssertTrue([[PBValueParser valueWithString:@"{F:14}"] isEqual:[UIFont systemFontOfSize:[Pbind valueScale] * 14]]);
    XCTAssertTrue([[PBValueParser valueWithString:@"{F:italic,14}"] isEqual:[UIFont italicSystemFontOfSize:[Pbind valueScale] * 14]]);
    XCTAssertTrue([[PBValueParser valueWithString:@"{F:bold,14}"] isEqual:[UIFont boldSystemFontOfSize:[Pbind valueScale] * 14]]);
}

@end
