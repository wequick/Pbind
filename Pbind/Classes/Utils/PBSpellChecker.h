//
//  PBSpellChecker.h
//  Pods
//
//  Created by Galen Lin on 2016/10/28.
//
//

#import <Foundation/Foundation.h>

@interface PBSpellChecker : NSObject

+ (instancetype)defaultSpellChecker;

- (void)checkKeysLikeKey:(NSString *)key withValue:(id)value ofObject:(id)object;

@end
