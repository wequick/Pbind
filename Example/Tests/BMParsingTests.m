//
//  BMParsingTests.m
//  Pbind
//
//  Created by Galen Lin on 22/01/2017.
//  Copyright © 2017 galenlin. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "BMXMLParser.h"

@interface BMParsingTests : XCTestCase

@end

@implementation BMParsingTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
}

- (void)testJSONToDictionaryPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
        NSDictionary *dict = [self dictionaryWithContentsOfJSONFile:@"level1"];
        NSLog(@"JSON: %@", dict);
    }];
}

- (void)testPlistToDictionaryPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
        NSDictionary *dict = [self dictionaryWithContentsOfPlistFile:@"level1"];
        NSLog(@"Plist: %@", dict);
    }];
}

- (void)testXMLToDictionaryPerformance {
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
        NSDictionary *dict = [BMXMLParser dictionaryWithContentsOfXMLFile:@"level1"];
        NSLog(@"XML: %@", dict);
    }];
}

- (NSDictionary *)dictionaryWithContentsOfPlistFile:(NSString *)file {
    NSString *path = [[NSBundle mainBundle] pathForResource:file ofType:@"plist"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        return nil;
    }
    
    return [NSDictionary dictionaryWithContentsOfFile:path];
}

- (NSDictionary *)dictionaryWithContentsOfJSONFile:(NSString *)file {
    NSString *path = [[NSBundle mainBundle] pathForResource:file ofType:@"json"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        return nil;
    }
    
    NSData *data = [[NSFileManager defaultManager] contentsAtPath:path];
    NSError *error;
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    if (dict == nil) {
        NSLog(@"Parse json failed, error %@", error);
    }
    return dict;
}

@end
