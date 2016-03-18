//
//  VedioList.m
//  smallPalyer
//
//  Created by ChengXi on 16/3/9.
//  Copyright © 2016年 ChengXi. All rights reserved.
//

#import "VedioList.h"
#import "MJExtension.h"

@implementation VedioList

+ (NSDictionary *)mj_replacedKeyFromPropertyName{
    return @{@"vedioDescription":@"description"};
}

@end
