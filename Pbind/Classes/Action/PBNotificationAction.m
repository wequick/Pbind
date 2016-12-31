//
//  PBNotificationAction.m
//  Pbind
//
//  Created by Galen Lin on 31/12/2016.
//
//

#import "PBNotificationAction.h"

@implementation PBNotificationAction

@pbactions(@"notify", @"watch")
- (void)run:(PBActionState *)state {
    if (self.name == nil) {
        return;
    }
    
    if ([self.type isEqualToString:@"notify"]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:self.name object:self.target userInfo:self.params];
    } else if ([self.type isEqualToString:@"watch"]) {
        if (![self haveNext:@"receive"]) {
            return;
        }
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceivedNotification:) name:self.name object:self.target];
    }
}

- (void)didReceivedNotification:(NSNotification *)notification {
    [self dispatchNext:@"receive"];
}

@end
