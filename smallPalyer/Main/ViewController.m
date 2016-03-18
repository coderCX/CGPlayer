//
//  ViewController.m
//  smallPalyer
//
//  Created by ChengXi on 16/3/9.
//  Copyright © 2016年 ChengXi. All rights reserved.
//

#import "ViewController.h"
#import "ViewCell.h"
#import "ViewCellModel.h"
#import "VedioList.h"
#import "MJExtension.h"
#import "Masonry.h"
#import "CGPlayer.h"

#define kScreenW ([UIScreen mainScreen].bounds.size.width)
#define kScreenH ([UIScreen mainScreen].bounds.size.height)
#define kNavbarHeight 0//导航栏高度
#define kTabBarHeight 44//dock条高度
@interface ViewController () <ViewCellDelegate,CGPlayerDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic,strong) ViewCellModel *cellModel;

@property (nonatomic,strong) CGPlayer *cgPlayer;

/** 当前显示的cell */
@property (nonatomic,strong) ViewCell *currentCell;

/** 是否处于右下角小屏模式 */
@property (nonatomic,assign) BOOL isSmallScreen;

@property (nonatomic,strong) NSIndexPath *currentIndexPath;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://c.m.163.com/nc/video/home/0-10.html"]] queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse * _Nullable response, NSData * _Nullable data, NSError * _Nullable connectionError) {
        NSDictionary * dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
        ViewCellModel *cellModel = [ViewCellModel mj_objectWithKeyValues:dict];
        self.cellModel = cellModel;
        [self.tableView reloadData];
    }];
    
//    [_tableView registerClass:[ViewCell class] forCellReuseIdentifier:@"viewcell"];
    [_tableView registerNib:[UINib nibWithNibName:@"ViewCell" bundle:nil] forCellReuseIdentifier:@"ViewCell"];
    
    //注册播放完成通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fullScreen:) name:kNOTIFYCATIONFULLSCREEN object:nil];
    
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 200;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.cellModel.videoList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentife = @"ViewCell";
    ViewCell *cell =  [tableView dequeueReusableCellWithIdentifier:cellIdentife];
    cell.delegate = self;
    if (!cell) {
        cell = [[ViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentife];
    }
    
    VedioList *vedioList = self.cellModel.videoList[indexPath.row];
    cell.vediolist = vedioList;
    
    //解决循环引用问题
    if (_cgPlayer) {
        //获取当前屏幕中所有可见的cell的indexPath
        NSArray *indexpaths = [tableView indexPathsForVisibleRows];
        if (![indexpaths containsObject:_currentIndexPath]) {
            
            //判断是否正在小窗口播放
            if ([[UIApplication sharedApplication].keyWindow.subviews containsObject:_cgPlayer]) {
                _cgPlayer.hidden = NO;
                
            }else{
                _cgPlayer.hidden = YES;
            }
        }else{//如果当前可见区域中包括复用的cell，则判断当前显示的cell中是否有之前存在的控件
            if ([cell.contentView.subviews containsObject:_cgPlayer]) {
                [cell.contentView addSubview:_cgPlayer];
                _cgPlayer.hidden = NO;
            }
            
        }
    }
    return cell;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    /**
     4种情况下可以调用此方法
     1、刷新表格
     2、上下滑动cell但是没有视频播放
     3、上下滑动cell但是有cell播放视频
     4、上线滑动cell右下角有小窗口播放视频
     */
    
    if (_cgPlayer) {
        //返回指定indexPath cell的frame
        CGRect rectInTableView = [_tableView rectForRowAtIndexPath:_currentIndexPath];
        //坐标转换到 相对于 [UIApplication sharedApplication].keyWindow 的坐标
        CGRect rectInSuperview = [_tableView convertRect:rectInTableView toView:[UIApplication sharedApplication].keyWindow];
        
        if (rectInSuperview.origin.y<-self.currentCell.contentView.frame.size.height
            || rectInSuperview.origin.y>self.view.frame.size.height-kNavbarHeight-kTabBarHeight) {//往上拖动
            if ([[UIApplication sharedApplication].keyWindow.subviews containsObject:_cgPlayer]&&_isSmallScreen) {
                _isSmallScreen = YES;
            }else{
                //放widow上,小屏显示
                [self toSmallScreen];
            }
        }else{
            if ([self.currentCell.contentView.subviews containsObject:_cgPlayer]) {
                
            }else{
                [self toCellSceen];
            }
        }
        
    }
}

#pragma -mark ViewCellDelegate
- (void)playButtonClick:(ViewCell *)viewCell
{
    //当前点击的cell的NSIndexPath标志
    _currentIndexPath = [_tableView indexPathForCell:viewCell];
    
    _currentCell = viewCell;
    _cgPlayer.isFullscreen = NO;
    
    if(!_cgPlayer){
       _cgPlayer = [[CGPlayer alloc] initWithFrame:viewCell.bounds videoURL:viewCell.vediolist.mp4_url];
        _cgPlayer.delegate = self;
    }else{
        //如果播放器对象已经存在则重新部署下一播放文件资源
        [_cgPlayer removeFromSuperview];
        [_cgPlayer  resetVedio];
        [_cgPlayer  setDataSource:viewCell.vediolist.mp4_url];
        [_cgPlayer prepareAsyncVedio];
        [_cgPlayer startVedio];
        _cgPlayer.hidden = NO;
        
        //如果当前正在右下角小屏播放,则干掉小屏播放进入选中cell播放
        if (_isSmallScreen) {
            [self toCellSceen];
        }
    }
    _isSmallScreen = NO;
    [_currentCell.contentView addSubview:_cgPlayer];
}

#pragma -mark CGPlayerDelegate
- (void)closeCGPlayer{
    [self freeCGPlayer];
}

- (void)tapOneTapGester
{
    //如果当前处于右下角小屏播放则单击直接进入全屏播放
    if(_isSmallScreen){
        [self toFullScreen];
        return;
    }
    
    if (_cgPlayer.bottomDockView.alpha>0) {
        [UIView animateWithDuration:1.0f animations:^{
            _cgPlayer.bottomDockView.alpha = 0.0f;
        }];
    }else{
        [UIView animateWithDuration:1.0f animations:^{
            _cgPlayer.bottomDockView.alpha = 1.0f;
        } completion:^(BOOL finished) {
            [_cgPlayer hideBottomDockView];
        }];
    }
}

#pragma -mark 释放播放器资源
- (void) freeCGPlayer{
    [_cgPlayer pauseVedio];
    [_cgPlayer resetVedio];
    [_cgPlayer unSetupPlayer];
    [_cgPlayer removeFromSuperview];
    _cgPlayer=nil;
}

#pragma -mark 进入全屏通知
- (void)fullScreen:(NSNotification *)notice
{
    if(!_cgPlayer.isFullscreen){
        [self toFullScreen];
    }else{
        if(_isSmallScreen){
            [self toSmallScreen];
        }else{
            [self toCellSceen];
        }
    }
}

/**
 进入全屏
 */
-(void)toFullScreen{
    [_cgPlayer removeFromSuperview];
    _cgPlayer.bottomDockView.alpha = 0;
    [UIView animateWithDuration:0.3f animations:^{
        _cgPlayer.transform = CGAffineTransformIdentity;
        _cgPlayer.transform = CGAffineTransformMakeRotation(M_PI_2);
        [_cgPlayer setVedioFrame:CGRectMake(0,0,kScreenW,kScreenH)];
        [[UIApplication sharedApplication].keyWindow addSubview:_cgPlayer];
        [_cgPlayer.bottomDockView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.height.mas_equalTo(bottomDockH);
            make.top.mas_equalTo(kScreenW-bottomDockH);
            make.width.mas_equalTo(kScreenH);
            make.left.mas_equalTo(0);
        }];
    } completion:^(BOOL finished) {
        //取消警告
#pragma clang diagnostic push
#pragma clang diagnostic ignored"-Wdeprecated-declarations"
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
#pragma clang diagnostic pop
        _cgPlayer.isFullscreen = YES;
        _cgPlayer.bottomDockView.alpha = 1;
    }];
}

/**
 退出全屏以后进入cell之前的位置
 */
- (void)toCellSceen
{
    [_cgPlayer removeFromSuperview];
    _cgPlayer.bottomDockView.alpha = 0;
    [UIView animateWithDuration:0.3f animations:^{
        _cgPlayer.transform = CGAffineTransformIdentity;
        _cgPlayer.frame = self.currentCell.contentView.bounds;
        [self.currentCell.contentView addSubview:_cgPlayer];
        [_cgPlayer.bottomDockView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.and.right.and.bottom.offset(0);
            make.height.mas_equalTo(bottomDockH);
        }];
    }completion:^(BOOL finished) {
        _cgPlayer.isFullscreen = NO;
        _cgPlayer.bottomDockView.alpha = 1;
        _isSmallScreen = NO;
#pragma clang diagnostic push
#pragma clang diagnostic ignored"-Wdeprecated-declarations"
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
#pragma clang diagnostic pop
        
    }];
}

/** 进入退出后的小屏 */
-(void)toSmallScreen{
    [_cgPlayer removeFromSuperview];
    [UIView animateWithDuration:0.3f animations:^{
        _cgPlayer.transform = CGAffineTransformIdentity;
        CGFloat cgPlayerH = (kScreenW/2)*0.75;
        _cgPlayer.frame = CGRectMake(kScreenW/2,kScreenH-cgPlayerH, kScreenW/2,cgPlayerH);
        [[UIApplication sharedApplication].keyWindow addSubview:_cgPlayer];
        [_cgPlayer.bottomDockView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(_cgPlayer).offset(0);
            make.right.equalTo(_cgPlayer).offset(0);
            make.height.mas_equalTo(bottomDockH);
            make.bottom.equalTo(_cgPlayer).offset(0);
        }];
        
    }completion:^(BOOL finished) {
        _cgPlayer.isFullscreen = NO;
        _isSmallScreen = YES;
        _cgPlayer.bottomDockView.alpha = 0;
#pragma clang diagnostic push
#pragma clang diagnostic ignored"-Wdeprecated-declarations"
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
#pragma clang diagnostic pop
    }];
    
}

-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
