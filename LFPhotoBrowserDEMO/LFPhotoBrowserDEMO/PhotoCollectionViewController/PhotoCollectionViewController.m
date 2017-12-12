//
//  PhotoCollectionViewController.m
//  LFPhotoBrowserDEMO
//
//  Created by LamTsanFeng on 2016/10/18.
//  Copyright © 2016年 GZMiracle. All rights reserved.
//

#import "PhotoCollectionViewController.h"
#import "XLPlainFlowLayout.h"
#import "PhotoHeadView.h"
#import "PhotoCollectionViewCell.h"

#import "LFPhotoBrowser.h"
#import "LFPhotoInfo.h"

#define HeadSize CGSizeMake([[UIScreen mainScreen] bounds].size.width, 25)
#define CellSize CGSizeMake(([[UIScreen mainScreen] bounds].size.width - 30) / 4, ([[UIScreen mainScreen] bounds].size.width - 30) / 4)

@interface PhotoCollectionViewController ()<UICollectionViewDelegate, UICollectionViewDataSource, LFPhotoBrowserDelegate>

@property (strong, nonatomic) UICollectionView *collectionView;

@property (nonatomic, strong) NSMutableDictionary *dataSourcDic;

@property (nonatomic, strong) NSMutableArray *titleArrs;

@property (nonatomic, assign) BOOL showPhotoBrowser;

@end

@implementation PhotoCollectionViewController

static NSString * const reuseIdentifier = @"Cell";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations
    // self.clearsSelectionOnViewWillAppear = NO;
//    [self.navigationController setNavigationBarHidden:YES animated:NO];
    
    // Register cell classes
    [self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:reuseIdentifier];
    
    
    // Do any additional setup after loading the view.
    [self initDataSource];
    [self initCollectionView];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
//    NSLog(@"%f", (CGRectGetHeight(self.navigationController.navigationBar.frame) + CGRectGetHeight([UIApplication sharedApplication].statusBarFrame)));
    
    /** 导航栏不存在 或 透明导航栏不计算 */
    BOOL autoScroll = YES;
    if (self.navigationController == nil || self.navigationController.navigationBar.hidden) {
        autoScroll = NO;
    }
    
    UIEdgeInsets safeAreaInsets = UIEdgeInsetsZero;
    if (@available(iOS 11.0, *)) {
        safeAreaInsets = self.view.safeAreaInsets;
    }
    CGFloat naviHeight = CGRectGetMaxY(self.navigationController.navigationBar.frame);
    UIEdgeInsets insets = self.collectionView.contentInset;
    UIEdgeInsets offsets = UIEdgeInsetsZero;
    
    CGFloat diff = naviHeight - insets.top + offsets.top;
    
    insets.top = naviHeight + offsets.top;
    
    CGFloat targetBottom = offsets.bottom;
    if (@available(iOS 11.0, *)) {
        targetBottom += safeAreaInsets.bottom;
    }
    diff += (targetBottom - insets.bottom);
    insets.bottom = targetBottom;
    insets.left = offsets.left;
    insets.right = offsets.right;
    
    CGPoint contentOffset = self.collectionView.contentOffset;
    self.collectionView.contentInset = insets;
    self.collectionView.scrollIndicatorInsets = insets;
    
    if (autoScroll && self.collectionView.contentSize.height > self.collectionView.frame.size.height - insets.top - insets.bottom) {
        [self.collectionView setContentOffset:CGPointMake(contentOffset.x, MAX((contentOffset.y - diff), -insets.top))];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    NSNumber *orientationUnknown = [NSNumber numberWithInt:UIInterfaceOrientationUnknown];
    [[UIDevice currentDevice] setValue:orientationUnknown forKey:@"orientation"];
    
    NSNumber *orientationTarget = [NSNumber numberWithInt:UIInterfaceOrientationPortrait];
    [[UIDevice currentDevice] setValue:orientationTarget forKey:@"orientation"];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIViewController *)childViewControllerForStatusBarHidden
{
    /** 因iOS7之后需要实现此方法才能控制状态栏，重写方法，让childViewController控制状态栏 */
    return self.childViewControllers.count ? self.childViewControllers.firstObject : nil;
}

#pragma mark - Private Methods
#pragma mark 初始化控件
- (void)initCollectionView{
    
    if ([self respondsToSelector:@selector(automaticallyAdjustsScrollViewInsets)]) {
        self.automaticallyAdjustsScrollViewInsets = NO;
    }
    
    XLPlainFlowLayout *flowLayout = [[XLPlainFlowLayout alloc] init];
    flowLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
    flowLayout.headerReferenceSize = CGSizeMake(0, 30);
    _collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) collectionViewLayout:flowLayout];
    _collectionView.contentInset = UIEdgeInsetsMake(64, 0, 0, 0);
    _collectionView.scrollIndicatorInsets = UIEdgeInsetsMake(64, 0, 0, 0);
    _collectionView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    _collectionView.delegate = self;
    _collectionView.dataSource = self;
    
    flowLayout.naviHeight = _collectionView.contentInset.top;
    [self.view addSubview:_collectionView];
    
    //注册cell
    [_collectionView registerClass:[PhotoCollectionViewCell class] forCellWithReuseIdentifier:reuseIdentifier];
    
    //注册表头
    [_collectionView registerClass:[PhotoHeadView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"PhotoHeadView"];
}

#pragma mark 创建数据源
- (void)initDataSource{
    _dataSourcDic = [NSMutableDictionary dictionary];
    _titleArrs = [[NSMutableArray alloc] init];
    
    NSArray *keys = @[@"1今天", @"2明天", @"3一周前", @"4一个月前", @"5三个月前"];
    
    for (NSInteger i=0; i<22; i++) {
        NSString *name = [NSString stringWithFormat:@"%ld.jpeg", i];
        if (i == 0) {
            name = [NSString stringWithFormat:@"%ld.gif", i];
        }
        if (i<5) {
            NSMutableArray *array = [self getMutableArrayWithKey:keys[0]];
            [array addObject:name];
        } else if (i < 10) {
            NSMutableArray *array = [self getMutableArrayWithKey:keys[1]];
            [array addObject:name];
        } else if (i < 15) {
            NSMutableArray *array = [self getMutableArrayWithKey:keys[2]];
            [array addObject:name];
        } else if (i < 20) {
            NSMutableArray *array = [self getMutableArrayWithKey:keys[3]];
            [array addObject:name];
        } else {
            NSMutableArray *array = [self getMutableArrayWithKey:keys[4]];
            [array addObject:name];
        }
    }
    for (NSInteger k=1; k<7; k++) {
        NSMutableArray *array = [self getMutableArrayWithKey:keys[arc4random() % (keys.count-1)]];
        [array addObject:[NSString stringWithFormat:@"%ld00.png", k]];
    }
    
}

- (NSMutableArray *)getMutableArrayWithKey:(NSString *)key
{
    NSMutableArray *array = _dataSourcDic[key];
    if (array == nil) {
        array = [NSMutableArray array];
        [_dataSourcDic setObject:array forKey:key];
        [_titleArrs addObject:key];
    }
    
    return array;
}

#pragma mark - collectionView data source

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    return _titleArrs.count;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    NSArray *array;
    NSString *key = _titleArrs[section];
    array = _dataSourcDic[key];
    return array.count;
}

///自定义cell，展示图片
-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    PhotoCollectionViewCell * cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    NSString *key = _titleArrs[indexPath.section];
    NSArray *array = _dataSourcDic[key];
    NSString *name = array[indexPath.row];
    cell.imageName = name;
    /** 视频标记 */
    if ([name containsString:@"00"]) {
        [cell markVideo];
    }
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    /** 当前点击 */
    NSString *key = _titleArrs[indexPath.section];
    NSArray *array = _dataSourcDic[key];
    NSString *clickName = array[indexPath.row];
    
    int index = 0;
    BOOL isFinded = NO;
    /** 生成图片数据源 */
    NSMutableArray *items = [NSMutableArray arrayWithCapacity:10];
    for (NSString *title in self.titleArrs) {
        NSArray *array = self.dataSourcDic[title];
        for (NSString *name in array) {
            if ([name containsString:@"00"]) {
                LFPhotoInfo *photo = [LFPhotoInfo photoInfoWithType:PhotoType_video key:title];
                photo.thumbnailPath = [[NSBundle mainBundle] pathForResource:name ofType:nil];
                photo.videoPath = [[NSBundle mainBundle] pathForResource:[[name stringByDeletingPathExtension] stringByAppendingPathExtension:@"mp4"] ofType:nil];
                [items addObject:photo];
                if ([name compare:@"400"] == NSOrderedAscending) { /** 部分模拟需要进度条 */
                    photo.isNeedSlider = YES;
//                    photo.isAutoPlay = YES;
                }
            } else {
                LFPhotoInfo *photo = [LFPhotoInfo photoInfoWithType:PhotoType_image key:title];
//                photo.originalImagePath = [[NSBundle mainBundle] pathForResource:name ofType:nil];
                /** 新增data传参，主要为了方便保存到相册的问题 */
                NSString *imagePath = [[NSBundle mainBundle] pathForResource:name ofType:nil];
                photo.originalImageData = [NSData dataWithContentsOfFile:imagePath options:NSDataReadingMappedIfSafe error:nil];
                [items addObject:photo];
            }
            if ([clickName isEqualToString:name]) {
                isFinded = YES;
            }
            if (isFinded == NO) {
                index ++;
            }
        }
    }
    
    LFPhotoBrowser *pbVC = [[LFPhotoBrowser alloc] initWithImageArray:items currentIndex:index];
    pbVC.animatedTime = 0.2f;
    pbVC.delegate = self;
    pbVC.canPullDown = YES;
    pbVC.coverViewColor = self.collectionView.backgroundColor;
    
    [pbVC showPhotoBrowser];
    
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
}

//定义每个UICollectionView 的大小
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
    return CellSize; //!<cell的大小;
}

//定义每个UICollectionView 的纵向间距
-(CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section{
    return 0.0f;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section{
    return UIEdgeInsetsMake(5, 5, 5, 5);
}

//定义每个UICollectionView 的横向间距
//-(CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section{
//    return 5.0f;
//}

//定义表头的大小
-(CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section{
    return HeadSize;
}


//定义表头内容
-(UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath{
    PhotoHeadView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"PhotoHeadView" forIndexPath:indexPath];
    headerView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.8f];
    ///表头文字
    NSString *headerTitle = _titleArrs[indexPath.section];
    [headerView setTitleLabWithText:[headerTitle substringFromIndex:1]];
    return headerView;
}

#pragma mark - PhotoBrowserDelegate
- (void)photoBrowserWillBeginShow:(LFPhotoBrowser *)photoBrowser
{
    self.showPhotoBrowser = YES;
}
- (void)photoBrowserDidEndShow:(LFPhotoBrowser *)photoBrowser
{
    self.showPhotoBrowser = NO;
}

- (CGRect)photoBrowserTargetFrameWithIndex:(int)index key:(NSString *)key
{
    CGFloat contentOffsetY = self.collectionView.contentOffset.y;
    //获取导航栏大小
    CGFloat statusBarHeight = 20;
    if ([UIApplication sharedApplication].statusBarHidden && [UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationPortrait) {
        statusBarHeight = 20.f;
    }
    CGFloat navigationBarMaxY = CGRectGetHeight(self.navigationController.navigationBar.frame) + statusBarHeight;
    CGFloat navigationBarMaxX = CGRectGetWidth(self.navigationController.navigationBar.frame);
    
    /** 顶部交集+头部高度 */
    CGRect topRect = CGRectMake(0, 0, navigationBarMaxX, navigationBarMaxY + HeadSize.height);
    
    /** 底部交集 */
    CGRect boomRect = (CGRect){0, CGRectGetMaxY(self.collectionView.frame), CGRectGetWidth(self.collectionView.frame), CellSize.height};
    
    
    /** 获取indexPath */
    
    NSInteger section = 0, row = NSNotFound, count = 0;
    for (NSString *title in self.titleArrs) {
        NSArray *array = self.dataSourcDic[title];
        if ([title isEqualToString:key]) {
            row = index - count;
            break;
        }
        section++;
        count += array.count;
    }
    /** 防止崩溃 */
    if (row == NSNotFound) return CGRectZero;
    
    NSIndexPath *indexPath =[NSIndexPath indexPathForRow:row inSection:section];
    PhotoCollectionViewCell * cell = (PhotoCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
    if (cell == nil) { /** indexPath 在屏幕外 无法获取cell */
        /** 获取当前可见的 头部 与 底部 的代表cell */
        __weak UICollectionViewCell *topCell, *boomCell;
        NSArray *visibleCells = [[self.collectionView visibleCells] sortedArrayUsingComparator:^NSComparisonResult(UICollectionViewCell *  _Nonnull obj1, UICollectionViewCell *  _Nonnull obj2) {
            /** y值排序 */
            return CGRectGetMinY(obj1.frame) > CGRectGetMinY(obj2.frame);
        }];
        for (UICollectionViewCell *vCell in visibleCells) {
            /** 转换坐标计算 */
            CGRect vCellRect = [vCell convertRect:vCell.contentView.frame toView:self.view];
            if (CGRectGetMaxY(vCellRect) >= CGRectGetMaxY(topRect)) {
                topCell = vCell;
                break;
            }
        }
        boomCell = visibleCells.lastObject;
        
        /** 滚到到当前indexPath */
        [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionNone animated:NO];
        /** 刷新数据 */
        [self.collectionView layoutIfNeeded];
        /** 获取cell */
        cell = (PhotoCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
        
        /** 重新获取contentOffset */
        contentOffsetY = self.collectionView.contentOffset.y;
        
        /** 到屏幕中心的偏移量 */
        CGFloat offsetY = (CGRectGetHeight(self.collectionView.frame)/2 - CGRectGetHeight(cell.frame)/2 - navigationBarMaxY);
        /** 判断超出2行高度，调整到屏幕中心 */
        if ((CGRectGetMaxY(topCell.frame) - CGRectGetMaxY(cell.frame)) >= CGRectGetHeight(cell.frame) * 2) {
            contentOffsetY -= offsetY;
        } else if (CGRectGetMaxY(cell.frame) - (CGRectGetMaxY(boomCell.frame)) >= CGRectGetHeight(cell.frame) * 2) {
            contentOffsetY += offsetY;
        }
    }
    
    
    //转换cell的坐标
    CGRect cellRect = [cell convertRect:cell.contentView.frame toView:self.view];
    
    BOOL isIntersectsTop = CGRectIntersectsRect(topRect, cellRect);
    BOOL isIntersectsBoom = CGRectIntersectsRect(boomRect, cellRect);
    if (isIntersectsTop || isIntersectsBoom) {
        /** 差值 */
        CGFloat offsetY = (isIntersectsTop ? CGRectGetMaxY(topRect) - cellRect.origin.y : CGRectGetMaxY(cellRect) - boomRect.origin.y);
        contentOffsetY -= (isIntersectsTop ? offsetY : -offsetY);
    }
    
    CGFloat offsetHeight = self.collectionView.contentSize.height - CGRectGetHeight(self.collectionView.frame);
    CGFloat minOffsetY = -(self.collectionView.contentInset.top+self.collectionView.contentInset.bottom);
    /** 判断contentOffset的y值能否到达屏幕中心，否则去最大值 */
    if ((offsetHeight > 0 && contentOffsetY > offsetHeight) || contentOffsetY < minOffsetY) {
        contentOffsetY = contentOffsetY < minOffsetY ? minOffsetY : offsetHeight;
    }
    
    /** 滚动到指定位置 */
    if (contentOffsetY != self.collectionView.contentOffset.y) {
        [self.collectionView setContentOffset:CGPointMake(self.collectionView.contentOffset.x, contentOffsetY)];
    }
    
    
    if(cell){
        return [cell convertRect:cell.contentView.frame toView:self.view];
    }else{
        return CGRectZero;
    }
}

- (NSArray <LFPhotoSheetAction *>*)photoBrowserLongPressActionItems:(LFPhotoBrowser *)photoBrowser photoInfo:(LFPhotoInfo *)photoInfo object:(id /* UIImage * /NSURL * */)object
{
    BOOL isImage = photoInfo.photoType == PhotoType_image ? YES : NO;
    NSMutableArray *actionsArr = [@[] mutableCopy];
    NSString *title = isImage ? @"保存图片" : @"保存视频";
    /** sheetAction1 */
    LFPhotoSheetAction *sheetAction1 = [LFPhotoSheetAction actionWithTitle:title style:LFPhotoSheetActionType_Default handler:^(id media) {
        /** object = UIImage 无法保存GIF图片的数据，需要使用photoInfo.originalImageData 或者photoInfo.originalImagePath 获取NSData来保存到相册  */
        NSLog(@"%@", title);
    }];
    [actionsArr addObject:sheetAction1];
    if (isImage) {
            LFPhotoSheetAction *sheetAction2 = [LFPhotoSheetAction actionWithTitle:@"识别图中二维码" style:LFPhotoSheetActionType_Default handler:^(id media) {
                    NSLog(@"识别图中二维码");
            }];
            [actionsArr addObject:sheetAction2];
    }
    
    LFPhotoSheetAction *sheetAction4 = [LFPhotoSheetAction actionWithTitle:@"ooooo" style:LFPhotoSheetActionType_Destructive handler:^(id media) {
        NSLog(@"ooooo");
    }];
    [actionsArr addObject:sheetAction4];

    
    /** sheetAction3 */
    LFPhotoSheetAction *sheetAction3 = [LFPhotoSheetAction actionWithTitle:@"取消" style:LFPhotoSheetActionType_Cancel handler:^(id media) {
        NSLog(@"cancel");
    }];
    [actionsArr addObject:sheetAction3];
    return actionsArr;
}

/** 设置保存按钮（右下角） */
- (void)photoBrowserSavePreview:(LFPhotoBrowser *)photoBrowser photoInfo:(LFPhotoInfo *)photoInfo object:(id /* UIImage * /NSURL * */)object
{
    NSLog(@"设置保存按钮（右下角）-- %@", object);
}
/** 设置更多按钮（右上角） */
- (void)photoBrowserMorePreview:(LFPhotoBrowser *)photoBrowser photoInfo:(LFPhotoInfo *)photoInfo object:(id /* UIImage * /NSURL * */)object
{
    NSLog(@"设置更多按钮（右上角）-- %@", object);
}

- (BOOL)shouldAutorotate
{
    return YES;
}


-(UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    /** 交由子界面决定横屏情况 */
    return self.childViewControllers.count ? [self.childViewControllers.firstObject supportedInterfaceOrientations] : UIInterfaceOrientationMaskPortrait;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationPortrait;
}

@end
