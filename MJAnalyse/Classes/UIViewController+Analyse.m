//
//  UIViewController+Analyse.m
//  FunTest
//
//  Created by 刘鹏i on 2019/3/15.
//  Copyright © 2019 Musjoy. All rights reserved.
//

#import "UIViewController+Analyse.h"
#import <objc/runtime.h>
#import <MJAnalyse.h>

#define kAnalyseRecordFromWhenPresent @"kAnalyseRecordFromWhenPresent"

static const NSDictionary *viewControllerNameMixDict = nil;

@implementation UIViewController (Analyse)
#pragma mark - Life Cycle
+ (void)load
{
    // 混淆后，控制器名称对应表
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        viewControllerNameMixDict = @{};
    });
    
    // 交换viewDidLoad
    Method viewDidLoad1 = class_getInstanceMethod([self class], NSSelectorFromString(@"viewDidLoad"));
    Method viewDidLoad2 = class_getInstanceMethod([self class], @selector(viewDidLoadSwizzle));
    method_exchangeImplementations(viewDidLoad1, viewDidLoad2);
    
    // 交换dealloc
    Method dealloc1 = class_getInstanceMethod([self class], NSSelectorFromString(@"dealloc"));
    Method dealloc2 = class_getInstanceMethod([self class], @selector(deallocSwizzle));
    method_exchangeImplementations(dealloc1, dealloc2);
}

- (void)viewDidLoadSwizzle
{
    [self viewDidLoadSwizzle];
    
    if ([self needRecord]) {
        [MJAnalyse logEvent:ANALYSE_EVENT_OPEN_CONTROLLER parameters:@{@"pageName": [[self class] userFriendlyControllerName:self]}];
    }
}

- (void)deallocSwizzle
{
    if ([self needRecord]) {
        [MJAnalyse logEvent:ANALYSE_EVENT_CLOSE_CONTROLLER parameters:@{@"pageName": [[self class] userFriendlyControllerName:self]}];
    }

    [self deallocSwizzle];
}

#pragma mark - Puclic
/// 记录页面来源（弹出时）
- (void)analyseRecordFromWhenPresent
{
    /*
     因为要在转场结束后，才能取到presentingViewController
     所以此方法，要放在viewDidAppear中执行，不能放在viewDidLoad中
     而viewDidAppear会执行多次，所以记录当前控制器地址，保证只执行一次
     */
    NSString *current = [NSString stringWithFormat:@"%p", self];
    NSMutableArray *dcit = [[[NSUserDefaults standardUserDefaults] objectForKey:kAnalyseRecordFromWhenPresent] mutableCopy];
    if (dcit == nil) {
        dcit = [[NSMutableArray alloc] init];
    }
    
    if ([dcit containsObject:current] == NO) {
        [dcit addObject:current];
        [[NSUserDefaults standardUserDefaults] setObject:dcit forKey:kAnalyseRecordFromWhenPresent];
        
        NSString *pageA = [[self class] userFriendlyControllerName:self];
        NSString *pageB = [self presentingName];
        [MJAnalyse logEvent:ANALYSE_EVENT_OPEN_CONTROLLER_FROM parameters:@{@"A_from_B":[NSString stringWithFormat:@"%@_from_%@", pageA, pageB]}];
    }
}

/// 记录页面来源（消失时）
- (void)analyseRecordFromWhenDismiss
{
    NSString *current = [NSString stringWithFormat:@"%p", self];
    NSMutableArray *dcit = [[[NSUserDefaults standardUserDefaults] objectForKey:kAnalyseRecordFromWhenPresent] mutableCopy];
    if ([dcit containsObject:current] == YES) {
        [dcit removeObject:current];
        [[NSUserDefaults standardUserDefaults] setObject:dcit forKey:kAnalyseRecordFromWhenPresent];
    }
    
    NSString *pageA = [[self class] userFriendlyControllerName:self];
    NSString *pageB = [self presentingName];
    [MJAnalyse logEvent:ANALYSE_EVENT_CLOSE_CONTROLLER_FROM parameters:@{@"A_from_B":[NSString stringWithFormat:@"%@_from_%@", pageA, pageB]}];
}

/// 购买开始（在页面中）
- (void)analysePurchaseStart:(NSString *)shortProductID
{
    NSString *name = [NSString stringWithFormat:@"%@_%@", [[self class] userFriendlyControllerName:self], shortProductID];
    [MJAnalyse logEvent:ANALYSE_EVENT_PURCHASE_START_AT parameters:@{@"pageName": name}];
}

/// 购买成功（在页面中）
- (void)analysePurchaseSuccessed:(NSString *)shortProductID
{
    NSString *name = [NSString stringWithFormat:@"%@_%@", [[self class] userFriendlyControllerName:self], shortProductID];
    [MJAnalyse logEvent:ANALYSE_EVENT_PURCHASE_SUCCESSED_AT parameters:@{@"pageName": name}];
}

/// 购买失败（在页面中）
- (void)analysePurchaseFailed:(NSString *)shortProductID
{
    NSString *name = [NSString stringWithFormat:@"%@_%@", [[self class] userFriendlyControllerName:self], shortProductID];
    [MJAnalyse logEvent:ANALYSE_EVENT_PURCHASE_FAILED_AT parameters:@{@"pageName": name}];
}

#pragma mark - private
/// 弹出前的控制器名称
- (NSString *)presentingName
{
    UIViewController *presentingVC = self.presentingViewController;
    
    while (presentingVC) {
        if ([presentingVC isKindOfClass:[UINavigationController class]]) {
            UINavigationController *nav = (UINavigationController *)presentingVC;
            presentingVC = nav.topViewController;
        } else if ([presentingVC isKindOfClass:[UITabBarController class]]) {
            UITabBarController *tab = (UITabBarController *)presentingVC;
            presentingVC = tab.selectedViewController;
        } else {
            break;
        }
    }
    
    NSString *name = @"UnKnown";
    if (presentingVC) {
        name = [[self class] userFriendlyControllerName:presentingVC];
    }
    
    return name;
}

/// 最终使用的控制器名称
+ (NSString *)userFriendlyControllerName:(UIViewController *)viewController
{
    NSString *mixName = NSStringFromClass([viewController class]);
    // 混淆前名称
    NSString *name = viewControllerNameMixDict[mixName];
    if (name == nil) {
        name = mixName;
    }
    // 更名
    NSDictionary *dictRename = kAnalyseControllersRename;
    if (dictRename.count > 0) {
        name = dictRename[name];
    }
    
    // 未更名
    if ([name isEqualToString:mixName]) {
        // 自动命名，去掉尾部的ViewController等
        name = [name stringByReplacingOccurrencesOfString:@"ViewController" withString:@""];
        name = [name stringByReplacingOccurrencesOfString:@"Controller" withString:@""];
        name = [name stringByReplacingOccurrencesOfString:@"VC" withString:@""];
    }

    return name;
}

/// 是否需要记录此控制器
- (BOOL)needRecord
{
    BOOL isNeed = YES;
    
    NSArray *arrNeed = kAnalyseControllersNeed;
    if (arrNeed.count > 0) {
        // 手动过滤
        isNeed = [arrNeed containsObject:NSStringFromClass([self class])];
    } else {
        // 自动过滤
        NSString *name = NSStringFromClass([self class]);
        
        if ([name hasPrefix:@"UI"] ||
            [name hasPrefix:@"_UI"] ||
            [name hasPrefix:@"MJ"]) {
            // 去掉系统、基础模块的控制器
            isNeed = NO;
        } else {
            // 去掉其他控制器
            NSArray *arrSuffix = @[@"NavigationController", @"TabBarController", @"WebViewController", @"SplitViewController"];
            for (NSString *str in arrSuffix) {
                if ([name hasSuffix:str] == YES) {
                    isNeed = NO;
                    break;
                }
            }
        }
    }
    
    return isNeed;
}

@end
