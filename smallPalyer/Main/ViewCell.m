//
//  ViewCell.m
//  smallPalyer
//
//  Created by ChengXi on 16/3/9.
//  Copyright © 2016年 ChengXi. All rights reserved.
//

#import "ViewCell.h"
#import "UIImageView+WebCache.h"

@interface ViewCell()

@property (weak, nonatomic) IBOutlet UILabel *nameTItle;

@end

@implementation ViewCell

- (void)awakeFromNib {
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

- (void)setVediolist:(VedioList *)vediolist{
    _vediolist = vediolist;
    
    self.nameTItle.text = vediolist.vedioDescription;
    [self.imageVedioView sd_setImageWithURL:[NSURL URLWithString:vediolist.cover]];
}

- (IBAction)playClick:(id)sender {
    [self.delegate playButtonClick:self];
}
@end
