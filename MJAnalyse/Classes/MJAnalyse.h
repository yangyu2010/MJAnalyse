//
//  MJAnalyse.h
//  Pods
//
//  Created by Yang Yu on 2018/9/14.
//  统计分析模块

//  在 didFinishLaunchingWithOptions 中 调用[MJAnalyse configWithApplication:options:]方法

//  如要统计内购 调用下面方法
//  [MJAnalyse analysePurchaseWithStatus:productId:price:] 推荐使用
/**
    点击订阅按钮: EVENT_NAME_INITIATED_CHECKOUT [:发起结账]
    订阅试用商品成功: EVENT_NAME_START_TRIAL [:开始试用]
    订阅非试用商品或者试用商品试用期过后已正常扣款: EVENT_NAME_SUBSCRIBE [:订阅]
    购买成功，不管是试用成功、订阅成功或者续订成功: EVENT_NAME_PURCHASED [:购买]
 */


//  如果要统计事件 内部会调用Facebook统计 Firebase统计
//  [MJAnalyse logEvent:parameters:]

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/// 记录内购方面的统计需要
typedef enum : NSUInteger {
    MJAnalyseInitiatedCheckout,     ///< 发起结账
    MJAnalyseStartTrial,            ///< 开始试用
    MJAnalyseSubscribe,             ///< 订阅
    MJAnalysePurchased,             ///< 购买
} MJAnalyseStatus;




@interface MJAnalyse : NSObject

#pragma mark- Public

/// 初始化统计模块, 包括初始化 iad Facebook adjust三个模块
+ (void)configWithApplication:(UIApplication *)application
                      options:(NSDictionary *)launchOptions;;


/// 记录内购相关的统计
+ (void)analysePurchaseWithStatus:(MJAnalyseStatus)status
                        productId:(NSString *)productId
                            price:(double)price;

/// 统计事件 会统计到Facebook Firebase
+ (void)logEvent:(NSString *)event parameters:(NSDictionary *)parameters;


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
