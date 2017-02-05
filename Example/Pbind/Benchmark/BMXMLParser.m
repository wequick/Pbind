//
//  BMXMLParser.m
//  Pbind
//
//  Created by Galen Lin on 22/01/2017.
//  Copyright © 2017 galenlin. All rights reserved.
//

#import "BMXMLParser.h"

@interface BMXMLParser () <NSXMLParserDelegate>
{
    NSMutableDictionary *_dict;
    BOOL _done;
}

@end

@implementation BMXMLParser

+ (NSDictionary *)dictionaryWithContentsOfXMLFile:(NSString *)xmlFile {
    NSString *path = [[NSBundle mainBundle] pathForResource:xmlFile ofType:@"xml"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        return nil;
    }
    
    NSData *data = [[NSData alloc] initWithContentsOfFile:path];
    BMXMLParser *parser = [[self alloc] initWithData:data];
    parser.delegate = parser;
    
    parser->_done = NO;
    
    if (![parser parse]) {
        NSLog(@"error %@", parser.parserError);
        return nil;
    }
    
    return parser->_dict;
}

#pragma mark - Delegate

- (void)parserDidStartDocument:(NSXMLParser *)parser {
    _dict = [[NSMutableDictionary alloc] init];
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary<NSString *,NSString *> *)attributeDict {
    [_dict addEntriesFromDictionary:attributeDict];
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
    if ([elementName isEqualToString:@"dict"]) {
        _done = YES;
    }
}

@end
