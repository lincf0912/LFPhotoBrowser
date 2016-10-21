//
//  PhotoBrowser.m
//  PhotoBrowser
//
//  Created by LamTsanFeng on 2016/9/28.
//  Copyright © 2016年 GZMiracle. All rights reserved.
//

#import "LFPhotoBrowser.h"
#import "LFPhotoInfo.h"
#import "UIImageView+WebCache.h"
#import "UIActionSheet+Block.h"
#import "UIViewController+Extension.h"

#define kRound(f) round(f*10)/10

#define SCREEN_WIDTH [[UIScreen mainScreen] bounds].size.width
#define SCREEN_HEIGHT ([[UIScreen mainScreen] bounds].size.height)

#define kScrollViewW (SCREEN_WIDTH+20)

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

@interface LFPhotoBrowser () <UIScrollViewDelegate>
{
    /** 状态栏隐藏 */
    BOOL _isStatusBarHiden;
    /** 导航栏侧滑返回手势 */
    BOOL _interactiveEnabled;
}
@property (nonatomic, strong) UIScrollView *scroll;
@property (nonatomic, strong, readwrite) NSMutableArray *images;
@property (nonatomic, strong) UIImageView *bgImageView;//背景imageView
@property (nonatomic, strong) UIPageControl *pageControl;
@property (nonatomic, strong) LFPhotoView *movePhotoView; //上一张、下一张
@property (nonatomic, strong) LFPhotoView *currPhotoView; //当前张
@property (nonatomic, assign) int curr; //记录当前张
@property (nonatomic, assign) int scrollIndex; //记录滑动到第几张

@property (nonatomic, strong) UIPanGestureRecognizer *panGesture;
@property (nonatomic, assign) CGPoint originalPoint;
@property (nonatomic, assign) CGPoint beginPoint;

@property (nonatomic, strong) UIView *coverView;

/** 记录触发代理加载数据，避免重复触发 */
/** 左边 */
@property (nonatomic, assign) BOOL callLeftSlideDataSource;
/** 右边 */
@property (nonatomic, assign) BOOL callRightSlideDataSource;

/** 触发开关，必须代理调用才能回滴数据 */
@property (nonatomic, assign) BOOL callDataSource;

/** 目标的frame */
@property (nonatomic, assign) CGRect targetFrame;

/** 长按列表 */
@property (nonatomic, strong) NSMutableArray *lpActionItems;

/** 子线程 */
@property (nonatomic, strong) dispatch_queue_t globalSerialQueue;

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
    
    self.originalPoint = CGPointZero;
    [self imageFromSelectItems:_curr withImageView:_currPhotoView];
    
    [self obtainTargetFrame];
    //动画
    [self handleAnimationBegin];
}

-(void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    if(_images.count > 1){//图片个数大于1，显示三个空间
        [_scroll setContentSize:CGSizeMake(kScrollViewW * 3, 0)];
    }else{
        [_scroll setContentSize:CGSizeMake(kScrollViewW, 0)];
    }
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
    _isStatusBarHiden = YES;
    
    [_currPhotoView calcFrameMaskPosition:self.maskPosition frame:self.targetFrame];
    CGRect currRect = CGRectMake(0, 0, _currPhotoView.frame.size.width, _currPhotoView.frame.size.height);
    
    [UIView animateWithDuration:self.animatedTime animations:^{
        _bgImageView.alpha = 1.f;
        [_currPhotoView calcFrameMaskPosition:MaskPosition_None frame:currRect];
    }completion:^(BOOL finished) {
        [self setNeedsStatusBarAppearanceUpdate];
    }];
}

-(void)handleAnimationEnd
{
    _isStatusBarHiden = NO;
    [self setNeedsStatusBarAppearanceUpdate];
    
    /** 因为触发viewWillDisappear时，self.navigationController 为nil，但不调用[self removeFromParentViewController] 又不会处罚viewWillDisappear */
    [self viewWillDisappear:YES];
    
    [UIView animateWithDuration:self.animatedTime animations:^{
        self.bgImageView.alpha = 0.0f;
    }];
    
    [UIView animateWithDuration:self.animatedTime delay:0.1f options:UIViewAnimationOptionCurveLinear animations:^{
        if(self.isWeaker){
            _currPhotoView.alpha = 0.0f;
        }
        [_currPhotoView calcFrameMaskPosition:self.maskPosition frame:self.targetFrame];
        
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
        _scroll = [[UIScrollView alloc]init];
        _scroll.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        _scroll.autoresizesSubviews = YES;
        _scroll.backgroundColor = [UIColor clearColor];
        [_scroll setShowsHorizontalScrollIndicator:NO];
        [_scroll setDelegate:self];
        [_scroll setPagingEnabled:YES];
        [_scroll setScrollEnabled:YES];
        [self.view addSubview:_scroll];
    }
    _scroll.frame = CGRectMake(0, 0, kScrollViewW, SCREEN_HEIGHT);
    CGFloat scrollViewH = _scroll.frame.size.height;
    CGRect frame = CGRectMake(kScrollViewW, 0, SCREEN_WIDTH, scrollViewH);

    /** 设置两个photoview*/
    if(!_movePhotoView && _images.count > 1){ /** 图片数量只有一张时，不初始化移动view */
        _movePhotoView = [[LFPhotoView alloc] initWithFrame:frame];
        _movePhotoView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        _movePhotoView.autoresizesSubviews = YES;
        [_scroll addSubview:_movePhotoView];
    }
    
    if(!_currPhotoView){
        _currPhotoView = [[LFPhotoView alloc] initWithFrame:frame];
        _currPhotoView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _currPhotoView.autoresizesSubviews = YES;
        _currPhotoView.photoViewDelegate = self;
        [_scroll addSubview:_currPhotoView];
    }
//    [self resetScrollView];
    [self setAutomaticallyAdjustsScrollViewInsets:NO];
    
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
    if (self.callDataSource && (self.curr <= self.slideRange || self.curr >= _images.count-1-self.slideRange)) {
        /** 这个需求不存在 */
    }
}


#pragma mark - 手势处理
-(void)panGesture:(id)sender
{
    if (_currPhotoView.photoInfo.downloadFail) return;
    
    UIPanGestureRecognizer *panGesture = sender;
    CGPoint movePoint = [panGesture translationInView:_currPhotoView];
    CGRect currFrame = _currPhotoView.photoRect;
    switch (panGesture.state)
    {
        case UIGestureRecognizerStateBegan:{
            self.beginPoint = movePoint;
            _movePhotoView.hidden = YES;
            [self obtainTargetFrame];
            /** 转换坐标 */
            [self.coverView setFrame:CGRectMake(kRound(self.targetFrame.origin.x), kRound(self.targetFrame.origin.y), kRound(self.targetFrame.size.width), kRound(self.targetFrame.size.height))];
        }
            break;
        case UIGestureRecognizerStateEnded:{
            if(currFrame.size.width > _currPhotoView.frame.size.width * 0.75)
            {
                _isStatusBarHiden = YES;
                CGRect currRect = _currPhotoView.bounds;
                if (CGRectEqualToRect(currFrame, currRect)) {
                    _movePhotoView.hidden = NO;
                    [_coverView removeFromSuperview];
                    _coverView = nil;
                    [self setNeedsStatusBarAppearanceUpdate];
                } else {
                    [UIView animateWithDuration:0.3 animations:^{
                        self.bgImageView.alpha = 1.0f;
                        [self.navigationController.navigationBar setAlpha:0];
                        [_currPhotoView calcFrameMaskPosition:MaskPosition_None frame:currRect];
                    }completion:^(BOOL finished) {
                        _movePhotoView.hidden = NO;
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
            
            CGRect rect = _currPhotoView.photoRect;
            
            BOOL isChanged = NO;
            if(movePoint.y > self.beginPoint.y && currFrame.size.width > _currPhotoView.frame.size.width/2){ /** 缩小 */
                isChanged = YES;
                if (_isStatusBarHiden) {
                    _isStatusBarHiden = NO;
                    [self setNeedsStatusBarAppearanceUpdate];
                }
            }else if(movePoint.y < self.originalPoint.y && currFrame.size.width < _currPhotoView.frame.size.width){ /** 放大 */
                isChanged = YES;
            }
            
            
            if (isChanged) {
                
                CGRect newRect = CGRectInset(rect, (movePoint.y - self.originalPoint.y), (movePoint.y - self.originalPoint.y));
                
                if (newRect.size.width > _currPhotoView.bounds.size.width) {
                    CGFloat width = newRect.size.width;
                    newRect.size.width = _currPhotoView.bounds.size.width;
                    newRect.origin.x += (width - newRect.size.width)/2;
                }
                if (newRect.size.height > _currPhotoView.bounds.size.height) {
                    CGFloat height = newRect.size.height;
                    newRect.size.height = _currPhotoView.bounds.size.height;
                    newRect.origin.y += (height - newRect.size.height)/2;
                }
                rect = newRect;
                
                //设置透明度
                CGFloat alpha = 1-((_currPhotoView.frame.size.width - rect.size.width)/(_currPhotoView.frame.size.width/2));
                if (alpha > 1.f) {
                    alpha = 1.f;
                } else if (alpha < 0.f) {
                    alpha = 0.f;
                }
                _bgImageView.alpha = alpha;
                
                [UIView animateWithDuration:self.animatedTime animations:^{
                    [self.navigationController.navigationBar setAlpha:1-alpha];
                }];
            }
            
            /** 移动 */
            rect.origin.x += (movePoint.x - self.originalPoint.x);
            rect.origin.y += (movePoint.y - self.originalPoint.y);
            
            if (CGRectEqualToRect(currFrame, rect) == NO) {
                [_currPhotoView calcFrameMaskPosition:MaskPosition_None frame:rect];
            }
            
            
        }
            break;
        default:
            break;
            
    }
    self.originalPoint = movePoint;
}

#pragma mark - 设置imageView的显示模型
- (void)imageFromSelectItems:(NSInteger)num withImageView:(LFPhotoView *)photoView
{
    /*设置图片*/
    LFPhotoInfo *photoInfo = _images[num];
    photoView.photoInfo = photoInfo;
}

#pragma mark 重置scrollView的起始位置
- (void)resetScrollView
{
    CGRect tmpFrame = _movePhotoView.frame;
    tmpFrame.origin.x = kScrollViewW;
    _movePhotoView.frame = tmpFrame;
    [_movePhotoView cleanData];
    if(_canCirculate){
        [_scroll setContentOffset:CGPointMake(kScrollViewW, 0)];
    }else{
        if(self.images.count > 1){
            if(_curr == 0){//_currPhotoView位于左边
                [self currPhotoViewPosition:0];
            }else if(_curr == self.images.count - 1){//_currPhotoView位于右边
                [self currPhotoViewPosition:2];
            }else{
                [_scroll setContentOffset:CGPointMake(kScrollViewW, 0)];
                if(_currPhotoView.frame.origin.x != kScrollViewW){//_currPhotoView位于中间
                    [self currPhotoViewPosition:1];
                }
            }
        }else{
            CGRect tmp = _currPhotoView.frame;
            tmp.origin.x = 0;
            _currPhotoView.frame = tmp;
            [_scroll setContentOffset:CGPointMake(0, 0)];
        }
    }
}

#pragma mark - 设置_currPhotoView的位置(0:左边，1：中间，2：右边)
- (void)currPhotoViewPosition:(int)position
{
    CGRect tmp = _currPhotoView.frame;
    tmp.origin.x = position * kScrollViewW;
    _currPhotoView.frame = tmp;
    [_scroll setContentOffset:CGPointMake(position * kScrollViewW, 0)];
}

- (void)resetNextImageView:(LFPhotoView *)imageView
{
    CGRect tmpFrame = imageView.frame;
    
    if (tmpFrame.origin.x <= kScrollViewW) {
        tmpFrame.origin.x = kScrollViewW*2;
        if(_canCirculate){
            imageView.frame = tmpFrame;
        }else{
            if(!((_curr == self.images.count - 1) || (_curr == 0))){
                imageView.frame = tmpFrame;
            }
        }
        /** 设置下一张图片 */
        self.scrollIndex = (_curr+1)%_images.count;
        
        [self imageFromSelectItems:_scrollIndex withImageView:imageView];
    }
}

- (void)resetPrevImageView:(LFPhotoView *)imageView
{
    CGRect tmpFrame = imageView.frame;
    if (tmpFrame.origin.x >= kScrollViewW) {
        tmpFrame.origin.x = 0;
        if(_canCirculate){
            imageView.frame = tmpFrame;
        }else{
            if(!((_curr == self.images.count - 1) || (_curr == 0))){
                imageView.frame = tmpFrame;
            }
        }
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
    if (scrollView.contentOffset.x>=kScrollViewW*2) {
        [self scrollViewDidEndDecelerating:scrollView];
    } else if (scrollView.contentOffset.x <= 0) {
        [self scrollViewDidEndDecelerating:scrollView];
    } else
        //判断向左拖动 或者 向右拖动
        if (scrollView.contentOffset.x>kScrollViewW && (_curr != self.images.count-1 || _canCirculate)) {//向左滑动
            [self resetNextImageView:_movePhotoView];
        } else if (scrollView.contentOffset.x <kScrollViewW && (_curr != 0 || _canCirculate)) {//向右滑动
            [self resetPrevImageView:_movePhotoView];
        } else if(scrollView.contentOffset.x <kScrollViewW * 2 && _curr == self.images.count-1 && !_canCirculate){
            if(self.images.count >1)
                [self resetPrevImageView:_movePhotoView];
        }else if(scrollView.contentOffset.x > 0 && _curr == 0 && !_canCirculate){
            [self resetNextImageView:_movePhotoView];
        }
}

# pragma mark 代理方法 拖动完毕后执行的方法
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
        [self imageFromSelectItems:_curr withImageView:_currPhotoView];
        [self resetScrollView];
    }
}

#pragma mark - 增加数据源
-(void)addDataSourceFormSlideDirection:(SlideDirection)direction dataSourceArray:(NSArray *)dataSource
{
    if(self.callDataSource && dataSource.count){
        if(direction == SlideDirection_Left && self.callLeftSlideDataSource == NO){
            dispatch_sync_main(^{
                self.callLeftSlideDataSource = YES;
                [self.images addObjectsFromArray:dataSource];
                _pageControl.numberOfPages = self.images.count;
                _pageControl.currentPage = _curr;
            });
            
        }else if(direction == SlideDirection_Right && self.callRightSlideDataSource == NO){
            dispatch_sync_main(^{
                self.callRightSlideDataSource = YES;
                [self.images insertObjects:dataSource atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, dataSource.count)]];
                _pageControl.numberOfPages = self.images.count;
                _curr += dataSource.count;
                _pageControl.currentPage = _curr;
            });
        }
//        [self resetScrollView];
    }
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
    if([self.delegate respondsToSelector:@selector(frameOfPhotoBrowserWithCurrentIndex:key:)]){
        CGRect frame = [self.delegate frameOfPhotoBrowserWithCurrentIndex:_curr key:_currPhotoView.photoInfo.key];
        if(frame.size.width != 0 && frame.size.height != 0){
            self.targetFrame = frame;
        } else {
            self.targetFrame = CGRectMake(SCREEN_WIDTH/2, SCREEN_HEIGHT/2, 0, 0);
        }
    } else {
        self.targetFrame = CGRectMake(SCREEN_WIDTH/2, SCREEN_HEIGHT/2, 0, 0);
    }
}
#pragma mark - photoView手势代理
-(void)photoViewGesture:(LFPhotoView *)photoView singleTapImageView:(UIImageView *)imageView
{
    [_movePhotoView removeFromSuperview];
    [self obtainTargetFrame];
    [self handleAnimationEnd];
}

-(void)photoViewGesture:(LFPhotoView *)photoView longPressImageView:(UIImageView *)imageView
{
    __block NSMutableArray *actionItems = [NSMutableArray array];
    if ([self.delegate respondsToSelector:@selector(longPressActionItems:image:)]) {
        NSArray *items = [self.delegate longPressActionItems:self image:imageView.image];
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
    
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:nil cancelButtonTitle:(cancelTitle.length ? cancelTitle : @"取消") destructiveButtonTitle:destructiveTitle otherButtonTitles:otherTitles block:^(NSInteger buttonIndex) {
        LFPhotoSheetAction *action = [actionItems objectAtIndex:buttonIndex];
        if (action.handler) {
            action.handler(imageView.image);
        }
    }];
    [sheet showInView:self.view];
}

-(void)photoViewWillBeginZooming:(LFPhotoView *)photoView
{
//    if (_canPullDown) {
//        [self obtainOverFrame];
//        _movePhotoView.hidden = YES;
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
//            _movePhotoView.hidden = NO;
//        }
//    }
}

#pragma mark - 重写方法,横屏
-(UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAllButUpsideDown;
}

- (LFPhotoView *)showView
{
    return _currPhotoView;
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
