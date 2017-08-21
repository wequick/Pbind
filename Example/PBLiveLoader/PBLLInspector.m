//
//  PBLLInspector.m
//  Pbind
//
//  Created by Galen Lin on 15/03/2017.
//

#import "PBLLInspector.h"

#if (DEBUG && !(TARGET_IPHONE_SIMULATOR))

#import "PBLLInspectorController.h"
#import <Pbind/Pbind.h>

@interface PBLLInspector () <UISearchBarDelegate>

@end

@implementation PBLLInspector

+ (instancetype)sharedInspector {
    static PBLLInspector *o;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        o = [PBLLInspector buttonWithType:UIButtonTypeCustom];
    });
    return o;
}

+ (void)addToWindow {
    PBLLInspector *inspector = [self sharedInspector];
    CGRect frame = [UIScreen mainScreen].bounds;
    frame.origin.x = frame.size.width - 68.f;
    frame.origin.y = frame.size.height - 100.f;
    frame.size.width = 60.f;
    frame.size.height = 44.f;
    inspector.frame = frame;
    inspector.backgroundColor = [UIColor greenColor];
    [inspector setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [inspector setTitle:@"Pbind" forState:UIControlStateNormal];
    [inspector addTarget:inspector action:@selector(didClick:) forControlEvents:UIControlEventTouchUpInside];
    [[[UIApplication sharedApplication].delegate window] addSubview:inspector];
}

- (void)didClick:(id)sender {
    PBLLInspectorController *controller = [[PBLLInspectorController alloc] init];
    [PBTopController().navigationController pushViewController:controller animated:YES];
}

@end

#endif
