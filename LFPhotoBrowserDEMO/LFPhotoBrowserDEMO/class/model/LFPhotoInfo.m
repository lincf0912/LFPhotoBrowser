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
    if(_placeholderImage == nil){
#warning 设置内置默认图片
//        _placeholderImage = [UIImage imageNamed:@"默认图片"];
    }
    return _placeholderImage;
}

-(void)setPlaceholderImage:(UIImage *)placeholderImage
{
    _placeholderImage = placeholderImage;
}

@end
