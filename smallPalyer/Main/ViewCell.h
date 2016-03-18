//
//  ViewCell.h
//  smallPalyer
//
//  Created by ChengXi on 16/3/9.
//  Copyright © 2016年 ChengXi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VedioList.h"

@class ViewCell;
//代理
@protocol ViewCellDelegate <NSObject>

/**
 *  播放按钮被点击
 */
- (void) playButtonClick:(ViewCell *)viewCell;

@end

@interface ViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *imageVedioView;

@property (nonatomic,strong) VedioList *vediolist;

@property (nonatomic, weak) id<ViewCellDelegate> delegate;

@end
