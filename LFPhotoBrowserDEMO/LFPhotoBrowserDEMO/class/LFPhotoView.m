//
//  photoView.m
//  PhotoBrowser
//
//  Created by LamTsanFeng on 2016/9/28.
//  Copyright © 2016年 GZMiracle. All rights reserved.
//

#import "LFPhotoView.h"
#import "LFPlayer.h"
#import "LFAVPlayerLayerView.h"
#import "LFVideoSlider.h"

#import "UIImage+LFPB_Format.h"

#import "LFImageProgressView.h"
#import "LFVideoProgressView.h"

#import "UIView+LFPB_CornerRadius.h"
#import "UIImage+LFPB_Size.h"

#import "UIImageView+LFWebCache.h"

#define kVideoSliderHeight 40.f

@interface LFPhotoView() <UIScrollViewDelegate, LFPlayerDelegate, LFVideoSliderDelegate>
{
    //    单击手势
    UITapGestureRecognizer *_singleTap;
    //    双击手势
    UITapGestureRecognizer *_doubleTap;
    //    长按手势
    UILongPressGestureRecognizer *_longPressGesture;
}

/** 百分比显示 */
@property (nonatomic, strong) UIView *progressView;

/** 遮罩层 */
@property (nonatomic, strong) UIImageView *imageMaskView;

/** 视图 */
@property (nonatomic, strong) LFAVPlayerLayerView *customView;

/** 视频播放器 */
@property (nonatomic, strong) LFPlayer *videoPlayer;

/** 播放提示文字 */
@property (nonatomic, strong) UILabel *tipsLabel;
/** 底部栏（播放按钮+进度条） */
@property (nonatomic, strong) LFVideoSlider *videoSlider;

/** 是否开启动画 */
@property (nonatomic, assign) BOOL isAminated;

@property (nonatomic, strong) NSMutableArray *delayMotheds;

/** 上次屏幕方向，判断方向是否发送变化 */
@property (nonatomic, assign) UIInterfaceOrientation prevOrientation;
@end

@implementation LFPhotoView

#pragma mark - 自定义视图
- (LFAVPlayerLayerView *)customView
{
    if (_customView == nil) {
        //初始化imageView 和 遮罩层
        LFAVPlayerLayerView *_imageView = [[LFAVPlayerLayerView alloc] initWithFrame:self.bounds];
        _imageView.contentMode = UIViewContentModeScaleAspectFit;
        [self addSubview:_imageView];
        _imageMaskView = [[UIImageView alloc]initWithFrame:_imageView.bounds];
        _imageMaskView.backgroundColor = [UIColor whiteColor];
        /** 设置遮罩 */
        [_imageView LFPB_setLayerMaskView:_imageMaskView];
        _customView = _imageView;
        _customView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
        _imageMaskView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    }
    return _customView;
}

- (UIView *)progressView
{
    /** 进度视图*/
    if (_progressView == nil) {
        if (self.photoInfo.photoType == PhotoType_image) {
            LFImageProgressView *progressView = [[LFImageProgressView alloc] initWithFrame:self.bounds];
            progressView.userInteractionEnabled = NO;
            [self addSubview:progressView];
            _progressView = progressView;
        } else if (self.photoInfo.photoType == PhotoType_video) {
            LFVideoProgressView *progressView = [[LFVideoProgressView alloc] init];
            progressView.center = CGPointMake(self.center.x-self.frame.origin.x, self.center.y-self.frame.origin.y);
            __weak typeof(self) weakSelf = self;
            [progressView setClickBlock:^{
                [weakSelf videoPlay];
            }];
            [self addSubview:progressView];
            _progressView = progressView;
        }
        _progressView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
    return _progressView;
}

-(instancetype)initWithFrame:(CGRect)frame
{
    if(self = [super initWithFrame:frame]){
        self.clipsToBounds = YES;
//        self.bounces = NO;
        //设置
        self.scrollsToTop = NO;
        self.delaysContentTouches = NO;
        self.showsVerticalScrollIndicator = NO;
        self.showsHorizontalScrollIndicator = NO;
        self.contentMode = UIViewContentModeScaleToFill;
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.backgroundColor = [UIColor clearColor];
        self.userInteractionEnabled = YES;
        self.autoresizesSubviews = NO;
        self.scrollEnabled = YES;
        
        //        self.bouncesZoom = NO;
        self.delegate = self;
        self.maximumZoomScale = 3.5f;
        self.minimumZoomScale = 1.f;
        
        _zoomEnable = YES;
        /** 默认正方向 */
        _orientation = UIInterfaceOrientationPortrait;
        _prevOrientation = UIInterfaceOrientationPortrait;
    }
    return self;
}

- (void)setPhotoViewDelegate:(id<LFPhotoViewDelegate>)photoViewDelegate
{
    _photoViewDelegate = photoViewDelegate;
    if (photoViewDelegate) {
        /** 添加手势*/
        [self addGesture];
    }
}

- (CGRect)photoRect
{
    return _customView.frame;
}

- (void)setPhotoRect:(CGRect)photoRect
{
    _customView.frame = photoRect;
}

-(void)layoutSubviews
{
    [super layoutSubviews];

    CGFloat bottom=0;
    if (@available(iOS 11.0, *)) {
        bottom += self.safeAreaInsets.bottom;
    }
    
    [_progressView setFrame:self.bounds];
    CGFloat videoSliderHeight = kVideoSliderHeight + bottom;
    [_videoSlider setFrame:CGRectMake(0, CGRectGetHeight(self.frame)-videoSliderHeight, CGRectGetWidth(self.frame), videoSliderHeight)];
    /** 判断屏幕是否发送变化 */
    if (self.orientation != self.prevOrientation) {
        self.prevOrientation = self.orientation;
        /** 重新排版 */
        [self calcFrameMaskPosition:MaskPosition_None frame:self.bounds];
    }
}

-(void)dealloc
{
    [self cleanData];
}

#pragma mark - 添加手势
-(void)addGesture
{
    //添加单击手势
    if (_singleTap == nil) {
        _singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
        _singleTap.delaysTouchesBegan = YES;
        _singleTap.numberOfTapsRequired = 1;
        [self addGestureRecognizer:_singleTap];
    }
    
    //添加双击手势
    if (_doubleTap == nil) {
        _doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
        _doubleTap.numberOfTapsRequired = 2;
        [self addGestureRecognizer:_doubleTap];
    }
    
    [_singleTap requireGestureRecognizerToFail:_doubleTap];
    
    //添加长按手势
    if (_longPressGesture == nil) {
        _longPressGesture = [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(longPressGestureAction:)];
        [self addGestureRecognizer:_longPressGesture];
    }
    
    /** 缩放手势-使用原生ScrollView的缩放 */
    
}

- (void)removeGesture
{
    [self removeGestureRecognizer:_singleTap];
    [self removeGestureRecognizer:_doubleTap];
    [self removeGestureRecognizer:_longPressGesture];
    _singleTap = nil;
    _doubleTap = nil;
    _longPressGesture = nil;
}

#pragma mark - 手势处理

- (id /* UIImage * /NSURL * */)getSelectObject
{
    id object = nil;
    if (self.photoInfo.photoType == PhotoType_image) {
        object = self.photoInfo.originalImage;
    } else if (self.photoInfo.photoType == PhotoType_video) {
        if (self.loadType == downLoadTypeLocale) { /** 本地视频才回调URL */
            object = self.videoPlayer.URL;
        }
    }
    return object;
}

#pragma mark 单击手势
- (void)handleSingleTap:(UIGestureRecognizer *)tap{
    //    if(!_customView) return;
    CGFloat delay = 0.f;
    if (self.zoomScale > 1.0) {//放大时单击缩小
        [self setZoomScale:1.f animated:YES];
        delay = .1f;
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        id object = [self getSelectObject];
        if([self.photoViewDelegate respondsToSelector:@selector(photoViewGesture:singleTapPhotoType:object:)]){
            [self.photoViewDelegate photoViewGesture:self singleTapPhotoType:self.photoInfo.photoType object:object];
        }
    });
}
#pragma mark 双击手势
- (void)handleDoubleTap:(UIGestureRecognizer *)tap
{
    if(!_customView) return;
    id object = [self getSelectObject];
    if (!object) return;
    
    if (self.zoomScale > 1.0) {//放大时单击缩小
        [self setZoomScale:1.f animated:YES];
    } else {
        CGPoint point = [tap locationInView:_customView];
        [self zoomToRect:(CGRect){point,1,1} animated:YES];
    }
    
    
    if([self.photoViewDelegate respondsToSelector:@selector(photoViewGesture:doubleTapPhotoType:object:)]){
        [self.photoViewDelegate photoViewGesture:self doubleTapPhotoType:self.photoInfo.photoType object:object];
    }
}

#pragma mark 长按手势
- (void)longPressGestureAction:(UILongPressGestureRecognizer *)longGesture
{
    if(!_customView) return;
    if(longGesture.state == UIGestureRecognizerStateBegan){
        id object = [self getSelectObject];
        if (object) {
            if([self.photoViewDelegate respondsToSelector:@selector(photoViewGesture:longPressPhotoType:object:)]){
                [self.photoViewDelegate photoViewGesture:self longPressPhotoType:self.photoInfo.photoType object:object];
            }
        }
    }
}

#pragma mark 缩放手势
#pragma mark UIScrollViewDelegate
- (nullable UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    // return a view that will be scaled. if delegate returns nil, nothing happens
    return self.zoomEnable ? _customView : nil;
}

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(nullable UIView *)view
{
    // called before the scroll view begins zooming its content
    
    if([self.photoViewDelegate respondsToSelector:@selector(photoViewWillBeginZooming:)]){
        [self.photoViewDelegate photoViewWillBeginZooming:self];
    }
    _progressView.alpha = 0.f;
    _videoSlider.alpha = 0.f;
    _tipsLabel.alpha = 0.f;
    /** 光栅化会影响图片放大的清晰度，放大将其关闭 */
    _customView.layer.shouldRasterize = NO;
}
- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(nullable UIView *)view atScale:(CGFloat)scale
{
    // scale between minimum and maximum. called after any 'bounce' animations
    
    if([self.photoViewDelegate respondsToSelector:@selector(photoViewDidEndZooming:)]){
        [self.photoViewDelegate photoViewDidEndZooming:self];
    }
    
    if (scale == 1.f) {
        _progressView.alpha = 1.f;
        _videoSlider.alpha = 1.f;
        _tipsLabel.alpha = 1.f;
        /** 还原重新恢复光栅化 */
        _customView.layer.shouldRasterize = YES;
    }
}
- (void)scrollViewDidZoom:(UIScrollView *)scrollView
{
    // any zoom scale changes
    
    [self setImageViewCenter];
    
    if([self.photoViewDelegate respondsToSelector:@selector(photoViewDidZoom:)]){
        [self.photoViewDelegate photoViewDidZoom:self];
    }
}

#pragma mark 设置图片居中
- (void)setImageViewCenter
{
    CGFloat offsetX = (self.bounds.size.width > self.contentSize.width)?(self.bounds.size.width - self.contentSize.width)/2 : 0.0;
    CGFloat offsetY = (self.bounds.size.height > self.contentSize.height)?(self.bounds.size.height - self.contentSize.height)/2 : 0.0;
    _customView.center = CGPointMake(self.contentSize.width/2 + offsetX,self.contentSize.height/2 + offsetY);
}

#pragma mark - 设置图片
-(void)setPhotoInfo:(id<LFModelProtocol, LFPhotoProtocol, LFVideoProtocol>)photoInfo
{
    if (_photoInfo != photoInfo) {
        [self cleanData];
        _photoInfo = photoInfo;
        //添加kvo
        [(NSObject *)self.photoInfo addObserver:self forKeyPath:@"downloadProgress" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:nil];
    }
    [self reloadPhotoView];
}

#pragma mark - 刷新photoView
-(void)reloadPhotoView
{
    [self selectLoadMethod];
    [self removePhotoLoadingView];
    if (self.photoInfo) {
        if (self.photoInfo.photoType == PhotoType_image) {
            [self loadPhotoViewImage];
        } else if (self.photoInfo.photoType == PhotoType_video) {
            [self loadPhotoViewVideo];
        }
    }
}

#pragma mark - 隐藏附属控件
-(void)setSubControlAlpha:(CGFloat)alpha
{
    CGFloat newAlpah = alpha < 0.9 ? alpha-0.5f : alpha;
    _progressView.alpha = newAlpah;
    self.videoSlider.alpha = newAlpah;
    self.tipsLabel.alpha = newAlpah;
}

#pragma mark - 选择加载方式
-(void)selectLoadMethod
{
    if (self.photoInfo.photoType == PhotoType_image) {
        if (self.photoInfo.downloadFail) {
            _loadType = downLoadTypeFail;
        }else if(_photoInfo.originalImageData){
            _loadType = downLoadTypeImage;
        }else if(_photoInfo.originalImage){
            _loadType = downLoadTypeImage;
        }else if(self.photoInfo.originalImagePath != nil && [[NSFileManager defaultManager] fileExistsAtPath:self.photoInfo.originalImagePath]){//存在路径和URL
            _loadType = downLoadTypeLocale;
        }else if(self.photoInfo.originalImageUrl){/*存在下载的URL*/
            _loadType = downLoadTypeNetWork;
        }else{
            _loadType = downLoadTypeUnknown;
        }
    } else if (self.photoInfo.photoType == PhotoType_video) {
        if (self.photoInfo.downloadFail) {
            _loadType = downLoadTypeFail;
        }else if(self.photoInfo.videoPath != nil && [[NSFileManager defaultManager] fileExistsAtPath:self.photoInfo.videoPath]){//存在路径和URL
            _loadType = downLoadTypeLocale;
        }else if(self.photoInfo.videoUrl){/*存在下载的URL*/
            _loadType = downLoadTypeNetWork;
        }else{
            _loadType = downLoadTypeUnknown;
        }
    }
}

#pragma mark - 加载imageView的image
-(void)loadPhotoViewImage
{
    switch (_loadType) {
        case downLoadTypeFail:
        {
            [self showPhotoLoadingFailure];
        }
            break;
        case downLoadTypeImage:
        {
            if (self.photoInfo.originalImage) {
                [self setImage:_photoInfo.originalImage];
            } else {
                UIImage *image = [UIImage LFPB_imageWithImageData:self.photoInfo.originalImageData];
                if (image == nil) {
                    [self showPhotoLoadingFailure];
                } else {                    
                    self.photoInfo.originalImage = image;
                    [self setImage:image];
                }
            }
        }
            break;
        case downLoadTypeLocale:
        {
            UIImage *image = [UIImage LFPB_imageWithImagePath:self.photoInfo.originalImagePath];
            
            if(image == nil){
                [self showPhotoLoadingFailure];
            } else {
                self.photoInfo.originalImage = image;
                [self setImage:image];
            }
        }
            break;
        case downLoadTypeNetWork:
        {
            /** 加载网络数据，优先判断缩略图 */
            [self setThumbnailImage];
            
            /** 下载原图*/
            [self showPhotoLoadingView];
            
            [self loadNormalImage];
        }
            break;
        case downLoadTypeUnknown:
            [self setThumbnailImage];
            break;
    }
}

#pragma mark - 加载imageView的video
-(void)loadPhotoViewVideo
{
    if (self.videoPlayer == nil) {
        self.videoPlayer = [LFPlayer new];
        self.videoPlayer.delegate = self;
    }
    
    switch (_loadType) {
        case downLoadTypeFail:
        {
            [self showPhotoLoadingFailure];
        }
            break;
        case downLoadTypeLocale:
        {
            [self setThumbnailImage];
            self.photoInfo.downloadProgress = 1.f;
            /** 显示播放按钮 */
            [self showPhotoLoadingView];
            
            [_videoPlayer setURL:[NSURL fileURLWithPath:self.photoInfo.videoPath]];
        }
            break;
        case downLoadTypeNetWork:
        {
            /** 加载网络数据，优先判断缩略图 */
            [self setThumbnailImage];
            
            /** 显示播放按钮 */
            [self showPhotoLoadingView];
        }
            break;
        case downLoadTypeImage:
        case downLoadTypeUnknown:
            [self setThumbnailImage];
            break;
    }
}

- (void)setThumbnailImage
{
    if (_photoInfo.thumbnailImage){
        [self setImage:_photoInfo.thumbnailImage];
    }else{
        UIImage *thumbnailImage = [UIImage LFPB_imageWithImagePath:self.photoInfo.thumbnailPath];
        if(thumbnailImage){
            self.photoInfo.thumbnailImage = thumbnailImage;
            [self setImage:thumbnailImage];
        }else{
            [self setImage:self.photoInfo.placeholderImage];
            [self loadThumbnailImage];//下载缩略图
        }
    }
}

#pragma mark - 下载缩略图
-(void)loadThumbnailImage
{
    if (self.photoInfo.thumbnailUrl) {
        BOOL SD_DL = YES;
        //如果代理实现缩略图下载方法，则优先执行代理的下载方法
        if(self.photoViewDelegate && [self.photoViewDelegate respondsToSelector:@selector(photoViewDownLoadThumbnail:url:)]){
            SD_DL = ![self.photoViewDelegate photoViewDownLoadThumbnail:self url:self.photoInfo.thumbnailUrl];
        }
        
        if (SD_DL) {
            //使用SD下载
            __weak typeof(self) weakSelf = self;
            [_customView lf_setImageWithURL:[NSURL URLWithString:self.photoInfo.thumbnailUrl] placeholderImage:_customView.image options:LFWebImageAvoidAutoSetImage completed:^(UIImage *image, NSError *error, NSURL *imageURL) {
                
                if ([imageURL.absoluteString isEqualToString:weakSelf.photoInfo.thumbnailUrl]) {
                    if(image){//下载成功
                        weakSelf.photoInfo.thumbnailImage = image;
                        if (weakSelf.photoInfo.photoType == PhotoType_image) {
                            if(!weakSelf.photoInfo.originalImage){//判断是否已经显示原图,没有才显示缩略图
                                [weakSelf reloadPhotoView];
                            }
                        } else if (weakSelf.photoInfo.photoType == PhotoType_video) {
                            if (weakSelf.videoPlayer.isPlaying == NO) {
                                [weakSelf reloadPhotoView];
                            }
                        }
                    }
                }
            }];
        }
    }
}

#pragma mark - 下载原图
-(void)loadNormalImage
{
    if (self.photoInfo.originalImageUrl) {
        BOOL SD_DL = YES;
        //代理有实现原图下载方法，优先选择代理下载
        if(self.photoViewDelegate && [self.photoViewDelegate respondsToSelector:@selector(photoViewDownLoadOriginal:url:)]){
            SD_DL = ![self.photoViewDelegate photoViewDownLoadOriginal:self url:self.photoInfo.originalImageUrl];
        }
        
        if (SD_DL) {
            //使用SD下载原图
            __weak typeof(self) weakSelf = self;
            __weak typeof(self.photoInfo.originalImageUrl) weakURL = self.photoInfo.originalImageUrl;
            
            [_customView lf_setImageWithURL:[NSURL URLWithString:self.photoInfo.originalImageUrl] placeholderImage:_customView.image options:LFWebImageAvoidAutoSetImage progress:^(int64_t receivedSize, int64_t expectedSize, NSURL *imageURL) {
                if (weakSelf.photoInfo.originalImageUrl != weakURL) return ;
                /*设置进度*/
                weakSelf.photoInfo.downloadProgress = (float)receivedSize/expectedSize;
            } completed:^(UIImage *image, NSError *error, NSURL *imageURL) {
                if ([imageURL.absoluteString isEqualToString:weakSelf.photoInfo.originalImageUrl]) {
                    if(image){/*下载成功*/
                        weakSelf.photoInfo.originalImage = image;
                        [weakSelf reloadPhotoView];
                    }else{/*下载失败*/
                        weakSelf.photoInfo.downloadFail = YES;
                        [weakSelf reloadPhotoView];
                    }
                }
            }];
        }
    }
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    if([keyPath isEqualToString:@"downloadProgress"]){
        if(change[@"new"] != change[@"old"]){
            [self photoLoadingViewProgress:[change[@"new"] floatValue]];
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - 清除
-(void)cleanData
{
    /** 重置大小 */
    self.contentSize = self.bounds.size;
    [self setZoomScale:1.f];
    if(_photoInfo){
        //移除kvo
        [(NSObject *)_photoInfo removeObserver:self forKeyPath:@"downloadProgress"];
        //删除对象
        _photoInfo = nil;
        //图片设置为空
        [_customView removeFromSuperview];
        _customView.image = nil;
        _customView = nil;
        self.imageMaskView = nil;
        //移除加载视图
        [self removePhotoLoadingView];
        
        self.videoPlayer.delegate = nil;
        self.videoPlayer = nil;
        [self.tipsLabel removeFromSuperview];
        self.tipsLabel = nil;
        [self.videoSlider removeFromSuperview];
        self.videoSlider = nil;
        
        self.isAminated = NO;
        [self.delayMotheds removeAllObjects];
    }
}

- (void)closeVideo
{
    [self.videoPlayer pause];
    self.videoPlayer.delegate = nil;
    self.videoPlayer = nil;
}

#pragma mark - 设置图片
-(void)setImage:(UIImage *)image
{
    self.customView.image = image;
    [self calcFrameMaskPosition:MaskPosition_None frame:self.bounds];
}

#pragma mark - 显示进度
-(void)showPhotoLoadingView
{
    if (self.photoInfo.photoType == PhotoType_image) {
        [(LFImageProgressView *)self.progressView showLoading];
        ((LFImageProgressView *)self.progressView).progress = self.photoInfo.downloadProgress;
    } else if (self.photoInfo.photoType == PhotoType_video) {
        [(LFVideoProgressView *)self.progressView showLoading];
        if (self.photoInfo.downloadProgress > 0) {
            ((LFVideoProgressView *)self.progressView).progress = self.photoInfo.downloadProgress;
        } else if (self.photoInfo.isLoading) {
            ((LFVideoProgressView *)self.progressView).progress = 1.f;
        }
    }
}

#pragma mark - 设置进度
-(void)photoLoadingViewProgress:(float)progress
{
    if (self.photoInfo.photoType == PhotoType_image) {
        ((LFImageProgressView *)self.progressView).progress = progress;
    } else if (self.photoInfo.photoType == PhotoType_video) {
        ((LFVideoProgressView *)self.progressView).progress = progress;
    }
}

#pragma mark - 移除进度
-(void)removePhotoLoadingView
{
    [_progressView removeFromSuperview];
    _progressView = nil;
}

#pragma mark - 显示加载失败
-(void)showPhotoLoadingFailure
{
    if (self.photoInfo.photoType == PhotoType_image) {
        //显示加载失败时清空默认图片
        [UIView animateWithDuration:0.2f animations:^{
            _customView.alpha = 0.f;
        } completion:^(BOOL finished) {
            [_customView removeFromSuperview];
            _customView = nil;
            self.imageMaskView = nil;
            [(LFImageProgressView *)self.progressView showFailure];
        }];
    } else if (self.photoInfo.photoType == PhotoType_video) {
        [(LFVideoProgressView *)self.progressView showFailure];
    }
}

#pragma mark - 计算imageView的frame
-(void)calcFrameMaskPosition:(MaskPosition)maskPosition frame:(CGRect)frame
{
    [self setContentOffset:CGPointZero];
    _progressView.alpha = CGRectEqualToRect(frame, self.bounds) ? 1.f : 0.f;
    CGRect imageFrame = frame;
    CGRect maskFrame = (CGRect){CGPointZero, frame.size};
    CGSize imageSize = frame.size;
    CGSize videoSize = CGSizeEqualToSize(CGSizeZero, _customView.image.size) ? self.videoPlayer.size : _customView.image.size;
    
    if (self.orientation == UIInterfaceOrientationLandscapeLeft || self.orientation == UIInterfaceOrientationLandscapeRight) { /** 横屏 */
        if (maskPosition == MaskPosition_None) {
            CGSize verticalSize = [UIImage LFPB_scaleImageSizeBySize:videoSize targetSize:CGSizeMake(frame.size.height, CGFLOAT_MAX) isBoth:NO];
            imageSize = [UIImage LFPB_scaleImageSizeBySize:videoSize targetSize:frame.size isBoth:NO];
            /** 计算相对宽度 */
            CGFloat scale = MAX(verticalSize.height/frame.size.width, 1.f);
            scale = !isnan(scale) ?: 0;
            imageSize = CGSizeMake(imageSize.width*scale, imageSize.height*scale);
        } else {
            imageSize = [UIImage LFPB_scaleImageSizeBySize:videoSize targetSize:frame.size isBoth:YES];
        }
    } else { /** 竖屏 */
        if (maskPosition == MaskPosition_None) {
            /** 判断宽度，拉伸 */
            imageSize = [UIImage LFPB_scaleImageSizeBySize:videoSize targetSize:CGSizeMake(frame.size.width, CGFLOAT_MAX) isBoth:NO];
        } else {
            /** 对两边判断，拉伸最小值(缩放效果实现) */
            imageSize = [UIImage LFPB_scaleImageSizeBySize:videoSize targetSize:frame.size isBoth:YES];
        }
    }
    
    
    if (CGSizeEqualToSize(CGSizeZero, imageSize)) {
        imageSize = frame.size;
    }
    imageFrame.size = imageSize;
    
    
    CGFloat offSetX = imageSize.width - frame.size.width;
    CGFloat offSetY = imageSize.height - frame.size.height;
    
    switch (maskPosition) {
        case MaskPosition_LeftOrUp:{
            maskFrame.origin.x = 0;
            maskFrame.origin.y = 0;
        }
            break;
        case MaskPosition_Middle:
        {
            imageFrame.origin.x -= offSetX/2;
            imageFrame.origin.y -= offSetY/2;
            maskFrame.origin.x = offSetX/2;
            maskFrame.origin.y = offSetY/2;
        }
            break;
        case MaskPosition_RightOrDown:
        {
            imageFrame.origin.x -= offSetX;
            imageFrame.origin.y -= offSetY;
            maskFrame.origin.x = offSetX;
            maskFrame.origin.y = offSetY;
        }
            break;
        case MaskPosition_None:
        {
            /** 适配遮罩层大小 */
            CGSize maskSize = self.bounds.size;
            if (imageFrame.size.width > self.bounds.size.width) {
                maskSize.width = imageFrame.size.width;
            }
            if (imageFrame.size.height > self.bounds.size.height) {
                maskSize.height = imageFrame.size.height;
            }
            
            maskFrame = (CGRect){CGPointZero, maskSize};
            /** 计算y差值 */
            if (offSetY < 0) {
                imageFrame.origin.y += fabs(offSetY)/2;
            }
            /** 计算x差值 */
            if (offSetX < 0) {
                imageFrame.origin.x += fabs(offSetX)/2;
            }
        }
            break;
    }
    _customView.frame = imageFrame;
    //遮罩位置
    self.imageMaskView.frame = maskFrame;
    
    /** 重设contentSize */
    if (imageFrame.size.width > self.bounds.size.width || imageFrame.size.height > self.bounds.size.height) {
        CGSize contentSize = self.bounds.size;
        if (imageFrame.size.width > self.bounds.size.width) {
            contentSize.width = imageFrame.size.width;
        }
        if (imageFrame.size.height > self.bounds.size.height) {
            contentSize.height = imageFrame.size.height;
        }
        
        self.contentSize = contentSize;
    } else {
        self.contentSize = self.bounds.size;
    }
}

#pragma mark - 设置遮罩图片
- (void)setMaskImage:(UIImage *)maskImage
{
    /** 修改遮罩图片 */
    if (maskImage) {
        self.imageMaskView.image = maskImage;
        self.imageMaskView.backgroundColor = [UIColor clearColor];
    } else {
        self.imageMaskView.backgroundColor = [UIColor whiteColor];
        self.imageMaskView.image = nil;
    }
}

#pragma mark - 视频操作事件
- (void)videoPlay
{
    /** 视频失败后，重新下载 */
    if (self.photoInfo.downloadFail) {
        self.photoInfo.downloadFail = NO;
        [self selectLoadMethod];
    }
    if (self.loadType == downLoadTypeNetWork) {
        BOOL isDownLoad = NO;
        /** 下载视频*/
        if(self.photoViewDelegate && [self.photoViewDelegate respondsToSelector:@selector(photoViewDownLoadVideo:url:)]){
            isDownLoad = [self.photoViewDelegate photoViewDownLoadVideo:self url:self.photoInfo.videoUrl];
        }
        if (!isDownLoad) {
            /** 没有实现代理，执行在线播放 */
            [_videoPlayer setURL:[NSURL URLWithString:self.photoInfo.videoUrl]];
        }
        
    } else if (self.loadType == downLoadTypeLocale){
        [_videoPlayer setURL:[NSURL fileURLWithPath:self.photoInfo.videoPath]];
    } else {
        [self showPhotoLoadingFailure];
    }
}

#pragma mark - LFPlayerDelegate
/** 画面回调 */
- (void)LFPlayerLayerDisplay:(LFPlayer *)player avplayer:(AVPlayer *)avplayer
{
    [self removePhotoLoadingView];
    
    if (self.isAminated) {
        __weak typeof(self) weakSelf = self;
        __weak LFAVPlayerLayerView *blockCustomView = _customView;
        [self addDelayAminateMothed:^{
            [blockCustomView setPlayer:avplayer];
            [weakSelf calcFrameMaskPosition:MaskPosition_None frame:weakSelf.bounds];
        }];
    } else {
        [_customView setPlayer:avplayer];
        [self calcFrameMaskPosition:MaskPosition_None frame:self.bounds];
    }
}
/** 可以播放 */
- (void)LFPlayerReadyToPlay:(LFPlayer *)player duration:(double)duration
{
    
    void (^videoPlay)(id<LFModelProtocol, LFPhotoProtocol, LFVideoProtocol>, LFVideoSlider *, LFPlayer *) = ^(id<LFModelProtocol, LFPhotoProtocol, LFVideoProtocol>photoInfo, LFVideoSlider *slider, LFPlayer *player){
        if (photoInfo.isNeedSlider) {
            [slider setTotalSecond:duration];
            if (photoInfo.isAutoPlay) {
                [player play];
            }
        } else {
            [player play];
        }
    };
    
    __weak id<LFModelProtocol, LFPhotoProtocol, LFVideoProtocol>photoInfo = self.photoInfo;
    __weak LFVideoSlider *slider = self.videoSlider;
    __weak LFPlayer *videoPlayer = self.videoPlayer;
    if (self.isAminated) {
        [self addDelayAminateMothed:^{
            videoPlay(photoInfo, slider, videoPlayer);
        }];
    } else {
        videoPlay(photoInfo, slider, videoPlayer);
    }
    
}
/** 播放结束 */
- (void)LFPlayerPlayDidReachEnd:(LFPlayer *)player
{
    if (!self.photoInfo.isNeedSlider) {
        if (self.tipsLabel == nil) {
            CGFloat height = 30;
            /** 不能直接使用CGRectGetMaxY(_customView.frame)，有下拉缩放的情况坐标需要重新计算 */
            CGSize videoSize = CGSizeEqualToSize(CGSizeZero, _customView.image.size) ? self.videoPlayer.size : _customView.image.size;
            CGSize imageSize = [UIImage LFPB_scaleImageSizeBySize:videoSize targetSize:CGSizeMake(self.frame.size.width, CGFLOAT_MAX) isBoth:NO];
            CGFloat y = (CGRectGetHeight(self.frame) + imageSize.height)/2;
            if (CGRectGetHeight(self.frame) < y+height) {
                y = CGRectGetHeight(self.frame) - height;
            }
            self.tipsLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, y, self.bounds.size.width, height)];
            self.tipsLabel.textColor = [UIColor whiteColor];
            self.tipsLabel.font = [UIFont boldSystemFontOfSize:13.f];
            self.tipsLabel.textAlignment = NSTextAlignmentCenter;
            self.tipsLabel.userInteractionEnabled = NO;
            self.tipsLabel.text = @"轻触退出";
            if (!CGSizeEqualToSize(_customView.frame.size, imageSize)) {
                self.tipsLabel.alpha = 0.f;
            }
            [self addSubview:self.tipsLabel];
        }
        [self.videoPlayer play];
    } else {
        [self.videoPlayer resetDisplay];
        [self.videoSlider reset];
    }
}
/** 进度回调 */
- (UISlider *)LFPlayerSyncScrub:(LFPlayer *)player
{
    if (self.photoInfo.isNeedSlider) {
        if (self.videoSlider == nil) {
            self.videoSlider = [[LFVideoSlider alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(self.frame)-kVideoSliderHeight, CGRectGetWidth(self.frame), kVideoSliderHeight)];
            self.videoSlider.delegate = self;;
            [self addSubview:self.videoSlider];
            [self.videoSlider setTotalSecond:0];
        }
        return self.videoSlider.slider;
    }
    return nil;
}
/** 错误回调 */
- (void)LFPlayerFailedToPrepare:(LFPlayer *)player error:(NSError *)error
{
    [self showPhotoLoadingFailure];
}

#pragma mark - LFVideoSliderDelegate
/** 是否播放 */
- (void)LFVideoSlider:(LFVideoSlider *)videoSlider isPlay:(BOOL)isPlay
{
    isPlay ? [self.videoPlayer play] : [self.videoPlayer pause];
}
/** 开始滑动 */
- (void)LFVideoSliderBeginChange:(LFVideoSlider *)videoSlider
{
    [self.videoPlayer beginScrubbing];
}
/** 滑动中 */
- (void)LFVideoSliderChangedValue:(LFVideoSlider *)videoSlider
{
    [self.videoPlayer scrub:videoSlider.slider];
}
/** 结束滑动 */
- (void)LFVideoSliderEndChange:(LFVideoSlider *)videoSlider
{
    [self.videoPlayer endScrubbing];
    /** 添加手势 */
    [self addGesture];
}

#pragma mark - 重写父类方法
- (BOOL)touchesShouldBegin:(NSSet *)touches withEvent:(UIEvent *)event inContentView:(UIView *)view {
    
    if ([view isKindOfClass:[LFVideoSlider class]]) { /** 不触发任何事件 */
        return NO;
    }
    if ([view isKindOfClass:[UISlider class]]) {
        BOOL isTouch = [super touchesShouldBegin:touches withEvent:event inContentView:view];
        if (isTouch) {
            /** 移除当前手势 */
            [self removeGesture];
        }
        return isTouch;
    }
    
    return YES;
}

/** 响应手势，让长图（超出屏幕长度的图片）触发下拉缩放手势 */
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    /** 不响应2个LFScrollView的响应。 */
    if (gestureRecognizer.view != self && [gestureRecognizer.view isKindOfClass:[UIScrollView class]]) {
        return NO;
    }
    if (otherGestureRecognizer.view != self && [otherGestureRecognizer.view isKindOfClass:[UIScrollView class]]) {
        return NO;
    }
    return YES;
}

#pragma mark - 更新动画
- (void)beginUpdate
{
    _isAminated = YES;
}

- (void)endUpdate
{
    _isAminated = NO;
    for (void (^mothed)(void) in self.delayMotheds) {
        mothed();
    }
    [self.delayMotheds removeAllObjects];
}

- (void)addDelayAminateMothed:(void (^)(void))mothed
{
    if (mothed == nil) return;
    if (self.delayMotheds == nil) {
        self.delayMotheds = [@[] mutableCopy];
    }
    [self.delayMotheds addObject:mothed];
}

@end
