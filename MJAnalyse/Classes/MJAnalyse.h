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
 */

//  2. 在 didFinishLaunchingWithOptions 中 调用[MJAnalyse configWithApplication:options:]方法

//  3. 如果有内购, 在内购完成后 调用 [MJAnalyse purchaseWithProduct:]

//  4. 加入购物车, 是点击内购按钮 调用 [MJAnalyse addedToCartWithProduct:]



#import <Foundation/Foundation.h>
@class SKProduct;

@interface MJAnalyse : NSObject



#pragma mark- Public

/// 初始化统计模块, 包括初始化 iad Facebook adjust三个模块
+ (void)configWithApplication:(UIApplication *)application
                      options:(NSDictionary *)launchOptions;;

/// 购买完成后调用, 内部处理统计
+ (void)purchaseWithProduct:(SKProduct *)product;

/// 点击购买按钮事件(加入购物车)
+ (void)addedToCartWithProduct:(SKProduct *)product;



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
 该事件记录购买消耗性内购, 没有试用的自动订阅等, 和知道某个试用转成付费后, 用该事件记录

 @param contentData 一些数据(目前没有规定是什么, 后续看市场需要我们提供哪些数据) 目前传""
 @param contentId 内购的key
 @param contentType 内购类型: "消耗型内购" "自动订阅型内购"等 (可以直接传字符串)
 @param currency 货币 获取内购的(有RMB, HKD等)
 @param price 价格
 */
+ (void)facebookPurchaseEvent:(NSString *)contentData
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
