//
//  UIView+CornerRadius.m
//  MEMobile
//
//  Created by LamTsanFeng on 2016/10/10.
//  Copyright © 2016年 GZMiracle. All rights reserved.
//

#import "UIView+LFPB_CornerRadius.h"

@implementation UIView (LFPB_CornerRadius)

- (void)setCornerRadius:(float)cornerRadius
{
    if (cornerRadius > 0) {
        self.layer.masksToBounds = YES;
        self.layer.cornerRadius = cornerRadius;
        self.layer.shouldRasterize = YES;
        self.layer.rasterizationScale = [UIScreen mainScreen].scale;
    } else {
        self.layer.masksToBounds = NO;
        self.layer.cornerRadius = 0;
        self.layer.shouldRasterize = NO;
        self.layer.rasterizationScale = 1.f;
    }
}
- (void)setLayerMaskView:(UIImageView *)maskView {
    [self setLayerMaskView:maskView isNeedBorder:NO];
}

- (void)setLayerMaskView:(UIImageView *)maskView isNeedBorder:(BOOL)isNeedBorder
{
    /** 获取遮罩层 */
    CALayer *maskLayer = maskView.layer;
    
    /** 计算遮罩层的位置 */
    CGFloat inset = 0.f;
    CGRect rect = maskView.bounds;
    
    /** 显示层需要描边，额外创建UIImageView */
    if (isNeedBorder) {
        /** 重新计算描边线粗 */
        inset = 0.5f;
        rect = CGRectInset(maskView.bounds, inset, inset);
    }
    
    
    [maskLayer setFrame:rect];
    
    /** 完成遮罩层创建 */
    self.layer.masksToBounds=YES;
    self.layer.mask = maskLayer;
    self.layer.shouldRasterize = YES;
    self.layer.rasterizationScale = [UIScreen mainScreen].scale;
}

@end
