//
//  UIView+CornerRadius.h
//  MEMobile
//
//  Created by LamTsanFeng on 2016/10/10.
//  Copyright © 2016年 GZMiracle. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (CornerRadius)

/**
 *  @author lincf
 *
 *  系统API设置圆形 layer.cornerRadius
 *
 *  @param 圆角大小（视图大小，若视图大小改变角度，需要重新设置）
 *
 */
- (void)setCornerRadius:(float)cornerRadius;// DEPRECATED_ATTRIBUTE;


/**
 *  @author lincf
 *
 *  设置自定义遮罩层
 *
 *  @param maskView      需要设置的遮罩试图
 *  @param isNeedBorder  是否需要显示遮罩描边
 *
 */
- (void)setLayerMaskView:(UIImageView * _Nonnull)maskView;
- (void)setLayerMaskView:(UIImageView * _Nonnull)maskView isNeedBorder:(BOOL)isNeedBorder;

@end
