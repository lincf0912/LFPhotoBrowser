//
//  PhotoViewType.h
//  MEMobile
//
//  Created by LamTsanFeng on 2016/9/28.
//  Copyright © 2016年 GZMiracle. All rights reserved.
//

#ifndef PhotoViewType_h
#define PhotoViewType_h

typedef NS_ENUM(NSInteger, downLoadType) { // 加载类型
    downLoadTypeUnknown, // 未知
    downLoadTypeLocale, // 本地
    downLoadTypeNetWork, // 网络
    downLoadTypeImage, // 显示单张图片
    downLoadTypeFail = 9, // 下载失败
};

typedef NS_ENUM(NSInteger, MaskPosition) {//遮罩位置
    MaskPosition_None, //遮罩与图层一样大
    MaskPosition_LeftOrUp, //左边或者上边
    MaskPosition_Middle, //中间位置
    MaskPosition_RightOrDown,//右边或者下边
};


#endif /* PhotoViewType_h */
