//
//  UIViewController+Analyse.h
//  FunTest
//
//  Created by 刘鹏i on 2019/3/15.
//  Copyright © 2019 Musjoy. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/* 自动记录的事件 */
// 打开页面
#ifndef ANALYSE_EVENT_OPEN_CONTROLLER
#define ANALYSE_EVENT_OPEN_CONTROLLER        @"open_page"
#endif

// 关闭页面
#ifndef ANALYSE_EVENT_CLOSE_CONTROLLER
#define ANALYSE_EVENT_CLOSE_CONTROLLER       @"close_page"
#endif


/* 需手动记录的事件 */
// 打开页面，且记录页面跳转来源（一般用于试用页面）
#ifndef ANALYSE_EVENT_OPEN_CONTROLLER_FROM
#define ANALYSE_EVENT_OPEN_CONTROLLER_FROM   @"open_page_from"
#endif

// 关闭页面，且记录页面跳转来源（一般用于试用页面）
#ifndef ANALYSE_EVENT_CLOSE_CONTROLLER_FROM
#define ANALYSE_EVENT_CLOSE_CONTROLLER_FROM  @"close_page_from"
#endif

// 购买开始（在哪个页面）
#ifndef ANALYSE_EVENT_PURCHASE_START_AT
#define ANALYSE_EVENT_PURCHASE_START_AT      @"purchase_start_at"
#endif

// 购买成功（在哪个页面）
#ifndef ANALYSE_EVENT_PURCHASE_SUCCESSED_AT
#define ANALYSE_EVENT_PURCHASE_SUCCESSED_AT  @"purchase_successed_at"
#endif

// 购买失败（在哪个页面）
#ifndef ANALYSE_EVENT_PURCHASE_FAILED_AT
#define ANALYSE_EVENT_PURCHASE_FAILED_AT     @"purchase_failed_at"
#endif

// 统计的控制器更名
#ifndef kAnalyseControllersRename
#define kAnalyseControllersRename @{}
#endif

// 只需要统计的控制器
#ifndef kAnalyseControllersNeed
#define kAnalyseControllersNeed @[]
#endif

/*
 一、自动记录的事件
    自定义控制器的打开、关闭
 
    特别注意：
    统计事件中会记录控制器的名字，默认会自动记录所有自定义的控制器，但是也提供自己控制记录哪些控制器，并且对这些控制器更名
 
    1.默认情况：
    ·统计所有自定义的控制器
    ·控制器的名字会默认去掉ViewController、VC
 
    2.如果Constant.h文件中，定义了kAnalyseControllersRename，则：
    ·如果给控制器更名了，则使用更改后的名字
    ·如果没更名，则按默认去掉ViewController、VC
 
    示例：
    // MARK: - 统计事件中的控制器更名
    #define kAnalyseControllersRename    \
    @{                  \
    @"HomeViewController"   : @"home",    \
    @"TrialViewController"  : @"subscribe",    \
    }
 
    3.如果Constant.h文件中，定义了kAnalyseControllersNeed，则：
    ·如果数组为空，则默认统计所有自定义控制器
    ·如果数组中有控制器名字，则只统计数组中的控制器
 
    示例：
    // MARK: - 只统计需要的控制器
    #define kAnalyseControllersNeed  @[@"HomeViewController",@"TrialViewController"]
 
 
 二、手动记录的事件
    1.记录页面来源（目前需要记录所有内购页面的来源页，只记录present出来的内购页）
 
    a).在内购页显示时，调用[self analyseRecordFromWhenPresent]，（此方法内部有判断，只会执行一次）
     - (void)viewDidAppear:(BOOL)animated
     {
        [super viewDidAppear:animated];
 
        [self analyseRecordFromWhenPresent];
     }
 
    b).在用户选择不购买商品，手动点击关闭按钮时调用[self analyseRecordFromWhenDismiss]，（注意，是用户手动关闭时调用）
     /// 手动关闭
     - (IBAction)clickedClose:(id)sender {
         [self analyseRecordFromWhenDismiss];
 
         [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
     }
 
 
    2.记录购买事件，不论是内购页中购买还是普通页面上直接购买（主要记录购买时所在的页面，和下面统计具体内购信息的事件不同）
     /// 购买产品
     - (IBAction)buyAction:(id)sender {
         // 开始购买
         [self analysePurchaseStart:shortProductID];
 
         __weak typeof(self) weakSelf = self;
         [[PurchaseManager sharedInstance] purchaseItem:product completion:^(BOOL isSucceed, NSString *message, id data) {
             if (isSucceed) {
                 // 购买成功
                 [weakSelf analysePurchaseSuccessed:shortProductID];
                 [weakSelf dismissSelf];
             } else {
                 // 购买失败
                 [weakSelf analysePurchaseFailed:shortProductID];
             }
         }];
     }
 
 三、基础内购事件
    需添加在自己的内购基类中
 
    1.支付前
    /// 发起结账
    [MJAnalyse analysePurchaseWithStatus:MJAnalyseInitiatedCheckout productId:productId price:round(product.price * 100) / 100];

    2.支付完成回调中
    if (isSucceed) {
        // 购买成功
        [MJAnalyse analysePurchaseWithStatus:MJAnalysePurchased productId:productId price:round(product.price * 100) / 100];
        
        if ([[IAPManager sharedInstance] isTrialFor:weakSelf.currentID]) {
            // 试用订阅成功
            [MJAnalyse analysePurchaseWithStatus:MJAnalyseStartTrial productId:productId price:round(product.price * 100) / 100];
        } else {
            // 正式订阅成功
            [MJAnalyse analysePurchaseWithStatus:MJAnalyseSubscribe productId:productId price:round(product.price * 100) / 100];
        }
    } else {
        // 购买失败
        [MJAnalyse analysePurchaseWithStatus:MJAnalysePurchasedFailure productId:productId price:round(product.price * 100) / 100];
    }

*/


@interface UIViewController (Analyse)
/// 记录页面来源（弹出时）
- (void)analyseRecordFromWhenPresent;

/// 记录页面来源（消失时）
- (void)analyseRecordFromWhenDismiss;

/// 购买开始（在页面中）
- (void)analysePurchaseStart:(NSString *)shortProductID;

/// 购买成功（在页面中）
- (void)analysePurchaseSuccessed:(NSString *)shortProductID;

/// 购买失败（在页面中）
- (void)analysePurchaseFailed:(NSString *)shortProductID;

@end

NS_ASSUME_NONNULL_END
