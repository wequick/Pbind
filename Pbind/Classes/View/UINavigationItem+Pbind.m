//
//  UINavigationItem+Pbind.m
//  Pods
//
//  Created by Galen Lin on 2016/12/18.
//
//

#import "UINavigationItem+Pbind.h"
#import "PBAction.h"
#import "PBRowMapper.h"
#import "Pbind+API.h"
#import "PBValueParser.h"

@interface PBBarButtonItem : UIBarButtonItem

@property (nonatomic, strong) PBActionMapper *actionMapper;

@end

@implementation PBBarButtonItem

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    NSInteger type = [[PBValueParser valueWithString:dictionary[@"type"]] integerValue];
    do {
        if (type != 0) {
            self = [super initWithBarButtonSystemItem:type target:nil action:nil];
            break;
        }
        
        NSInteger style = [[PBValueParser valueWithString:dictionary[@"style"]] integerValue];
        NSString *imageName = dictionary[@"image"];
        UIImage *image = nil;
        if (imageName != nil) {
            image = PBImage(imageName);
        }
        if (image != nil) {
            self = [super initWithImage:image style:style target:nil action:nil];
            break;
        }
        
        NSDictionary *customViewInfo = dictionary[@"customView"];
        if (customViewInfo != nil) {
            PBRowMapper *mapper = [PBRowMapper mapperWithDictionary:customViewInfo owner:nil];
            UIView *customView = [mapper createView];
            self = [super initWithCustomView:customView];
            break;
        }
        
        NSString *title = dictionary[@"title"];
        self = [super initWithTitle:title style:style target:nil action:nil];
    } while (false);
    
    if (self == nil) {
        return nil;
    }
    
    NSDictionary *action = dictionary[@"action"];
    if (action != nil) {
        PBActionMapper *mapper = [PBActionMapper mapperWithDictionary:action owner:nil];
        [self setActionMapper:mapper];
        [self setTarget:self];
        [self setAction:@selector(pb_handleAction:)];
    } else {
        [self setActionMapper:nil];
    }
    return self;
}

- (void)pb_handleAction:(PBBarButtonItem *)item {
    // FIXME: Using the private API of `_view'
    UIView *context = [self valueForKey:@"view"];
    [PBAction dispatchActionWithActionMapper:self.actionMapper context:context];
}

@end

@implementation UINavigationItem (Pbind)

static const NSString *kActionMapperKey;

- (void)setRight:(NSDictionary *)right {
    if (right == nil || right.count == 0) {
        self.rightBarButtonItem = nil;
        return;
    }
    
    self.rightBarButtonItem = [[PBBarButtonItem alloc] initWithDictionary:right];
}

- (NSDictionary *)right {
    return nil;
}

- (void)setRights:(NSArray *)rights {
    if (rights == nil || rights.count == 0) {
        self.rightBarButtonItems = nil;
        return;
    }
    
    NSMutableArray *rightBarButtonItems = [NSMutableArray arrayWithCapacity:rights.count];
    for (NSDictionary *info in rights) {
        PBBarButtonItem *item = [[PBBarButtonItem alloc] initWithDictionary:info];
        [rightBarButtonItems addObject:item];
    }
    self.rightBarButtonItems = rightBarButtonItems;
}

- (void)setLeft:(NSDictionary *)left {
    if (left == nil || left.count == 0) {
        self.leftBarButtonItem = nil;
        return;
    }
    
    self.leftBarButtonItem = [[PBBarButtonItem alloc] initWithDictionary:left];
}

- (NSDictionary *)left {
    return nil;
}

- (void)setLefts:(NSArray *)lefts {
    if (lefts == nil || lefts.count == 0) {
        self.leftBarButtonItems = nil;
        return;
    }
    
    NSMutableArray *leftBarButtonItems = [NSMutableArray arrayWithCapacity:lefts.count];
    for (NSDictionary *info in lefts) {
        PBBarButtonItem *item = [[PBBarButtonItem alloc] initWithDictionary:info];
        [leftBarButtonItems addObject:item];
    }
    self.leftBarButtonItems = leftBarButtonItems;
}

@end
