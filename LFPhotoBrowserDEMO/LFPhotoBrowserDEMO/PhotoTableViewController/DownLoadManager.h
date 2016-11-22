//
//  DownLoadManager.h
//  LFPhotoBrowserDEMO
//
//  Created by LamTsanFeng on 2016/11/22.
//  Copyright © 2016年 GZMiracle. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^SuccessBlock)();
typedef void(^FailureBlock)(NSError *error);
typedef void(^DownloadBlock)(long long totalBytes,long long totalBytesExpected);

@interface DownLoadManager : NSObject

+ (void)basicHttpFileDownloadWithUrlString:(NSString*)aUrlString
                                    offset:(u_int64_t)offset
                                    params:(NSDictionary*)aParams
                                   timeout:(NSTimeInterval)timeout
                                  savePath:(NSString*)aSavePath
                                  download:(DownloadBlock)aDownload
                                   success:(SuccessBlock)aSuccess
                                   failure:(FailureBlock)aFailure;

@end
