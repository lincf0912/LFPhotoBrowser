//
//  PhotoInfo.m
//  PhotoBrowser
//
//  Created by LamTsanFeng on 2016/9/28.
//  Copyright © 2016年 GZMiracle. All rights reserved.
//

#import "LFPhotoInfo.h"

@implementation LFPhotoInfo

@synthesize placeholderImage = _placeholderImage;

+ (instancetype)photoInfoWithType:(PhotoType)type key:(NSString *)key
{
    return [[self alloc] initWithType:type key:key];
}

- (instancetype)initWithType:(PhotoType)type key:(NSString *)key
{
    self = [self init];
    if (self) {
        _photoType = type;
        _key = key;
    }
    return self;
}

-(UIImage *)placeholderImage
{
    if(_placeholderImage == nil && _photoType == PhotoType_image) {
        /** 图片内置默认占位图 */
        _placeholderImage = [UIImage imageNamed:@"LFPhotoSource.bundle/PhotoDownloadDefault@2x"];
    }
    return _placeholderImage;
}

-(void)setPlaceholderImage:(UIImage *)placeholderImage
{
    _placeholderImage = placeholderImage;
}

@end
