//
//  photoView.h
//  PhotoBrowser
//
//  Created by LamTsanFeng on 2016/9/28.
//  Copyright © 2016年 GZMiracle. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LFPhotoInfo.h"
#import "PhotoViewType.h"


@class LFPhotoView;

@protocol LFPhotoViewDelegate <NSObject>
@optional

/** change photoView's zoomScale*/
/** 缩放代理 */
-(void)photoViewWillBeginZooming:(LFPhotoView *)photoView;
-(void)photoViewDidZoom:(LFPhotoView *)photoView;
-(void)photoViewDidEndZooming:(LFPhotoView *)photoView;

/** 单击手势代理方法*/
-(void)photoViewGesture:(LFPhotoView *)photoView singleTapImageView:(UIImageView *)imageView;
/** 双击手势代理方法(传imageView出去)*/
-(void)photoViewGesture:(LFPhotoView *)photoView doubleTapImageView:(UIImageView *)imageView;
/** 长按手势代理方法*/
-(void)photoViewGesture:(LFPhotoView *)photoView longPressImageView:(UIImageView *)imageView;

/** 下载缩略图代理方法*/
-(void)downLoadthumbnailInPhotoView:(LFPhotoView *)photoView;
/** 下载原图代理方法*/
-(void)downLoadImageInPhotoView:(LFPhotoView *)photoView;
@end

@interface LFPhotoView : UIScrollView
/** 加载方式*/
@property (nonatomic, readonly) downLoadType loadType;
@property (nonatomic, strong) LFPhotoInfo *photoInfo;
@property (nonatomic, readonly) CGRect photoRect;
/** 代理*/
@property (nonatomic, weak) id<LFPhotoViewDelegate> photoViewDelegate;

/** 设置View的frame*/
-(void)calcFrameMaskPosition:(MaskPosition)maskPosition frame:(CGRect)frame;

/** 清除数据*/
-(void)cleanData;
/** 刷新photoView*/
-(void)reloadPhotoView;
@end
