//
//  LFVideoProtocol.h
//  LFPhotoBrowserDEMO
//
//  Created by LamTsanFeng on 2016/11/21.
//  Copyright © 2016年 GZMiracle. All rights reserved.
//

@protocol LFVideoProtocol <NSObject>

@required
/** 第一帧URLString*/
@property (nonatomic, copy) NSString *thumbnailUrl;
/** 第一帧路径*/
@property (nonatomic, copy) NSString *thumbnailPath;
/** 第一帧图片*/
@property (nonatomic, strong) UIImage *thumbnailImage;

/** 视频URLString*/
@property (nonatomic, copy) NSString *videoUrl;
/** 视频路径*/
@property (nonatomic, copy) NSString *videoPath;

/** 是否需要进度条 */
@property (nonatomic, assign) BOOL isNeedSlider;

/** 已是下载状态 */
@property (nonatomic, assign) BOOL isLoading;
@end
