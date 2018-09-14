//
//  MJAnalyse.m
//  Pods
//
//  Created by Yang Yu on 2018/9/14.
//

#import "MJAnalyse.h"
#import <ModuleCapability.h>

#import <iAd/iAd.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <Adjust/Adjust.h>

/// 存储归因
#define kLastSearchGroupId  @"kLastSearchGroupId"
/// 存储归因广告信息本地key
#define kSearchAd           @"kSearchAd"

@implementation MJAnalyse

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
 Facebook统计, "添加到购物车"
 某个内购有试用时, 才使用该事件记录, 其他内购不使用这个事件
 */
+ (void)facebookAddedToCartEvent:(NSString *)contentData
                       contentId:(NSString *)contentId
                     contentType:(NSString *)contentType
                        currency:(NSString *)currency
                      valueToSum:(double)price {
    
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


#pragma mark- Adjust

/// Adjust 配置
+ (void)adjustLaunching {
    
#ifdef AdJustAppToken
    
    NSString *yourAppToken = AdJustAppToken;
    
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
                currency:(nonnull NSString *)currency
              eventToken:(NSString *)eventToken {
    
    if (eventToken.length == 0) {
        return ;
    }

    ADJEvent *event = [ADJEvent eventWithEventToken:eventToken];
    [event setRevenue:amount currency:currency];
}


/**
 事件跟踪
 
 @param eventToken 该事件的token, 每个app可能不同
 */
+ (void)adjustEventWithEventToken:(NSString *)eventToken {
    ADJEvent *event = [ADJEvent eventWithEventToken:eventToken];
    [Adjust trackEvent:event];
}

@end
