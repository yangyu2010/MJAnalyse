# MJAnalyse

[![CI Status](https://img.shields.io/travis/yangyu2010@aliyun.com/MJAnalyse.svg?style=flat)](https://travis-ci.org/yangyu2010@aliyun.com/MJAnalyse)
[![Version](https://img.shields.io/cocoapods/v/MJAnalyse.svg?style=flat)](https://cocoapods.org/pods/MJAnalyse)
[![License](https://img.shields.io/cocoapods/l/MJAnalyse.svg?style=flat)](https://cocoapods.org/pods/MJAnalyse)
[![Platform](https://img.shields.io/cocoapods/p/MJAnalyse.svg?style=flat)](https://cocoapods.org/pods/MJAnalyse)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

MJAnalyse is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'MJAnalyse'
```

## Author

yangyu2010@aliyun.com, yangyu2010@aliyun.com

## License

MJAnalyse is available under the MIT license. See the LICENSE file for more info.


## Use

1. 初始化模块

		/// 初始化统计模块, 包括初始化 iad Facebook adjust三个模块
		+ (void)configWithApplication:(UIApplication *)application
		                      options:(NSDictionary *)launchOptions;


2. 统计内购

		// 点击订阅按钮, 统计事件是 发起结账
	    [MJAnalyse analysePurchaseWithStatus:MJAnalyseInitiatedCheckout productId:@"your productId" price:9.9];
	    [[IAPManager sharedInstance] purchaseItem:@"your productId" completion:^(BOOL isSucceed, id message, id result) {
	        if (isSucceed == NO) {
	            return ;
	        }
	        // 如果成功后
	        
	        // 购买成功，不管是试用成功、订阅成功或者续订成功 统计事件是 购买
	        [MJAnalyse analysePurchaseWithStatus:MJAnalysePurchased productId:@"your productId" price:9.9];
	        
	        if ([[IAPManager sharedInstance] isTrialFor:@"your productId"]) {
	            // 订阅试用商品 统计事件是 开始试用
	            [MJAnalyse analysePurchaseWithStatus:MJAnalyseStartTrial productId:@"your productId" price:9.9];
	        } else {
	            // 订阅非试用商品或者试用商品试用期过后已正常扣款 统计事件是 订阅
	            [MJAnalyse analysePurchaseWithStatus:MJAnalyseSubscribe productId:@"your productId" price:9.9];
	        }
	    }];
	    
3. 统计事件

		/// 统计事件 会统计到Facebook Firebase
		+ (void)logEvent:(NSString *)event parameters:(NSDictionary *)parameters;
