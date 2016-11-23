//
//  DownLoadManager.m
//  LFPhotoBrowserDEMO
//
//  Created by LamTsanFeng on 2016/11/22.
//  Copyright © 2016年 GZMiracle. All rights reserved.
//

#import "DownLoadManager.h"
#import "AFNetworking.h"

#define kFileListTempExtension @".tmp"

/** 单例 */
const NSMutableDictionary * downloadDicts;

@implementation DownLoadManager


+ (NSString *)getDLTempPathWithSavePath:(NSString *)path
{
    NSString *tempPath = [path stringByAppendingString:kFileListTempExtension];
    return tempPath;
}

+ (BOOL)isExistsDL:(NSString *)url
{
    return [downloadDicts objectForKey:url];
}

+ (void)cancelDL:(NSString *)url
{
    AFHTTPRequestOperation *operation = [downloadDicts objectForKey:url];
    [operation cancel];
}

+ (void)cancelAllDL
{
    for (NSString *key in downloadDicts) {
        [self cancelDL:key];
    }
}

+ (void)basicHttpFileDownloadWithUrlString:(NSString*)aUrlString
                                    offset:(u_int64_t)offset
                                    params:(NSDictionary*)aParams
                                   timeout:(NSTimeInterval)timeout
                                  savePath:(NSString*)aSavePath
                                  download:(DownloadBlock)aDownload
                                   success:(SuccessBlock)aSuccess
                                   failure:(FailureBlock)aFailure
{
    
    if (downloadDicts == nil) {
        downloadDicts = [@{} mutableCopy];
    }
    
    if ([self isExistsDL:aUrlString]) return;
    
    NSString *tempPath = [aSavePath stringByAppendingString:kFileListTempExtension]; // 临时保存路径
    
    NSMutableURLRequest *request = [[AFHTTPRequestSerializer serializer] requestWithMethod:@"GET" URLString:aUrlString parameters:aParams error:nil];
    request.timeoutInterval = (timeout <= 0 ? 15.f : timeout);
    [request setValue:@"gzip, deflate" forHTTPHeaderField:@"Accept-Encoding"];
    [request setCachePolicy:NSURLRequestReloadIgnoringCacheData]; // 忽略本地缓存重新下载
    if (offset>0) {
        NSMutableURLRequest *mutableURLRequest = [request mutableCopy];
        [mutableURLRequest setValue:[NSString stringWithFormat:@"bytes=%llu-", offset] forHTTPHeaderField:@"Range"];
        request = mutableURLRequest;
    }
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc]initWithRequest:request];
    operation.securityPolicy.allowInvalidCertificates = YES;
    operation.securityPolicy.validatesDomainName = NO;
    operation.outputStream = [NSOutputStream outputStreamToFileAtPath:tempPath append:(offset > 0)];
    
    //下载中
    [operation setDownloadProgressBlock:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
        if (aDownload) {
            aDownload(totalBytesRead + offset, totalBytesExpectedToRead + offset);
        }
    }];
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject){
        
        [downloadDicts removeObjectForKey:aUrlString];
        NSError *err;
        NSFileManager *fileManager = [NSFileManager new];
        [fileManager moveItemAtPath:tempPath toPath:aSavePath error:&err];
        
        NSError *error = nil;
        if (error && aFailure)
            aFailure(error);
        else if (aSuccess)
            aSuccess();
        
        
    }failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        [downloadDicts removeObjectForKey:aUrlString];
        if (![[operation.userInfo objectForKey:@"error"] isEqualToString:@"cancelError"]) {
            if (aFailure)aFailure(error);
        } else {
            /** 暂停 即手动取消 */
            if (aFailure)aFailure(nil);
        }
        
        
    }];
    
    [downloadDicts setObject:operation forKey:aUrlString];
    
    [operation start];
}

@end
