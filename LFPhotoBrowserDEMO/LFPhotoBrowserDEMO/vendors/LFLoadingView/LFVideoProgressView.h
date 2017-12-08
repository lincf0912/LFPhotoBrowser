//
//  LFVideoProgressView.h
//  LFPhotoBrowserDEMO
//
//  Created by LamTsanFeng on 2016/11/21.
//  Copyright © 2016年 GZMiracle. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LFVideoProgressView : UIView

/** 进度值*/
@property (nonatomic, assign) float progress;

@property (nonatomic, copy) void (^clickBlock)(void);

- (void)showLoading;
- (void)showFailure;

@end
