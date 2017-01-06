//
//  LFModelProtocol.h
//  LFPhotoBrowserDEMO
//
//  Created by LamTsanFeng on 2017/1/6.
//  Copyright © 2017年 GZMiracle. All rights reserved.
//

typedef NS_ENUM(NSInteger, PhotoType) {
    /** 默认 图片 */
    PhotoType_image,
    /** 视频 */
    PhotoType_video,
};

@protocol LFModelProtocol <NSObject>

@required
@property (nonatomic, readonly) PhotoType photoType;
/** 唯一识别的key*/
@property (nonatomic, copy, readonly) NSString *key;
/** 进度 */
@property (nonatomic, assign) float downloadProgress;
/** 下载失败记录，显示另外UI */
@property (nonatomic, assign) BOOL downloadFail;

/** 图片读取优先级  低->高 往下 */
/** 占位图片*/
@property (nonatomic, strong) UIImage *placeholderImage;

+ (instancetype)photoInfoWithType:(PhotoType)type key:(NSString *)key;

@end
