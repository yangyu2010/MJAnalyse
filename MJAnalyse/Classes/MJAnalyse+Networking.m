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

static NSString *const API_ANALYSE_APPINSTALL = @"Analyse.appInstall";
static NSString *const API_ANALYSE_APPLAUNCH  = @"Analyse.appLaunch";
static NSString *const API_ANALYSE_RECORD     = @"Analyse.record";


@implementation MJAnalyse (Networking)

#pragma mark- Public

/// 应用安装
+ (void)appInstallAnalyse {
    NSInteger activeCount = [self getActiveCount];
    if (activeCount == NSNotFound) {
        return;
    }
    
    [self appInstallNetworkingWith:activeCount];
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
    /**
     MJAnalyseUVLaunchEvent,             ///< 启动App人数
     MJAnalyseUVHomeEvent,               ///< 到达首页人数
     MJAnalyseUVPaidEvent,               ///< 付费用户数
     MJAnalyseHomeEvent,                 ///< 到达首页人次
     MJAnalysePaymentCreatEvent,         ///< 点击购买人次 购买相关的recordValue传商品ID
     MJAnalysePaymentSucceedEvent,       ///< 购买成功人次
     MJAnalysePaymentSucceedTrialEvent,  ///< 购买成功试用人次
     MJAnalysePaymentFailedEvent,        ///< 购买失败人次
     */
    
    NSString *eventCode = nil;
    switch (type) {
        case MJAnalyseUVLaunchEvent:
            eventCode = @"UV_Launch";
            break;
        case MJAnalyseUVHomeEvent:
            eventCode = @"UV_Home";
            break;
        case MJAnalyseUVPaidEvent:
            eventCode = @"UV_Paid";
            break;
        case MJAnalyseHomeEvent:
            eventCode = @"Home";
            break;
        case MJAnalysePaymentCreatEvent:
            eventCode = @"PaymentCreate";
            break;
        case MJAnalysePaymentSucceedEvent:
            eventCode = @"PaymentSucceed";
            break;
        case MJAnalysePaymentSucceedTrialEvent:
            eventCode = @"PaymentSucceedTrial";
            break;
        case MJAnalysePaymentFailedEvent:
            eventCode = @"PaymentFailed";
            break;
        default:
            break;
    }
    
    [self recordNetworkingWith:eventCode recordValue:recordValue];
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





