//
//  MJViewController.m
//  MJAnalyse
//
//  Created by yangyu2010@aliyun.com on 09/14/2018.
//  Copyright (c) 2018 yangyu2010@aliyun.com. All rights reserved.
//

#import "MJViewController.h"
//#import "MJAnalyse.h"
#import <MJAnalyse/MJAnalyse.h>


@interface MJViewController ()

@end

@implementation MJViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

//    [MJAnalyse analysePurchaseWithStatus:MJAnalysePurchased productId:@"com.arescrowd.InstaCaller.vip_OneNumber" price:0.99];

    [MJAnalyse analysePurchaseWithStatus:MJAnalysePurchasedFailure productId:@"vip_OneNumber" price:0];

    
//    [MJAnalyse analysePurchaseWithStatus:MJAnalysePurchasedFailure productId:@"" price:0];
//    [MJAnalyse analysePurchaseWithStatus:MJAnalysePurchasedFailure productId:nil price:0];

    
    
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
