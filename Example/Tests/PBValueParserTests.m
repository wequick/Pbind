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
    XCTAssertTrue([[PBValueParser valueWithString:@"#FFF"] isEqual:[UIColor colorWithRed:1 green:1 blue:1 alpha:1]]);
    XCTAssertTrue([[PBValueParser valueWithString:@"#FF00FF"] isEqual:[UIColor colorWithRed:1 green:0 blue:1 alpha:1]]);
}

- (void)testCanParseCGColor {
    XCTAssertTrue([[PBValueParser valueWithString:@"##FF00FF"] isEqual:(id)[UIColor colorWithRed:1 green:0 blue:1 alpha:1].CGColor]);
}

- (void)testCanParseEnum {
    // Special constants
    XCTAssertEqual([[PBValueParser valueWithString:@":none"] intValue], 0);
    XCTAssertEqual([PBValueParser valueWithString:@":null"], [NSNull null]);
    XCTAssertEqual([PBValueParser valueWithString:@":nil"], nil);
    
    // NSTextAlignment
    XCTAssertEqual([[PBValueParser valueWithString:@":left"] intValue], NSTextAlignmentLeft);
    XCTAssertEqual([[PBValueParser valueWithString:@":right"] intValue], NSTextAlignmentRight);
    XCTAssertEqual([[PBValueParser valueWithString:@":center"] intValue], NSTextAlignmentCenter);
    // Cell accessory type
    XCTAssertEqual([[PBValueParser valueWithString:@":/"] intValue], UITableViewCellAccessoryCheckmark);
    XCTAssertEqual([[PBValueParser valueWithString:@":i"] intValue], UITableViewCellAccessoryDetailButton);
    XCTAssertEqual([[PBValueParser valueWithString:@":>"] intValue], UITableViewCellAccessoryDisclosureIndicator);
    // Cell style
    XCTAssertEqual([[PBValueParser valueWithString:@":value1"] intValue], UITableViewCellStyleValue1);
    XCTAssertEqual([[PBValueParser valueWithString:@":value2"] intValue], UITableViewCellStyleValue2);
    XCTAssertEqual([[PBValueParser valueWithString:@":subtitle"] intValue], UITableViewCellStyleSubtitle);
    // Cell height
    XCTAssertEqual([[PBValueParser valueWithString:@":auto"] intValue], UITableViewAutomaticDimension);
    // UIBarButtonItem
    XCTAssertEqual([[PBValueParser valueWithString:@":done"] intValue], UIBarButtonSystemItemDone);
    XCTAssertEqual([[PBValueParser valueWithString:@":cancel"] intValue], UIBarButtonSystemItemCancel);
    XCTAssertEqual([[PBValueParser valueWithString:@":edit"] intValue], UIBarButtonSystemItemEdit);
    XCTAssertEqual([[PBValueParser valueWithString:@":save"] intValue], UIBarButtonSystemItemSave);
    XCTAssertEqual([[PBValueParser valueWithString:@":add"] intValue], UIBarButtonSystemItemAdd);
    XCTAssertEqual([[PBValueParser valueWithString:@":compose"] intValue], UIBarButtonSystemItemCompose);
    XCTAssertEqual([[PBValueParser valueWithString:@":reply"] intValue], UIBarButtonSystemItemReply);
    XCTAssertEqual([[PBValueParser valueWithString:@":share"] intValue], UIBarButtonSystemItemAction);
    XCTAssertEqual([[PBValueParser valueWithString:@":organize"] intValue], UIBarButtonSystemItemOrganize);
    XCTAssertEqual([[PBValueParser valueWithString:@":bookmarks"] intValue], UIBarButtonSystemItemBookmarks);
    XCTAssertEqual([[PBValueParser valueWithString:@":search"] intValue], UIBarButtonSystemItemSearch);
    XCTAssertEqual([[PBValueParser valueWithString:@":refresh"] intValue], UIBarButtonSystemItemRefresh);
    XCTAssertEqual([[PBValueParser valueWithString:@":stop"] intValue], UIBarButtonSystemItemStop);
    XCTAssertEqual([[PBValueParser valueWithString:@":camera"] intValue], UIBarButtonSystemItemCamera);
    XCTAssertEqual([[PBValueParser valueWithString:@":trash"] intValue], UIBarButtonSystemItemTrash);
    XCTAssertEqual([[PBValueParser valueWithString:@":play"] intValue], UIBarButtonSystemItemPlay);
    XCTAssertEqual([[PBValueParser valueWithString:@":pause"] intValue], UIBarButtonSystemItemPause);
    XCTAssertEqual([[PBValueParser valueWithString:@":rewind"] intValue], UIBarButtonSystemItemRewind);
    XCTAssertEqual([[PBValueParser valueWithString:@":fastforward"] intValue], UIBarButtonSystemItemFastForward);
    XCTAssertEqual([[PBValueParser valueWithString:@":undo"] intValue], UIBarButtonSystemItemUndo);
    XCTAssertEqual([[PBValueParser valueWithString:@":redo"] intValue], UIBarButtonSystemItemRedo);
    XCTAssertEqual([[PBValueParser valueWithString:@":pagecurl"] intValue], UIBarButtonSystemItemPageCurl);
    // PBFormIndicating
    XCTAssertEqual([[PBValueParser valueWithString:@":focus"] intValue], PBFormIndicatingMaskInputFocus);
    XCTAssertEqual([[PBValueParser valueWithString:@":invalid"] intValue], PBFormIndicatingMaskInputInvalid);
}

- (void)testCanDefineEnum {
    [PBValueParser registerEnums:@{@"hello": @1}];
    XCTAssertEqual([[PBValueParser valueWithString:@":hello"] intValue], UITableViewCellStyleValue1);
}

- (void)testCanParseIndexPath {
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:1 inSection:2];
    NSIndexPath *value = [PBValueParser valueWithString:@"[2-1]"]; // section-row
    XCTAssertTrue([indexPath isEqual:value]);
}

- (void)testCanParseCGSize {
    CGSize size = PBSizeMake(1, 2);
    XCTAssertTrue(CGSizeEqualToSize([[PBValueParser valueWithString:@"{1,2}"] CGSizeValue], size));
}

- (void)testCanParseCGRect {
    CGRect rect = PBRectMake(1, 2, 3, 4);
    XCTAssertTrue(CGRectEqualToRect([[PBValueParser valueWithString:@"{1,2,3,4}"] CGRectValue], rect));
    XCTAssertTrue(CGRectEqualToRect([[PBValueParser valueWithString:@"{{1,2},{3,4}}"] CGRectValue], rect));
}

- (void)testCanParseUIEdgeInsets {
    UIEdgeInsets insets = PBEdgeInsetsMake(1, 2, 3, 4);
    XCTAssertTrue(UIEdgeInsetsEqualToEdgeInsets([[PBValueParser valueWithString:@"{1,2,3,4}"] UIEdgeInsetsValue], insets));
}

- (void)testCanParseFont {
    CGFloat fontSize = PBValue(14); // Helvetica
    XCTAssertTrue([[PBValueParser valueWithString:@"{F:14}"] isEqual:[UIFont systemFontOfSize:fontSize]]);
    XCTAssertTrue([[PBValueParser valueWithString:@"{F:italic,14}"] isEqual:[UIFont italicSystemFontOfSize:fontSize]]);
    XCTAssertTrue([[PBValueParser valueWithString:@"{F:bold,14}"] isEqual:[UIFont boldSystemFontOfSize:fontSize]]);
    XCTAssertTrue([[PBValueParser valueWithString:@"{F:Helvetica,14}"] isEqual:[UIFont fontWithName:@"Helvetica" size:fontSize]]);
    
    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
    attributes[UIFontDescriptorNameAttribute] = @"Helvetica";
    attributes[UIFontDescriptorTraitsAttribute] = @{UIFontSymbolicTrait: @(UIFontDescriptorTraitBold)};
    XCTAssertTrue([[PBValueParser valueWithString:@"{F:Helvetica,bold,14}"] isEqual:[UIFont fontWithDescriptor:[UIFontDescriptor fontDescriptorWithFontAttributes:attributes] size:fontSize]]);
    
    attributes[UIFontDescriptorTraitsAttribute] = @{UIFontSymbolicTrait: @(UIFontDescriptorTraitItalic)};
    XCTAssertTrue([[PBValueParser valueWithString:@"{F:Helvetica,italic,14}"] isEqual:[UIFont fontWithDescriptor:[UIFontDescriptor fontDescriptorWithFontAttributes:attributes] size:fontSize]]);
    
    attributes[UIFontDescriptorTraitsAttribute] = @{UIFontSymbolicTrait: @(UIFontDescriptorTraitBold|UIFontDescriptorTraitItalic)};
    XCTAssertTrue([[PBValueParser valueWithString:@"{F:Helvetica,bold|italic,14}"] isEqual:[UIFont fontWithDescriptor:[UIFontDescriptor fontDescriptorWithFontAttributes:attributes] size:fontSize]]);
}

@end
