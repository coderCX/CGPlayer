//
//  CGPlayer.m
//  smallPalyer
//
//  Created by ChengXi on 16/3/9.
//  Copyright © 2016年 ChengXi. All rights reserved.
//

#import "CGPlayer.h"
#import "Masonry.h"

@interface CGPlayer()

/**
 *  播放器核心类
 */
@property (nonatomic,strong) VMediaPlayer *mediaPlayer;

/**
 *  播放开始、暂停按钮
 */
@property(nonatomic,strong) UIButton *playOrPauseButton;

/**
 *  进度条
 */
@property(nonatomic,strong) UISlider *sliderView;

/**
 *  时间倒计时显示
 */
@property(nonatomic,strong) UILabel *dateLabel;

/**
 *  关闭按钮
 */
@property(nonatomic,strong) UIButton *closeButton;

/**
 *  全屏、缩小全屏按钮
 */
@property(nonatomic,strong) UIButton *fullScreenButton;

/**
 定时器
 */
@property (nonatomic,strong) NSTimer *timer;

/** 
 是否正在拖动进度条
 */
@property (nonatomic, assign) BOOL  progressDragging;

/** 
 logo 
 */
@property (nonatomic,strong) UIImageView *logoImageView;

/** 
  滚一下
 */
@property (nonatomic, strong) UIActivityIndicatorView  *activeView;

@end

#define CGPlayerBoundleName(file) [@"CGPlayer.bundle" stringByAppendingPathComponent:file]

@implementation CGPlayer

- (id)initWithFrame:(CGRect)frame videoURL:(NSString *)videoURL
{
    self.frame = frame;
    
    self =  [self initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor blackColor];
        
        [self initUI:videoURL];
        
        [self addRecognizer];
    }
    
    return self;
}

#pragma -mark 隐藏和显示所有UI
- (void) hideAllUI
{
    self.closeButton.hidden = YES;
    self.bottomDockView.hidden = YES;
}

- (void) showAllUI
{
    self.closeButton.hidden = NO;
    self.bottomDockView.hidden = NO;
}

#pragma -mark 初始化UI
- (void)initUI:(NSString *)videoURL
{
    //播放器对象
    self.mediaPlayer = ({
        VMediaPlayer *mediaPlayer = [VMediaPlayer sharedInstance];
        [mediaPlayer setupPlayerWithCarrierView:self withDelegate:self];
        [mediaPlayer setDataSource:[NSURL URLWithString:videoURL] header:nil];
        [mediaPlayer setVideoFillMode:VMVideoFillModeFit];
        [mediaPlayer prepareAsync];
        mediaPlayer;
    });
    
    //底部操作条
    self.bottomDockView = ({
        UIView *bottomDockView  = [[UIView alloc] init];
        bottomDockView.backgroundColor = [UIColor clearColor];
        [self addSubview:bottomDockView];
        [bottomDockView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.and.bottom.right.equalTo(self).offset(0);
            make.height.offset(bottomDockH);
        }];
        bottomDockView;
    });
    
    //播放暂停按钮
    self.playOrPauseButton = ({
        UIButton *playOrPauseButton = [self returnCommonButtonWithSelected:NO
                                           norlmalStateImage:CGPlayerBoundleName(@"play")
                                           selectedStateImage:CGPlayerBoundleName(@"pause")];
        [playOrPauseButton addTarget:self action:@selector(playButtonClick) forControlEvents:UIControlEventTouchUpInside];
        [playOrPauseButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(_bottomDockView);
            make.left.equalTo(_bottomDockView).offset(0);
            make.size.mas_equalTo(CGSizeMake(40,40));
        }];
        playOrPauseButton;
    });
    
    //全屏退出全屏按钮
    self.fullScreenButton = ({
        UIButton *fullScreenButton = [self returnCommonButtonWithSelected:NO
                                                         norlmalStateImage:CGPlayerBoundleName(@"fullscreen")
                                                        selectedStateImage:CGPlayerBoundleName(@"nonfullscreen")];
        [fullScreenButton addTarget:self action:@selector(fullScreenClick) forControlEvents:UIControlEventTouchUpInside];
        [fullScreenButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(_bottomDockView);
            make.right.equalTo(_bottomDockView).offset(0);
            make.size.mas_equalTo(CGSizeMake(40,40));
        }];
        fullScreenButton;
    });
    
    //进度条
    self.sliderView = ({
        UISlider *sliderView = [[UISlider alloc] init];
        sliderView.minimumValue = 0.0;
        [sliderView setThumbImage:[UIImage imageNamed:CGPlayerBoundleName(@"dot")]  forState:UIControlStateNormal];
        sliderView.minimumTrackTintColor = [UIColor redColor];
        sliderView.value = 0.0;//指定初始值
        [sliderView addTarget:self action:@selector(lightChange) forControlEvents:UIControlEventValueChanged|UIControlEventTouchDown];
        [sliderView addTarget:self action:@selector(lightDownUp) forControlEvents:UIControlEventTouchUpInside];
        [_bottomDockView addSubview:sliderView];
        [sliderView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(_bottomDockView);
            make.left.equalTo(_playOrPauseButton.mas_right).offset(5);
            make.right.equalTo(_fullScreenButton.mas_left).offset(5);
            make.height.offset(40);
        }];
        sliderView;
    });
    
    //关闭按钮
    self.closeButton = ({
        UIButton *closeButton = [[UIButton alloc] init];
        [closeButton setImage:[UIImage imageNamed:CGPlayerBoundleName(@"ic_close")] forState:UIControlStateNormal];
        [closeButton addTarget:self action:@selector(close) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:closeButton];
        [closeButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.mas_left).offset(5);
            make.top.equalTo(self.mas_top).offset(5);
            make.size.mas_equalTo(CGSizeMake(40,40));
        }];
        closeButton;
    });
    
    //倒计时
    self.dateLabel = ({
         UILabel *dateLabel = [[UILabel alloc] init];
        dateLabel.font = [UIFont systemFontOfSize:10];
        dateLabel.text = @"00:00:00 / -00:00:00";
        dateLabel.textColor = [UIColor whiteColor];
        [_bottomDockView addSubview:dateLabel];
        [dateLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(_bottomDockView.mas_top).offset(20);
            make.right.equalTo(_fullScreenButton.mas_left).offset(5);
            make.height.offset(15);
        }];
        dateLabel;
    });
    
    //logo
    self.logoImageView = ({
        UIImageView *logoImageView = [[UIImageView alloc] init];
        logoImageView.image = [UIImage imageNamed:CGPlayerBoundleName(@"nav_today_city")];
        [self addSubview:logoImageView];
        [logoImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(self);
            make.size.mas_equalTo(CGSizeMake(75,16));
        }];
        logoImageView;
    });
    
    //滚轮
    self.activeView = ({
        UIActivityIndicatorView *activeView = [[UIActivityIndicatorView alloc] init];
        [activeView setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleWhite];
        [activeView startAnimating];
        [self addSubview:activeView];
        [activeView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.logoImageView.mas_bottom).offset(8);
            make.centerX.equalTo(self);
        }];
        activeView;
    });
    
    
    [self hideAllUI];
}

#pragma -mark 添加手势
- (void)addRecognizer
{
    //添加单击手势
    UITapGestureRecognizer *oneRecognizer = [[UITapGestureRecognizer alloc] init];
    [oneRecognizer addTarget:self action:@selector(tapOneClick:)];
    [self addGestureRecognizer:oneRecognizer];
    
    //添加双击手势
    UITapGestureRecognizer *twoRecognizer = [[UITapGestureRecognizer alloc] init];
    [twoRecognizer addTarget:self action:@selector(tapTwoClick:)];
    [twoRecognizer setNumberOfTapsRequired:2];
    [self addGestureRecognizer:twoRecognizer];
    
    //解决单击和双击事件共存冲突
    [oneRecognizer requireGestureRecognizerToFail:twoRecognizer];
}

#pragma -mark 播放器代理
//    Vitamio播放器准备完成可以准备播放
- (void)mediaPlayer:(VMediaPlayer *)player didPrepared:(id)arg
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [player start];
        _playOrPauseButton.selected = YES;
        _dateLabel.text = @"00:00:00 / -00:00:00";
        [self startTimer];
        [self hideBottomDockView];
        [self showAllUI];
        self.logoImageView.hidden = YES;
        [self.activeView stopAnimating];
    });
    NSLog(@"-------播放器准备完毕");
}

//    Vitamio播放器播放完毕
- (void)mediaPlayer:(VMediaPlayer *)player playbackComplete:(id)arg
{
    //扫尾工作(清除上一次播放器的数据)
    [player reset];
    [self stopTimer];
    [self.delegate closeCGPlayer];
    NSLog(@"-------播放器播放完毕");
}

//    Vitamio播放器内部错误
- (void)mediaPlayer:(VMediaPlayer *)player error:(id)arg
{
    NSLog(@"-------播放器内部错误");
}

//   Vitamio播放器开始缓冲
- (void)mediaPlayer:(VMediaPlayer *)player bufferingStart:(id)arg
{
    self.progressDragging = YES;
    NSLog(@"-------播放器开始缓冲");
}

//  Vitamio播放器结束缓冲
- (void)mediaPlayer:(VMediaPlayer *)player bufferingEnd:(id)arg
{
    self.progressDragging = NO;
    NSLog(@"-------播放器结束缓冲");
}

//    Vitamio播放器 拖动进度条失败
- (void)mediaPlayer:(VMediaPlayer *)player notSeekable:(id)arg{
    self.progressDragging = NO;
}

#pragma -mark 外部控制播放器方法
/**
 快速重置播放器
 可以在无需alloc一个新的播放器对象之前清除上一播放器对象残留数据
 */
- (void) resetVedio
{
    [self hideAllUI];
    [_mediaPlayer reset];
}

/**
 设置播放器资源
 */
- (void) setDataSource:(NSString *)vedioUrl
{
    [_mediaPlayer setDataSource:[NSURL URLWithString:vedioUrl]];
}

/**
 设置播放器资源
 播放视屏之前的资源准备，完成以后会调用 mediaPlayer:(VMediaPlayer *)player didPrepared:(id)arg代理 开始播放
 */
- (void) prepareAsyncVedio
{
   [_mediaPlayer prepareAsync];
}

/**
 开始播放视屏
 
 */
- (void) startVedio
{
    self.logoImageView.hidden = NO;
    [self.activeView startAnimating];
    [_mediaPlayer start];
}

/**
 暂停视屏播放
 */
- (void) pauseVedio
{
    [_mediaPlayer pause];
}

- (BOOL) unSetupPlayer
{
    return [_mediaPlayer unSetupPlayer];
}

#pragma -mark 快速返回 按钮
- (UIButton *) returnCommonButtonWithSelected:(BOOL)selected norlmalStateImage:(NSString *)norlmalStateImage selectedStateImage:(NSString *)selectedStateImage{
    UIButton *tempButton = [[UIButton alloc] init];
    tempButton.selected = selected;
    [tempButton setImage:[UIImage imageNamed:norlmalStateImage] forState:UIControlStateNormal];
    [tempButton setImage:[UIImage imageNamed:selectedStateImage] forState:UIControlStateSelected];
    [_bottomDockView addSubview:tempButton];
    return tempButton;
}

#pragma -mark 按钮点击事件
- (void)playButtonClick
{
    BOOL isPlaying = [_mediaPlayer isPlaying];
    if (isPlaying) {
        [_mediaPlayer pause];
        _playOrPauseButton.selected = NO;
    } else {
        [_mediaPlayer start];
        _playOrPauseButton.selected = YES;
    }
}

- (void)fullScreenClick
{
    _fullScreenButton.selected = !_fullScreenButton.selected;
   [[NSNotificationCenter defaultCenter] postNotificationName:kNOTIFYCATIONFULLSCREEN object:_fullScreenButton];
}

- (void)close
{
  [self stopTimer];
  [self.delegate closeCGPlayer];
}

#pragma -mark 进度条更新
- (void)lightChange
{
    self.progressDragging = YES;
    _dateLabel.text = [NSString stringWithFormat:@"%@ / %@",[self timeToHumanString:(long)(_sliderView.value * _mediaPlayer.getDuration)],
                        [self timeToHumanString:[_mediaPlayer getDuration]]];
}

- (void)lightDownUp
{
   [_mediaPlayer seekTo:(long)(_sliderView.value * [_mediaPlayer getDuration])];
}

#pragma -mark  主线程开启定时器
- (void)startTimer{
    //为了保证UI刷新在主线程中完成。
    [self performSelectorOnMainThread:@selector(startTimeroOnMainThread) withObject:nil waitUntilDone:NO];
}

#pragma -mark 初始化定时器
- (void)startTimeroOnMainThread{
    if (!_timer) {
        _timer = [NSTimer scheduledTimerWithTimeInterval:1.0/3 target:self selector:@selector(timerHandler:) userInfo:nil repeats:YES];
    }
}

- (void)timerHandler:(NSTimer*)timer{
    [self refreshProgress:(int)[_mediaPlayer getCurrentPosition] totalDuration:(int)[_mediaPlayer getDuration]];
}

#pragma -mark 进度刷新
- (void)refreshProgress:(int) currentTime totalDuration:(int)allSecond{
    if (!self.progressDragging) {
        _sliderView.value = (float)currentTime/allSecond;
        _dateLabel.text = [NSString stringWithFormat:@"%@ / %@",[self timeToHumanString:currentTime],[self timeToHumanString:allSecond]];
    }
}

//时间转换
- (NSString *)timeToHumanString:(unsigned long)ms
{
    unsigned long seconds, h, m, s;
    char buff[128] = { 0 };
    NSString *nsRet = nil;
    
    seconds = ms / 1000;
    h = seconds / 3600;
    m = (seconds - h * 3600) / 60;
    s = seconds - h * 3600 - m * 60;
    snprintf(buff, sizeof(buff), "%02ld:%02ld:%02ld", h, m, s);
    nsRet = [[NSString alloc] initWithCString:buff
                                     encoding:NSUTF8StringEncoding];
    
    return nsRet;
}

#pragma -mark 停止定时器
- (void)stopTimer{
    if (_timer) {
        [_timer invalidate];
        _timer=nil;
    }
}

#pragma -mark 手势事件
- (void)tapOneClick:(UITapGestureRecognizer *)tapGestureRecognizer
{
    [self.delegate tapOneTapGester];
}

- (void)tapTwoClick:(UITapGestureRecognizer *)tapGestureRecognizer
{
    if ([_mediaPlayer isPlaying]) {
        [_mediaPlayer pause];
    }else{
        [_mediaPlayer start];
    }
}

#pragma -mark 休息一会儿进入透明
- (void) hideBottomDockView
{
    AFTER(bottomDockHide, ^{//首次播放5秒之后自动隐藏
        [UIView animateWithDuration:1.0f animations:^{
            _bottomDockView.alpha = 0.0f;
        }];
    });
}

- (void) setVedioFrame:(CGRect)frame
{
    [self setFrame:frame];
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

@end
