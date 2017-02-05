//
//  BMXMLParser.h
//  Pbind
//
//  Created by Galen Lin on 22/01/2017.
//  Copyright © 2017 galenlin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BMXMLParser : NSXMLParser

+ (NSDictionary *)dictionaryWithContentsOfXMLFile:(NSString *)xmlFile;

@end
