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
    点击订阅按钮: EVENT_NAME_INITIATED_CHECKOUT [:发起结账] (对应自定义事件Key "Checkout")
    订阅试用商品成功: EVENT_NAME_START_TRIAL [:开始试用] (对应自定义事件Key "StartTrial")
    订阅非试用商品或者试用商品试用期过后已正常扣款: EVENT_NAME_SUBSCRIBE [:订阅] (对应自定义事件Key "Subscribe")
    购买成功，不管是试用成功、订阅成功或者续订成功: EVENT_NAME_PURCHASED [:购买] (对应自定义事件Key "Purchased")
    购买失败 (对应自定义事件Key "PurchasedFailure")
 
    内购统计后 自动调用手动打点记录内购producId和对应的状态
    Key的格式是 : 去除bundle id的producId + "_" + 内购状态的字符串
    例如: vip_OneNumber_Purchased
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
    MJAnalysePurchasedFailure,      ///< 购买失败
} MJAnalyseStatus;


/// 服务器事件记录
typedef enum : NSUInteger {
    MJAnalyseEventHome,                     ///< 到达首页人次
    MJAnalyseEventPaymentCreat,             ///< 点击购买人次 购买相关的recordValue传商品ID
    MJAnalyseEventPaymentSucceed,           ///< 购买成功人次
    MJAnalyseEventPaymentSucceedTrial,      ///< 购买成功试用人次
    MJAnalyseEventPaymentFailed,            ///< 购买失败人次 会调用IAP_*购买失败
    MJAnalyseEventNonSubscriptionSucceed    ///< (非订阅类型)付费成功 IAP_* (完整的商品ID)
} MJAnalyseEventCode;


@interface MJAnalyse : NSObject

#pragma mark- Public

/// 初始化统计模块, 包括初始化 iad Facebook adjust三个模块
+ (void)configWithApplication:(UIApplication *)application
                      options:(NSDictionary *)launchOptions;

/// app变活跃时调用 记录启动用
+ (void)applicationDidBecomeActive;

/// 自己服务器的事件记录
+ (void)logEven:(MJAnalyseEventCode)eventCode value:(NSString *)value;
/// 给宏定义triggerEventStr使用的方法
+ (void)logEvenStr:(NSString *)eventStr value:(NSString *)value;

/// 记录内购相关的统计
+ (void)analysePurchaseWithStatus:(MJAnalyseStatus)status
                        productId:(NSString *)productId
                            price:(double)price;

/// 统计事件 会统计到Facebook Firebase uMeng
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
