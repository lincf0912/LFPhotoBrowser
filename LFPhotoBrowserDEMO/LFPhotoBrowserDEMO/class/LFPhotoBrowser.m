//
//  PhotoBrowser.m
//  PhotoBrowser
//
//  Created by LamTsanFeng on 2016/9/28.
//  Copyright © 2016年 GZMiracle. All rights reserved.
//

#import "LFPhotoBrowser.h"
#import "LFPhotoScrollView.h"
#import "LFActionSheet.h"
#import "UIViewController+LFPB_Extension.h"
#import <AVFoundation/AVFoundation.h>
#import "LFDownloadManager.h"

#define kRound(f) (round(f*10)/10)

#define SCREEN_WIDTH [[UIScreen mainScreen] bounds].size.width
#define SCREEN_HEIGHT ([[UIScreen mainScreen] bounds].size.height)

/** 左右滑动的效果显示 */
#define kScrollAminated 1 //0

/** 方案1 */
#define kShieldViewW (kScrollAminated ? 50 : 0)
/** 方案2 */
#define kScrollViewMargin (kScrollAminated ? 0 : 30)
#define kScrollViewW (SCREEN_WIDTH+kScrollViewMargin)

#define kAnimatedTime 0.25f

#define kMoreButtonMargin 20.f

/** ================================长按列表对象===================================== */
@interface LFPhotoSheetAction ()

/** 标题*/
@property (nonatomic, copy) NSString *title;
/** 响应block*/
@property (nonatomic, copy) LFPhotoSheetActionBlock handler;
/** 类型 */
@property (nonatomic, assign) LFPhotoSheetActionType style;

@end

@implementation LFPhotoSheetAction

+(LFPhotoSheetAction *)actionWithTitle:(NSString *)title style:(LFPhotoSheetActionType)style handler:(LFPhotoSheetActionBlock)handler
{
    LFPhotoSheetAction *action = [LFPhotoSheetAction new];
    action.title = title;
    action.style = style;
    action.handler = handler;
    return action;
}

@end

/** ================================图片预览===================================== */

#define dispatch_sync_main(block)\
if ([NSThread isMainThread]) {\
block();\
} else {\
dispatch_sync(dispatch_get_main_queue(), block);\
}

@interface LFPhotoBrowser () <UIScrollViewDelegate>
{
    /** 状态栏隐藏 */
    BOOL _isStatusBarHiden;
    /** 导航栏侧滑返回手势 */
    BOOL _interactiveEnabled;
    
    /** 下拉手势记录点 */
    CGPoint _originalPoint;
    CGPoint _beginPoint;
    CGPoint _endPoint;
    BOOL _isPullBegan;
    BOOL _isPulling;
    
    /** 防止横屏原生属性被重置的问题 */
    CGFloat _navigationBarAlpha;
    /** 排除系统自动执行scrollViewDidScroll */
    BOOL _isMTScroll;
}
@property (nonatomic, strong) LFPhotoScrollView *photoScrollView;
@property (nonatomic, strong, readwrite) NSMutableArray *images;
@property (nonatomic, strong) UIImageView *bgImageView;//背景imageView
@property (nonatomic, strong) UIPageControl *pageControl;
@property (nonatomic, strong) LFPhotoView *prevPhotoView; //上一张
@property (nonatomic, strong) LFPhotoView *nextPhotoView; //下一张
@property (nonatomic, weak) LFPhotoView *movePhotoView; //移动张
@property (nonatomic, weak) LFPhotoView *currPhotoView; //当前张
@property (nonatomic, assign) int curr; //记录当前张
@property (nonatomic, assign) int scrollIndex; //记录滑动到第几张

@property (nonatomic, strong) UIPanGestureRecognizer *panGesture;

@property (nonatomic, strong) UIView *shieldView;
@property (nonatomic, strong) UIView *coverView;

/** 保存按钮 */
@property (nonatomic, weak) UIButton *saveButton;
/** 更多按钮 */
@property (nonatomic, weak) UIButton *moreButton;


/** 记录触发代理加载数据，避免重复触发 */
/** 左边 */
@property (nonatomic, assign) BOOL callLeftSlideDataSource;
/** 右边 */
@property (nonatomic, assign) BOOL callRightSlideDataSource;

/** 触发开关，必须代理调用才能回调数据 */
@property (nonatomic, assign) BOOL callDataSource;

/** 目标的frame */
@property (nonatomic, assign) CGRect targetFrame;
/** 目标遮罩图片 */
@property (nonatomic, strong) UIImage *targetMaskImage;

/** 子线程 */
@property (nonatomic, strong) dispatch_queue_t globalSerialQueue;

/** 批量下载列表 */
@property (nonatomic, strong) NSHashTable *batchDLHash;
/** 批量下载记录 */
@property (nonatomic, assign) BOOL isBatchDLing;

/** 父视图导航栏隐藏状态 */
@property (nonatomic, assign) BOOL parentNaviHiden;

@end

@implementation LFPhotoBrowser

-(id)initWithImageArray:(NSArray *)imageArray
{
    if(self = [super init]){
        self.images = [NSMutableArray arrayWithArray:imageArray];
        self.animatedTime = kAnimatedTime;
        self.curr = 0;//默认从第一张开始显示
        self.canCirculate = NO;//默认不可以循环滚动
        self.isNeedPageControl = NO;//默认不需要pageControl
        self.canPullDown = NO;//默认不可以下拉
        self.isWeaker = NO;//是否淡化
        self.coverViewColor = [UIColor clearColor];
        self.maskPosition = MaskPosition_Middle;
        self.slideRange = 2;
        self.batchDLHash = [NSHashTable weakObjectsHashTable];
        _globalSerialQueue = dispatch_queue_create("LFPhotoBrowser.SerialQueue", NULL);
    }
    return self;
}

-(id)initWithImageArray:(NSArray *)imageArray currentIndex:(int)currentIndex
{
    if(self = [self initWithImageArray:imageArray]){
        if(currentIndex <= imageArray.count)
            self.curr = currentIndex;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor clearColor];
    
    /** 监听app返回前台的激活状态，因为self.navigationController.navigationBar.alpha 会再返回前台时，自动重置为默认值1（不隐藏） */
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    
    [self.view addSubview:self.bgImageView];
    if(self.isNeedPageControl){/* 添加pageControl */
        [self.view addSubview:self.pageControl];
    }
    [self setupView];
    
    if(self.canPullDown){//手势
        _panGesture = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(panGesture:)];
        [self.view addGestureRecognizer:_panGesture];
    }
    
    [self imageFromSelectItems:_curr withImageView:self.currPhotoView];
    //动画
    [self handleAnimationBegin];
    
    [self hiddenPreviewButton];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    self.currPhotoView.orientation = orientation;
    self.movePhotoView.orientation = orientation;
    
    _panGesture.enabled = (orientation == UIInterfaceOrientationPortrait);
    
    CGFloat top=0, bottom=0, right=0;
    if (@available(iOS 11.0, *)) {
        top += self.view.safeAreaInsets.top;
        bottom += self.view.safeAreaInsets.bottom;
        right += self.view.safeAreaInsets.right;
    }
    
    CGRect tempRect = self.saveButton.frame;
    tempRect.origin.x = self.view.frame.size.width - tempRect.size.width - kMoreButtonMargin - right;
    tempRect.origin.y = self.view.frame.size.height - tempRect.size.height - kMoreButtonMargin - top;
    self.saveButton.frame = tempRect;
    
    tempRect = self.moreButton.frame;
    tempRect.origin.x = self.view.frame.size.width - tempRect.size.width - kMoreButtonMargin - right;
    tempRect.origin.y = kMoreButtonMargin+top;
    self.moreButton.frame = tempRect;
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    [self resetScrollView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    _navigationBarAlpha = 0;
    [UIView animateWithDuration:self.animatedTime animations:^{
        [self.navigationController.navigationBar setAlpha:_navigationBarAlpha];
    } completion:^(BOOL finished) {
        [self.navigationController setNavigationBarHidden:YES];
    }];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    /** 刷新视频 */
    if (self.currPhotoView.photoInfo.photoType == PhotoType_video) {
        [self.currPhotoView reloadPhotoView];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:NO];
    [self.navigationController.navigationBar setAlpha:_navigationBarAlpha];
    _navigationBarAlpha = 1;
    [UIView animateWithDuration:self.animatedTime animations:^{
        [self.navigationController.navigationBar setAlpha:_navigationBarAlpha];
    }];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    /** 关闭视频 */
    if (self.currPhotoView.photoInfo.photoType == PhotoType_video) {
        [self.currPhotoView closeVideo];
    }
}

- (void)dealloc
{
    /** 恢复原来的音频 */
    [[AVAudioSession sharedInstance] setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    for (LFPhotoInfo *photoInfo in self.imageSources) {
        if (photoInfo.photoType == PhotoType_image) {
            if (photoInfo.originalImage && photoInfo.originalImageData) {
                /** 释放缓存 */
                photoInfo.originalImage = nil;
            }
        }
    }
}

- (BOOL)prefersStatusBarHidden
{
    return _isStatusBarHiden;
}

- (void)setNeedsStatusBarAppearanceUpdate
{
    [super setNeedsStatusBarAppearanceUpdate];
    [self.navigationController.navigationBar setAlpha:_navigationBarAlpha];
}

#pragma mark - app返回前台状态
- (void)appDidBecomeActive:(NSNotification *)notify
{
    _navigationBarAlpha = 0;
    [self.navigationController.navigationBar setAlpha:_navigationBarAlpha];
}

#pragma mark - 处理动画
- (void)handleAnimationBegin
{
    if ([self.delegate respondsToSelector:@selector(photoBrowserWillBeginShow:)]) {
        [self.delegate photoBrowserWillBeginShow:self];
    }
    
    [self obtainTargetFrame];
    
    _isStatusBarHiden = YES;
    
    [_currPhotoView beginUpdate];
    [self.currPhotoView calcFrameMaskPosition:self.maskPosition frame:self.targetFrame];
    [self.currPhotoView setMaskImage:self.targetMaskImage];
    CGRect currRect = CGRectMake(0, 0, self.currPhotoView.frame.size.width, self.currPhotoView.frame.size.height);
    
    [UIView animateWithDuration:self.animatedTime animations:^{
        _bgImageView.alpha = 1.f;
    }completion:^(BOOL finished) {
        [self.currPhotoView setMaskImage:nil];
    }];
    
    [UIView animateWithDuration:self.animatedTime delay:0.1f options:UIViewAnimationOptionCurveLinear animations:^{
        [_currPhotoView calcFrameMaskPosition:MaskPosition_None frame:currRect];
    } completion:^(BOOL finished) {
        [self setNeedsStatusBarAppearanceUpdate];
        [_currPhotoView endUpdate];
        if ([self.delegate respondsToSelector:@selector(photoBrowserDidBeginShow:)]) {
            [self.delegate photoBrowserDidBeginShow:self];
        }
        if (self.isBatchDownload) {
            /** 获取需要下载的对象 批量下载 */
            for (LFPhotoInfo *info in self.images) {
                if (info && info.originalImage == nil && info.originalImagePath.length == 0 && info.originalImageUrl.length) {
                    [self.batchDLHash addObject:info];
                }
            }
            [self batchDownload];
        }
    }];
}

-(void)handleAnimationEnd
{
    if ([self.delegate respondsToSelector:@selector(photoBrowserWillEndShow:)]) {
        [self.delegate photoBrowserWillEndShow:self];
    }
    _isStatusBarHiden = NO;
    [self setNeedsStatusBarAppearanceUpdate];
    
    /** 因为调用[self removeFromParentViewController]才会触发viewWillDisappear时，此时self.navigationController 为nil，但不调用[self removeFromParentViewController] 又不会触发viewWillDisappear，手动提前调用 */
    [self viewWillDisappear:YES];
    [self.navigationController setNavigationBarHidden:_parentNaviHiden];
    
    UIViewController *parentViewController = self.parentViewController;
    self.parentViewController.navigationController.interactivePopGestureRecognizer.enabled = _interactiveEnabled;
    [self removeFromParentViewController];
    UIInterfaceOrientationMask orientation = [parentViewController supportedInterfaceOrientations];
    [self resetInterfaceOrientation:orientation];
    
    [UIView animateWithDuration:self.animatedTime animations:^{
        self.bgImageView.alpha = 0.0f;
    }completion:^(BOOL finished) {
        
    }];
    
    [UIView animateWithDuration:self.animatedTime delay:0.1f options:0 animations:^{
        [self.currPhotoView setSubControlAlpha:0.f];
        if(self.isWeaker){
            self.currPhotoView.alpha = 0.0f;
        }
        if (CGRectEqualToRect(CGRectZero, self.targetFrame)) {
            self.currPhotoView.alpha = 0.0f;
        } else {
            [self.currPhotoView calcFrameMaskPosition:self.maskPosition frame:self.targetFrame];
            [self.currPhotoView setMaskImage:self.targetMaskImage];
        }
        
    } completion:^(BOOL finished) {
        [_coverView removeFromSuperview];
        _coverView = nil;
        
        if ([self.delegate respondsToSelector:@selector(photoBrowserDidEndShow:)]) {
            [self.delegate photoBrowserDidEndShow:self];
        }
        [self.view removeFromSuperview];
    }];
    
}

-(NSMutableArray *)images
{
    if(_images == nil){
        _images = [NSMutableArray array];
    }
    return _images;
}

-(UIImageView *)bgImageView
{
    if(!_bgImageView){
        _bgImageView = [[UIImageView alloc]initWithFrame:[UIScreen mainScreen].bounds];
        _bgImageView.alpha = 0.0f;
        _bgImageView.backgroundColor = [UIColor blackColor];
        _bgImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
    return _bgImageView;
}

-(UIView *)coverView
{
    if(!_coverView && self.view.superview){
        _coverView = [[UIView alloc]init];
        _coverView.backgroundColor = _coverViewColor;
        [self.view.superview insertSubview:_coverView belowSubview:self.view];
    }
    return _coverView;
}

-(UIPageControl *)pageControl
{
    if(!_pageControl){
        _pageControl = [[UIPageControl alloc]initWithFrame:CGRectMake(0, SCREEN_HEIGHT - 50, SCREEN_WIDTH, 50)];
        _pageControl.numberOfPages = self.images.count;
        _pageControl.currentPage = _curr;
    }
    return _pageControl;
}

- (void)setupView
{
    [self setAutomaticallyAdjustsScrollViewInsets:NO];
    /** 设置scrollview*/
    if(!_photoScrollView){
        _photoScrollView = [[LFPhotoScrollView alloc]init];
        _photoScrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        _photoScrollView.autoresizesSubviews = YES;
        _photoScrollView.backgroundColor = [UIColor clearColor];
        [_photoScrollView setShowsHorizontalScrollIndicator:NO];
        [_photoScrollView setDelegate:self];
        [_photoScrollView setPagingEnabled:YES];
        [_photoScrollView setScrollEnabled:YES];
        [self.view addSubview:_photoScrollView];
        
        if (kScrollAminated == 1) {
            _shieldView = [[UIView alloc] initWithFrame:CGRectMake(-kShieldViewW, 0, kShieldViewW, SCREEN_HEIGHT)];
            _shieldView.backgroundColor = self.bgImageView.backgroundColor;
            [self.photoScrollView addSubview:_shieldView];
        }
    }
    self.photoScrollView.frame = CGRectMake(0, 0, kScrollViewW, SCREEN_HEIGHT);
    
    
    /** 设置两个photoview*/
    if(!_prevPhotoView){
        _prevPhotoView = [self createPhotoView];
        [self.photoScrollView addSubview:_prevPhotoView];
        self.currPhotoView = _prevPhotoView;
    }
    
    if(!_nextPhotoView && _images.count > 1){ /** 图片数量只有一张时，不初始化移动view */
        _nextPhotoView = [self createPhotoView];
        [self.photoScrollView addSubview:_nextPhotoView];
        self.movePhotoView = _nextPhotoView;
    }
    //    [self resetScrollView];
    
    CGFloat button_W = 28.f, margin = kMoreButtonMargin;
    /** 保存按钮 */
    if ([self.delegate respondsToSelector:@selector(photoBrowserSavePreview:photoInfo:object:)]) {
        UIButton *saveButton = [UIButton buttonWithType:UIButtonTypeCustom];
        saveButton.frame = CGRectMake(self.view.frame.size.width - button_W - margin, self.view.frame.size.height - button_W - margin, button_W, button_W);
        saveButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
        [saveButton setImage:[UIImage imageNamed:@"LFPhotoSource.bundle/mediaPreviewDownload"] forState:UIControlStateNormal];
        [saveButton addTarget:self action:@selector(mediaSavePreviewAction) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:saveButton];
        self.saveButton = saveButton;
    }
    /** 更多按钮 */
    if ([self.delegate respondsToSelector:@selector(photoBrowserMorePreview:photoInfo:object:)]) {
        UIButton *moreButton = [UIButton buttonWithType:UIButtonTypeCustom];
        moreButton.frame = CGRectMake(self.view.frame.size.width - button_W - margin, margin, button_W, button_W);
        moreButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
        [moreButton setImage:[UIImage imageNamed:@"LFPhotoSource.bundle/mediaPreviewAlbum"] forState:UIControlStateNormal];
        [moreButton addTarget:self action:@selector(mediaMorePreviewAction) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:moreButton];
        self.moreButton = moreButton;
    }
    
}

- (LFPhotoView *)createPhotoView
{
    CGFloat scrollViewH = self.photoScrollView.frame.size.height;
    CGRect frame = CGRectMake(kScrollViewW, 0, SCREEN_WIDTH, scrollViewH);
    LFPhotoView *photoView = [[LFPhotoView alloc] initWithFrame:frame];
    photoView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    photoView.autoresizesSubviews = YES;
    photoView.photoViewDelegate = self;
    photoView.orientation = [[UIApplication sharedApplication] statusBarOrientation];
    return photoView;
}

-(void)showPhotoBrowser
{
    //    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    //    [window.rootViewController addChildViewController:self];
    //    [window.rootViewController.view addSubview:self.view];
    
    UIViewController *viewController = [UIViewController LFPB_getCurrentVC];
    [viewController addChildViewController:self];
    [viewController.view addSubview:self.view];
    _interactiveEnabled = self.parentViewController.navigationController.interactivePopGestureRecognizer.enabled;
    _parentNaviHiden = self.parentViewController.navigationController.navigationBarHidden;
    self.parentViewController.navigationController.interactivePopGestureRecognizer.enabled = NO;
    
    /** 首次打开，判断是否在触发代理范围内 */
    if (self.callDataSource) {
        /** 关闭开关，避免触发代理 */
        if (self.curr <= self.slideRange) {
            self.callRightSlideDataSource = NO;
        } else if (self.curr >= _images.count-1-self.slideRange) {
            self.callLeftSlideDataSource = NO;
        }
    }
}

/** 关闭相册 */
-(void)closePhotoBrowser
{
    [self.movePhotoView removeFromSuperview];
    /** 竖屏正常处理 */
    if ([[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationPortrait) {
        [self obtainTargetFrame];
    } else { /** 清空坐标 */
        self.targetFrame = CGRectZero;
    }
    [self handleAnimationEnd];
}

/** 刷新UI */
- (void)reloadView:(LFPhotoInfo *)photoInfo
{
    if (photoInfo == nil) return;
    if (self.currPhotoView.photoInfo == photoInfo) {
        [self.currPhotoView reloadPhotoView];
    } else if (self.movePhotoView.photoInfo == photoInfo) {
        [self.movePhotoView reloadPhotoView];
    }
}

#pragma mark - 设置imageView的显示模型
- (void)imageFromSelectItems:(NSInteger)num withImageView:(LFPhotoView *)photoView
{
    /*设置图片*/
    LFPhotoInfo *photoInfo = _images[num];
    photoView.photoInfo = photoInfo;
    [self.photoScrollView bringSubviewToFront:photoView];
}

#pragma mark 重置scrollView的起始位置
- (void)resetScrollView
{
    //图片个数大于1，显示三个空间
    CGSize contentSize = CGSizeMake(kScrollViewW * 3, 0);
    if(_images.count == 1){
        contentSize.width = kScrollViewW;
    }
    if (self.photoScrollView.contentSize.width != contentSize.width) {
        [self.photoScrollView setContentSize:contentSize];
    }
    
    if(self.images.count > 1){
        if(_canCirculate){
            [self setScrollViewPosition:1];
        } else {
            if(_curr == 0){//self.currPhotoView位于左边
                [self setScrollViewPosition:0];
            }else if(_curr == self.images.count - 1){//self.currPhotoView位于右边
                [self setScrollViewPosition:2];
            }else{
                [self setScrollViewPosition:1];//self.currPhotoView位于中间
            }
        }
    }else{
        [self setScrollViewPosition:0];
    }

    [self.movePhotoView cleanData];
    
    _shieldView.frame = CGRectMake(-kShieldViewW, 0, kShieldViewW, SCREEN_HEIGHT);
}

#pragma mark - 偏移scrollView到中间位置
- (void)offsetScrollViewPosition:(int)position
{
    CGFloat newPointX = position * kScrollViewW;
    if (self.currPhotoView.frame.origin.x != newPointX) {
        /** 偏移视图坐标 */
        CGFloat offset = self.currPhotoView.frame.origin.x >= newPointX ? -kScrollViewW : kScrollViewW;
        
        CGRect tmp = self.currPhotoView.frame;
        tmp.origin.x += offset;
        self.currPhotoView.frame = tmp;
        
        tmp = self.movePhotoView.frame;
        tmp.origin.x += offset;
        self.movePhotoView.frame = tmp;
    }
    /** 偏移contentOffset */
    [self.photoScrollView setContentOffset:CGPointMake(newPointX, 0)];
}

#pragma mark - 设置self.currPhotoView的位置(0:左边，1：中间，2：右边)
- (void)setScrollViewPosition:(int)position
{
    CGRect tmp = self.currPhotoView.frame;
    tmp.origin.x = position * kScrollViewW;
    self.currPhotoView.frame = tmp;
    
    /** 重新指向当前视图为最顶层 */
    [self.photoScrollView bringSubviewToFront:self.currPhotoView];
    
    /** 移动张永远在当前张后面 */
    self.movePhotoView.frame = tmp;
    
    [self.photoScrollView setContentOffset:CGPointMake(position * kScrollViewW, 0)];
}

- (void)resetNextImageView:(LFPhotoView *)imageView
{
    CGFloat targetFrameX = CGRectGetMaxX(self.currPhotoView.frame) + kScrollViewMargin;
    CGRect tmpFrame = imageView.frame;
    
    if (tmpFrame.origin.x != targetFrameX) {
        tmpFrame.origin.x = targetFrameX;
        imageView.frame = tmpFrame;
        /** 设置下一张图片 */
        self.scrollIndex = (_curr+1)%_images.count;
        
        [imageView beginUpdate];
        [self imageFromSelectItems:_scrollIndex withImageView:imageView];
    }
}

- (void)resetPrevImageView:(LFPhotoView *)imageView
{
    CGFloat targetFrameX = CGRectGetMinX(self.currPhotoView.frame) - CGRectGetWidth(self.currPhotoView.frame) - kScrollViewMargin;
    CGRect tmpFrame = imageView.frame;
    if (tmpFrame.origin.x != targetFrameX) {
        tmpFrame.origin.x = targetFrameX;
        imageView.frame = tmpFrame;
        /** 设置上一张图片 */
        int imageCount = (int)_images.count;
        self.scrollIndex = (_curr-1+imageCount)%imageCount;
        
        [imageView beginUpdate];
        [self imageFromSelectItems:_scrollIndex withImageView:imageView];
    }
}

#pragma mark - UIScrollViewDelegate
#pragma mark 拖动时执行的方法
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (_isMTScroll) {
        
        if (self.images.count > 1) {
            //判断向左拖动 或者 向右拖动
            if (scrollView.contentOffset.x>kScrollViewW && (_curr != self.images.count-1 || _canCirculate)) {//向左滑动
                [self resetNextImageView:self.movePhotoView];
            } else if (scrollView.contentOffset.x <kScrollViewW && (_curr != 0 || _canCirculate)) {//向右滑动
                [self resetPrevImageView:self.movePhotoView];
            } else if(scrollView.contentOffset.x <kScrollViewW * 2 && _curr == self.images.count-1 && !_canCirculate){ //边缘向右滑动
                if(self.images.count >1)
                    [self resetPrevImageView:self.movePhotoView];
            }else if(scrollView.contentOffset.x > 0 && _curr == 0 && !_canCirculate){ //边缘向左滑动
                if(self.images.count >1)
                    [self resetNextImageView:self.movePhotoView];
            }
            
            /** 终止动画 */
            [self cancelHiddenPreviewButton];
            self.moreButton.alpha = 1.f;
            if (self.movePhotoView.photoInfo.photoType == PhotoType_video) {
                self.saveButton.alpha = 0.f;
            } else {
                self.saveButton.alpha = 1.f;
            }
        }
        
        
        if (self.shieldView) {
            CGRect frame = self.shieldView.frame;
            if (scrollView.contentOffset.x > CGRectGetMinX(self.currPhotoView.frame)) {
                /** 向左滑动 */
                frame.origin.x = CGRectGetMaxX(self.currPhotoView.frame) - ((scrollView.contentOffset.x-CGRectGetMinX(self.currPhotoView.frame))/CGRectGetWidth(self.currPhotoView.frame))*frame.size.width;
            } else {
                /** 向右滑动 */
                frame.origin.x = CGRectGetMinX(self.currPhotoView.frame) - frame.size.width + ((CGRectGetMinX(self.currPhotoView.frame) - scrollView.contentOffset.x)/CGRectGetWidth(self.currPhotoView.frame))*frame.size.width;
            }
            self.shieldView.frame = frame;
            [self.photoScrollView bringSubviewToFront:self.shieldView];
        }
    }
}

#pragma mark 拖动开始执行的方法
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    _isMTScroll = YES;
    /** 在未停止上一次滑动时，再次触发新的滑动 */
    if (scrollView.isDecelerating) {
        /** 判断与当前视图是否一致 */
        if (!CGRectContainsPoint(self.currPhotoView.frame, [scrollView.panGestureRecognizer locationInView:scrollView])) {
            if (!_canCirculate && (self.scrollIndex == 0 || self.scrollIndex == self.images.count - 1)) {
                if (self.images.count == 2) { /** 2张图片特殊情况处理 */
                    if (self.scrollIndex == 0) { /** 偏移到左侧 */
                        [self offsetScrollViewPosition:0];
                    } else { /** 偏移到右侧 */
                        [self offsetScrollViewPosition:2];
                    }
                }
                /** 跳过边缘张的UI调整 */
                return;
            }
            self.curr = self.scrollIndex;
            _pageControl.currentPage = _curr;
            /** 将点击的视图作为当前视图 */
            LFPhotoView *photoView = self.currPhotoView;
            self.currPhotoView = self.movePhotoView;
            self.movePhotoView = photoView;
            
            [self offsetScrollViewPosition:1];
        }
    }
}
#pragma mark 拖动完毕后执行的方法
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    _isMTScroll = NO;
    BOOL isNextPage = NO;
    if (scrollView.contentOffset.x >= kScrollViewW*2 && (_curr != self.images.count - 1 || _canCirculate)) {//向左滑动
        isNextPage = YES;
        if(self.callLeftSlideDataSource && self.curr >= _images.count-1-self.slideRange){//滑到右边倒数第二张
            if([self.delegate respondsToSelector:@selector(photoBrowserDidSlide:slideDirection:photoInfo:)]){
                self.callLeftSlideDataSource = NO;
                dispatch_async(_globalSerialQueue, ^{
                    [self.delegate photoBrowserDidSlide:self slideDirection:SlideDirection_Left photoInfo:self.images.lastObject];
                });
            } else if (self.slideBlock) {
                self.callLeftSlideDataSource = NO;
                dispatch_async(_globalSerialQueue, ^{
                    self.slideBlock(SlideDirection_Left, self.images.lastObject);
                });
            }
        }
    } else if (scrollView.contentOffset.x <= 0 && (_curr != 0 || _canCirculate)) {//向右滑动
        isNextPage = YES;
        if(self.callRightSlideDataSource && self.curr <= self.slideRange){//滑到左边倒数第二张
            if([self.delegate respondsToSelector:@selector(photoBrowserDidSlide:slideDirection:photoInfo:)]){
                self.callRightSlideDataSource = NO;
                dispatch_async(_globalSerialQueue, ^{
                    [self.delegate photoBrowserDidSlide:self slideDirection:SlideDirection_Right photoInfo:self.images.firstObject];
                });
            } else if (self.slideBlock) {
                self.callRightSlideDataSource = NO;
                dispatch_async(_globalSerialQueue, ^{
                    self.slideBlock(SlideDirection_Right, self.images.firstObject);
                });
            }
        }
        /** 因为不开启循环滑动时，最后一张contentOffset不会重置，需要新增判断 */
    }else if (scrollView.contentOffset.x <= kScrollViewW  && _curr == self.images.count - 1 && !_canCirculate){ /** 最后一张向左滑动 */
        isNextPage = YES;
    }else if (scrollView.contentOffset.x >= kScrollViewW && _curr == 0 && !_canCirculate){ /** 最后一张向右滑动 */
        isNextPage = YES;
    }
    
    /** 是否已滑动到下一页 */
    if (isNextPage) {
        self.curr = self.scrollIndex;
        _pageControl.currentPage = _curr;
        
        /** 设置当前预览UI */
        LFPhotoView *photoView = self.currPhotoView;
        self.currPhotoView = self.movePhotoView;
        self.movePhotoView = photoView;
        
        [self.currPhotoView endUpdate];
        
        /** 重置全局 */
        [self resetScrollView];
    }
    
    [self hiddenPreviewButton];
}

#pragma mark - 增加数据源
-(void)addDataSourceFormSlideDirection:(SlideDirection)direction dataSourceArray:(NSArray <LFPhotoInfo *>*)dataSource
{
    dispatch_sync_main(^{
        if(self.callDataSource && dataSource.count){
            BOOL isUseData = NO;
            if(direction == SlideDirection_Left && self.callLeftSlideDataSource == NO){
                self.callLeftSlideDataSource = YES;
                [self.images addObjectsFromArray:dataSource];
                _pageControl.numberOfPages = self.images.count;
                _pageControl.currentPage = _curr;
                isUseData = YES;
            }else if(direction == SlideDirection_Right && self.callRightSlideDataSource == NO){
                self.callRightSlideDataSource = YES;
                [self.images insertObjects:dataSource atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, dataSource.count)]];
                _pageControl.numberOfPages = self.images.count;
                _curr += dataSource.count;
                _pageControl.currentPage = _curr;
                isUseData = YES;
            }
            
            if (isUseData) {
                if (self.isBatchDownload) {
                    /** 获取需要下载的对象 批量下载 */
                    for (LFPhotoInfo *info in dataSource) {
                        if (info && info.originalImage == nil && info.originalImagePath.length == 0 && info.originalImageUrl.length) {
                            [self.batchDLHash addObject:info];
                        }
                    }
                    [self batchDownload];
                }
                
                /** 判断1个的情况，增加数据源时需要调整contentSize */
                if (self.photoScrollView.contentSize.width == kScrollViewW) {
                    /** 初始化移动view */
                    if (!_nextPhotoView) {
                        _nextPhotoView = [self createPhotoView];
                        [self.photoScrollView addSubview:_nextPhotoView];
                        self.movePhotoView = _nextPhotoView;
                        /** 置顶当前张 */
                        [self.photoScrollView bringSubviewToFront:self.currPhotoView];
                    }
                }
                /** 非滑动情况下 */
                if (!(self.photoScrollView.isDragging || self.photoScrollView.isDecelerating || self.photoScrollView.isTracking)) {
                    if (self.photoScrollView.contentOffset.x != kScrollViewW) {
                        /** 重置UI */
                        [self resetScrollView];
                    }
                }
            }
        }
    });
}

- (void)loadView
{
    self.view = [[UIView alloc] init];
    self.view.frame = [UIScreen mainScreen].bounds;
    self.view.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
}

#pragma mark - 获取targetFrame
-(void)obtainTargetFrame
{
    if([self.delegate respondsToSelector:@selector(photoBrowserTargetFrameWithIndex:key:)]){
        CGRect frame = [self.delegate photoBrowserTargetFrameWithIndex:_curr key:self.currPhotoView.photoInfo.key];
        if(frame.size.width != 0 && frame.size.height != 0){
            self.targetFrame = CGRectInset(frame, -0.05f, -0.05f);
        } else {
            self.targetFrame = CGRectMake(SCREEN_WIDTH/2, SCREEN_HEIGHT/2, 0, 0);
        }
    } else if (self.targetFrameBlock) {
        CGRect frame = self.targetFrameBlock(_curr, self.currPhotoView.photoInfo.key);
        if(frame.size.width != 0 && frame.size.height != 0){
            self.targetFrame = CGRectInset(frame, -0.05f, -0.05f);
        } else {
            self.targetFrame = CGRectMake(SCREEN_WIDTH/2, SCREEN_HEIGHT/2, 0, 0);
        }
    } else {
        self.targetFrame = CGRectMake(SCREEN_WIDTH/2, SCREEN_HEIGHT/2, 0, 0);
    }
    
    if ([self.delegate respondsToSelector:@selector(photoBrowserTargetMaskImageWithIndex:key:)]) {
        UIImage *image = [self.delegate photoBrowserTargetMaskImageWithIndex:_curr key:self.currPhotoView.photoInfo.key];
        self.targetMaskImage = image;
    } else if (self.targetMaskImageBlock) {
        self.targetMaskImage = self.targetMaskImageBlock(_curr, self.currPhotoView.photoInfo.key);
    } else {
        self.targetMaskImage = nil;
    }
}

#pragma mark - 下拉手势处理
-(void)panGesture:(id)sender
{
    if (self.currPhotoView.photoInfo.downloadFail) return;
    /** 缩放状态下不触发 */
    if (self.currPhotoView.zoomScale != 1.f) return;
    /** 滑动情况下不能触发 */
    BOOL isScroll = self.currPhotoView.isTracking || self.currPhotoView.isDragging || self.currPhotoView.isDecelerating || self.currPhotoView.isZooming || self.currPhotoView.isZoomBouncing;
    
    UIPanGestureRecognizer *panGesture = sender;
    CGPoint movePoint = [panGesture translationInView:self.currPhotoView];
    
    /** 优先判断：
        1、已经开始下拉 无视以下步骤
        2、是向上滑动 停止
     */
    if (!_isPulling) {
        if ((_beginPoint.y > movePoint.y || self.currPhotoView.contentOffset.y > 0) && isScroll) return;
    }
    
    CGRect currFrame = self.currPhotoView.photoRect;
    switch (panGesture.state)
    {
        case UIGestureRecognizerStateBegan:{
            _isStatusBarHiden = NO;
            [self.navigationController setNavigationBarHidden:NO];
            [self setNeedsStatusBarAppearanceUpdate];
            _isPullBegan = YES;
            _beginPoint = movePoint;
            self.movePhotoView.hidden = YES;
            [self obtainTargetFrame];
            /** 转换坐标 */
            [self.coverView setFrame:CGRectMake(kRound(self.targetFrame.origin.x), kRound(self.targetFrame.origin.y), kRound(self.targetFrame.size.width), kRound(self.targetFrame.size.height))];
            
            /** 关闭滑动 */
            self.photoScrollView.scrollEnabled = NO;
            /** 关闭缩放 */
            self.currPhotoView.zoomEnable = NO;
        }
            break;
        case UIGestureRecognizerStateEnded:{
            _originalPoint = _beginPoint = _endPoint = CGPointZero;
            /** 开放滑动 */
            self.photoScrollView.scrollEnabled = YES;
            /** 开放缩放 */
            self.currPhotoView.zoomEnable = YES;
            if (_isPullBegan && _isPulling) { /** 有触发滑动情况 */
                _isPullBegan = NO;
                _isPulling = NO;
                if(currFrame.size.width > self.currPhotoView.frame.size.width * 0.75)
                {
                    _isStatusBarHiden = YES;
                    CGRect currRect = (CGRect){CGPointZero, self.currPhotoView.bounds.size};
                    _navigationBarAlpha = 0;
                    [UIView animateWithDuration:self.animatedTime animations:^{
                        self.bgImageView.alpha = 1.0f;
                        [self.navigationController.navigationBar setAlpha:_navigationBarAlpha];
                        [self.currPhotoView setSubControlAlpha:1.f];
                        [self.currPhotoView calcFrameMaskPosition:MaskPosition_None frame:currRect];
                    }completion:^(BOOL finished) {
                        self.movePhotoView.hidden = NO;
                        [_coverView removeFromSuperview];
                        _coverView = nil;
                        [self.navigationController setNavigationBarHidden:YES];
                        [self setNeedsStatusBarAppearanceUpdate];
                    }];
                }else{
                    [self.movePhotoView removeFromSuperview];
                    [self handleAnimationEnd];
                }
            }
        }
            break;
        case UIGestureRecognizerStateChanged:{
            if (_isPullBegan) {
                _isPulling = YES;
                BOOL isChanged = NO;
                /** 当前移动点 大于 起始点 同时 大于 上一次移动点 视为向下滑动 */
                if(movePoint.y > _beginPoint.y && movePoint.y > _originalPoint.y && currFrame.size.width > self.currPhotoView.frame.size.width/2){ /** 缩小 */
                    isChanged = YES;
                    _endPoint = _originalPoint;
                    if (_isStatusBarHiden) {
                        _isStatusBarHiden = NO;
                        [self setNeedsStatusBarAppearanceUpdate];
                    }
                    /** 当前移动点 小于 结束点 视为向上滑动 */
                }else if(movePoint.y <= _endPoint.y && currFrame.size.width < self.currPhotoView.frame.size.width){ /** 放大 */
                    isChanged = YES;
                }
                
                
                CGFloat moveX = (movePoint.x - _originalPoint.x) / 1.5;
                CGFloat moveY = (movePoint.y - _originalPoint.y);
                if (isChanged) {
                    moveY /= 2;
                    
                    CGFloat inset = (movePoint.y - _originalPoint.y)/2;
                    CGRect newRect = currFrame;//CGRectInset(currFrame, inset, inset);此方法不是绝对比例缩放，导致部分尺寸图片缩放偏小
                    newRect.origin.x += inset/2;
                    newRect.origin.y += inset/2;
                    CGSize oldSize = newRect.size;
                    newRect.size.width -= inset;
                    newRect.size.height = oldSize.height * newRect.size.width / oldSize.width;
                    
                    /** 拖动大于屏幕时，固定大小 */
                    if (newRect.size.width > self.currPhotoView.contentSize.width) {
                        CGFloat width = newRect.size.width;
                        newRect.size.width = self.currPhotoView.contentSize.width;
                        newRect.origin.x += (width - newRect.size.width)/2;
                    }
                    if (newRect.size.height > self.currPhotoView.contentSize.height) {
                        CGFloat height = newRect.size.height;
                        newRect.size.height = self.currPhotoView.contentSize.height;
                        newRect.origin.y += (height - newRect.size.height)/2;
                    }
                    currFrame = newRect;
                    
                    //设置透明度
                    CGFloat alpha = 1-((self.currPhotoView.frame.size.width - currFrame.size.width)/(self.currPhotoView.frame.size.width/2));
                    if (alpha > 1.f) {
                        alpha = 1.f;
                    } else if (alpha < 0.f) {
                        alpha = 0.f;
                    }
                    _bgImageView.alpha = alpha;
                    [self.currPhotoView setSubControlAlpha:alpha];
                    
                    _navigationBarAlpha = 1-alpha;
                    if (_parentNaviHiden == NO) {
                        [self.navigationController.navigationBar setAlpha:_navigationBarAlpha];
                    }
                }
                
                /** 移动 */
                currFrame.origin.x += moveX;
                currFrame.origin.y += moveY;
                
                [self.currPhotoView setPhotoRect:currFrame];
            }
        }
            break;
        default:
            break;
            
    }
    _originalPoint = movePoint;
}

#pragma mark - photoView手势代理
-(void)photoViewGesture:(LFPhotoView *)photoView singleTapPhotoType:(PhotoType)PhotoType object:(id /* UIImage * /NSURL * */)object
{
    [self closePhotoBrowser];
}

-(void)photoViewGesture:(LFPhotoView *)photoView longPressPhotoType:(PhotoType)photoType object:(id /* UIImage * /NSURL * */)object
{
    __block NSMutableArray *actionItems = [NSMutableArray array];
    if ([self.delegate respondsToSelector:@selector(photoBrowserLongPressActionItems:photoInfo:object:)]) {
        NSArray *items = [self.delegate photoBrowserLongPressActionItems:self photoInfo:photoView.photoInfo object:object];
        if (items) {
            [actionItems addObjectsFromArray:items];
        }
    } else if (self.longPressActionItemsBlock) {
        NSArray *items = self.longPressActionItemsBlock(photoView.photoInfo, object);
        if (items) {
            [actionItems addObjectsFromArray:items];
        }
    }
    
    if (actionItems.count) { /** 存在才启动长按菜单 */
        /** 列表排序 */
        [actionItems sortUsingComparator:^NSComparisonResult(LFPhotoSheetAction *  _Nonnull obj1, LFPhotoSheetAction *  _Nonnull obj2) {
            return obj1.style > obj2.style;
        }];
        
        /** 新数组，实际显示列表 */
        LFPhotoSheetAction *cancelAction = nil, *destructiveAction = nil;
        NSMutableArray *newActionItems = [@[] mutableCopy];
        
        NSString *cancelTitle = nil, *destructiveTitle = nil;
        NSMutableArray *otherTitles = [@[] mutableCopy];
        for (LFPhotoSheetAction *action in actionItems) {
            switch (action.style) {
                case LFPhotoSheetActionType_Default:
                    //                [otherTitles addObject:action.title];
                    [otherTitles addObject:action.title];
                    /** actionSheet的点击顺序 */
                    [newActionItems addObject:action];
                    break;
                case LFPhotoSheetActionType_Destructive:
                    destructiveTitle = action.title;
                    destructiveAction = action;
                    break;
                case LFPhotoSheetActionType_Cancel:
                    cancelTitle = action.title;
                    cancelAction = action;
                    break;
            }
        }
        
        /** 不错新数组头尾部分 */
        if (cancelAction == nil) { /** 创建一个取消action占位，因为取消无论如何都存在 */
            cancelAction = [[LFPhotoSheetAction alloc] init];
            cancelTitle = @"取消";
        }
        [newActionItems addObject:cancelAction];
        
        if (destructiveAction) { /** 在actionSheet为最顶层 */
            [newActionItems insertObject:destructiveAction atIndex:0];
        }
        
        
        if (destructiveTitle.length || otherTitles.count) {
            [[[LFActionSheet alloc] initWithTitle:nil cancelButtonTitle:cancelTitle destructiveButtonTitle:destructiveTitle otherButtonTitles:otherTitles didSelectBlock:^(LFActionSheet * _Nonnull actionSheet, NSInteger buttonIndex) {
                
                LFPhotoSheetAction *action = [newActionItems objectAtIndex:buttonIndex];
                if (action.handler) {
                    action.handler(object);
                }
            }] show];
        }
    }
    
}

-(void)photoViewWillBeginZooming:(LFPhotoView *)photoView
{
    //    if (_canPullDown) {
    //        [self obtainOverFrame];
    //        self.movePhotoView.hidden = YES;
    //    }
}
-(void)photoViewDidZoom:(LFPhotoView *)photoView
{
    //    if (_canPullDown) {
    //        _bgImageView.alpha = photoView.zoomScale;
    //    }
}
-(void)photoViewDidEndZooming:(LFPhotoView *)photoView
{
    //    if (_canPullDown) {
    //        if (photoView.zoomScale < 1.f) {
    //            [self handleAnimationEnd];
    //        } else {
    //            _bgImageView.alpha = 1.f;
    //            self.movePhotoView.hidden = NO;
    //        }
    //    }
}

#pragma mark - photoView下载代理
-(BOOL)photoViewDownLoadThumbnail:(LFPhotoView *)photoView url:(NSString *)url
{
    if ([self.downloadDelegate respondsToSelector:@selector(photoBrowser:downloadThumbnailWithPhotoInfo:)]) {
        [self.downloadDelegate photoBrowser:self downloadThumbnailWithPhotoInfo:photoView.photoInfo];
        return YES;
    }
    return NO;
}

-(BOOL)photoViewDownLoadOriginal:(LFPhotoView *)photoView url:(NSString *)url
{
    if (self.isBatchDownload) return YES;
    if ([self.downloadDelegate respondsToSelector:@selector(photoBrowser:downloadOriginalWithPhotoInfo:)]) {
        [self.downloadDelegate photoBrowser:self downloadOriginalWithPhotoInfo:photoView.photoInfo];
        return YES;
    }
    return NO;
}

-(BOOL)photoViewDownLoadVideo:(LFPhotoView *)photoView url:(NSString *)url
{
    if ([self.downloadDelegate respondsToSelector:@selector(photoBrowser:downloadVideoWithPhotoInfo:)]) {
        [self.downloadDelegate photoBrowser:self downloadVideoWithPhotoInfo:photoView.photoInfo];
        return YES;
    }
    return NO;
}

#pragma mark - BatchDownload下载
- (void)batchDownload
{
    if (_isBatchDLing) return;
    LFPhotoInfo *info = [self.batchDLHash anyObject];
    /** 对象原图不存在、原图路径不存在、只有原图URL才进行下载 */
    if (info && info.originalImage == nil && info.originalImagePath.length == 0 && info.originalImageUrl.length) {
        _isBatchDLing = YES;
        __weak typeof(self) weakSelf = self;
        
        [[LFDownloadManager shareLFDownloadManager] lf_downloadURL:[NSURL URLWithString:info.originalImageUrl] progress:nil completion:^(NSData *data, NSError *error, NSURL *URL) {
            [weakSelf.batchDLHash removeObject:info];
            weakSelf.isBatchDLing = NO;
            [weakSelf batchDownload];
        }];
    }
}

#pragma mark - 额外按钮事件
- (void)mediaSavePreviewAction
{
    if ([self.delegate respondsToSelector:@selector(photoBrowserSavePreview:photoInfo:object:)]) {
        [self.delegate photoBrowserSavePreview:self photoInfo:self.currPhotoView.photoInfo object:[self.currPhotoView getSelectObject]];
    }
}

- (void)mediaMorePreviewAction
{
    if ([self.delegate respondsToSelector:@selector(photoBrowserMorePreview:photoInfo:object:)]) {
        [self.delegate photoBrowserMorePreview:self photoInfo:self.currPhotoView.photoInfo object:[self.currPhotoView getSelectObject]];
    }
}

- (void)hiddenPreviewButton
{
    self.saveButton.alpha = self.currPhotoView.photoInfo.photoType == PhotoType_video ? 0 : 1;
    [self performSelector:@selector(hidePreviewButtonAlpha) withObject:nil afterDelay:5.f];
}

- (void)cancelHiddenPreviewButton
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hidePreviewButtonAlpha) object:nil];
}

- (void)hidePreviewButtonAlpha
{
    [UIView animateWithDuration:0.25f delay:0.f options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.saveButton.alpha = 0.f;
        self.moreButton.alpha = 0.f;
    } completion:^(BOOL finished) {
        
    }];
}

#pragma mark - 重写方法,横屏
-(UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAllButUpsideDown;
}

//#pragma mark - iOS7
//- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
//{
//    self.currPhotoView.orientation = toInterfaceOrientation;
//    self.movePhotoView.orientation = toInterfaceOrientation;
//    
//    _panGesture.enabled = (toInterfaceOrientation == UIInterfaceOrientationPortrait);
//}
//#pragma mark - iOS8 Later
//- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator
//{
//    UIInterfaceOrientation orientation = size.width < size.height ? UIInterfaceOrientationPortrait : UIInterfaceOrientationLandscapeLeft;
//    self.currPhotoView.orientation = orientation;//[[UIApplication sharedApplication] statusBarOrientation];
//    self.movePhotoView.orientation = orientation;//[[UIApplication sharedApplication] statusBarOrientation];
//    
//    _panGesture.enabled = (size.width < size.height);
//}

#pragma mark - 重置屏幕方向
- (void)resetInterfaceOrientation:(UIInterfaceOrientationMask)orientationMask
{
    UIInterfaceOrientation orientation = UIInterfaceOrientationUnknown;
    switch (orientationMask) {
        case UIInterfaceOrientationMaskPortrait:
            orientation = UIInterfaceOrientationPortrait;
            break;
        case UIInterfaceOrientationMaskLandscapeLeft:
            orientation = UIInterfaceOrientationLandscapeLeft;
            break;
        case UIInterfaceOrientationMaskLandscapeRight:
            orientation = UIInterfaceOrientationLandscapeRight;
            break;
        case UIInterfaceOrientationMaskPortraitUpsideDown:
            orientation = UIInterfaceOrientationPortraitUpsideDown;
            break;
        default:
            break;
    }
    if (orientation != UIInterfaceOrientationUnknown) {
        if ([[UIDevice currentDevice] respondsToSelector:@selector(setOrientation:)]) {
            SEL selector = NSSelectorFromString(@"setOrientation:");
            NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[UIDevice instanceMethodSignatureForSelector:selector]];
            [invocation setSelector:selector];
            [invocation setTarget:[UIDevice currentDevice]];
            int val = UIInterfaceOrientationUnknown;
            [invocation setArgument:&val atIndex:2];
            [invocation invoke];
            
            NSInvocation *invocation1 = [NSInvocation invocationWithMethodSignature:[UIDevice instanceMethodSignatureForSelector:selector]];
            [invocation1 setSelector:selector];
            [invocation1 setTarget:[UIDevice currentDevice]];
            int val1 = orientation;
            [invocation1 setArgument:&val1 atIndex:2];
            [invocation1 invoke];
            
//            objc_msgSend([UIDevice currentDevice], @selector(setOrientation:), orientation);
        }
    }
}

- (void)setSlideRange:(NSUInteger)slideRange
{
    _slideRange = slideRange;
    _callDataSource = (_slideRange < self.images.count / 2);
    self.callLeftSlideDataSource = _callDataSource;
    self.callRightSlideDataSource = _callDataSource;
}

- (NSArray *)imageSources
{
    return [self.images copy];
}

@end
