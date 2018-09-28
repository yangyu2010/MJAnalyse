//
//  MJAnalyse.h
//  Pods
//
//  Created by Yang Yu on 2018/9/14.
//  统计分析模块
//  ‼️‼️‼️‼️ 使用注意

//  1. 在Constant里配置Adjust token(如没有Adjust 则不需要)
/**
 /// Adjust App token, 如有使用Adjust, 必须定义
 #define AdjustAppToken  @"AdjustAppToken"
 /// 加入购物车token, 如不需要统计, 不定义
 #define AdjustAddedToCartEvent  @"AdjustAddedToCartEvent"
 /// 购买token, 如不需要统计, 不定义
 #define AdjustRevenueEvent  @"AdjustRevenueEvent"
 /// 试用转付费token
 #define AdjustTrailToPayEvent      @"AdjustTrailToPayEvent"
 */

//  2. 在 didFinishLaunchingWithOptions 中 调用[MJAnalyse configWithApplication:options:]方法

//  3. 如要统计内购 调用下面三个其中一个
//  [MJAnalyse analysePurchaseWithStatus:product:]
//  [MJAnalyse analysePurchaseWithStatus:info:]
//  [MJAnalyse analysePurchaseWithStatus:productId:currency:price:]


/// 记录内购方面的统计需要
typedef enum : NSUInteger {
    MJAnalysePurchaseAddToCart = 0,     ///< 加入购物车, 点击内购按钮d时的状态
    MJAnalysePurchaseSucceed,           ///< 内购完成
    MJAnalysePurchaseTrialToPay,        ///< 内购从试用转为付费状态
} MJAnalysePurchaseStatus;


#import <Foundation/Foundation.h>
@class SKProduct;

@interface MJAnalyse : NSObject



#pragma mark- Public

/// 初始化统计模块, 包括初始化 iad Facebook adjust三个模块
+ (void)configWithApplication:(UIApplication *)application
                      options:(NSDictionary *)launchOptions;;

/// 记录内购相关的统计 传入product
+ (void)analysePurchaseWithStatus:(MJAnalysePurchaseStatus)status
                          product:(SKProduct *)product;

/// 记录内购相关的统计
/// info字典里需传入  price currency productId
+ (void)analysePurchaseWithStatus:(MJAnalysePurchaseStatus)status
                             info:(NSDictionary *)info;

/// 记录内购相关的统计
+ (void)analysePurchaseWithStatus:(MJAnalysePurchaseStatus)status
                        productId:(NSString *)productId
                         currency:(NSString *)currency
                            price:(double)price;


#pragma mark- 废弃了, 请使用上面的API
/// 购买完成后调用, 内部处理统计
+ (void)purchaseWithProduct:(SKProduct *)product NS_DEPRECATED_IOS(2_0, 9_0, "API已经废弃, 请使用 [MJAnalyse analysePurchaseWithStatus:product:]");
/// 点击购买按钮事件(加入购物车)
+ (void)addedToCartWithProduct:(SKProduct *)product NS_DEPRECATED_IOS(2_0, 9_0, "API已经废弃, 请使用 [MJAnalyse analysePurchaseWithStatus:product:]");


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


/**
 Facebook统计, 外部购买时调用, 外部不用区分是否是续订型
 
 @param product SKProduct
 */
+ (void)facebookPurchaseWithProduct:(SKProduct *)product;


/**
 Facebook统计, "添加到购物车"

 @param contentData 一些数据(目前没有规定是什么, 后续看市场需要我们提供哪些数据) 目前传""
 @param contentId 内购的key
 @param contentType 内购类型: "消耗型内购" "自动订阅型内购"等 (可以直接传字符串)
 @param currency 货币 获取内购的(有RMB, HKD等)
 @param price 价格
 */
+ (void)facebookAddedToCartEvent:(NSString *)contentData
                       contentId:(NSString *)contentId
                     contentType:(NSString *)contentType
                        currency:(NSString *)currency
                      valueToSum:(double)price;


/**
 Facebook统计, "购买"
 该事件记录购买消耗性内购, 自动订阅等
 */
+ (void)facebookPurchaseEvent:(NSString *)contentData
                    contentId:(NSString *)contentId
                  contentType:(NSString *)contentType
                     currency:(NSString *)currency
                   valueToSum:(double)price;


/**
 Facebook统计, "试用转付费", 对应Facebook的 "开始结账" 事件
 FBSDKAppEventNameInitiatedCheckout
 某个试用转成付费后, 用该事件记录
 */
+ (void)facebookTrialToPayEvent:(NSString *)contentData
                       contentId:(NSString *)contentId
                     contentType:(NSString *)contentType
                        currency:(NSString *)currency
                      valueToSum:(double)price;


#pragma mark- Adjust

/// Adjust 配置
/// 一定要在Constant.h里配置 AdJustAppToken
+ (void)adjustLaunching;

/**
 收入跟踪

 @param amount 收入
 @param currency 货币
 @param eventToken 该事件的token, 每个app可能不同
 */
+ (void)adjustSetRevenue:(double)amount
                currency:(nonnull NSString *)currency;


/**
 事件跟踪

 @param eventToken 该事件的token, 每个app可能不同
 */
+ (void)adjustEventWithEventToken:(NSString *)eventToken;



@end
