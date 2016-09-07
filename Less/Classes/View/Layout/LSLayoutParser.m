//
//  LSLayoutParser.m
//  Less
//
//  Created by galen on 15/3/8.
//  Copyright (c) 2015年 galen. All rights reserved.
//

#import "LSLayoutParser.h"
#import "UIView+Less.h"
#import "UIView+LSLayout.h"
#import "UITableView+LSLayout.h"
#import "UICollectionView+LSLayout.h"
#import "LSMutableExpression.h"
#import "LSValueParser.h"
#import "_LSFormInputSpec.h"
#import "LSMapperProperties.h"

NSString *const kCellReuseIdentifier = @"LSCell";

//___________________________________________________________________________________________________
@interface LSCellViewLayoutData : NSObject

@property (nonatomic, assign) Class viewClass;
@property (nonatomic, strong) NSDictionary *constantProperties;
@property (nonatomic, strong) NSDictionary *dynamicProperties;

@end

@implementation LSCellViewLayoutData

@end

//___________________________________________________________________________________________________

@interface LSLayoutParser () <NSXMLParserDelegate, UITableViewDataSource, UITableViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>
{
    NSXMLParser *_XMLParser;
    UIView      *_rootView;
    UIView      *_currentView;
    NSInteger    _currentDepth;
    CGFloat      _scale;
    struct {
        unsigned int inTableView:1;
        unsigned int inCell:1;
    } _flags;
}

@end

@implementation LSLayoutParser

DEF_SINGLETON(sharedParser)

- (instancetype)init
{
    if (self = [super init]) {
        
    }
    return self;
}

- (UIView *)viewFromLayout:(NSString *)layout bundle:(NSBundle *)bundle
{
    if (bundle == nil) {
        bundle = [NSBundle mainBundle];
    }
    NSURL *URL = [bundle URLForResource:layout withExtension:@"xml"];
    return [self viewFromLayoutURL:URL];
}

- (UIView *)viewFromLayoutURL:(NSURL *)layoutURL
{
    _XMLParser = [[NSXMLParser alloc] initWithContentsOfURL:layoutURL];
    _XMLParser.delegate = self;
    
    _rootView = nil;
    BOOL success = [_XMLParser parse];
    if (success) {
        [_rootView setContentMode:UIViewContentModeScaleToFill];
        [_rootView setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
        return _rootView;
    }
    return nil;
}

#pragma mark - NSXMLParserDelegate

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    Class viewClass = NSClassFromString(elementName);
    if (viewClass == nil) {
        return;
    }
    
    UIView *view = nil;
    if ([viewClass isSubclassOfClass:[UICollectionView class]]) {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.itemSize = CGSizeMake(100, 100);
        view = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    } else {
        view = [[viewClass alloc] init];
        if (![view isKindOfClass:[UIView class]]) {
            return;
        }
    }
    
    // Init attributes
    NSMutableDictionary *constantProperties = nil;
    NSMutableDictionary *dynamicProperties = nil;
    NSValue *rootFrameValue = nil;
    for (NSString *key in attributeDict) {
        id value = [attributeDict objectForKey:key];
        LSMutableExpression *expression = [LSMutableExpression expressionWithString:value];
        if (expression != nil) {
            if (dynamicProperties == nil) {
                dynamicProperties = [[NSMutableDictionary alloc] init];
            }
            [dynamicProperties setObject:expression forKey:key];
        } else {
            if (constantProperties == nil) {
                constantProperties = [[NSMutableDictionary alloc] init];
            }
            value = [LSValueParser valueWithString:value];
            if ([key isEqualToString:@"frame"]) {
                // Auto size
                CGRect frame = [(NSValue *)value CGRectValue];
                CGSize winSize = [UIScreen mainScreen].bounds.size;
                if (_rootView == nil) {
                    rootFrameValue = value;
                    frame.size = winSize;
                } else {
                    frame.size.width *= _scale;
                    frame.size.height *= _scale;
                }
                value = [NSValue valueWithCGRect:frame];
            }
            if ([_currentView isKindOfClass:[UITableViewCell class]]
                || [_currentView isKindOfClass:[UICollectionViewCell class]]
                || [view isKindOfClass:[UITableViewCell class]]
                || [view isKindOfClass:[UICollectionViewCell class]]) {
                // Lazy init
                [constantProperties setObject:value forKey:key];
            } else {
                [view setValue:value forKeyPath:key];
            }
        }
    }
    
    if (_rootView == nil) {
        _rootView = _currentView = view;
        _scale = [UIScreen mainScreen].bounds.size.width / [rootFrameValue CGRectValue].size.width;
        _currentDepth = 1;
    } else {
        _currentDepth++;
        
        if ([_currentView isKindOfClass:[UITableView class]]) {
            UITableView *tableView = (id)_currentView;
            [tableView setLSCellConstantProperties:constantProperties];
            [tableView setLSCellDynamicProperties:dynamicProperties];
            [tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kCellReuseIdentifier];
            [tableView setDataSource:self];
            [tableView setDelegate:self];
            [tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
            [tableView setBackgroundColor:[UIColor clearColor]];
            if ([[_currentView superview] isKindOfClass:[UIScrollView class]]) {
                [(UIScrollView *)[_currentView superview] setDelaysContentTouches:YES];
                [(UIScrollView *)[_currentView superview] setCanCancelContentTouches:NO];
            }
            [_currentView addSubview:view];
            _currentView = view;
        } else if ([_currentView isKindOfClass:[UICollectionView class]]) {
            UICollectionView *collectionView = (id)_currentView;
            [collectionView setLSCollectionCellConstantProperties:constantProperties];
            [collectionView setLSCollectionCellDynamicProperties:dynamicProperties];
            [collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:kCellReuseIdentifier];
            [collectionView setDataSource:self];
            [collectionView setDelegate:self];
            [collectionView setBackgroundColor:[UIColor clearColor]];
            if ([[_currentView superview] isKindOfClass:[UIScrollView class]]) {
                [(UIScrollView *)[_currentView superview] setDelaysContentTouches:YES];
                [(UIScrollView *)[_currentView superview] setCanCancelContentTouches:NO];
            }
            [_currentView addSubview:view];
            _currentView = view;
        } else if ([_currentView isKindOfClass:[UITableViewCell class]] ) {
            UITableView *tableView = (id)_currentView.superview;
            LSCellViewLayoutData *data = [[LSCellViewLayoutData alloc] init];
            data.viewClass = viewClass;
            data.constantProperties = constantProperties;
            data.dynamicProperties = dynamicProperties;
            if (tableView.LSCellSubviewDatas == nil) {
                tableView.LSCellSubviewDatas = [[NSMutableArray alloc] init];
            }
            [tableView.LSCellSubviewDatas addObject:data];
            [_currentView addSubview:view];
            _currentView = view;
        } else if ([_currentView isKindOfClass:[UICollectionViewCell class]]) {
            UICollectionView *collectionView = (id)_currentView.superview;
            LSCellViewLayoutData *data = [[LSCellViewLayoutData alloc] init];
            data.viewClass = viewClass;
            data.constantProperties = constantProperties;
            data.dynamicProperties = dynamicProperties;
            if (collectionView.LSCollectionCellSubviewDatas == nil) {
                collectionView.LSCollectionCellSubviewDatas = [[NSMutableArray alloc] init];
            }
            [collectionView.LSCollectionCellSubviewDatas addObject:data];
            [_currentView addSubview:view];
            _currentView = view;
        } else {
            if ([elementName isEqualToString:@"UILabel"]) {
                // Compatible for iOS6
                [view setBackgroundColor:[UIColor clearColor]];
            } else if ([view isKindOfClass:[UIButton class]]) {
                // Hypertext link
                if ([constantProperties valueForKey:@"href"] != nil
                    || [dynamicProperties valueForKey:@"href"] != nil) {
                    [(UIButton *)view addTarget:self action:@selector(hrefButtonClick:) forControlEvents:UIControlEventTouchUpInside];
                }
            }
            [_currentView addSubview:view];
            _currentView = view;
        }
    }
    
    [view setLSDynamicProperties:dynamicProperties];
    [view setLSConstantProperties:constantProperties];
    
    // Auto layout
    NSString *autoHeightDesc = [attributeDict objectForKey:@"autoHeight"];
    if ([autoHeightDesc boolValue]) {
        if ([view isKindOfClass:[UILabel class]]) {
            UILabel *label = (id)view;
            if (label.numberOfLines == 1) {
                label.numberOfLines = 0;
            }
            [label setLineBreakMode:NSLineBreakByWordWrapping];
        }
//        [view setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
//        [view setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
        
        NSNumber *depthValue = @(_currentDepth);
        _rootView.LSAutoheightSubviewMaxDepth = depthValue;
        NSMutableDictionary *autoHeightSubviews = _rootView.LSAutoheightSubviews;
        if (autoHeightSubviews == nil) {
            autoHeightSubviews = [[NSMutableDictionary alloc] init];
            _rootView.LSAutoheightSubviews = autoHeightSubviews;
        }
        NSMutableArray *depthSubviews = [autoHeightSubviews objectForKey:depthValue];
        if (depthSubviews == nil) {
            depthSubviews = [[NSMutableArray alloc] init];
            [autoHeightSubviews setObject:depthSubviews forKey:depthValue];
        }
        [depthSubviews addObject:view];
        [depthSubviews sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            CGFloat d = [obj1 frame].origin.y - [obj2 frame].origin.y;
            if (d < 0) {
                return NSOrderedAscending;
            } else if (d > 0) {
                return NSOrderedDescending;
            } else {
                return NSOrderedSame;
            }
        }];
    } else {
        [view setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
    }
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    UIView *view = _currentView;
    _currentView = [_currentView superview];
    if ([view isKindOfClass:[UITableViewCell class]]
        || [view isKindOfClass:[UICollectionViewCell class]]) {
        [view removeFromSuperview];
    }
    
    _currentDepth--;
    if (_currentDepth == 0) {
        [_rootView pr_initConstraintForAutoheight];
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[tableView data] count];
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellReuseIdentifier forIndexPath:indexPath];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kCellReuseIdentifier];
    }
    
    [cell setBackgroundColor:[UIColor clearColor]];
    [cell setLSConstantProperties:[tableView LSCellConstantProperties]];
    [cell setLSDynamicProperties:[tableView LSCellDynamicProperties]];
    id cellData = [[tableView data] objectAtIndex:indexPath.row];
    [cell setData:cellData];
    if ([[cell.contentView subviews] count] <= 1) {
        for (LSCellViewLayoutData *layoutData in [tableView LSCellSubviewDatas]) {
            UIView *view = [[layoutData.viewClass alloc] init];
            [view setData:cellData];
            [view setLSConstantProperties:layoutData.constantProperties];
            [view setLSDynamicProperties:layoutData.dynamicProperties];
            [cell.contentView addSubview:view];
        }
    }
    [cell pr_initData];
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    [cell pr_mapData:[tableView data]];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    NSString *href = [cell valueForAdditionKey:@"href"];
    LSViewClickHref(cell, href);
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [[collectionView data] count];
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kCellReuseIdentifier forIndexPath:indexPath];
    if (cell == nil) {
        cell = [[UICollectionViewCell alloc] init];
    }
    
    [cell setBackgroundColor:[UIColor redColor]];
    [cell setLSConstantProperties:[collectionView LSCollectionCellConstantProperties]];
    [cell setLSDynamicProperties:[collectionView LSCollectionCellDynamicProperties]];
    id cellData = [[collectionView data] objectAtIndex:indexPath.row];
    [cell setData:cellData];
    if ([[cell.contentView subviews] count] == 0) {
        for (LSCellViewLayoutData *layoutData in [collectionView LSCollectionCellSubviewDatas]) {
            UIView *view = [[layoutData.viewClass alloc] init];
            [view setData:cellData];
            [view setLSConstantProperties:layoutData.constantProperties];
            [view setLSDynamicProperties:layoutData.dynamicProperties];
            [cell.contentView addSubview:view];
        }
    }
    [cell pr_initData];
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSValue *sizeValue = [collectionView valueForKey:@"collectionSize"];
    if (sizeValue != nil) {
        return [sizeValue CGSizeValue];
    }
    return CGSizeMake(44, 44);
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    NSValue *insets = [collectionView valueForKey:@"collectionInsets"];
    if (insets != nil) {
        return [insets UIEdgeInsetsValue];
    }
    return UIEdgeInsetsMake(0, 0, 0, 0);
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    [cell pr_mapData:[collectionView data]];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
    NSString *href = [cell valueForAdditionKey:@"href"];
    LSViewClickHref(cell, href);
}

#pragma mark - Href button

- (void)hrefButtonClick:(id)sender {
    NSString *href = [sender valueForAdditionKey:@"href"];
    LSViewClickHref(sender, href);
}

@end

