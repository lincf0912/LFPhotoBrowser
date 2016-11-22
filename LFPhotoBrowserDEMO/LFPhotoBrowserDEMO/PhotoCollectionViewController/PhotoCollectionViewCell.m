//
//  PhotoCollectionViewCell.m
//  LFPhotoBrowserDEMO
//
//  Created by LamTsanFeng on 2016/10/20.
//  Copyright © 2016年 GZMiracle. All rights reserved.
//

#import "PhotoCollectionViewCell.h"

@interface PhotoCollectionViewCell ()

@property (strong, nonatomic) UIImageView *showImageView;

@property (nonatomic, strong) UILabel *label;

@end

@implementation PhotoCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self customInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self customInit];
    }
    return self;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self customInit];
    }
    return self;
}

- (void)customInit
{
    _showImageView = [[UIImageView alloc] initWithFrame:self.bounds];
    _showImageView.contentMode = UIViewContentModeScaleAspectFill;
    _showImageView.clipsToBounds = YES;
    [self.contentView addSubview:_showImageView];
    
    _label = [[UILabel alloc] initWithFrame:self.bounds];
    _label.font = [UIFont systemFontOfSize:10.f];
    _label.textColor = [UIColor redColor];
    _label.text = @"视频";
    _label.textAlignment = NSTextAlignmentCenter;
    _label.hidden = YES;
    [self.contentView addSubview:_label];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    _showImageView.frame = self.bounds;
}

- (void)setImageName:(NSString *)imageName
{
    _label.hidden = YES;
    [_showImageView setImage:[UIImage imageNamed:imageName]];
}

- (void)markVideo
{
    _label.hidden = NO;
}
@end
