//
//  LFImageProgressView.h
//  LFPhotoBrowserDEMO
//
//  Created by LamTsanFeng on 2016/11/21.
//  Copyright © 2016年 GZMiracle. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LFImageProgressView : UIView

@property (nonatomic) float progress;

- (void)showLoading;
- (void)showFailure;

@end
