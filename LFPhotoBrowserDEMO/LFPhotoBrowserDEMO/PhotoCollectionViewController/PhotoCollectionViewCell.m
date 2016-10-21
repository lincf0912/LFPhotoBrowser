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
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    _showImageView.frame = self.bounds;
}

- (void)setImageName:(NSString *)imageName
{
    [_showImageView setImage:[UIImage imageNamed:imageName]];
}
@end
