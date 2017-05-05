//
//  LFPhotoProtocol.h
//  LFPhotoBrowserDEMO
//
//  Created by LamTsanFeng on 2016/11/21.
//  Copyright © 2016年 GZMiracle. All rights reserved.
//

@protocol LFPhotoProtocol <NSObject>

/** 属性优先级 由上到下 -> 低到高 */

@required
/** 缩略图URLString*/
@property (nonatomic, copy) NSString *thumbnailUrl;
/** 缩略图路径*/
@property (nonatomic, copy) NSString *thumbnailPath;
/** 缩略图图片*/
@property (nonatomic, strong) UIImage *thumbnailImage;

/** 原图URLString*/
@property (nonatomic, copy) NSString *originalImageUrl;
/** 图片本地路径*/
@property (nonatomic, copy) NSString *originalImagePath;
/** 本地图片、保存下载图片*/
@property (nonatomic, copy) UIImage *originalImage;
/** 图片数据*/
@property (nonatomic, strong) NSData *originalImageData;

@end
