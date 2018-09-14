//
//  MJAnalyse.h
//  Pods
//
//  Created by Yang Yu on 2018/9/14.
//  统计分析模块

#import <Foundation/Foundation.h>

@interface MJAnalyse : NSObject


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
 Facebook统计, "添加到购物车"
 某个内购有试用时, 才使用该事件记录, 其他内购不使用这个事件

 @param contentData 一些数据(目前没有规定是什么, 后续看市场需要我们提供哪些数据) 目前传""
 @param contentId 内购的key
 @param contentType 内购类型: "消耗型内购" "自动订阅型内购"等 (可以直接传字符串)
 @param currency 货币 获取内购的(有RMB等) 我们简单处理, 直接获取地区(CN HK US等)给市场
 @param price 价格
 */
+ (void)facebookAddedToCartEvent:(NSString *)contentData
                       contentId:(NSString *)contentId
                     contentType:(NSString *)contentType
                        currency:(NSString *)currency
                      valueToSum:(double)price;






@end
