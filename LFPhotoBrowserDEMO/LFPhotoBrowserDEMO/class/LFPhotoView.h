//
//  photoView.h
//  PhotoBrowser
//
//  Created by LamTsanFeng on 2016/9/28.
//  Copyright © 2016年 GZMiracle. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LFScrollView.h"
#import "PhotoViewType.h"

@class LFPhotoView,LFPhotoInfo;

@protocol LFPhotoViewDelegate <NSObject>
@optional

/** change photoView's zoomScale*/
/** 缩放代理 */
-(void)photoViewWillBeginZooming:(LFPhotoView *)photoView;
-(void)photoViewDidZoom:(LFPhotoView *)photoView;
-(void)photoViewDidEndZooming:(LFPhotoView *)photoView;

/** 单击手势代理方法*/
-(void)photoViewGesture:(LFPhotoView *)photoView singleTapImage:(UIImage *)image;
/** 双击手势代理方法(传imageView出去)*/
-(void)photoViewGesture:(LFPhotoView *)photoView doubleTapImage:(UIImage *)image;
/** 长按手势代理方法*/
-(void)photoViewGesture:(LFPhotoView *)photoView longPressImage:(UIImage *)image;

/** (不实现，自带SD下载)下载缩略图代理方法 return YES 自定义下载，改变self.photoInfo对象属性，下载完毕调用reloadPhotoView */
-(BOOL)photoViewDownLoadThumbnail:(LFPhotoView *)photoView url:(NSString *)url;
/** (不实现，自带SD下载)下载原图代理方法 return YES 自定义下载，改变self.photoInfo对象属性，下载完毕调用reloadPhotoView */
-(BOOL)photoViewDownLoadOriginal:(LFPhotoView *)photoView url:(NSString *)url;

/** (不实现，在线播放)下载视频代理方法 改变self.photoInfo对象属性，下载完毕调用reloadPhotoView */
-(BOOL)photoViewDownLoadVideo:(LFPhotoView *)photoView url:(NSString *)url;
@end

@interface LFPhotoView : LFScrollView
/** 加载方式*/
@property (nonatomic, readonly) downLoadType loadType;
@property (nonatomic, strong) LFPhotoInfo *photoInfo;
@property (nonatomic, assign) CGRect photoRect;
/** 代理*/
@property (nonatomic, weak) id<LFPhotoViewDelegate> photoViewDelegate;

/** 设置View的frame*/
-(void)calcFrameMaskPosition:(MaskPosition)maskPosition frame:(CGRect)frame;

/** 清除数据*/
-(void)cleanData;
/** 刷新photoView*/
-(void)reloadPhotoView;

/** 隐藏附属控件 */
-(void)setSubControlAlpha:(CGFloat)alpha;
@end
