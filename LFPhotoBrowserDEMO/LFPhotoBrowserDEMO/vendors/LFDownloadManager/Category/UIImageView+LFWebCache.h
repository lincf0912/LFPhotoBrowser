//
//  UIImageView+LFWebCache.h
//  LFPhotoBrowserDEMO
//
//  Created by TsanFeng Lam on 2017/12/11.
//  Copyright © 2017年 GZMiracle. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LFDownloadManager.h"

typedef void(^LFWebImageDownloaderProgressBlock)(NSInteger receivedSize, NSInteger expectedSize, NSURL *imageURL);
typedef void(^LFWebImageCompletionBlock)(UIImage *image, NSError *error, NSURL *imageURL);

typedef NS_OPTIONS(NSUInteger, LFWebImageOptions) {
    
    /**
     * By default, placeholder images are loaded while the image is loading. This flag will delay the loading
     * of the placeholder image until after the image has finished loading.
     */
    LFWebImageDelayPlaceholder = 1 << 9,
    
    /**
     * By default, image is added to the imageView after download. But in some cases, we want to
     * have the hand before setting the image (apply a filter or add it with cross-fade animation for instance)
     * Use this flag if you want to manually set the image in the completion when success
     */
    LFWebImageAvoidAutoSetImage = 1 << 11
};

@interface UIImageView (LFWebCache)

- (void)lf_setImageWithURL:(NSURL *)url;
- (void)lf_setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(LFWebImageOptions)options;
- (void)lf_setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(LFWebImageOptions)options completed:(LFWebImageCompletionBlock)completedBlock;
- (void)lf_setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(LFWebImageOptions)options progress:(LFWebImageDownloaderProgressBlock)progressBlock completed:(LFWebImageCompletionBlock)completedBlock;

@end
