//
//  PBLLInspectorTipsController.m
//  Pbind
//
//  Created by galen on 17/7/29.
//

#import "PBLLInspectorTipsController.h"

#if (PBLIVE_ENABLED)

#import "PBLLRemoteWatcher.h"
#import "PBLLResource.h"
#import <Pbind/Pbind.h>

@interface PBLLInspectorTipsController ()

@property (nonatomic, strong) UILabel *tipsLabel;
@property (nonatomic, strong) UIToolbar *toolbar;
@property (nonatomic, assign) CGFloat preferredWidth;
@property (nonatomic, strong) UIBarButtonItem *codeOrTipsItem;

@end

@implementation PBLLInspectorTipsController

static BOOL kDisplaysCode = NO;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    CGRect rect = [UIScreen mainScreen].bounds;
    _preferredWidth = rect.size.width * 2.f / 3.f;
    
    rect.origin.x = 16.f;
    rect.origin.y = 16.f;
    UILabel *label = [[UILabel alloc] initWithFrame:rect];
    label.textColor = [UIColor whiteColor];
    label.text = self.tips;
    label.font = [UIFont systemFontOfSize:12.f];
    label.numberOfLines = 0;
    rect.size.height = [label sizeThatFits:rect.size].height;
    label.frame = rect;
    
    [self.view addSubview:label];
    _tipsLabel = label;
    
    UIToolbar *toolbar = [[UIToolbar alloc] init];
    [toolbar setBarTintColor:self.popoverPresentationController.backgroundColor];
    [toolbar setTintColor:[UIColor whiteColor]];
    
    NSMutableArray *items = [NSMutableArray arrayWithCapacity:4];
    [items addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:self action:@selector(handleClose:)]];
    [items addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]];
    if (self.code != nil) {
        _codeOrTipsItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:self action:@selector(handleToggleCode:)];
        [items addObject:_codeOrTipsItem];
        
        [items addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]];
    }
    // Copy
    [items addObject:[[UIBarButtonItem alloc] initWithImage:[PBLLResource copyImage] style:UIBarButtonItemStylePlain target:self action:@selector(handleCopy:)]];
#if !(TARGET_IPHONE_SIMULATOR)
    // Post
    UIBarButtonItem *postItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemReply target:self action:@selector(handlePost:)];
    [items addObject:postItem];
#endif
    
    toolbar.items = items;
    [self.view addSubview:toolbar];
    _toolbar = toolbar;
    
    [self render];
}

- (void)render {
    [self renderWithAnimated:NO];
}

- (void)renderWithAnimated:(BOOL)animated {
    dispatch_block_t renderBlock = ^{
        if (_code != nil) {
            if (kDisplaysCode) {
                _codeOrTipsItem.title = @"Value";
                _tipsLabel.text = _code;
            } else {
                _codeOrTipsItem.title = @"Code";
                _tipsLabel.text = _tips;
            }
        } else {
            _tipsLabel.text = _tips;
        }
        
        CGRect rect = CGRectMake(16.f, 16.f, _preferredWidth - 32.f, CGFLOAT_MAX);
        rect.size.height = [_tipsLabel sizeThatFits:rect.size].height;
        _tipsLabel.frame = rect;
        
        rect.origin.x = 0.f;
        rect.origin.y += rect.size.height + 16.f;
        rect.size.width = _preferredWidth;
        rect.size.height = 44.f;
        _toolbar.frame = rect;
        
        rect.size.height += rect.origin.y;
        self.preferredContentSize = rect.size;
    };
    if (animated) {
        [UIView animateWithDuration:.25f animations:renderBlock completion:^(BOOL finished) {
            [self.popoverPresentationController.containerView setNeedsLayout];
        }];
    } else {
        renderBlock();
    }
}

#pragma mark - BarButtonItem

- (void)handleClose:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)handleToggleCode:(id)sender {
    kDisplaysCode = !kDisplaysCode;
    [self renderWithAnimated:YES];
}

- (void)handleCopy:(id)sender {
    [UIPasteboard generalPasteboard].string = _tipsLabel.text;
}

#if !(TARGET_IPHONE_SIMULATOR)
- (void)handlePost:(id)sender {
    [[PBLLRemoteWatcher globalWatcher] sendLog:_tips];
}
#endif

@end

#endif
