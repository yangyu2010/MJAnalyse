//
//  MJAnalyse+Networking.h
//  MJAnalyse_Example
//
//  Created by Yang Yu on 2019/8/16.
//  Copyright © 2019 yangyu2010@aliyun.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MJAnalyse.h"

NS_ASSUME_NONNULL_BEGIN

@interface MJAnalyse (Networking)

/// 应用安装
+ (void)appInstallAnalyse;
/// 应用启动
+ (void)appLaunchAnalyse;
/// 事件记录
+ (void)recordAnalyseWith:(MJAnalyseEventCode)type
              recordValue:(NSString *)recordValue;


@end

NS_ASSUME_NONNULL_END
