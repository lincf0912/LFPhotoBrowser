//
//  PhotoBrowser.m
//  PhotoBrowser
//
//  Created by LamTsanFeng on 2016/9/28.
//  Copyright © 2016年 GZMiracle. All rights reserved.
//

#import "LFPhotoBrowser.h"
#import "LFScrollView.h"
#import "LFPhotoView.h"
#import "LFPhotoInfo.h"
#import "UIImageView+WebCache.h"
#import "UIActionSheet+Block.h"
#import "UIViewController+Extension.h"

#define kRound(f) round(f*10)/10

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

@interface LFPhotoBrowser () <UIScrollViewDelegate, LFPhotoViewDelegate>
{
    /** 状态栏隐藏 */
    BOOL _isStatusBarHiden;
    /** 导航栏侧滑返回手势 */
    BOOL _interactiveEnabled;
    
    /** 下拉手势记录点 */
    CGPoint _originalPoint;
    CGPoint _beginPoint;
    CGPoint _endPoint;
}
@property (nonatomic, strong) LFScrollView *scroll;
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

/** 记录触发代理加载数据，避免重复触发 */
/** 左边 */
@property (nonatomic, assign) BOOL callLeftSlideDataSource;
/** 右边 */
@property (nonatomic, assign) BOOL callRightSlideDataSource;

/** 触发开关，必须代理调用才能回调数据 */
@property (nonatomic, assign) BOOL callDataSource;

/** 目标的frame */
@property (nonatomic, assign) CGRect targetFrame;

/** 长按列表 */
@property (nonatomic, strong) NSMutableArray *lpActionItems;

/** 子线程 */
@property (nonatomic, strong) dispatch_queue_t globalSerialQueue;

/** 批量下载列表 */
@property (nonatomic, strong) NSHashTable *batchDLHash;
/** 批量下载记录 */
@property (nonatomic, assign) BOOL isBatchDLing;

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
}

-(void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    [self resetScrollView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [UIView animateWithDuration:self.animatedTime animations:^{
        [self.navigationController.navigationBar setAlpha:0];
    }];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [UIView animateWithDuration:self.animatedTime animations:^{
        [self.navigationController.navigationBar setAlpha:1];
    }];
}

- (void)dealloc
{
    
}
- (BOOL)prefersStatusBarHidden
{
    return _isStatusBarHiden;
}

- (void)setNeedsStatusBarAppearanceUpdate
{
    CGFloat alpha = [self.navigationController.navigationBar alpha];
    [super setNeedsStatusBarAppearanceUpdate];
    [self.navigationController.navigationBar setAlpha:alpha];
}

#pragma mark - 处理动画
- (void)handleAnimationBegin
{
    [self obtainTargetFrame];
    
    _isStatusBarHiden = YES;
    
    [self.currPhotoView calcFrameMaskPosition:self.maskPosition frame:self.targetFrame];
    CGRect currRect = CGRectMake(0, 0, self.currPhotoView.frame.size.width, self.currPhotoView.frame.size.height);
    
    [UIView animateWithDuration:self.animatedTime animations:^{
        _bgImageView.alpha = 1.f;
    }completion:^(BOOL finished) {
        
    }];
    
    [UIView animateWithDuration:self.animatedTime delay:0.1f options:UIViewAnimationOptionCurveLinear animations:^{
        [_currPhotoView calcFrameMaskPosition:MaskPosition_None frame:currRect];
    } completion:^(BOOL finished) {
        [self setNeedsStatusBarAppearanceUpdate];
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
    _isStatusBarHiden = NO;
    [self setNeedsStatusBarAppearanceUpdate];
    
    /** 因为调用[self removeFromParentViewController]才会触发viewWillDisappear时，此时self.navigationController 为nil，但不调用[self removeFromParentViewController] 又不会触发viewWillDisappear，手动提前调用 */
    [self viewWillDisappear:YES];
    
    [UIView animateWithDuration:self.animatedTime animations:^{
        self.bgImageView.alpha = 0.0f;
    }completion:^(BOOL finished) {
        
    }];
    
    [UIView animateWithDuration:self.animatedTime delay:0.1f options:0 animations:^{
        [self.currPhotoView setSubControlAlpha:0.f];
        if(self.isWeaker){
            self.currPhotoView.alpha = 0.0f;
        }
        [self.currPhotoView calcFrameMaskPosition:self.maskPosition frame:self.targetFrame];
        
    } completion:^(BOOL finished) {
        [_coverView removeFromSuperview];
        _coverView = nil;
        self.parentViewController.navigationController.interactivePopGestureRecognizer.enabled = _interactiveEnabled;
        [self removeFromParentViewController];
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
    /** 设置scrollview*/
    if(!_scroll){
        _scroll = [[LFScrollView alloc]init];
        _scroll.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        _scroll.autoresizesSubviews = YES;
        _scroll.backgroundColor = [UIColor clearColor];
        [_scroll setShowsHorizontalScrollIndicator:NO];
        [_scroll setDelegate:self];
        [_scroll setPagingEnabled:YES];
        [_scroll setScrollEnabled:YES];
        [self.view addSubview:_scroll];
        
        if (kScrollAminated == 1) {
            _shieldView = [[UIView alloc] initWithFrame:CGRectMake(-kShieldViewW, 0, kShieldViewW, SCREEN_HEIGHT)];
            _shieldView.backgroundColor = self.bgImageView.backgroundColor;
            [self.scroll addSubview:_shieldView];
        }
    }
    _scroll.frame = CGRectMake(0, 0, kScrollViewW, SCREEN_HEIGHT);
    

    /** 设置两个photoview*/
    if(!_prevPhotoView){
        [self createPrevPhotoView];
    }
    
    if(!_nextPhotoView && _images.count > 1){ /** 图片数量只有一张时，不初始化移动view */
        [self createNextPhotoView];
    }
//    [self resetScrollView];
    [self setAutomaticallyAdjustsScrollViewInsets:NO];
    
}

- (void)createPrevPhotoView
{
    CGFloat scrollViewH = _scroll.frame.size.height;
    CGRect frame = CGRectMake(kScrollViewW, 0, SCREEN_WIDTH, scrollViewH);
    _prevPhotoView = [[LFPhotoView alloc] initWithFrame:frame];
    _prevPhotoView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    _prevPhotoView.autoresizesSubviews = YES;
    _prevPhotoView.photoViewDelegate = self;
    [_scroll addSubview:_prevPhotoView];
    self.currPhotoView = _prevPhotoView;
}

- (void)createNextPhotoView
{
    CGFloat scrollViewH = _scroll.frame.size.height;
    CGRect frame = CGRectMake(kScrollViewW, 0, SCREEN_WIDTH, scrollViewH);
    _nextPhotoView = [[LFPhotoView alloc] initWithFrame:frame];
    _nextPhotoView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _nextPhotoView.autoresizesSubviews = YES;
    _nextPhotoView.photoViewDelegate = self;
    [_scroll addSubview:_nextPhotoView];
    self.movePhotoView = _nextPhotoView;
}

-(void)showPhotoBrowser
{
//    UIWindow *window = [UIApplication sharedApplication].keyWindow;
//    [window.rootViewController addChildViewController:self];
//    [window.rootViewController.view addSubview:self.view];
    
    UIViewController *viewController = [UIViewController getCurrentVC];
    [viewController addChildViewController:self];
    [viewController.view addSubview:self.view];
    _interactiveEnabled = self.parentViewController.navigationController.interactivePopGestureRecognizer.enabled;
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

#pragma mark - 设置imageView的显示模型
- (void)imageFromSelectItems:(NSInteger)num withImageView:(LFPhotoView *)photoView
{
    /*设置图片*/
    LFPhotoInfo *photoInfo = _images[num];
    photoView.photoInfo = photoInfo;
    [self.scroll bringSubviewToFront:photoView];
}

#pragma mark 重置scrollView的起始位置
- (void)resetScrollView
{
    //图片个数大于1，显示三个空间
    CGSize contentSize = CGSizeMake(kScrollViewW * 3, 0);
    if(_images.count == 1){
        contentSize.width = kScrollViewW;
    }
    if (self.scroll.contentSize.width != contentSize.width) {
        [self.scroll setContentSize:contentSize];
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
}

#pragma mark - 设置self.currPhotoView的位置(0:左边，1：中间，2：右边)
- (void)setScrollViewPosition:(int)position
{
    CGRect tmp = self.currPhotoView.frame;
    tmp.origin.x = position * kScrollViewW;
    self.currPhotoView.frame = tmp;
    
    /** 移动张永远在当前张后面 */
    self.movePhotoView.frame = tmp;
    
    [_scroll setContentOffset:CGPointMake(position * kScrollViewW, 0)];
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
        
        [self imageFromSelectItems:_scrollIndex withImageView:imageView];
    }
}

#pragma mark - UIScrollViewDelegate
#pragma mark 拖动时执行的方法
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
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
        [self.scroll bringSubviewToFront:self.shieldView];
    }
}

#pragma mark 代理方法 拖动完毕后执行的方法
//- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
//{
//    if (decelerate) {
//        
//    }
//}
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    BOOL isNextPage = NO;
    if (scrollView.contentOffset.x >= kScrollViewW*2 && (_curr != self.images.count - 1 || _canCirculate)) {//向左滑动
        isNextPage = YES;
        if(self.callLeftSlideDataSource && self.curr == _images.count-1-self.slideRange){//滑到右边倒数第二张
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
        if(self.callRightSlideDataSource && self.curr == self.slideRange){//滑到左边倒数第二张
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
        
        [self.movePhotoView cleanData];
        
        /** 重置全局 */
        [self resetScrollView];
    }
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
                if (self.scroll.contentSize.width == kScrollViewW) {
                    /** 初始化移动view */
                    if (!_nextPhotoView) {
                        [self createNextPhotoView];
                        /** 置顶当前张 */
                        [self.scroll bringSubviewToFront:self.currPhotoView];
                    }
                }
                /** 当前显示页不再中间，并且非滑动情况下 */
                if (self.scroll.isDragging || self.scroll.isDecelerating || self.scroll.isTracking) {
                    return ;
                }
                if (self.scroll.contentOffset.x != kScrollViewW) {
                    /** 重置UI */
                    [self resetScrollView];
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
            self.targetFrame = frame;
        } else {
            self.targetFrame = CGRectMake(SCREEN_WIDTH/2, SCREEN_HEIGHT/2, 0, 0);
        }
    } else if (self.targetFrameBlock) {
        CGRect frame = self.targetFrameBlock(_curr, self.currPhotoView.photoInfo.key);
        if(frame.size.width != 0 && frame.size.height != 0){
            self.targetFrame = frame;
        } else {
            self.targetFrame = CGRectMake(SCREEN_WIDTH/2, SCREEN_HEIGHT/2, 0, 0);
        }
    } else {
        self.targetFrame = CGRectMake(SCREEN_WIDTH/2, SCREEN_HEIGHT/2, 0, 0);
    }
}

#pragma mark - 下拉手势处理
-(void)panGesture:(id)sender
{
    if (self.currPhotoView.photoInfo.downloadFail) return;
    /** 滑动情况下不能触发 */
    if (self.currPhotoView.zoomScale > 1.f) return;
    
    UIPanGestureRecognizer *panGesture = sender;
    CGPoint movePoint = [panGesture translationInView:self.currPhotoView];
    CGRect currFrame = self.currPhotoView.photoRect;
    switch (panGesture.state)
    {
        case UIGestureRecognizerStateBegan:{
            _beginPoint = movePoint;
            self.movePhotoView.hidden = YES;
            [self obtainTargetFrame];
            /** 转换坐标 */
            [self.coverView setFrame:CGRectMake(kRound(self.targetFrame.origin.x), kRound(self.targetFrame.origin.y), kRound(self.targetFrame.size.width), kRound(self.targetFrame.size.height))];
        }
            break;
        case UIGestureRecognizerStateEnded:{
            _originalPoint = _beginPoint = _endPoint = CGPointZero;
            
            if(currFrame.size.width > self.currPhotoView.frame.size.width * 0.75)
            {
                _isStatusBarHiden = YES;
                CGRect currRect = self.currPhotoView.bounds;
                if (CGRectEqualToRect(currFrame, currRect)) {
                    self.movePhotoView.hidden = NO;
                    [_coverView removeFromSuperview];
                    _coverView = nil;
                    [self setNeedsStatusBarAppearanceUpdate];
                } else {
                    [UIView animateWithDuration:0.25 animations:^{
                        self.bgImageView.alpha = 1.0f;
                        [self.navigationController.navigationBar setAlpha:0];
                        [self.currPhotoView setSubControlAlpha:1.f];
                        [self.currPhotoView calcFrameMaskPosition:MaskPosition_None frame:currRect];
                    }completion:^(BOOL finished) {
                        self.movePhotoView.hidden = NO;
                        [_coverView removeFromSuperview];
                        _coverView = nil;
                        [self setNeedsStatusBarAppearanceUpdate];
                    }];
                }
            }else{
                [self handleAnimationEnd];
            }
        }
            break;
        case UIGestureRecognizerStateChanged:{
            
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
                
                if (newRect.size.width > self.currPhotoView.bounds.size.width) {
                    CGFloat width = newRect.size.width;
                    newRect.size.width = self.currPhotoView.bounds.size.width;
                    newRect.origin.x += (width - newRect.size.width)/2;
                }
                if (newRect.size.height > self.currPhotoView.bounds.size.height) {
                    CGFloat height = newRect.size.height;
                    newRect.size.height = self.currPhotoView.bounds.size.height;
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
                
                [self.navigationController.navigationBar setAlpha:1-alpha];
            }
            
            /** 移动 */
            currFrame.origin.x += moveX;
            currFrame.origin.y += moveY;
            
            [self.currPhotoView setPhotoRect:currFrame];
        }
            break;
        default:
            break;
            
    }
    _originalPoint = movePoint;
}

#pragma mark - photoView手势代理
-(void)photoViewGesture:(LFPhotoView *)photoView singleTapImage:(UIImage *)image
{
    [self.movePhotoView removeFromSuperview];
    [self obtainTargetFrame];
    [self handleAnimationEnd];
}

-(void)photoViewGesture:(LFPhotoView *)photoView longPressImage:(UIImage *)image
{
    UIImage *clickImage = image;
    __block NSMutableArray *actionItems = [NSMutableArray array];
    if ([self.delegate respondsToSelector:@selector(photoBrowserLongPressActionItems:image:)]) {
        NSArray *items = [self.delegate photoBrowserLongPressActionItems:self image:clickImage];
        if (items) {
            [actionItems addObjectsFromArray:items];
        }
    } else if (self.longPressActionItemsBlock) {
        NSArray *items = self.longPressActionItemsBlock(clickImage);
        if (items) {
            [actionItems addObjectsFromArray:items];
        }
    } else {
        [actionItems addObjectsFromArray:self.lpActionItems];
    }

    /** 列表排序 */
    [actionItems sortUsingComparator:^NSComparisonResult(LFPhotoSheetAction *  _Nonnull obj1, LFPhotoSheetAction *  _Nonnull obj2) {
        return obj1.style > obj2.style;
    }];
    
    NSString *cancelTitle = nil, *destructiveTitle = nil;
    NSMutableString *otherTitles = [NSMutableString stringWithFormat:@""];
    for (LFPhotoSheetAction *action in actionItems) {
        switch (action.style) {
            case LFPhotoSheetActionType_Default:
//                [otherTitles addObject:action.title];
                [otherTitles appendString:action.title];
                [otherTitles appendString:kSeparator];
                break;
            case LFPhotoSheetActionType_Destructive:
                destructiveTitle = action.title;
                break;
            case LFPhotoSheetActionType_Cancel:
                cancelTitle = action.title;
                break;
        }
    }
    [otherTitles deleteCharactersInRange:NSMakeRange(otherTitles.length - kSeparator.length, kSeparator.length)];
    
    if (destructiveTitle.length || otherTitles.length) {
        UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:nil cancelButtonTitle:(cancelTitle.length ? cancelTitle : @"取消") destructiveButtonTitle:destructiveTitle otherButtonTitles:otherTitles block:^(NSInteger buttonIndex) {
            if (actionItems.count > buttonIndex) {
                LFPhotoSheetAction *action = [actionItems objectAtIndex:buttonIndex];
                if (action.handler) {
                    action.handler(clickImage);
                }
            }
        }];
        [sheet showInView:self.view];
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
    if ([self.downloadDelegate respondsToSelector:@selector(photoBrowser:downloadThumbnailWithPhotoView:photoInfo:)]) {
        [self.downloadDelegate photoBrowser:self downloadThumbnailWithPhotoView:photoView photoInfo:photoView.photoInfo];
        return YES;
    }
    return NO;
}

-(BOOL)photoViewDownLoadOriginal:(LFPhotoView *)photoView url:(NSString *)url
{
    if (self.isBatchDownload) return YES;
    if ([self.downloadDelegate respondsToSelector:@selector(photoBrowser:downloadOriginalWithPhotoView:photoInfo:)]) {
        [self.downloadDelegate photoBrowser:self downloadOriginalWithPhotoView:photoView photoInfo:photoView.photoInfo];
        return YES;
    }
    return NO;
}

-(void)photoViewDownLoadVideo:(LFPhotoView *)photoView url:(NSString *)url
{
    if ([self.downloadDelegate respondsToSelector:@selector(photoBrowser:downloadVideoWithPhotoView:photoInfo:)]) {
        [self.downloadDelegate photoBrowser:self downloadVideoWithPhotoView:photoView photoInfo:photoView.photoInfo];
    }
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
        [SDWebImageManager.sharedManager downloadImageWithURL:[NSURL URLWithString:info.originalImageUrl]
                                                      options:SDWebImageRetryFailed|SDWebImageLowPriority
                                                     progress:nil
                                                    completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
                                                        
                                                        [weakSelf.batchDLHash removeObject:info];
                                                        weakSelf.isBatchDLing = NO;
                                                        [weakSelf batchDownload];
        }];
    }
}

#pragma mark - 重写方法,横屏
-(UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAllButUpsideDown;
}

- (LFPhotoView *)showView
{
    return self.currPhotoView;
}

- (NSArray *)actionItems
{
    return [self.lpActionItems copy];
}

#pragma mark - 懒加载 长按列表数据
- (NSMutableArray *)lpActionItems
{
    if (_lpActionItems == nil) {
        
        LFPhotoSheetAction *action1 = [LFPhotoSheetAction actionWithTitle:@"保存图片" style:LFPhotoSheetActionType_Default handler:^(id object) {
            
            NSLog(@"保存到相册");
        }];
        
        LFPhotoSheetAction *action2 = [LFPhotoSheetAction actionWithTitle:@"取消" style:LFPhotoSheetActionType_Cancel handler:^(id object) {
            NSLog(@"取消");
        }];
        
        _lpActionItems = [NSMutableArray arrayWithObjects:action1, action2, nil];
    }
    
    return _lpActionItems;
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
