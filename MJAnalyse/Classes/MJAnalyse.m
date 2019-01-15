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

#import <Firebase/Firebase.h>
#import <FirebaseAnalytics/FirebaseAnalytics/FIRAnalytics.h>

#ifdef MODULE_WEB_INTERFACE
#import <WebInterface/WebInterface.h>
#endif

#ifdef HEADER_ANALYSE
#import HEADER_ANALYSE
#endif

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
    [self firebaseConfig];
}


/// 记录内购相关的统计 推荐使用
+ (void)analysePurchaseWithStatus:(MJAnalysePurchaseStatus)status
                        productId:(NSString *)productId
                            price:(double)price {

    [self analysePurchaseWithStatus:status
                          productId:productId
                           currency:@""
                              price:price];
}


/// 统计事件 会统计到Facebook Firebase
+ (void)logEvent:(NSString *)event parameters:(NSDictionary *)parameters {
    [self facebookLogEvent:event parameters:parameters];
    [self firebaseLogEvent:event parameters:parameters];
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
                        [self logEvent:@"keyword_install_count" parameters:dict];
                        [[NSUserDefaults standardUserDefaults] setObject:groupId forKey:kLastSearchGroupId];
                        [[NSUserDefaults standardUserDefaults] synchronize];
                   
#ifdef MODULE_WEB_INTERFACE
                        [WebInterface startRequest:@"MJAnalyse.iad" describe:@"MJAnalyse.iad" body:attributionDetails completion:nil];
#endif
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



#pragma mark- Firebase

+ (void)firebaseConfig {
    [FIRApp configure];
}


+ (void)firebaseLogEvent:(NSString *)event parameters:(NSDictionary *)parameters {
    [FIRAnalytics logEventWithName:event parameters:parameters];
}


#pragma mark- Facebook private

/// Facebook统计事件
+ (void)facebookLogEvent:(NSString *)event
              parameters:(NSDictionary *)parameters {
    
    [FBSDKAppEvents logEvent:event parameters:parameters];
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
 Facebook统计, "开始结账" 事件
 FBSDKAppEventNameInitiatedCheckout
 某个试用转成付费后, 用该事件记录
 */
+ (void)facebookInitiatedCheckout:(NSString *)contentData
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



#pragma mark- Private

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
    else if (status == MJAnalysePurchaseInitiatedCheckout) {
        /// 开始结账
        [self trialToPayWithProductId:productId currency:currency valueToSum:price];
    }
}

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
    
}

/// 开始结账
+ (void)trialToPayWithProductId:(NSString *)productId
                       currency:(NSString *)currency
                     valueToSum:(double)price {
    
    [self facebookInitiatedCheckout:@""
                          contentId:productId
                        contentType:@""
                           currency:currency
                         valueToSum:price];
    
}



@end
