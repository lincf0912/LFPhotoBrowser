//
//  PhotoBrowser.h
//  PhotoBrowser
//
//  Created by LamTsanFeng on 2016/9/28.
//  Copyright © 2016年 GZMiracle. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LFPhotoView.h"
#import "LFPhotoInfo.h"

//@class LFPhotoView, LFPhotoInfo;

/** ================================长按列表对象===================================== */

typedef NS_ENUM(NSInteger, LFPhotoSheetActionType) {
    /** 特殊按钮 */
    LFPhotoSheetActionType_Destructive = -1, //标题为红色,并且置顶（仅只一个）
    /** 默认显示 */
    LFPhotoSheetActionType_Default = 0, //普通标题
    /** 取消按钮 */
    LFPhotoSheetActionType_Cancel, //普通标题，隔离到最底部（仅只一个）
};

@class LFPhotoSheetAction;
typedef void (^LFPhotoSheetActionBlock)(id object);
@interface LFPhotoSheetAction : NSObject
/** 标题*/
@property (nonatomic, copy, readonly) NSString *title;
/** 响应block*/
@property (nonatomic, copy, readonly) LFPhotoSheetActionBlock handler;
/** 创建方法*/
+(LFPhotoSheetAction *)actionWithTitle:(NSString *)title style:(LFPhotoSheetActionType)style handler:(LFPhotoSheetActionBlock)handler;
@end



/** ================================图片预览===================================== */

typedef NS_ENUM(NSInteger, SlideDirection) {
    SlideDirection_Left, //向左滑动
    SlideDirection_Right, //向右滑动
};

@class LFPhotoBrowser;
@protocol LFPhotoBrowserDelegate <NSObject>

@optional
/* 即将显示 */
- (void)photoBrowserWillBeginShow:(LFPhotoBrowser *)photoBrowser;
/* 完全显示 */
- (void)photoBrowserDidBeginShow:(LFPhotoBrowser *)photoBrowser;
/* 即将关闭 */
- (void)photoBrowserWillEndShow:(LFPhotoBrowser *)photoBrowser;
/* 完全关闭 */
- (void)photoBrowserDidEndShow:(LFPhotoBrowser *)photoBrowser;

/** 获取startFrame或者overFrame */
- (CGRect)photoBrowserTargetFrameWithIndex:(int)index key:(NSString *)key;
/** 获取遮罩图片 */
- (UIImage *)photoBrowserTargetMaskImageWithIndex:(int)index key:(NSString *)key;
/** 设置长按列表 */
- (NSArray <LFPhotoSheetAction *>*)photoBrowserLongPressActionItems:(LFPhotoBrowser *)photoBrowser photoInfo:(LFPhotoInfo *)photoInfo object:(id /* UIImage * /NSURL * */)object;
/** 设置保存按钮（右下角） */
- (void)photoBrowserSavePreview:(LFPhotoBrowser *)photoBrowser photoInfo:(LFPhotoInfo *)photoInfo object:(id /* UIImage * /NSURL * */)object;
/** 设置更多按钮（右上角） */
- (void)photoBrowserMorePreview:(LFPhotoBrowser *)photoBrowser photoInfo:(LFPhotoInfo *)photoInfo object:(id /* UIImage * /NSURL * */)object;

/** 滑动(滑动增加数据源，调用 增加数据源方法)[异步回调] 获取数据后执行addDataSourceFormSlideDirection:dataSourceArray:回调数据源 */
- (void)photoBrowserDidSlide:(LFPhotoBrowser *)photoBrowser slideDirection:(SlideDirection)direction photoInfo:(LFPhotoInfo *)photoInfo;
@end

/** 内置SD下载图片，需要自定义下载实现下载协议 */
@protocol LFPhotoBrowserDownloadDelegate <NSObject>

/**
 *  方案一
 *  1、实现协议方法即表示关闭内置的SD下载
 *  2、依靠改变photoInfo的属性触发进度与优先级的调整
 *  3、下载完成后判断photoView.photoInfo == photoInfo 对象一致调用reloadPhotoView方法即可
 *
 *  方案二
 *  创建一个业务类继承LFPhotoBrowser，实现LFPhotoView的协议自定义下载
 */
@optional
/** 下载缩略图代理方法*/
-(void)photoBrowser:(LFPhotoBrowser *)photoBrowser downloadThumbnailWithPhotoInfo:(LFPhotoInfo *)photoInfo;
/** 下载原图代理方法*/
-(void)photoBrowser:(LFPhotoBrowser *)photoBrowser downloadOriginalWithPhotoInfo:(LFPhotoInfo *)photoInfo;
/** 下载视频代理方法*/
-(void)photoBrowser:(LFPhotoBrowser *)photoBrowser downloadVideoWithPhotoInfo:(LFPhotoInfo *)photoInfo;
@end

/**
 *  注意：不能使用UITableViewController或者UICollectionViewController上显示，因为这种类型UI整个view都可以滚动，所以滚动之后显示图片预览只能在滚到顶部才能看到，图片预览是加载在UI的view上，可以调整为加载在keyWindow上（showPhotoBrowser方法），但若需要使用图片预览的长按菜单点击事件来推送一个新UI（例如：扫描二维码），会被keyWindow遮挡无法看见推送界面；最好基础UIViewController 添加UITableView 来使用
 */

@interface LFPhotoBrowser : UIViewController <LFPhotoViewDelegate>
/** 数据源 */
@property (nonatomic, strong, readonly) NSArray <LFPhotoInfo *>*imageSources;
@property (nonatomic, assign, readonly) int curr;
/** 动画时间 default 0.25f */
@property (nonatomic, assign) NSTimeInterval animatedTime;
/** 遮盖view的颜色, default is clearColor*/
@property (nonatomic, strong) UIColor *coverViewColor;
/** 代理 */
@property (nonatomic, weak) id<LFPhotoBrowserDelegate> delegate;
@property (nonatomic, weak) id<LFPhotoBrowserDownloadDelegate> downloadDelegate;
/** block回调 效果等同于 LFPhotoBrowserDelegate代理, 若实现了代理，block将不会回调 */
@property (nonatomic, copy) CGRect (^targetFrameBlock)(int index, NSString *key);
@property (nonatomic, copy) UIImage * (^targetMaskImageBlock)(int index, NSString *key);
@property (nonatomic, copy) NSArray <LFPhotoSheetAction *>* (^longPressActionItemsBlock)(LFPhotoInfo *photoInfo, id /* UIImage * /NSURL * */ object);
@property (nonatomic, copy) void (^slideBlock)(SlideDirection direction, LFPhotoInfo *photoInfo);
/** 触发photoBrowserDidSlide:slideDirection:photoInfo:代理的范围（距离最后一张）,default is 2 */
@property (nonatomic, assign) NSUInteger slideRange;
/** 遮罩的位置,default is MaskPosition_Middle*/
@property (nonatomic, assign) MaskPosition maskPosition;
/** 是否可以循环滚动,default is NO */
@property (nonatomic, assign) BOOL canCirculate;
/** 是否需要pageControl,default is NO */
@property (nonatomic, assign) BOOL isNeedPageControl;
/** 是否需要下拉动画,default is NO */
@property (nonatomic, assign) BOOL canPullDown;
/** 是否淡化,default is NO*/
@property (nonatomic, assign) BOOL isWeaker;
/** 是否批量下载（数据源所有的对象进行下载,注意：开启后只会批量下载原图,并且只能使用内置下载 不会再调用downloadDelegate的原图下载方法。）,default is NO */
@property (nonatomic, assign) BOOL isBatchDownload;

/** 销毁回调 */
@property (nonatomic, copy) void (^dismissBlock)() __deprecated_msg("Block type deprecated. Use `photoBrowserDidEndShow:`");

/** 初始化 */
-(id)initWithImageArray:(NSArray <LFPhotoInfo *>*)imageArray;
-(id)initWithImageArray:(NSArray <LFPhotoInfo *>*)imageArray currentIndex:(int)currentIndex;
/** 显示相册
 状态栏隐藏：需要调用UI 重写childViewControllerForStatusBarHidden方法，返回当前UI才能控制状态栏（return self.childViewControllers.count ? self.childViewControllers.firstObject : nil;） */
-(void)showPhotoBrowser;
/** 刷新UI */
- (void)reloadView:(LFPhotoInfo *)photoInfo;

/** =======实现代理滑动 photoBrowserDidSlide:slideDirection:photoInfo: ======= */
/** 增加数据源[自动切换主线程] */
-(void)addDataSourceFormSlideDirection:(SlideDirection)direction dataSourceArray:(NSArray <LFPhotoInfo *>*)dataSource;

@end
