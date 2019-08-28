//
//  MJAnalyse+Networking.m
//  MJAnalyse_Example
//
//  Created by Yang Yu on 2019/8/16.
//  Copyright © 2019 yangyu2010@aliyun.com. All rights reserved.
//

#import "MJAnalyse+Networking.h"
#import <WebInterface.h>

#define kMJAnalyseActiveCount           @"analyseActiveCount"
#define kMJAnalyseLastLaunchTime        @"analyseLastLaunchTime"
#define kMJAnalyseLaunchTimeInterval    (12 * 60 * 60)

/// 最后一次推广的app
#define kAppInstallDeviceInfo   @"AppInstallDeviceInfo"
/// 首次推广激活需要次数
#define ANALYTICS_INSTALL_ACTIVE_COUNT 10
#ifndef SERVER_API_APP_INSTALL_RECORD
#define SERVER_API_APP_INSTALL_RECORD   @"Analyse.appInstall"
#endif

/// 到达首页人数
#define kAnalyseEventUVHome             @"UV_Home"
/// 到达首页人次
#define kAnalyseEventHome               @"Home"
/// 点击购买人次
#define kAnalyseEventPaymentCreat       @"PaymentCreate"
/// 购买成功人次
#define kAnalyseEventPaymentSucceed       @"PaymentSucceed"
/// 购买成功试用人次
#define kAnalyseEventPaymentSucceedTrial       @"PaymentSucceedTrial"
/// 购买成功试用人次
#define kAnalyseEventPaymentFailed       @"PaymentFailed"



static NSString *const API_ANALYSE_APPINSTALL = @"Analyse.appInstall";
static NSString *const API_ANALYSE_APPLAUNCH  = @"Analyse.appLaunch";
static NSString *const API_ANALYSE_RECORD     = @"Analyse.record";


@implementation MJAnalyse (Networking)

#pragma mark- Public

/// 应用安装
+ (void)appInstallAnalyse {
//    NSInteger activeCount = [self getActiveCount];
//    if (activeCount == NSNotFound) {
//        return;
//    }
//    [self appInstallNetworkingWith:activeCount];

#ifdef MODULE_WEB_INTERFACE
    // 没有网络接口模块，可以不调用
    // 检查deviceUUID和deviceIDFA
#ifdef MODULE_DEVICE
    NSString *deviceUUID = [MJDevice deviceUUID];
#else
    NSString *deviceUUID = [[UIDevice currentDevice].identifierForVendor UUIDString];
#endif
    
#ifdef MODULE_AD_SUPPORT
    NSString *deviceIDFA = [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
#else
    NSString *deviceIDFA = @"00000000-0000-0000-0000-000000000000";
#endif
    // 获取本地保存的记录
    NSData *deviceData = keychainDefaultSharedObjectForKey(kAppInstallDeviceInfo);
    NSInteger *activeCount = 1;
    if (deviceData) {
        NSDictionary *deviceInfo = [NSJSONSerialization JSONObjectWithData:deviceData options:NSJSONReadingMutableLeaves error:nil];
        if ([deviceInfo[@"deviceUUID"] isEqualToString:deviceUUID] && [deviceInfo[@"deviceIDFA"] isEqualToString:deviceIDFA]) {
            NSInteger curActiveCount = [deviceInfo[@"activeCount"] integerValue];
            if (curActiveCount >= ANALYTICS_INSTALL_ACTIVE_COUNT) {
                return;
            }
        }
        activeCount = [deviceInfo[@"activeCount"] integerValue] + 1;
    }
    
    NSString *action = SERVER_API_APP_INSTALL_RECORD;
    NSDictionary *sendData = [NSDictionary dictionaryWithObjectsAndKeys:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"], @"appBundleId", [NSNumber numberWithInteger:activeCount], @"activeCount", nil];
    [WebInterface startRequest:action describe:@"App install record" body:sendData completion:^(BOOL isSucceed, NSString *message, id data) {
        if (isSucceed) {
            NSDictionary *saveData = [NSDictionary dictionaryWithObjectsAndKeys:deviceUUID, @"deviceUUID", deviceIDFA, @"deviceIDFA", [NSNumber numberWithInteger:activeCount], @"activeCount", nil];
            keychainSetDefaultSharedObject([NSJSONSerialization dataWithJSONObject:sendData options:NSJSONWritingPrettyPrinted error:nil], kAppInstallDeviceInfo);
        }
    }];
#endif

}

/// 应用启动
+ (void)appLaunchAnalyse {
    if ([self checkLastLaunchTime]) {
        [self appLaunchNetworking];
    }
    
}


/// 事件记录
+ (void)recordAnalyseWith:(MJAnalyseEventCode)type
              recordValue:(NSString *)recordValue {

//    MJAnalyseEventHome,                 ///< 到达首页人次
//    MJAnalyseEventPaymentCreat,         ///< 点击购买人次 购买相关的recordValue传商品ID
//    MJAnalyseEventPaymentSucceed,       ///< 购买成功人次
//    MJAnalyseEventPaymentSucceedTrial,  ///< 购买成功试用人次
//    MJAnalyseEventPaymentFailed,        ///< 购买失败人次
//    MJAnalyseEventPaymentIAP            ///< 内购事件人次 IAP_* (完整的商品ID)

    
    switch (type) {
        case MJAnalyseEventHome: {
            [self recordNetworkingWith:@"UV_Home" recordValue:recordValue];
            [self recordNetworkingWith:@"Home" recordValue:recordValue];
            }
            break;
        case MJAnalyseEventPaymentCreat: {
            [self recordNetworkingWith:@"PaymentCreate" recordValue:recordValue];
        }
            break;
        case MJAnalyseEventPaymentSucceed: {
            [self recordNetworkingWith:@"PaymentSucceed" recordValue:recordValue];
        }
            break;
        case MJAnalyseEventPaymentSucceedTrial: {
            [self recordNetworkingWith:@"PaymentSucceedTrial" recordValue:recordValue];
        }
            break;
        case MJAnalyseEventPaymentFailed: {
            [self recordNetworkingWith:@"PaymentFailed" recordValue:recordValue];
            NSString *eventCode = [NSString stringWithFormat:@"IAP_%@", recordValue];
            [self recordNetworkingWith:eventCode recordValue:@"1"];
        }
            break;
        case MJAnalyseEventNonSubscriptionSucceed: {
            NSString *eventCode = [NSString stringWithFormat:@"IAP_%@", recordValue];
            [self recordNetworkingWith:eventCode recordValue:@"0"];
        }
            break;
        default:
            break;
    }
}


#pragma mark- Private

/// 获取Bundle ID
static NSString *_appBundleId = nil;
+ (NSString *)getAppBundleId {
    if (_appBundleId) {
        return _appBundleId;
    }
    _appBundleId = [[NSBundle mainBundle] bundleIdentifier];
    return _appBundleId;
}


/// 获取启动次数
/// 如果返回NSNotFound 表示超过了10次 不需要再调用服务器接口了
+ (NSInteger)getActiveCount {
    NSInteger activeCount = [[NSUserDefaults standardUserDefaults] integerForKey:kMJAnalyseActiveCount];
    if (activeCount == 0) {
        activeCount = 1;
    }
    if (activeCount > 10) {
        activeCount = NSNotFound;
    } else {
        [[NSUserDefaults standardUserDefaults] setInteger:(activeCount + 1) forKey:kMJAnalyseActiveCount];
    }
    return activeCount;
}

/// 是否需要调用启动的接口
+ (BOOL)checkLastLaunchTime {
    NSTimeInterval lastLaunchTime = [[NSUserDefaults standardUserDefaults] doubleForKey:kMJAnalyseLastLaunchTime];
    if (lastLaunchTime == 0) {
        return YES;
    }
    
    NSDate *lastLaunchDate = [NSDate dateWithTimeIntervalSince1970:lastLaunchTime];
    NSTimeInterval differenceValue = [[NSDate date] timeIntervalSinceDate:lastLaunchDate];
    if (differenceValue > kMJAnalyseLaunchTimeInterval) {
        return YES;
    }
    
    return NO;
}

/// 更新调用启动时间
+ (void)updateLastLaunchTime {
    NSTimeInterval curTime = [[NSDate date] timeIntervalSince1970];
    [[NSUserDefaults standardUserDefaults] setDouble:curTime forKey:kMJAnalyseLastLaunchTime];
}


#pragma mark- Networking

+ (void)appInstallNetworkingWith:(NSInteger)activeCount {
    NSMutableDictionary *body = [NSMutableDictionary dictionaryWithCapacity:2];
    [body setValue:[NSNumber numberWithInteger:activeCount] forKey:@"activeCount"];
    [body setValue:[self getAppBundleId] forKey:@"appBundleId"];
    
    [self startRequest:API_ANALYSE_APPINSTALL describe:API_ANALYSE_APPINSTALL body:body completion:^(BOOL isSucceed, NSString *message, id data) {
        
    }];
}

+ (void)appLaunchNetworking {
    NSMutableDictionary *body = [NSMutableDictionary dictionaryWithCapacity:1];
    [body setValue:[self getAppBundleId] forKey:@"appBundleId"];
    
    [self startRequest:API_ANALYSE_APPLAUNCH describe:API_ANALYSE_APPLAUNCH body:body completion:^(BOOL isSucceed, NSString *message, id data) {
        if (isSucceed) {
            [self updateLastLaunchTime];
        }
    }];
}

+ (void)recordNetworkingWith:(NSString *)eventCode
                  recordValue:(NSString *)recordValue {
    if (eventCode.length == 0) {
        return;
    }
    
    NSMutableDictionary *body = [NSMutableDictionary dictionaryWithCapacity:2];
    [body setValue:eventCode forKey:@"eventCode"];
    [body setValue:recordValue forKey:@"recordValue"];

    [self startRequest:API_ANALYSE_RECORD describe:API_ANALYSE_RECORD body:body completion:^(BOOL isSucceed, NSString *message, id data) {

    }];
}

/// 普通请求 未授权
+ (void)startRequest:(NSString *)action
            describe:(NSString *)describe
                body:(NSDictionary *)body
          completion:(ActionCompleteBlock)completion {
    
    [WebInterface startRequest:action describe:describe body:body completion:completion];
}



@end





