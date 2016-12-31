//
//  PBNotificationAction.m
//  Pbind
//
//  Created by Galen Lin on 31/12/2016.
//
//

#import "PBNotificationAction.h"

@implementation PBNotificationAction

@pbaction(@"notify")
- (void)run:(PBActionState *)state {
    [[NSNotificationCenter defaultCenter] postNotificationName:self.name object:self.target userInfo:self.params];
}

@end
