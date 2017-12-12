//
//  LFDownloadManager.m
//  LFPhotoBrowserDEMO
//
//  Created by TsanFeng Lam on 2017/12/11.
//  Copyright © 2017年 GZMiracle. All rights reserved.
//

#import "LFDownloadManager.h"

#define LFDownloadManagerDirector [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:NSStringFromClass([LFDownloadManager class])]
#define LFDownloadManagerDirectorAppending(name) [LFDownloadManagerDirector stringByAppendingPathComponent:name]

@interface LFDownloadInfo : NSObject

@property (nonatomic, assign) NSInteger downloadTimes;
@property (nonatomic, strong) NSURL *downloadURL;

@property (nonatomic, readonly) BOOL reDownload;

@property (nonatomic, copy) lf_progressBlock progress;
@property (nonatomic, copy) lf_completeBlock complete;

@end

@implementation LFDownloadInfo

+ (LFDownloadInfo *)lf_downloadInfoWithURL:(NSURL *)downloadURL
{
    LFDownloadInfo *info = [[LFDownloadInfo alloc] init];
    info.downloadURL = downloadURL;
    return info;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _downloadTimes = 1;
    }
    return self;
}

- (BOOL)reDownload
{
    return _downloadTimes > 1;
}

@end

@interface LFDownloadManager() <NSURLSessionDownloadDelegate>

@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSMutableDictionary *downloadDictionary;

@end

@implementation LFDownloadManager

+ (void)initialize {
    
    NSString *directory = LFDownloadManagerDirector;
    BOOL isDirectory = NO;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isExists = [fileManager fileExistsAtPath:directory isDirectory:&isDirectory];
    if (!isExists || !isDirectory) {
        [fileManager createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:nil];
    }
}

+ (LFDownloadManager *)shareLFDownloadManager
{
    static LFDownloadManager *share = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        share = [LFDownloadManager new];
    });
    return share;
}

- (NSMutableDictionary <NSURL *, LFDownloadInfo *>*)downloadDictionary {
    
    if (!_downloadDictionary) {
        _downloadDictionary = @{}.mutableCopy;
    }
    return _downloadDictionary;
}

- (instancetype)init {
    
    if (self = [super init]) {
        _session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[NSOperationQueue mainQueue]];
        _repeatCountWhenDownloadFailed = 2;
    }
    return self;
}

- (NSData *)dataFromSandboxWithURL:(NSURL *)URL {
    
    NSString *path = LFDownloadManagerDirectorAppending(URL.lastPathComponent);
    NSData *data = [NSData dataWithContentsOfFile:path];
    if (data.length > 0 ) {
        return data;
    } else {
        [[NSFileManager defaultManager] removeItemAtPath:path error:NULL];
    }
    return nil;
}

- (void)lf_downloadURL:(NSURL *)URL progress:(lf_progressBlock)progress completion:(lf_completeBlock)completion
{
    LFDownloadInfo *info = [LFDownloadInfo lf_downloadInfoWithURL:URL];
    info.progress = [progress copy];
    info.complete = [completion copy];
    self.downloadDictionary[URL] = info;
    
    [self downloadInfo:info];
}

- (BOOL)redownloadInfo:(LFDownloadInfo *)info
{
    NSInteger downloadTimes = info.downloadTimes;
    if (self.repeatCountWhenDownloadFailed > downloadTimes) {
        info.downloadTimes++;
        [self downloadInfo:info];
        return YES;
    }
    return NO;
}

- (void)downloadInfo:(LFDownloadInfo *)info
{
    NSURL *URL = info.downloadURL;
    NSData *data = [self dataFromSandboxWithURL:URL];
    if (data) {
        if (info.progress) {
            info.progress(data.length, data.length, info.downloadURL);
        }
        if (info.complete) {
            info.complete(data, nil, info.downloadURL);
        }
        info.complete = nil;
        info.progress = nil;
        return;
    }
    
    // 2、利用NSURLSessionDownloadTask创建任务(task)
    NSURLSessionDownloadTask *task = [self.session downloadTaskWithURL:URL];
    // 3、执行任务
    [task resume];
}

+ (void)lf_clearCached {
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *fileNames = [fileManager contentsOfDirectoryAtPath:LFDownloadManagerDirector error:nil];
    for (NSString *fileName in fileNames) {
        if (![fileManager removeItemAtPath:[LFDownloadManagerDirector stringByAppendingPathComponent:fileName] error:nil]) {
            NSLog(@"removeItemAtPath Failed!");
        }
    }
}

#pragma mark - NSURLSessionDownloadDelegate
/*
 1.接收到服务器返回的数据
 bytesWritten: 当前这一次写入的数据大小
 totalBytesWritten: 已经写入到本地文件的总大小
 totalBytesExpectedToWrite : 被下载文件的总大小
 */
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    //给progressView赋值进度
//    self.progressView.progress = 1.0 * totalBytesWritten / totalBytesExpectedToWrite;
    NSURL *URL = downloadTask.currentRequest.URL;
    
    LFDownloadInfo *info = self.downloadDictionary[URL];
    if (info.progress) {
        info.progress(totalBytesWritten, totalBytesExpectedToWrite, info.downloadURL);
    }
}

/*
 2.下载完成
 downloadTask:里面包含请求信息，以及响应信息
 location：下载后自动帮我保存的地址
 */
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location
{
    //location为下载好的文件路径
    //NSLog(@"didFinishDownloadingToURL, %@", location);
    
    NSURL *URL = downloadTask.currentRequest.URL;
    
    LFDownloadInfo *info = self.downloadDictionary[URL];
    //1、生成的Caches地址
    NSString *cacepath = LFDownloadManagerDirectorAppending(info.downloadURL.lastPathComponent);
    //2、移动图片的存储地址
    NSFileManager *manager = [NSFileManager defaultManager];
    [manager moveItemAtURL:location toURL:[NSURL fileURLWithPath:cacepath] error:nil];
    
    [self.downloadDictionary removeObjectForKey:URL];
    
    if (info.complete) {
        info.complete([NSData dataWithContentsOfFile:cacepath], nil, info.downloadURL);
    }
    info.complete = nil;
    info.progress = nil;
}

/*
 3.请求完毕
 如果有错误, 那么error有值
 */
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    if (error) {
        NSURL *URL = task.currentRequest.URL;
        
        LFDownloadInfo *info = self.downloadDictionary[URL];
        if (![self redownloadInfo:info]) {
            [self.downloadDictionary removeObjectForKey:URL];
            if (info.complete) {
                info.complete(nil, error, info.downloadURL);
            }
            info.complete = nil;
            info.progress = nil;
        }
    }
}
@end
