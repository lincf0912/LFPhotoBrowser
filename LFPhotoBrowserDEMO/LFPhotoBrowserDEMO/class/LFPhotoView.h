//
//  photoView.h
//  PhotoBrowser
//
//  Created by LamTsanFeng on 2016/9/28.
//  Copyright © 2016年 GZMiracle. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LFPhotoScrollView.h"
#import "PhotoViewType.h"
#import "LFModelProtocol.h"
#import "LFPhotoProtocol.h"
#import "LFVideoProtocol.h"

@class LFPhotoView;

@protocol LFPhotoViewDelegate <NSObject>
@optional

/** change photoView's zoomScale*/
/** 缩放代理 */
-(void)photoViewWillBeginZooming:(LFPhotoView *)photoView;
-(void)photoViewDidZoom:(LFPhotoView *)photoView;
-(void)photoViewDidEndZooming:(LFPhotoView *)photoView;

/** 单击手势代理方法*/
-(void)photoViewGesture:(LFPhotoView *)photoView singleTapPhotoType:(PhotoType)PhotoType object:(id /* UIImage * /NSURL * */)object;
/** 双击手势代理方法(传imageView出去)*/
-(void)photoViewGesture:(LFPhotoView *)photoView doubleTapPhotoType:(PhotoType)PhotoType object:(id /* UIImage * /NSURL * */)object;
/** 长按手势代理方法*/
-(void)photoViewGesture:(LFPhotoView *)photoView longPressPhotoType:(PhotoType)PhotoType object:(id /* UIImage * /NSURL * */)object;

/** (不实现，自带SD下载)下载缩略图代理方法 return YES 自定义下载，改变self.photoInfo对象属性，下载完毕调用reloadPhotoView */
-(BOOL)photoViewDownLoadThumbnail:(LFPhotoView *)photoView url:(NSString *)url;
/** (不实现，自带SD下载)下载原图代理方法 return YES 自定义下载，改变self.photoInfo对象属性，下载完毕调用reloadPhotoView */
-(BOOL)photoViewDownLoadOriginal:(LFPhotoView *)photoView url:(NSString *)url;

/** (不实现，在线播放)下载视频代理方法 改变self.photoInfo对象属性，下载完毕调用reloadPhotoView */
-(BOOL)photoViewDownLoadVideo:(LFPhotoView *)photoView url:(NSString *)url;
@end

@interface LFPhotoView : LFPhotoScrollView
/** 加载方式*/
@property (nonatomic, readonly) downLoadType loadType;
@property (nonatomic, strong) id<LFModelProtocol, LFPhotoProtocol, LFVideoProtocol> photoInfo;
@property (nonatomic, assign) CGRect photoRect;
/** 缩放操作 默认打开 default is YES */
@property (nonatomic, assign) BOOL zoomEnable;
/** 代理*/
@property (nonatomic, weak) id<LFPhotoViewDelegate> photoViewDelegate;

/** 横屏适配(在屏幕将要改变方向时，设置orientation=实际屏幕方向) */
@property (nonatomic, assign) UIInterfaceOrientation orientation;

/** 设置View的frame*/
-(void)calcFrameMaskPosition:(MaskPosition)maskPosition frame:(CGRect)frame;

/** 设置遮罩图片 */
- (void)setMaskImage:(UIImage *)maskImage;

/** 清除数据*/
-(void)cleanData;
/** 刷新photoView*/
-(void)reloadPhotoView;

/** 触发动画开始 */
- (void)beginUpdate;
/** 触发动画结束 */
- (void)endUpdate;

/** 隐藏附属控件 */
-(void)setSubControlAlpha:(CGFloat)alpha;
@end
