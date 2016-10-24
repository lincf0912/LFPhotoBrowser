//
//  photoView.m
//  PhotoBrowser
//
//  Created by LamTsanFeng on 2016/9/28.
//  Copyright © 2016年 GZMiracle. All rights reserved.
//

#import "LFPhotoView.h"
#import <UIImageView+WebCache.h>
#import "UIImage+MultiFormat.h"

#import "MLPhotoLoadingView.h"
#import "UIView+CornerRadius.h"
#import "UIImage+Size.h"

@interface LFPhotoView() <UIScrollViewDelegate>
{
    
}

/** 百分比显示 */
@property (nonatomic, strong) UIView *progressView;

/** 遮罩最终位置 */
@property (nonatomic, assign) CGRect finalMaskRect;

/** 遮罩层 */
@property (nonatomic, strong) UIImageView *imageMaskView;

/** 视图 */
@property (nonatomic, strong) UIImageView *customView;

@end

@implementation LFPhotoView

#pragma mark - 自定义视图
- (UIImageView *)customView
{
    if (_customView == nil) {
        if (self.photoInfo.photoType == PhotoType_image) {
            //初始化imageView 和 遮罩层
            UIImageView *_imageView = [[UIImageView alloc] initWithFrame:self.bounds];
            _imageView.contentMode = UIViewContentModeScaleAspectFit;
            [self addSubview:_imageView];
            _imageMaskView = [[UIImageView alloc]initWithFrame:_imageView.bounds];
            _imageMaskView.backgroundColor = [UIColor whiteColor];
            /** 设置遮罩 */
            [_imageView setLayerMaskView:_imageMaskView];
            _customView = _imageView;
        }
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
            MLPhotoLoadingView *progressView = [[MLPhotoLoadingView alloc] initWithFrame:self.bounds];
            [self addSubview:progressView];
            _progressView = progressView;
        }
        _progressView.userInteractionEnabled = NO;
        _progressView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
    return _progressView;
}

-(instancetype)initWithFrame:(CGRect)frame
{
    if(self = [super initWithFrame:frame]){
        self.clipsToBounds = YES;
        
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
        self.scrollEnabled= YES;

//        self.bouncesZoom = NO;
        self.delegate = self;
        self.maximumZoomScale = 3.5f;
        self.minimumZoomScale = 1.f;
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

-(void)layoutSubviews
{
    [super layoutSubviews];
    
    if (self.photoInfo.photoType == PhotoType_image) {
        [_progressView setFrame:self.bounds];
    } else if (self.photoInfo.photoType == PhotoType_video) {
        
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
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    singleTap.delaysTouchesBegan = YES;
    singleTap.numberOfTapsRequired = 1;
    [self addGestureRecognizer:singleTap];
    
    //添加双击手势
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
    doubleTap.numberOfTapsRequired = 2;
    [self addGestureRecognizer:doubleTap];
    
    [singleTap requireGestureRecognizerToFail:doubleTap];
    
    //添加长按手势
    UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(longPressGestureAction:)];
    [self addGestureRecognizer:longPressGesture];
    
    /** 缩放手势-使用原生ScrollView的缩放 */
    
}

#pragma mark - 手势处理
#pragma mark 单击手势
- (void)handleSingleTap:(UIGestureRecognizer *)tap{
//    if(!_customView) return;
    CGFloat delay = 0.f;
    if (self.zoomScale > 1.0) {//放大时单击缩小
        [self setZoomScale:1.f animated:YES];
        delay = .1f;
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if([self.photoViewDelegate respondsToSelector:@selector(photoViewGesture:singleTapImageView:)]){
            [self.photoViewDelegate photoViewGesture:self singleTapImageView:_customView];
        }
    });
}
#pragma mark 双击手势
- (void)handleDoubleTap:(UIGestureRecognizer *)tap
{
    if(!_customView) return;
    if (self.zoomScale > 1.0) {//放大时单击缩小
        [self setZoomScale:1.f animated:YES];
    } else {
        CGPoint point = [tap locationInView:_customView];
        [self zoomToRect:(CGRect){point,1,1} animated:YES];
    }
    
    if([self.photoViewDelegate respondsToSelector:@selector(photoViewGesture:doubleTapImageView:)]){
        [self.photoViewDelegate photoViewGesture:self doubleTapImageView:_customView];
    }
}

#pragma mark 长按手势
- (void)longPressGestureAction:(UILongPressGestureRecognizer *)longGesture
{
    if(!_customView) return;
    if(longGesture.state == UIGestureRecognizerStateBegan){
        if([self.photoViewDelegate respondsToSelector:@selector(photoViewGesture:longPressImageView:)]){
            [self.photoViewDelegate photoViewGesture:self longPressImageView:_customView];
        }
    }
}

#pragma mark 缩放手势
#pragma mark UIScrollViewDelegate
- (nullable UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    // return a view that will be scaled. if delegate returns nil, nothing happens
    return _customView;
}

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(nullable UIView *)view
{
    // called before the scroll view begins zooming its content
    
    if([self.photoViewDelegate respondsToSelector:@selector(photoViewWillBeginZooming:)]){
        [self.photoViewDelegate photoViewWillBeginZooming:self];
    }
}
- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(nullable UIView *)view atScale:(CGFloat)scale
{
    // scale between minimum and maximum. called after any 'bounce' animations
    
    if([self.photoViewDelegate respondsToSelector:@selector(photoViewDidEndZooming:)]){
        [self.photoViewDelegate photoViewDidEndZooming:self];
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
-(void)setPhotoInfo:(LFPhotoInfo *)photoInfo
{
    if (_photoInfo != photoInfo) {
        [self cleanData];
        _photoInfo = photoInfo;
        
        //添加kvo
        [self.photoInfo addObserver:self forKeyPath:@"downloadProgress" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:nil];
    }
    [self reloadPhotoView];
}

#pragma mark - 刷新photoView
-(void)reloadPhotoView
{
    //sd-cancle下载
    [_customView sd_cancelCurrentImageLoad];
    [self selectLoadMethod];
    [self loadPhotoViewImage];
}

#pragma mark - 选择加载方式
-(void)selectLoadMethod
{
    if (self.photoInfo.downloadFail) {
        _loadType = downLoadTypeFail;
    }else if(_photoInfo.localImage){
        _loadType = downLoadTypeImage;
    }else if(self.photoInfo.localImagePath != nil && [[NSFileManager defaultManager] fileExistsAtPath:self.photoInfo.localImagePath]){//存在路径和URL
        _loadType = downLoadTypeLocale;
    }else if(self.photoInfo.localImageUrl){/*存在下载的URL*/
        _loadType = downLoadTypeNetWork;
    }else{
        _loadType = downLoadTypeUnknown;
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
            [self setImage:_photoInfo.localImage];
        }
            break;
        case downLoadTypeLocale:
        {
            NSData *imageData = nil;
            if (self.photoInfo.localImagePath.length) {                
                imageData = [[NSData alloc]initWithContentsOfFile:self.photoInfo.localImagePath options:NSDataReadingMappedIfSafe error:nil];
            }
            UIImage *image = [UIImage sd_imageWithData:imageData];
            
            if(image == nil){
                image = self.photoInfo.placeholderImage;
            } else {
                self.photoInfo.localImage = image;
            }
            [self setImage:image];
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

- (void)setThumbnailImage
{
    if (_photoInfo.thumbnailImage){
        [self setImage:_photoInfo.thumbnailImage];
    }else{
        NSData *imageData = nil;
        if (self.photoInfo.thumbnailPath.length) {
            imageData = [[NSData alloc]initWithContentsOfFile:self.photoInfo.thumbnailPath options:NSDataReadingMappedIfSafe error:nil];
        }
        UIImage *thumbnailImage = [UIImage sd_imageWithData:imageData];
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
    //如果代理实现缩略图下载方法，则优先执行代理的下载方法
    if(self.photoViewDelegate && [self.photoViewDelegate respondsToSelector:@selector(downLoadthumbnailInPhotoView:)]){
        [self.photoViewDelegate downLoadthumbnailInPhotoView:self];
    }else{//使用SD下载
        if (self.photoInfo.thumbnailUrl) {
            __weak typeof(self) weakSelf = self;
            [_customView sd_setImageWithURL:[NSURL URLWithString:self.photoInfo.thumbnailUrl] placeholderImage:_customView.image options:SDWebImageRetryFailed|SDWebImageLowPriority|SDWebImageAvoidAutoSetImage completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                if ([imageURL.absoluteString isEqualToString:weakSelf.photoInfo.thumbnailUrl]) {
                    if(image){//下载成功
                        weakSelf.photoInfo.thumbnailImage = image;
                        if(!weakSelf.photoInfo.localImage){//判断是否已经显示原图,没有才显示缩略图
                            [weakSelf setImage:image];
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
    [self photoLoadingViewProgress:self.photoInfo.downloadProgress];
    //代理有实现原图下载方法，优先选择代理下载
    if(self.photoViewDelegate && [self.photoViewDelegate respondsToSelector:@selector(downLoadImageInPhotoView:)]){
        [self.photoViewDelegate downLoadImageInPhotoView:self];
    }else{//使用SD下载原图
        if (self.photoInfo.localImageUrl) {
            __weak typeof(self) weakSelf = self;
            __weak typeof(self.photoInfo.localImageUrl) weakURL = self.photoInfo.localImageUrl;
            [_customView sd_setImageWithURL:[NSURL URLWithString:self.photoInfo.localImageUrl] placeholderImage:_customView.image options:SDWebImageRetryFailed|SDWebImageLowPriority|SDWebImageAvoidAutoSetImage progress:^(NSInteger receivedSize, NSInteger expectedSize) {
                if (weakSelf.photoInfo.localImageUrl != weakURL) return ;
                /*设置进度*/
                weakSelf.photoInfo.downloadProgress = (float)receivedSize/expectedSize;
            } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                if ([imageURL.absoluteString isEqualToString:weakSelf.photoInfo.localImageUrl]) {
                    if(image){/*下载成功*/
                        weakSelf.photoInfo.localImage = image;
                        [weakSelf setImage:image];
                        [weakSelf removePhotoLoadingView];
                    }else{/*下载失败*/
                        weakSelf.photoInfo.downloadFail = YES;
                        [weakSelf showPhotoLoadingFailure];//没有缩略图显示烂图
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
    if(_photoInfo){
        //移除kvo
        [_photoInfo removeObserver:self forKeyPath:@"downloadProgress"];
        //删除对象
        _photoInfo = nil;
        //图片设置为空
        [_customView removeFromSuperview];
        _customView = nil;
        self.imageMaskView = nil;
        //移除加载视图
        [self removePhotoLoadingView];
    }
}

#pragma mark - 设置图片
-(void)setImage:(UIImage *)image
{
    if (self.photoInfo.photoType == PhotoType_image) {
        self.customView.image = image;
        
        [self calcFrameMaskPosition:MaskPosition_None frame:self.bounds];
    }
}

#pragma mark - 显示进度
-(void)showPhotoLoadingView
{
    if (self.photoInfo.photoType == PhotoType_image) {
        [(MLPhotoLoadingView *)self.progressView showLoading];
        ((MLPhotoLoadingView *)self.progressView).progress = self.photoInfo.downloadProgress;
    }
}

#pragma mark - 设置进度
-(void)photoLoadingViewProgress:(float)progress
{
    if (self.photoInfo.photoType == PhotoType_image) {
        ((MLPhotoLoadingView *)self.progressView).progress = progress;
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
            [(MLPhotoLoadingView *)self.progressView showFailure];
        }];
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
    if (maskPosition == MaskPosition_None) {
        /** 判断宽度，拉伸 */
        imageSize = [UIImage scaleImageSizeBySize:_customView.image.size targetSize:CGSizeMake(frame.size.width, CGFLOAT_MAX) isBoth:NO];
    } else {
        /** 对两边判断，拉伸最小值 */
        imageSize = [UIImage scaleImageSizeBySize:_customView.image.size targetSize:frame.size isBoth:YES];
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
    }
}

@end
