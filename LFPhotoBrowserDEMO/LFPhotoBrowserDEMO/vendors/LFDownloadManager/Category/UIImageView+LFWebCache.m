//
//  UIImageView+LFWebCache.m
//  LFPhotoBrowserDEMO
//
//  Created by TsanFeng Lam on 2017/12/11.
//  Copyright © 2017年 GZMiracle. All rights reserved.
//

#import "UIImageView+LFWebCache.h"
#import "UIImage+LFPB_Format.h"

#define lf_dispatch_main_async_safe(block)\
if ([NSThread isMainThread]) {\
block();\
} else {\
dispatch_async(dispatch_get_main_queue(), block);\
}

@implementation UIImageView (LFWebCache)

- (void)lf_setImageWithURL:(NSURL *)url
{
    [self lf_setImageWithURL:url placeholderImage:nil options:0 progress:nil completed:nil];
}
- (void)lf_setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(LFWebImageOptions)options
{
    [self lf_setImageWithURL:url placeholderImage:placeholder options:options progress:nil completed:nil];
}
- (void)lf_setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(LFWebImageOptions)options completed:(LFWebImageCompletionBlock)completedBlock
{
    [self lf_setImageWithURL:url placeholderImage:placeholder options:options progress:nil completed:completedBlock];
}
- (void)lf_setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(LFWebImageOptions)options progress:(LFWebImageDownloaderProgressBlock)progressBlock completed:(LFWebImageCompletionBlock)completedBlock
{
    if (!(options & LFWebImageDelayPlaceholder)) {
        lf_dispatch_main_async_safe(^{
            self.image = placeholder;
        });
    }
    
    __weak typeof(self) weakSelf = self;
    [[LFDownloadManager shareLFDownloadManager] lf_downloadURL:url progress:^(int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite, NSURL *URL) {
        lf_dispatch_main_async_safe(^{
            if (progressBlock) {
                progressBlock(totalBytesWritten, totalBytesExpectedToWrite, URL);
            }
        });
    } completion:^(NSData *data, NSError *error, NSURL *URL) {
        
        lf_dispatch_main_async_safe(^{
            if (!weakSelf) return;
            UIImage *image = [UIImage LFPB_imageWithImageData:data];
            if (image && (options & LFWebImageAvoidAutoSetImage) && completedBlock)
            {
                if (completedBlock) {
                    completedBlock(image, data, error, URL);
                }
                return;
            } else if (image) {
                weakSelf.image = image;
                [weakSelf setNeedsLayout];
            } else if ((options & LFWebImageDelayPlaceholder)) {
                weakSelf.image = placeholder;
                [weakSelf setNeedsLayout];
            }
            if (completedBlock) {
                completedBlock(image, data, error, URL);
            }
        });
    }];
}
@end
