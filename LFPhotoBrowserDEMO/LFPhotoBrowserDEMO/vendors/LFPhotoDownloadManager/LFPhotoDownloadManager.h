//
//  LFDownloadManager.h
//  LFPhotoBrowserDEMO
//
//  Created by TsanFeng Lam on 2017/12/11.
//  Copyright © 2017年 GZMiracle. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^lf_photoDownloadProgressBlock)(int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite, NSURL *URL);
typedef void(^lf_photoDownloadCompleteBlock)(NSData * data, NSError *error, NSURL *URL);

@interface LFPhotoDownloadManager : NSObject

+ (LFPhotoDownloadManager *)shareLFDownloadManager;

@property (nonatomic, assign) NSUInteger repeatCountWhenDownloadFailed;

- (void)lf_requestGetURL:(NSURL *)URL completion:(lf_photoDownloadCompleteBlock)completion;

- (void)lf_downloadURL:(NSURL *)URL progress:(lf_photoDownloadProgressBlock)progress completion:(lf_photoDownloadCompleteBlock)completion;
- (void)lf_downloadURL:(NSURL *)URL cacheData:(BOOL)cacheData progress:(lf_photoDownloadProgressBlock)progress completion:(lf_photoDownloadCompleteBlock)completion;

+ (void)lf_clearCached;

@end
