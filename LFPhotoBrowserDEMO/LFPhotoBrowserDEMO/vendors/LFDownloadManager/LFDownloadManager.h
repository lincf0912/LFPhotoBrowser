//
//  LFDownloadManager.h
//  LFPhotoBrowserDEMO
//
//  Created by TsanFeng Lam on 2017/12/11.
//  Copyright © 2017年 GZMiracle. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^lf_progressBlock)(int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite, NSURL *URL);
typedef void(^lf_completeBlock)(NSData * data, NSError *error, NSURL *URL);

@interface LFDownloadManager : NSObject

+ (LFDownloadManager *)shareLFDownloadManager;

@property (nonatomic, assign) NSUInteger repeatCountWhenDownloadFailed;

- (void)lf_requestGetURL:(NSURL *)URL completion:(lf_completeBlock)completion;

- (void)lf_downloadURL:(NSURL *)URL progress:(lf_progressBlock)progress completion:(lf_completeBlock)completion;
- (void)lf_downloadURL:(NSURL *)URL cacheData:(BOOL)cacheData progress:(lf_progressBlock)progress completion:(lf_completeBlock)completion;

+ (void)lf_clearCached;

@end
