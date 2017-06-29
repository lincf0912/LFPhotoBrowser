//
//  PhotoTableViewCell.m
//  LFPhotoBrowserDEMO
//
//  Created by LamTsanFeng on 2016/10/20.
//  Copyright © 2016年 GZMiracle. All rights reserved.
//

#import "PhotoTableViewCell.h"
#import "UIImageView+WebCache.h"
#import "UIImage+LFPB_Size.h"
#import "MBProgressHUD.h"

@interface PhotoTableViewCell ()

@property (nonatomic, strong) UIImageView *photoView;
@property (nonatomic, strong) MBRoundProgressView *progressView;

@end

@implementation PhotoTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)dealloc
{
    [_photoView sd_cancelCurrentImageLoad];
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        _photoView = [[UIImageView alloc] initWithFrame:CGRectZero];
        _photoView.contentMode = UIViewContentModeScaleAspectFit;
        [self.contentView addSubview:_photoView];
        _progressView = [[MBRoundProgressView alloc] init];
        _progressView.progressTintColor = [UIColor colorWithWhite:0.8 alpha:1.f];
        _progressView.backgroundTintColor = [UIColor colorWithWhite:0.5 alpha:.8f];
        _progressView.alpha = 0.f;
        [self.contentView addSubview:_progressView];
        
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    
    CGSize size = [UIImage LFPB_imageSizeBySize:self.photoView.image.size maxHeight:self.bounds.size.height];
//    [_photoView setFrame:(CGRect){(self.bounds.size.width - size.width) / 2, 0, size}];
    [_photoView setFrame:(CGRect){_photoView.frame.origin, size}];
    
    _progressView.frame = CGRectMake(0, 0, self.bounds.size.height/2, self.bounds.size.height/2);
    _progressView.center = self.contentView.center;
}

- (void)setUrl:(NSString *)url
{
    _url = url;
    CGFloat x = (arc4random() % (int)(self.bounds.size.width+0.5 - 100)) + 50;
    CGRect frame = _photoView.frame;
    frame.origin.x = x;
    _photoView.frame = frame;
    
    if ([url hasSuffix:@".jpg"]) {
        __weak typeof(self) weakSelf = self;
        __weak typeof(self.url) weakURL = self.url;
        _progressView.alpha = 1.f;
        [_photoView sd_setImageWithURL:[NSURL URLWithString:url] placeholderImage:nil options:SDWebImageRetryFailed|SDWebImageLowPriority progress:^(NSInteger receivedSize, NSInteger expectedSize) {
            if (weakSelf.url != weakURL) return ;
            weakSelf.progressView.progress = (float)receivedSize/(float)expectedSize;
        } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
            weakSelf.progressView.alpha = 0.f;
            if (image) {
                [weakSelf setNeedsLayout];
            }
        }];
    } else {
        [self.photoView setImage:[UIImage imageNamed:@"default"]];
    }
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    [_photoView sd_cancelCurrentImageLoad];
    _photoView.image = nil;
    _progressView.progress = 0.f;
    _progressView.alpha = 0.f;
}

-(CGRect)obtainPhotoViewFrameInView:(UIView *)view
{
    return [self.photoView.superview convertRect:self.photoView.frame toView:view];
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
