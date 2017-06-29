//
//  UIImage+Size.h
//  MiracleMessenger
//
//  Created by LamTsanFeng on 15/3/26.
//  Copyright (c) 2015年 Anson. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (LFPB_Size)

/** 读取图片路径，超过最大宽度后自动缩放，返回图片大小 */
+ (CGSize)LFPB_imageSizeByFileName:(NSString *)fileName maxWidth:(CGFloat)maxWidth;
/** 根据图片大小和设置的最大宽度，返回缩放后的大小 */
+ (CGSize)LFPB_imageSizeBySize:(CGSize)size maxWidth:(CGFloat)maxWidth;
/** 根据图片大小和设置的最大高度，返回缩放后的大小 */
+ (CGSize)LFPB_imageSizeBySize:(CGSize)size maxHeight:(CGFloat)maxHeight;
/** 根据图片大小和设置的大小，返回拉伸或缩放后的大小 2边都必须达到设置大小 */
+ (CGSize)LFPB_scaleImageSizeBySize:(CGSize)imageSize targetSize:(CGSize)size isBoth:(BOOL)isBoth;
@end
