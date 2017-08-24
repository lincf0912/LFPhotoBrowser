//
//  LFImageProgressView.m
//  LFPhotoBrowserDEMO
//
//  Created by LamTsanFeng on 2016/11/21.
//  Copyright © 2016年 GZMiracle. All rights reserved.
//

#import "LFImageProgressView.h"
#import "X_LLARingSpinnerView.h"


@interface LFImageProgressView ()
{
    UIImageView *_failureImageView;
    UILabel *_failureLabel;
    X_LLARingSpinnerView *_progressView;
}
@end

@implementation LFImageProgressView

- (void)showFailure
{
    [_progressView removeFromSuperview];
    
    if (_failureImageView == nil) {
        _failureImageView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, 120, 120)];
        _failureImageView.contentMode = UIViewContentModeScaleAspectFit;
        _failureImageView.image = [UIImage imageNamed:@"LFPhotoSource.bundle/PhotoDownloadfailedSamll@2x"];
        _failureImageView.center = CGPointMake(self.center.x, self.center.y - 150);
        _failureImageView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
    }
    [self addSubview:_failureImageView];
    if (_failureLabel == nil) {
        _failureLabel = [[UILabel alloc] init];
        _failureLabel.bounds = CGRectMake(0, 0, self.bounds.size.width, 44);
        _failureLabel.textAlignment = NSTextAlignmentCenter;
        _failureLabel.center = self.center;
        _failureLabel.text = @"无法加载图片";
        _failureLabel.font = [UIFont boldSystemFontOfSize:16.0f];
        _failureLabel.textColor = [UIColor whiteColor];
        _failureLabel.backgroundColor = [UIColor clearColor];
        _failureLabel.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
    }
    [self addSubview:_failureLabel];
}

- (void)showLoading
{
    [_failureImageView removeFromSuperview];
    [_failureLabel removeFromSuperview];
    
    if (_progressView == nil) {
        _progressView = [[X_LLARingSpinnerView alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
        _progressView.center = self.center;
        _progressView.tintColor = [[UIColor whiteColor] colorWithAlphaComponent:1];
    }
    [self addSubview:_progressView];
    [_progressView startAnimating];
}

#pragma mark - customlize method
- (void)setProgress:(float)progress
{
    if (progress >= 1.0) {
        [_progressView removeFromSuperview];
    } else {
        _progressView.progress = progress;
    }
}


@end
