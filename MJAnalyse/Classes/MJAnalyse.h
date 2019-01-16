//
//  MJAnalyse.h
//  Pods
//
//  Created by Yang Yu on 2018/9/14.
//  统计分析模块

//  在 didFinishLaunchingWithOptions 中 调用[MJAnalyse configWithApplication:options:]方法

//  如要统计内购 调用下面其中一个
//  [MJAnalyse analysePurchaseWithStatus:productId:price:] 推荐使用

//  如果要统计事件 内部会调用Facebook统计 Firebase统计
//  [MJAnalyse logEvent:parameters:]

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/// 记录内购方面的统计需要
typedef enum : NSUInteger {
    MJAnalysePurchaseAddToCart = 1,         ///< 加入购物车
    MJAnalysePurchaseSucceed,               ///< 内购成功
    MJAnalysePurchaseInitiatedCheckout,     ///< 开始结账
    
    MJAnalysePurchaseTrialToPay,            ///< 内购从试用转为付费状态(目前没有用到)
} MJAnalysePurchaseStatus;




@interface MJAnalyse : NSObject

#pragma mark- Public

/// 初始化统计模块, 包括初始化 iad Facebook adjust三个模块
+ (void)configWithApplication:(UIApplication *)application
                      options:(NSDictionary *)launchOptions;;


/// 记录内购相关的统计 推荐使用
+ (void)analysePurchaseWithStatus:(MJAnalysePurchaseStatus)status
                        productId:(NSString *)productId
                            price:(double)price;

/// 统计事件 会统计到Facebook Firebase
+ (void)logEvent:(NSString *)event parameters:(NSDictionary *)parameters;



/// 记录内购相关的统计 推荐使用上面的
+ (void)analysePurchaseWithStatus:(MJAnalysePurchaseStatus)status
                        productId:(NSString *)productId;


#pragma mark- 归因API

/**
 归因API初始化, 在didFinishLaunchingWithOptions中调用
 (使用了友盟统计, 保证项目中导入了友盟的库, 同时让市场添加统计的key)
 后面如果没有友盟统计, 可以考虑用Firebase统计
 */
+ (void)iAdLaunching;

/// 归因API统计购买
+ (void)iAdPurchase;




#pragma mark- Facebook统计

/// 初始化Facebook SDK
+ (void)facebookSDKApplication:(UIApplication *)application options:(NSDictionary *)launchOptions;

/// 活跃Facebook SDK(一般不需要调用, SDK会自己调用)
+ (void)facebookActivateApp;

/// 处理application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options这个方法时, 调用
/// if ([url.scheme hasPrefix:@"fb"]) 需提前判断下, 再调用
+ (BOOL)facebookHandleUrl:(NSURL *)url
              application:(UIApplication *)application
                  options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options;


@end
