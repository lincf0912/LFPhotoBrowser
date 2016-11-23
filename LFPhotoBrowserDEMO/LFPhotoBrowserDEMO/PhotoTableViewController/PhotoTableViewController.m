//
//  PhotoTableViewController.m
//  LFPhotoBrowserDEMO
//
//  Created by LamTsanFeng on 2016/10/18.
//  Copyright © 2016年 GZMiracle. All rights reserved.
//

#import "PhotoTableViewController.h"
#import "PhotoTableViewCell.h"

#import "DownLoadManager.h"

#import "LFPhotoBrowser.h"
#import "LFPhotoInfo.h"

#import "LFPhotoView.h"

#define kPhotoBrower @"PhotoBrower"

@interface PhotoTableViewController () <UITableViewDelegate, UITableViewDataSource, LFPhotoBrowserDelegate, LFPhotoBrowserDownloadDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *resources;

@property (nonatomic, strong) NSMapTable *mapTable;

@end

@implementation PhotoTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    if ([self respondsToSelector:@selector(automaticallyAdjustsScrollViewInsets)]) {
        self.automaticallyAdjustsScrollViewInsets = NO;
    }
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) style:UITableViewStylePlain];
    
    self.tableView.contentInset = UIEdgeInsetsMake(64, 0, 0, 0);
    self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(64, 0, 0, 0);
    [self.view addSubview:self.tableView];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    self.mapTable = [NSMapTable weakToWeakObjectsMapTable];
    
}

- (void)dealloc
{
    [DownLoadManager cancelAllDL];
}

- (NSArray *)resources
{
    if (_resources == nil) {
        NSMutableArray *array = [NSMutableArray array];
        [array addObject:@"http://data.vod.itc.cn/?prod=app&new=/194/216/JBUeCIHV4s394vYk3nbgt2.mp4"];
        [array addObject:@"http://data.vod.itc.cn/?prod=app&new=/5/36/aUe9kB0906IvkI5UCpq11K.mp4"];
        [array addObject:@"http://data.vod.itc.cn/?prod=app&new=/10/66/eCGPkAewSVqy9P57hvB11D.mp4"];
        [array addObject:@"http://data.vod.itc.cn/?prod=app&new=/125/206/g586XlZhJQBGTnFDS75cPF.mp4"];
        
        [array addObject:@"http://superhero.wingzero.tw/wp-content/uploads/2013/11/punisher.jpg"];
        [array addObject:@"http://superhero.wingzero.tw/wp-content/uploads/2015/06/green-lantern.jpg"];
        [array addObject:@"http://superhero.wingzero.tw/wp-content/uploads/2015/06/star-lord.jpg"];
        [array addObject:@"http://superhero.wingzero.tw/wp-content/uploads/2014/07/superman.jpg"];
        [array addObject:@"http://superhero.wingzero.tw/wp-content/uploads/2014/07/wolverine.jpg"];
        [array addObject:@"http://superhero.wingzero.tw/wp-content/uploads/2014/06/spider-man.jpg"];
        [array addObject:@"http://superhero.wingzero.tw/wp-content/uploads/2014/05/flash.jpg"];
        [array addObject:@"http://superhero.wingzero.tw/wp-content/uploads/2014/04/green_arrow.jpg"];
        [array addObject:@"http://superhero.wingzero.tw/wp-content/uploads/2014/03/captain_america_ws.jpg"];
        [array addObject:@"http://superhero.wingzero.tw/wp-content/uploads/2014/01/ironman_mk42.jpg"];
        [array addObject:@"http://superhero.wingzero.tw/wp-content/uploads/2014/01/batman.jpg"];
        [array addObject:@"http://superhero.wingzero.tw/wp-content/uploads/2015/07/captain_atom.jpg"];
        [array addObject:@"http://superhero.wingzero.tw/wp-content/uploads/2015/06/shazam.jpg"];
        [array addObject:@"http://superhero.wingzero.tw/wp-content/uploads/2015/06/hawkeye.jpg"];
        [array addObject:@"http://superhero.wingzero.tw/wp-content/uploads/2014/01/ironman_mk43.jpg"];
        [array addObject:@"http://superhero.wingzero.tw/wp-content/uploads/2015/06/wonder_woman.jpg"];
        [array addObject:@"http://superhero.wingzero.tw/wp-content/uploads/2015/06/thor.jpg"];
        [array addObject:@"http://superhero.wingzero.tw/wp-content/uploads/2015/06/aquaman.jpg"];
        [array addObject:@"http://superhero.wingzero.tw/wp-content/uploads/2015/06/hulk-450x450.jpg"];
        [array addObject:@"http://superhero.wingzero.tw/wp-content/uploads/2015/06/martian-manhunter.jpg"];
        [array addObject:@"http://superhero.wingzero.tw/wp-content/uploads/2016/01/falcon-450x394.jpg"];
        [array addObject:@"http://superhero.wingzero.tw/wp-content/uploads/2015/12/supergirl.jpg"];
        [array addObject:@"http://superhero.wingzero.tw/wp-content/uploads/2015/11/deadpool.jpg"];
        [array addObject:@"http://superhero.wingzero.tw/wp-content/uploads/2015/10/firestorm.jpg"];
        [array addObject:@"http://superhero.wingzero.tw/wp-content/uploads/2015/10/winter_soldier.jpg"];
        [array addObject:@"http://superhero.wingzero.tw/wp-content/uploads/2015/09/dr_fate.jpg"];
        [array addObject:@"http://superhero.wingzero.tw/wp-content/uploads/2015/09/atom.jpg"];
        [array addObject:@"http://superhero.wingzero.tw/wp-content/uploads/2015/09/mr_fantastic.jpg"];
        [array addObject:@"http://superhero.wingzero.tw/wp-content/uploads/2015/08/ant-man.jpg"];
        [array addObject:@"http://superhero.wingzero.tw/wp-content/uploads/2015/07/daredevil.jpg"];
        [array addObject:@"http://superhero.wingzero.tw/wp-content/uploads/2016/09/beast_boy.jpg"];
        [array addObject:@"http://superhero.wingzero.tw/wp-content/uploads/2016/06/black_panther.jpg"];
        [array addObject:@"http://superhero.wingzero.tw/wp-content/uploads/2016/06/red_robin.jpg"];
        [array addObject:@"http://superhero.wingzero.tw/wp-content/uploads/2016/04/vision-1.png"];
        [array addObject:@"http://superhero.wingzero.tw/wp-content/uploads/2016/04/quicksilver.jpg"];
        [array addObject:@"http://superhero.wingzero.tw/wp-content/uploads/2016/03/blade.jpg"];
        [array addObject:@"http://superhero.wingzero.tw/wp-content/uploads/2016/02/raven.jpg"];
        [array addObject:@"http://superhero.wingzero.tw/wp-content/uploads/2016/02/iron_fist.jpg"];
        [array addObject:@"http://superhero.wingzero.tw/wp-content/uploads/2016/01/iceman.jpg"];
        [array addObject:@"http://superhero.wingzero.tw/wp-content/uploads/2016/01/vixen.jpg"];
        _resources = [array copy];
    }
    return _resources;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.resources.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *const reuseIdentifier = @"PhotoTableCell";
    PhotoTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    if (cell == nil) {
        cell = [[PhotoTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    }
    
    cell.url = self.resources[indexPath.row];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 100.f;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSMutableArray *items = [NSMutableArray arrayWithCapacity:self.resources.count];
    int count=0,max = 2;
    for (NSString *url in self.resources) {
        if ([url hasSuffix:@".mp4"]) {
            LFPhotoInfo *photo = [LFPhotoInfo photoInfoWithType:PhotoType_video key:nil];
            if (count++ < max) {
                photo.isNeedSlider = YES;
            }
            photo.videoPath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES) objectAtIndex:0] stringByAppendingPathComponent:url.lastPathComponent];
            photo.videoUrl = url;
            photo.isLoading = [DownLoadManager isExistsDL:url];
            [items addObject:photo];
            
            [self.mapTable setObject:photo forKey:url];
        } else {
            LFPhotoInfo *photo = [LFPhotoInfo photoInfoWithType:PhotoType_image key:nil];
            photo.originalImageUrl = url;
            [items addObject:photo];
            /** 图片是内置SD下载，没有必要记录数据源 */
//            [self.mapTable setObject:photo forKey:url];
        }
    }
    
    LFPhotoBrowser *pbVC = [[LFPhotoBrowser alloc] initWithImageArray:items currentIndex:(int)indexPath.row];
    //    pbVC.isWeaker = YES;
    pbVC.animatedTime = 0.25f;
    pbVC.delegate = self;
    pbVC.downloadDelegate = self;
    [pbVC showPhotoBrowser];
    
    [self.mapTable setObject:pbVC forKey:kPhotoBrower];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - LFPhotoBrowserDelegate
- (CGRect)photoBrowserTargetFrameWithIndex:(int)index key:(NSString *)key
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
    if([self.tableView.indexPathsForVisibleRows containsObject:indexPath]){
        PhotoTableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
        
        return [cell obtainPhotoViewFrameInView:self.view];
    }else{
        return CGRectZero;
    }
}

- (NSArray <LFPhotoSheetAction *>*)photoBrowserLongPressActionItems:(LFPhotoBrowser *)photoBrowser image:(UIImage *)image
{
    NSMutableArray *items = [NSMutableArray arrayWithArray:photoBrowser.actionItems];
    LFPhotoSheetAction *action = [LFPhotoSheetAction actionWithTitle:@"识别图中二维码" style:LFPhotoSheetActionType_Default handler:^(id object) {
        NSLog(@"新增识别图中二维码");
    }];
    [items addObject:action];
    return [items copy];
}

#warning 注释以下方法，视频则为在线播放
#pragma mark - LFPhotoBrowserDownloadDelegate
-(void)photoBrowser:(LFPhotoBrowser *)photoBrowser downloadVideoWithPhotoInfo:(LFPhotoInfo *)photoInfo
{
    __weak typeof(self) weakSelf = self;
    NSString *path = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES) objectAtIndex:0] stringByAppendingPathComponent:photoInfo.videoUrl.lastPathComponent];
    
    /** 测试下载失败 */
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        photoInfo.downloadFail = YES;
//        [photoBrowser reloadView:photoInfo];
//    });
//    
//    
//    return;
    
    NSString *tempPath = [DownLoadManager getDLTempPathWithSavePath:path];
    signed long long fileSize = 0;
    NSFileManager *fileManager = [NSFileManager new]; // default is not thread safe
    if ([fileManager fileExistsAtPath:tempPath]) {
        NSError *error = nil;
        NSDictionary *fileDict = [fileManager attributesOfItemAtPath:tempPath error:&error];
        if (!error && fileDict) {
            fileSize = [fileDict fileSize];
        }
    }
    
    [DownLoadManager basicHttpFileDownloadWithUrlString:photoInfo.videoUrl
                                                 offset:fileSize /** 获取原下载路径续传 */
                                                 params:nil
                                                timeout:5.f
                                               savePath:path
                                               download:^(long long totalBytes, long long totalBytesExpected) {
                                                   
                                                   LFPhotoInfo *b_phtoInfo = [weakSelf.mapTable objectForKey:photoInfo.videoUrl];
                                                   b_phtoInfo.downloadProgress = (float)(totalBytes*1.0/totalBytesExpected);
                                                   
                                               } success:^{
                                                   
                                                   LFPhotoInfo *b_phtoInfo = [weakSelf.mapTable objectForKey:photoInfo.videoUrl];
                                                   b_phtoInfo.videoPath = path;
                                                   LFPhotoBrowser *pb = [weakSelf.mapTable objectForKey:kPhotoBrower];
                                                   [pb reloadView:b_phtoInfo];
                                                   
                                               } failure:^(NSError *error) {
                                                   
                                                   LFPhotoInfo *b_phtoInfo = [weakSelf.mapTable objectForKey:photoInfo.videoUrl];
                                                   /** 更新Model状态 */
                                                   b_phtoInfo.downloadFail = YES;
                                                   LFPhotoBrowser *pb = [weakSelf.mapTable objectForKey:kPhotoBrower];
                                                   [pb reloadView:b_phtoInfo];
                                               }];
}
@end
