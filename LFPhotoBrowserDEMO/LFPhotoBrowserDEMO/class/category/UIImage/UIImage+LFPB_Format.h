//
//  UIImage+Format.h
//  MEMobile
//
//  Created by LamTsanFeng on 16/9/23.
//  Copyright © 2016年 GZMiracle. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, LFPBImageType) {
    LFPBImageType_Unknow = 0,
    LFPBImageType_JPEG,
    LFPBImageType_JPEG2000,
    LFPBImageType_TIFF,
    LFPBImageType_BMP,
    LFPBImageType_ICO,
    LFPBImageType_ICNS,
    LFPBImageType_GIF,
    LFPBImageType_PNG,
    LFPBImageType_WebP,
};

CG_EXTERN LFPBImageType LFPBImageDetectType(CFDataRef data);

@interface UIImage (LFPB_Format)

/**
 *  @author lincf, 16-09-23 14:09:47
 *
 *  匹配加载 webp、gif、jpeg 等图片
 *
 *  @param imagePath 图片路径
 *
 *  @return UIImage
 */
+ (instancetype)LFPB_imageWithImagePath:(NSString *)imagePath;

+ (instancetype)LFPB_imageWithImagePath:(NSString *)imagePath error:(NSError **)error;

+ (instancetype)LFPB_imageWithImageData:(NSData *)imgData;
@end
