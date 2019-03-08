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

#ifdef MODULE_WEB_INTERFACE
#import <WebInterface/WebInterface.h>
#endif

#if __has_include(<Firebase/Firebase.h>)
#import <Firebase/Firebase.h>
#endif

#if __has_include(<FirebaseAnalytics/FirebaseAnalytics/FIRAnalytics.h>)
#import <FirebaseAnalytics/FirebaseAnalytics/FIRAnalytics.h>
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
+ (void)analysePurchaseWithStatus:(MJAnalyseStatus)status
                        productId:(NSString *)productId
                            price:(double)price {

    if (productId.length == 0) {
        return ;
    }
    
    [self analysePurchaseWithStatus:status
                          productId:productId
                           currency:@""
                              price:price];
    
    [self logEventPurchaseWithStatus:status
                           productId:productId
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
#if __has_include(<Firebase/Firebase.h>)
    [FIRApp configure];
#endif
}


+ (void)firebaseLogEvent:(NSString *)event parameters:(NSDictionary *)parameters {
#if __has_include(<FirebaseAnalytics/FirebaseAnalytics/FIRAnalytics.h>)
    [FIRAnalytics logEventWithName:event parameters:parameters];
#endif
}


#pragma mark- Facebook private

/// Facebook统计事件
+ (void)facebookLogEvent:(NSString *)event
              parameters:(NSDictionary *)parameters {
    
    [FBSDKAppEvents logEvent:event parameters:parameters];
}

/**
 Facebook统计, "开始试用"
 订阅试用商品成功
 */
+ (void)facebookStartTrialEvent:(NSString *)contentData
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

        [FBSDKAppEvents logEvent:FBSDKAppEventNameStartTrial
                      valueToSum:price
                      parameters:params];

}



/**
 Facebook统计, "购买"
 订阅非试用商品或者试用商品试用期过后已正常扣款
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

//    FBSDKAppEventNamePurchased
    [FBSDKAppEvents logPurchase:price
                       currency:currency
                     parameters:params];
}


/**
 Facebook统计, "发起结账" 事件
 FBSDKAppEventNameInitiatedCheckout
 点击订阅按钮, 用该事件记录
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

/**

 */
+ (void)facebookSubscribeEvent:(NSString *)contentData
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

    [FBSDKAppEvents logEvent:FBSDKAppEventNameSubscribe
                  valueToSum:price
                  parameters:params];
}


#pragma mark- Private

/// 手动打点记录内购相关
+ (void)logEventPurchaseWithStatus:(MJAnalyseStatus)status
                         productId:(NSString *)productId
                             price:(double)price {
    
    NSString *logEvent = nil;
    switch (status) {
        case MJAnalyseInitiatedCheckout:
            logEvent = @"Checkout";
            break;
        case MJAnalyseStartTrial:
            logEvent = @"StartTrial";
            break;
        case MJAnalyseSubscribe:
            logEvent = @"Subscribe";
            break;
        case MJAnalysePurchased:
            logEvent = @"Purchased";
            break;
        case MJAnalysePurchasedFailure:
            logEvent = @"PurchasedFailure";
            break;
        default:
            break;
    }
    
    logEvent = [[productId componentsSeparatedByString:@"."].lastObject stringByAppendingFormat:@"_%@", logEvent];
    NSDictionary *parameters = @{
                                 @"price": [NSNumber numberWithDouble:price],
                                 };
    
    [self logEvent:logEvent parameters:parameters];
}

/// 记录内购相关的统计
+ (void)analysePurchaseWithStatus:(MJAnalyseStatus)status
                        productId:(NSString *)productId
                         currency:(NSString *)currency
                            price:(double)price {
    
    if (status == MJAnalyseInitiatedCheckout) {
        // 发起结账
        [self initiatedCheckoutWithProductId:productId currency:currency valueToSum:price];
    }
    else if (status == MJAnalyseStartTrial) {
        // 开始试用
        [self startTrialWithProductId:productId currency:currency valueToSum:price];
    }
    else if (status == MJAnalyseSubscribe) {
        // 订阅
        [self subscribeWithProductId:productId currency:currency valueToSum:price];
    }
    else if (status == MJAnalysePurchased) {
        // 购买
        [self purchaseWithProductId:productId currency:currency valueToSum:price];
    }
}




/// 发起结账
+ (void)initiatedCheckoutWithProductId:(NSString *)productId
                              currency:(NSString *)currency
                            valueToSum:(double)price {
    
    [self facebookInitiatedCheckout:@""
                          contentId:productId
                        contentType:@""
                           currency:currency
                         valueToSum:price];
    
}

/// 开始试用
+ (void)startTrialWithProductId:(NSString *)productId
                       currency:(NSString *)currency
                     valueToSum:(double)price {
    
    [self facebookStartTrialEvent:@""
                        contentId:productId
                      contentType:@""
                         currency:currency
                       valueToSum:price];
    
}

/// 订阅
+ (void)subscribeWithProductId:(NSString *)productId
                      currency:(NSString *)currency
                    valueToSum:(double)price {

    [self facebookSubscribeEvent:@""
                        contentId:productId
                      contentType:@""
                         currency:currency
                       valueToSum:price];
    
}

/// 购买
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


@end
