//
//  ViewCellModel.m
//  smallPalyer
//
//  Created by ChengXi on 16/3/9.
//  Copyright © 2016年 ChengXi. All rights reserved.
//

#import "ViewCellModel.h"
#import "MJExtension.h"
#import "VedioList.h"

@implementation ViewCellModel

+ (NSDictionary *)mj_objectClassInArray{
    return @{@"videoList":[VedioList class]};
}

@end
