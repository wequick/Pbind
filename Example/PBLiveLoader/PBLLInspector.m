//
//  PBLLInspector.m
//  Pbind
//
//  Created by Galen Lin on 15/03/2017.
//

#import "PBLLInspector.h"

#if (PBLIVE_ENABLED)

#import "PBLLInspectorController.h"
#import "PBLLInspectorTipsController.h"
#import "PBLLResource.h"
#import <Pbind/Pbind.h>

@interface PBLLTipsTapper : UITapGestureRecognizer

@property (nonatomic, strong) NSString *tips;

@property (nonatomic, weak) UIView *owner;

@property (nonatomic, copy) NSString *keyPath;

@property (nonatomic, assign) BOOL ownerUserInteractionEnabled;

@end

@implementation PBLLTipsTapper

- (NSString *)tips {
    if (_tips != nil) {
        return _tips;
    }
    
    NSMutableString *s = [NSMutableString string];
    [s appendString:[_owner valueForAdditionKey:[NSString stringWithFormat:@"~%@", _keyPath]]];
    if ([_owner isKindOfClass:[UIImageView class]]) {
        UIImage *image = [(UIImageView *)_owner image];
        [s appendFormat:@"\nsize: %.1f x %.1f @%.1fx", image.size.width, image.size.height, image.scale];
    }
    return s;
}

@end

@interface PBLLInspector () <UIPopoverPresentationControllerDelegate>
{
    NSString *_identifier;
}

@end

@implementation PBLLInspector

#define kPbindPrimaryColor PBColorMake(@"5D74E9")

static const CGFloat kWidth = 44.f;
static const CGFloat kHeight = 44.f;

static BOOL kDisplaysExpression = NO;

+ (void)load {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pbactionWillDispatch:) name:PBActionStoreWillDispatchActionNotification object:nil];
    [Pbind registerViewValueSetter:^id(UIView *view, NSString *keyPath, id value, BOOL *canceld, UIView *contextView, NSString *contextKeyPath) {
        [self showInspectorToViewIfNeeded:contextView];
        
        if (!kDisplaysExpression) {
            return value;
        }
        
        PBExpression *exp = [[contextView pb_expressions] objectForKey:contextKeyPath];
        if (exp == nil) {
            return value;
        }
        
        if ([keyPath isEqualToString:@"text"]) {
            return [exp stringValue];
        }
        
        return value;
    }];
    
    [Pbind registerViewValueAsyncSetter:^(UIView *view, NSString *keyPath, id value, CGSize viewSize, UIView *contextView, NSString *contextKeyPath) {
        PBExpression *exp = [[contextView pb_expressions] objectForKey:contextKeyPath];
        if (exp == nil) {
            return;
        }
        
        if ([view isKindOfClass:[UIImageView class]] && [keyPath isEqualToString:@"image"]) {
            CALayer *imageBgInspectorLayer = [view valueForAdditionKey:@"pb_bg_inspector"];
            CATextLayer *textInspectorLayer = [view valueForAdditionKey:@"pb_text_inspector"];
            PBLLTipsTapper *tapper = [view valueForAdditionKey:@"pb_tap_inspector"];
            if (kDisplaysExpression) {
                CGRect bounds = (CGRect){.origin = CGPointZero, .size = viewSize};
                if (imageBgInspectorLayer == nil) {
                    imageBgInspectorLayer = [[CALayer alloc] init];
                    imageBgInspectorLayer.backgroundColor = [kPbindPrimaryColor colorWithAlphaComponent:.5f].CGColor;
                    imageBgInspectorLayer.bounds = bounds;
                    imageBgInspectorLayer.position = CGPointZero;
                    imageBgInspectorLayer.anchorPoint = CGPointZero;
                    [view.layer addSublayer:imageBgInspectorLayer];
                    [view setValue:imageBgInspectorLayer forAdditionKey:@"pb_bg_inspector"];
                }
                
                if (textInspectorLayer == nil) {
                    textInspectorLayer = [[CATextLayer alloc] init];
                    textInspectorLayer.bounds = CGRectMake(0, 0, viewSize.width, 36);
                    textInspectorLayer.position = CGPointMake(0, viewSize.height / 2);
                    textInspectorLayer.anchorPoint = CGPointMake(0, 0.5);
                    textInspectorLayer.foregroundColor = [UIColor whiteColor].CGColor;
                    textInspectorLayer.alignmentMode = kCAAlignmentCenter;
                    textInspectorLayer.contentsScale = [UIScreen mainScreen].scale;
                    textInspectorLayer.fontSize = 14.f;
                    [view.layer addSublayer:textInspectorLayer];
                    [view setValue:textInspectorLayer forAdditionKey:@"pb_text_inspector"];
                }
                textInspectorLayer.string = [NSString stringWithFormat:@"%@\n%.1f x %.1f", exp.stringValue, viewSize.width, viewSize.height];
                
                if (tapper == nil) {
                    tapper = [[PBLLTipsTapper alloc] initWithTarget:self action:@selector(handleShowTips:)];
                    tapper.owner = view;
                    tapper.keyPath = keyPath;
                    [view addGestureRecognizer:tapper];
                    [view setValue:tapper forAdditionKey:@"pb_tap_inspector"];
                    
                    tapper.ownerUserInteractionEnabled = view.userInteractionEnabled;
                    view.userInteractionEnabled = YES;
                }
            } else {
                if (imageBgInspectorLayer != nil) {
                    [imageBgInspectorLayer removeFromSuperlayer];
                    [view setValue:nil forAdditionKey:@"pb_bg_inspector"];
                }
                if (textInspectorLayer != nil) {
                    [textInspectorLayer removeFromSuperlayer];
                    [view setValue:nil forAdditionKey:@"pb_text_inspector"];
                }
                if (tapper != nil) {
                    view.userInteractionEnabled = tapper.ownerUserInteractionEnabled;
                    [view removeGestureRecognizer:tapper];
                    [view setValue:nil forAdditionKey:@"pb_tap_inspector"];
                }
            }
        }
        
        return;
    }];
}

+ (instancetype)sharedInspector {
    static PBLLInspector *inspector;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        inspector = [[PBLLInspector alloc] initWithFrame:CGRectMake(0, 0, kWidth, kHeight)];
    });
    return inspector;
}

+ (void)addToController:(UIViewController *)controller withIdentifier:(NSString *)identifier {
    if (controller == nil) return;
    
    PBLLInspector *inspector = [self sharedInspector];
    if ([inspector.superview isEqual:controller.view]) {
        return;
    }
    
    [inspector removeFromSuperview];
    [controller.view addSubview:inspector];
    
    CGPoint center = CGPointZero;
    CGFloat x = [[NSUserDefaults standardUserDefaults] floatForKey:[NSString stringWithFormat:@"pbind.inspector.x@%@", identifier]];
    CGFloat y = [[NSUserDefaults standardUserDefaults] floatForKey:[NSString stringWithFormat:@"pbind.inspector.y@%@", identifier]];
    CGFloat minX = kWidth / 2;
    CGFloat minY = kHeight / 2;
    CGFloat maxX = controller.view.frame.size.width - minX;
    CGFloat maxY = controller.view.frame.size.height - minY;
    if (x >= minX && x <= maxX) {
        center.x = x;
    } else {
        center.x = maxX - 6.f;
    }
    if (y >= minY && y <= maxY) {
        center.y = y;
    } else {
        center.y = maxY - 70.f;
    }
    inspector.center = center;
    inspector->_identifier = identifier;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor lightGrayColor];
        self.layer.cornerRadius = 5.f;
        self.layer.zPosition = 999;
        [self setImage:[PBLLResource logoImage] forState:UIControlStateNormal];
//        [self setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
//        [self setTitle:@"Pbind" forState:UIControlStateNormal];
        [self addTarget:self action:@selector(handleClick:) forControlEvents:UIControlEventTouchUpInside];
        
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        [self addGestureRecognizer:pan];
        
#if !(TARGET_IPHONE_SIMULATOR)
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
        [self addGestureRecognizer:longPress];
#endif
    }
    return self;
}

#pragma mark - Display

+ (void)showInspectorToViewIfNeeded:(UIView *)view {
    NSString *plist = view.plist;
    if (plist == nil) {
        return;
    }
    
    UIViewController *vc = [view supercontroller];
    if (vc == nil) {
        return;
    }
    [self addToController:vc withIdentifier:plist];
}

- (void)willMoveToWindow:(UIWindow *)newWindow {
    if (newWindow == nil) {
        UIViewController *vc = [self supercontroller];
        if (vc.navigationController.topViewController != vc) {
            // pop
            kDisplaysExpression = NO;
        }
    }
}

#pragma mark - User Interaction

- (void)handleClick:(id)sender {
    kDisplaysExpression = !kDisplaysExpression;
    if (!kDisplaysExpression) {
        UIViewController *curVC = [self supercontroller];
        if (curVC.presentedViewController != nil) {
            [curVC.presentedViewController dismissViewControllerAnimated:YES completion:nil];
        }
    }
    
    [[self superview] pb_reloadPlist];
}

- (void)handlePan:(UIPanGestureRecognizer *)recognizer {
    CGPoint translation = [recognizer translationInView:self];
    CGPoint center = self.center;
    center.x += translation.x;
    center.y += translation.y;
    self.center = center;
    [recognizer setTranslation:CGPointZero inView:self];
    
    [[NSUserDefaults standardUserDefaults] setFloat:center.x forKey:[NSString stringWithFormat:@"pbind.inspector.x@%@", _identifier]];
    [[NSUserDefaults standardUserDefaults] setFloat:center.y forKey:[NSString stringWithFormat:@"pbind.inspector.y@%@", _identifier]];
}

#if !(TARGET_IPHONE_SIMULATOR)
- (void)handleLongPress:(UILongPressGestureRecognizer *)sender {
    if (sender.state != UIGestureRecognizerStateBegan) {
        return;
    }
    
    UIViewController *currentController = [self supercontroller];
    if (currentController == nil) {
        return;
    }
    
    PBLLInspectorController *inspectorVC = [[PBLLInspectorController alloc] init];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:inspectorVC];
    [currentController presentViewController:nav animated:YES completion:nil];
}
#endif

+ (void)handleShowTips:(PBLLTipsTapper *)sender {
    if (sender.tips == nil) {
        return;
    }
    
    [[self sharedInspector] showTips:sender.tips code:nil onView:sender.owner];
}

#pragma mark - Notification

- (void)updateConnectState:(BOOL)connected {
    self.backgroundColor = connected ? kPbindPrimaryColor : [UIColor lightGrayColor];
}

+ (void)pbactionWillDispatch:(NSNotification *)notification {
    PBAction *action = notification.object;
    if (action.mapper == nil) {
        return;
    }
    
    if (!kDisplaysExpression) {
        return;
    }
    
    // Prevent default action
    action.disabled = YES;

    // Build up tips
    NSMutableDictionary *temp = [NSMutableDictionary dictionary];
    PBActionState *state = action.store.state;
    [action.mapper initPropertiesForTarget:temp];
    [action.mapper mapPropertiesToTarget:temp withData:state.data owner:state.context context:state.context];
    NSString *tips = [temp description];
    
    // Build up code (expression)
    NSString *code = [[action.mapper targetSource] description];
    
    [[self sharedInspector] showTips:tips code:code onView:state.sender];
}

#pragma mark - Tips

- (void)showTips:(NSString *)tips code:(NSString *)code onView:(UIView *)view {
    UIViewController *curVC = [self supercontroller];
    if (curVC == nil) {
        return;
    }
    
    PBLLInspectorTipsController *popVC = (id) curVC.presentedViewController;
    UIPopoverPresentationController *popContainerVC = popVC.popoverPresentationController;
    if (popContainerVC != nil) {
        BOOL changed = popContainerVC.sourceView != view || ![tips isEqualToString:popVC.tips];
        if (changed) {
            [popVC dismissViewControllerAnimated:NO completion:^{
                [self showTips:tips code:code onView:view];
            }];
        } else {
            [popVC dismissViewControllerAnimated:YES completion:nil];
        }
    } else {
        popVC = [[PBLLInspectorTipsController alloc] init];
        popVC.modalPresentationStyle = UIModalPresentationPopover;
        
        popContainerVC = popVC.popoverPresentationController;
        popContainerVC.permittedArrowDirections = UIPopoverArrowDirectionAny;
        popContainerVC.delegate = self;
        popContainerVC.backgroundColor = kPbindPrimaryColor;
        popContainerVC.passthroughViews = @[curVC.view];
        
        popVC.tips = tips;
        popVC.code = code;
        popContainerVC.sourceView = view;
        popContainerVC.sourceRect = view.bounds;
        
        [curVC presentViewController:popVC animated:YES completion:nil];
    }
}

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller{
    return UIModalPresentationNone;
}

- (BOOL)popoverPresentationControllerShouldDismissPopover:(UIPopoverPresentationController *)popoverPresentationController{
    return YES;
}

@end

#endif
