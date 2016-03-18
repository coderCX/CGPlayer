//
//  CGPlayer.h
//  smallPalyer
//
//  Created by ChengXi on 16/3/9.
//  Copyright © 2016年 ChengXi. All rights reserved.
//  简书：http://www.jianshu.com/users/a72b5c006dd1/latest_articles

#import <UIKit/UIKit.h>
#import "VMediaPlayer.h"

//点击全屏或缩小通知
#define kNOTIFYCATIONFULLSCREEN (@"kNOTIFYCATIONFULLSCREEN")

#define AFTER(time, block) dispatch_after(dispatch_time(DISPATCH_TIME_NOW, time*NSEC_PER_SEC), dispatch_get_main_queue(), block)
@protocol CGPlayerDelegate <NSObject>

/**
 *  关闭播放器代理
 */
- (void) closeCGPlayer;

/**
    播放器单击手势
 */
- (void) tapOneTapGester;

@end

/* 底部操作条高度 **/
static const NSInteger bottomDockH = 35;

/* 底部操作条延时进入透明的时间阀 **/
static const NSInteger bottomDockHide = 5.f;

@interface CGPlayer : UIView <VMediaPlayerDelegate>

/* 
 代理协议 
 **/
@property (nonatomic, weak) id<CGPlayerDelegate> delegate;

/**
 *  是否进入全屏状态
 */
@property(nonatomic,assign) BOOL isFullscreen;

/**
 *  播放器底部操作条
 */
@property(nonatomic,strong) UIView *bottomDockView;

/** 
 *快速初始化
 */
- (id)initWithFrame:(CGRect)frame videoURL:(NSString *)videoURL;

/**
 快速重置播放器
 可以在无需alloc一个新的播放器对象之前清除上一播放器对象残留数据
 */
- (void) resetVedio;

/**
 设置播放器资源
 */
- (void) setDataSource:(NSString *)vedioUrl;

/**
 设置播放器资源(注册播放器)
 播放视屏之前的资源准备，完成以后会调用 mediaPlayer:(VMediaPlayer *)player didPrepared:(id)arg代理 开始播放
 */
- (void) prepareAsyncVedio;

/**
 开始播放视屏
 */
- (void) startVedio;

/**
 暂停视屏播放
 */
- (void) pauseVedio;

/** 
 关闭播放器
 */
- (void)close;

/**
 取消注册播放器（资源回收）
 */
-(BOOL)unSetupPlayer;

/**
 重新设置播放器Frame
 */
- (void) setVedioFrame:(CGRect)frame;

/**
   操作条延时透明
*/
- (void) hideBottomDockView;

@end