//
//  UIImage+Size.m
//  MiracleMessenger
//
//  Created by LamTsanFeng on 15/3/26.
//  Copyright (c) 2015年 Anson. All rights reserved.
//

#import "UIImage+LFPB_Size.h"

@implementation UIImage (LFPB_Size)

+ (CGSize)imageSizeByFileName:(NSString *)fileName maxWidth:(CGFloat)maxWidth
{
    UIImage *img = nil;
    NSString *imageName = fileName;
    NSRange range = [fileName rangeOfString:@"/"];
    
    //文件名。非url路径
    if (range.location == NSNotFound)
        //读本地bundle表情
        img = [UIImage imageNamed:fileName];
    else{
        img = [UIImage imageWithContentsOfFile:fileName];
        imageName = fileName.lastPathComponent;
    }
    CGSize imageSize = img.size;
    /** 是否开启网络请求 */
    BOOL isNetwork = NO;
    if (img == nil) {
        if (isNetwork) {
            /** 图片不存在，网络请求获取图片大小 提供下载图片的URL */
//            NSURL *imageURL = [[HttpUtility httpURLEncode:imageName] offlineImageUrl:NO];
//            imageSize =  [UIImage downloadImageSizeWithURL:imageURL type:[imageName pathExtension]];
        }
    }
    imageSize = [self imageSizeBySize:imageSize maxWidth:maxWidth];

    if(CGSizeEqualToSize(CGSizeZero, imageSize)){
        /** 手工设置图片大小 */
//        imageSize = CGSizeMake(120, 120);
        /** 设置风景图大小 */

    }
    
    return imageSize;
}

+ (CGSize)imageSizeBySize:(CGSize)size maxWidth:(CGFloat)maxWidth
{
    if (maxWidth == 0) return size;
    CGSize imageSize = size;
    if (imageSize.width > maxWidth) {
        /** 压缩比例 */
        CGSize aSize = imageSize;
        CGFloat width = 0;
        CGFloat height = 0;
        if (aSize.height > aSize.width){
            width = aSize.width/aSize.height * maxWidth;
            height = aSize.height/aSize.width * width;
        }else{
            height = aSize.height/aSize.width * maxWidth;
            width = aSize.width/aSize.height * height;
        }
        imageSize = CGSizeMake(ceilf(width), ceilf(height));
    }
    return imageSize;
}

+ (CGSize)imageSizeBySize:(CGSize)size maxHeight:(CGFloat)maxHeight
{
    if (maxHeight == 0) return size;
    CGSize imageSize = size;
    if (imageSize.height > maxHeight) {
        /** 压缩比例 */
        CGSize aSize = imageSize;
        CGFloat width = 0;
        CGFloat height = 0;
        if (aSize.height > aSize.width){
            width = aSize.width/aSize.height * maxHeight;
            height = aSize.height/aSize.width * width;
        }else{
            height = aSize.height/aSize.width * maxHeight;
            width = aSize.width/aSize.height * height;
        }
        imageSize = CGSizeMake(ceilf(width), ceilf(height));
    }
    return imageSize;
}

+ (CGSize)scaleImageSizeBySize:(CGSize)imageSize targetSize:(CGSize)size isBoth:(BOOL)isBoth {
    
    /** 原图片大小为0 不再往后处理 */
    if (CGSizeEqualToSize(imageSize, CGSizeZero)) {
        return imageSize;
    }
    
    CGFloat width = imageSize.width;
    CGFloat height = imageSize.height;
    CGFloat targetWidth = size.width;
    CGFloat targetHeight = size.height;
    CGFloat scaleFactor = 0.0;
    CGFloat scaledWidth = targetWidth;
    CGFloat scaledHeight = targetHeight;
    CGPoint thumbnailPoint = CGPointMake(0.0, 0.0);
    if(CGSizeEqualToSize(imageSize, size) == NO){
        CGFloat widthFactor = targetWidth / width;
        CGFloat heightFactor = targetHeight / height;
        if (isBoth) {
            if(widthFactor > heightFactor){
                scaleFactor = widthFactor;
            }
            else{
                scaleFactor = heightFactor;
            }
        } else {
            if(widthFactor > heightFactor){
                scaleFactor = heightFactor;
            }
            else{
                scaleFactor = widthFactor;
            }
        }
        scaledWidth = width * scaleFactor;
        scaledHeight = height * scaleFactor;
        if(widthFactor > heightFactor){
            thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5;
        }else if(widthFactor < heightFactor){
            thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5;
        }
    }
    return CGSizeMake(ceilf(scaledWidth), ceilf(scaledHeight));
}

+ (CGSize)downloadImageSizeWithURL:(id)imageURL type:(NSString *)type
{
    NSURL* URL = nil;
    if([imageURL isKindOfClass:[NSURL class]]){
        URL = imageURL;
    }
    if([imageURL isKindOfClass:[NSString class]]){
        URL = [NSURL URLWithString:imageURL];
    }
    if(URL == nil)
        return CGSizeZero;
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:URL];
    
    CGSize size = CGSizeZero;
    if([type isEqualToString:@"png"]){
        size = [self downloadPNGImageSizeWithRequest:request];
    }
    else if([type isEqual:@"gif"])
    {
        size = [self downloadGIFImageSizeWithRequest:request];
    }
    else{
        size = [self downloadJPGImageSizeWithRequest:request];
    }
    if(CGSizeEqualToSize(CGSizeZero, size))
    {
        NSData* data = [NSURLConnection sendSynchronousRequest:[NSURLRequest requestWithURL:URL] returningResponse:nil error:nil];
        UIImage* image = [UIImage imageWithData:data];
        if(image)
        {
            size = image.size;
        }
    }
    return size;
}

+ (CGSize)downloadPNGImageSizeWithRequest:(NSMutableURLRequest*)request
{
    [request setValue:@"bytes=16-23" forHTTPHeaderField:@"Range"];
    NSData* data = [self networkSynchronousRequest:request];
    if(data.length == 8)
    {
        int w1 = 0, w2 = 0, w3 = 0, w4 = 0;
        [data getBytes:&w1 range:NSMakeRange(0, 1)];
        [data getBytes:&w2 range:NSMakeRange(1, 1)];
        [data getBytes:&w3 range:NSMakeRange(2, 1)];
        [data getBytes:&w4 range:NSMakeRange(3, 1)];
        int w = (w1 << 24) + (w2 << 16) + (w3 << 8) + w4;
        int h1 = 0, h2 = 0, h3 = 0, h4 = 0;
        [data getBytes:&h1 range:NSMakeRange(4, 1)];
        [data getBytes:&h2 range:NSMakeRange(5, 1)];
        [data getBytes:&h3 range:NSMakeRange(6, 1)];
        [data getBytes:&h4 range:NSMakeRange(7, 1)];
        int h = (h1 << 24) + (h2 << 16) + (h3 << 8) + h4;
        return CGSizeMake(w, h);
    }
    return CGSizeZero;
}

+ (CGSize)downloadGIFImageSizeWithRequest:(NSMutableURLRequest*)request
{
    [request setValue:@"bytes=6-9" forHTTPHeaderField:@"Range"];
    NSData* data = [self networkSynchronousRequest:request];
    if(data.length == 4)
    {
        short w1 = 0, w2 = 0;
        [data getBytes:&w1 range:NSMakeRange(0, 1)];
        [data getBytes:&w2 range:NSMakeRange(1, 1)];
        short w = w1 + (w2 << 8);
        short h1 = 0, h2 = 0;
        [data getBytes:&h1 range:NSMakeRange(2, 1)];
        [data getBytes:&h2 range:NSMakeRange(3, 1)];
        short h = h1 + (h2 << 8);
        return CGSizeMake(w, h);
    }
    return CGSizeZero;
}

+ (CGSize)downloadJPGImageSizeWithRequest:(NSMutableURLRequest*)request
{
    [request setValue:@"bytes=0-209" forHTTPHeaderField:@"Range"];
    NSData* data = [self networkSynchronousRequest:request];
    
    if ([data length] <= 0x58) {
        return CGSizeZero;
    }
    
    if ([data length] < 210) {// 肯定只有一个DQT字段
        short w1 = 0, w2 = 0;
        [data getBytes:&w1 range:NSMakeRange(0x60, 0x1)];
        [data getBytes:&w2 range:NSMakeRange(0x61, 0x1)];
        short w = (w1 << 8) + w2;
        short h1 = 0, h2 = 0;
        [data getBytes:&h1 range:NSMakeRange(0x5e, 0x1)];
        [data getBytes:&h2 range:NSMakeRange(0x5f, 0x1)];
        short h = (h1 << 8) + h2;
        return CGSizeMake(w, h);
    } else {
        short word = 0x0;
        [data getBytes:&word range:NSMakeRange(0x15, 0x1)];
        if (word == 0xdb) {
            [data getBytes:&word range:NSMakeRange(0x5a, 0x1)];
            if (word == 0xdb) {// 两个DQT字段
                short w1 = 0, w2 = 0;
                [data getBytes:&w1 range:NSMakeRange(0xa5, 0x1)];
                [data getBytes:&w2 range:NSMakeRange(0xa6, 0x1)];
                short w = (w1 << 8) + w2;
                short h1 = 0, h2 = 0;
                [data getBytes:&h1 range:NSMakeRange(0xa3, 0x1)];
                [data getBytes:&h2 range:NSMakeRange(0xa4, 0x1)];
                short h = (h1 << 8) + h2;
                return CGSizeMake(w, h);
            } else {// 一个DQT字段
                short w1 = 0, w2 = 0;
                [data getBytes:&w1 range:NSMakeRange(0x60, 0x1)];
                [data getBytes:&w2 range:NSMakeRange(0x61, 0x1)];
                short w = (w1 << 8) + w2;
                short h1 = 0, h2 = 0;
                [data getBytes:&h1 range:NSMakeRange(0x5e, 0x1)];
                [data getBytes:&h2 range:NSMakeRange(0x5f, 0x1)];
                short h = (h1 << 8) + h2;
                return CGSizeMake(w, h);
            }
        } else {
            return CGSizeZero;
        }
    }
}

#pragma mark - 网络请求返回nsdata
+ (NSData *)networkSynchronousRequest:(NSMutableURLRequest *)request
{
    [request setTimeoutInterval:2.0]; // 设置超时
    NSData* data = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
    
    return data;
}

@end
