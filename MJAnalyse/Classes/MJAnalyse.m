//
//  MJAnalyse.m
//  Pods
//
//  Created by Yang Yu on 2018/9/14.
//

#import "MJAnalyse.h"
#import <ModuleCapability/ModuleCapability.h>
#import <StoreKit/StoreKit.h>

#import <iAd/iAd.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <Adjust/Adjust.h>

#import <FirebaseCore/FIRApp.h>

/// 存储归因
#define kLastSearchGroupId  @"kLastSearchGroupId"
/// 存储归因广告信息本地key
#define kSearchAd           @"kSearchAd"

@implementation MJAnalyse


#pragma mark- Public

/// 初始化统计模块, 包括初始化 iad Facebook adjust三个模块
+ (void)configWithApplication:(UIApplication *)application
                      options:(NSDictionary *)launchOptions {
    
    [self facebookSDKApplication:application options:launchOptions];
    [self iAdLaunching];
    [self adjustLaunching];
    [FIRApp configure];
}


/// 记录内购相关的统计
+ (void)analysePurchaseWithStatus:(MJAnalysePurchaseStatus)status
                          product:(SKProduct *)product {
    
    double localPrice = [product.price doubleValue];

    NSString *currency = nil;
    if (@available(iOS 10.0, *)) {
        currency = [product.priceLocale currencyCode];
    } else {
        currency = [product.priceLocale objectForKey:NSLocaleCurrencyCode];
    }

    NSString *productId = product.productIdentifier;

    [self analysePurchaseWithStatus:status
                          productId:productId
                           currency:currency
                              price:localPrice];
}

/// 记录内购相关的统计
+ (void)analysePurchaseWithStatus:(MJAnalysePurchaseStatus)status
                             info:(NSDictionary *)info {
    
    double localPrice = [info[@"price"] doubleValue];
    NSString *currency = info[@"currency"];
    NSString *productId = info[@"productId"];

    [self analysePurchaseWithStatus:status
                          productId:productId
                           currency:currency
                              price:localPrice];
}

/// 记录内购相关的统计
+ (void)analysePurchaseWithStatus:(MJAnalysePurchaseStatus)status
                        productId:(NSString *)productId
                         currency:(NSString *)currency
                            price:(double)price {
    
    if (status == MJAnalysePurchaseAddToCart) {
        /// 加入购物车
        [self addedToCartWithProductId:productId currency:currency valueToSum:price];
    }
    else if (status == MJAnalysePurchaseSucceed) {
        /// 成功
        [self purchaseWithProductId:productId currency:currency valueToSum:price];
    }
    else if (status == MJAnalysePurchaseTrialToPay) {
        /// 转为付费
        [self trialToPayWithProductId:productId currency:currency valueToSum:price];
    }
}



#pragma mark- 废弃了, 请使用上面的API
/// 购买完成后调用, 内部处理统计
+ (void)purchaseWithProduct:(SKProduct *)product {
    [self analysePurchaseWithStatus:MJAnalysePurchaseSucceed product:product];
}

/// 点击购买按钮事件(加入购物车)
+ (void)addedToCartWithProduct:(SKProduct *)product {
    [self analysePurchaseWithStatus:MJAnalysePurchaseAddToCart product:product];
}




#pragma mark- 归因API


/// 归因API初始化
/// 在didFinishLaunchingWithOptions中调用
+ (void)iAdLaunching {

    if ([[ADClient sharedClient] respondsToSelector:@selector(requestAttributionDetailsWithBlock:)]) {
        
        [[ADClient sharedClient] requestAttributionDetailsWithBlock:^(NSDictionary *attributionDetails, NSError *error) {

            if (error) {
                return ;
            }

            dispatch_async(dispatch_get_main_queue(), ^{
                NSDictionary *dict = attributionDetails.allValues.firstObject;
                if (dict == nil) {
                    return ;
                }

                NSString *groupId = dict[@"iad-adgroup-id"];
                NSString *keyword = dict[@"iad-keyword"];
                if (groupId && keyword) {
                    NSString *lastGroupId = [[NSUserDefaults standardUserDefaults] objectForKey:kLastSearchGroupId];
                    BOOL noLastGroup = (lastGroupId == nil);
                    BOOL diff = ![groupId isEqualToString:lastGroupId];
                    if (noLastGroup || diff) {
                        triggerEventStr(@"keyword_install_count", keyword);
                        [[NSUserDefaults standardUserDefaults] setObject:groupId forKey:kLastSearchGroupId];
                        [[NSUserDefaults standardUserDefaults] synchronize];
                    }
                }

                [[NSUserDefaults standardUserDefaults] setObject:dict forKey:kSearchAd];
                [[NSUserDefaults standardUserDefaults] synchronize];
            });
        }];
    }
}


/// 归因API统计购买
+ (void)iAdPurchase {
    
    NSDictionary *dic = [[NSUserDefaults standardUserDefaults] objectForKey:kSearchAd];
    if (dic) {
        NSString *keyword = dic[@"iad-keyword"];
        if (keyword) {
            triggerEventStr(@"keyword_buy_count", keyword);
        }
    }
}


#pragma mark- Facebook统计

/// 初始化Facebook SDK
+ (void)facebookSDKApplication:(UIApplication *)application options:(NSDictionary *)launchOptions {
    [[FBSDKApplicationDelegate sharedInstance] application:application
                             didFinishLaunchingWithOptions:launchOptions];
}

/// 活跃Facebook SDK(一般不需要调用, SDK会自己调用)
+ (void)facebookActivateApp {
    [FBSDKAppEvents activateApp];
}

/// 处理application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options这个方法时, 调用
/// if ([url.scheme hasPrefix:@"fb"]) 需提前判断下
+ (BOOL)facebookHandleUrl:(NSURL *)url
              application:(UIApplication *)application
                  options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
    
    BOOL handled = [[FBSDKApplicationDelegate sharedInstance] application:application openURL:url options:options];
    return handled;
}

/**
 Facebook统计, 外部购买时调用, 外部不用区分是否是续订型
 */
+ (void)facebookPurchaseWithProduct:(SKProduct *)product {
    
    double localPrice = 0;
    localPrice = [product.price doubleValue];
    
    NSString *currency = nil;
    if (@available(iOS 10.0, *)) {
        currency = [product.priceLocale currencyCode];
    } else {
        currency = [product.priceLocale objectForKey:NSLocaleCurrencyCode];
    }
    
    NSString *productId = product.productIdentifier;
    
    /// 如果是试用
    if ([productId hasSuffix:@"_Trial"]) {
        [self facebookAddedToCartEvent:@""
                             contentId:productId
                           contentType:@""
                              currency:currency
                            valueToSum:localPrice];
    } else {
        [self facebookPurchaseEvent:@""
                          contentId:productId
                        contentType:@""
                           currency:currency
                         valueToSum:localPrice];
    }
}


/**
 Facebook统计, "添加到购物车"
 某个内购有试用时, 才使用该事件记录, 其他内购不使用这个事件
 */
+ (void)facebookAddedToCartEvent:(NSString *)contentData
                       contentId:(NSString *)contentId
                     contentType:(NSString *)contentType
                        currency:(NSString *)currency
                      valueToSum:(double)price {
    
    if (contentData == nil) {
        contentData = @"";
    }
    if (contentId == nil) {
        contentId = @"";
    }
    if (contentType == nil) {
        contentType = @"";
    }
    if (currency == nil) {
        currency = @"";
    }
    
    NSDictionary *params =
    @{
      FBSDKAppEventParameterNameContent : contentData,
      FBSDKAppEventParameterNameContentID : contentId,
      FBSDKAppEventParameterNameContentType : contentType,
      FBSDKAppEventParameterNameCurrency : currency
      };
    
    [FBSDKAppEvents logEvent:FBSDKAppEventNameAddedToCart
                  valueToSum:price
                  parameters:params];
}


/**
 Facebook统计, "购买"
 该事件记录购买消耗性内购, 没有试用的自动订阅等, 和知道某个试用转成付费后, 用该事件记录
 */
+ (void)facebookPurchaseEvent:(NSString *)contentData
                    contentId:(NSString *)contentId
                  contentType:(NSString *)contentType
                     currency:(NSString *)currency
                   valueToSum:(double)price {
    
    if (contentData == nil) {
        contentData = @"";
    }
    if (contentId == nil) {
        contentId = @"";
    }
    if (contentType == nil) {
        contentType = @"";
    }
    if (currency == nil) {
        currency = @"";
    }
    
    NSDictionary *params =
    @{
      FBSDKAppEventParameterNameContent : contentData,
      FBSDKAppEventParameterNameContentID : contentId,
      FBSDKAppEventParameterNameContentType : contentType,
      FBSDKAppEventParameterNameCurrency : currency
      };
    
    [FBSDKAppEvents logPurchase:price
                       currency:currency
                     parameters:params];
}


/**
 Facebook统计, "试用转付费", 对应Facebook的 "开始结账" 事件
 FBSDKAppEventNameInitiatedCheckout
 某个试用转成付费后, 用该事件记录
 */
+ (void)facebookTrialToPayEvent:(NSString *)contentData
                      contentId:(NSString *)contentId
                    contentType:(NSString *)contentType
                       currency:(NSString *)currency
                     valueToSum:(double)price {
    
    if (contentData == nil) {
        contentData = @"";
    }
    if (contentId == nil) {
        contentId = @"";
    }
    if (contentType == nil) {
        contentType = @"";
    }
    if (currency == nil) {
        currency = @"";
    }
    
    NSDictionary *params =
    @{
      FBSDKAppEventParameterNameContent : contentData,
      FBSDKAppEventParameterNameContentID : contentId,
      FBSDKAppEventParameterNameContentType : contentType,
      FBSDKAppEventParameterNameCurrency : currency
      };
    
    [FBSDKAppEvents logEvent:FBSDKAppEventNameInitiatedCheckout
                  valueToSum:price
                  parameters:params];
}

#pragma mark- Adjust

/// Adjust 配置
+ (void)adjustLaunching {
    
#ifdef AdjustAppToken
    
    NSString *yourAppToken = AdjustAppToken;
    
#if defined(DEBUG) || defined(ForTest)
    ADJConfig *adjustConfig = [ADJConfig configWithAppToken:yourAppToken environment:ADJEnvironmentSandbox];
    [adjustConfig setLogLevel:ADJLogLevelVerbose];  // enable all logging
#else
    ADJConfig *adjustConfig = [ADJConfig configWithAppToken:yourAppToken environment:ADJEnvironmentProduction];
#endif
    [adjustConfig setSendInBackground:YES];
    [Adjust appDidLaunch:adjustConfig];
#else
    LogInfo(@"‼️‼️‼️‼️❌❌❌❌ 如有使用Adjust, 请在 Constant.h 配置 AdJustAppToken");
#endif

}

/**
 收入跟踪
 */
+ (void)adjustSetRevenue:(double)amount
                currency:(nonnull NSString *)currency {
    
#ifdef AdjustRevenueEvent
    ADJEvent *event = [ADJEvent eventWithEventToken:AdjustRevenueEvent];
    [event setRevenue:amount currency:currency];
    [Adjust trackEvent:event];
#endif
    
}


/**
 事件跟踪
 
 @param eventToken 该事件的token, 每个app可能不同
 */
+ (void)adjustEventWithEventToken:(NSString *)eventToken {
    ADJEvent *event = [ADJEvent eventWithEventToken:eventToken];
    [Adjust trackEvent:event];
}



#pragma mark- Private

///// 购买完成后调用, 内部处理统计
+ (void)purchaseWithProductId:(NSString *)productId
                     currency:(NSString *)currency
                   valueToSum:(double)price {
    
    /// facebook平台
    [self facebookPurchaseEvent:@""
                      contentId:productId
                    contentType:@""
                       currency:currency
                     valueToSum:price];
    
    /// 归因平台
    [self iAdPurchase];
    
    /// Adjust平台
#ifdef AdjustRevenueEvent
    [self adjustSetRevenue:price currency:currency];
#endif
}


/// 点击购买按钮事件(加入购物车)
+ (void)addedToCartWithProductId:(NSString *)productId
                        currency:(NSString *)currency
                      valueToSum:(double)price {
    
    [self facebookAddedToCartEvent:@""
                         contentId:productId
                       contentType:@""
                          currency:currency
                        valueToSum:price];
    
#ifdef AdjustAddedToCartEvent
    [self adjustEventWithEventToken:AdjustAddedToCartEvent];
#endif
}

/// 付费转试用
+ (void)trialToPayWithProductId:(NSString *)productId
                       currency:(NSString *)currency
                     valueToSum:(double)price {
    
    [self facebookTrialToPayEvent:@""
                        contentId:productId
                      contentType:@""
                         currency:currency
                       valueToSum:price];
    
#ifdef AdjustTrailToPayEvent
    [self adjustEventWithEventToken:AdjustTrailToPayEvent];
#endif
}

@end
