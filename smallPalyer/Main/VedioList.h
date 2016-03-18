//
//  VedioList.h
//  smallPalyer
//
//  Created by ChengXi on 16/3/9.
//  Copyright © 2016年 ChengXi. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VedioList : NSObject

@property (nonatomic,copy) NSString *cover;
@property (nonatomic,copy) NSString *vedioDescription;
@property (nonatomic,assign) int length;
@property (nonatomic,copy) NSString *mp4_url;
@property (nonatomic,assign) int playCount;

@end
