//
//  VideoView.m
//  VideoPlayDemo
//
//  Created by LamTsanFeng on 2016/11/17.
//  Copyright © 2016年 GZMiracle. All rights reserved.
//

#import "LFAVPlayerLayerView.h"

@implementation LFAVPlayerLayerView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

+ (Class)layerClass
{
    return [AVPlayerLayer class];
}

- (void)setPlayer:(AVPlayer*)player
{
    [(AVPlayerLayer*)[self layer] setPlayer:player];
    [(AVPlayerLayer*)[self layer] setVideoGravity:AVLayerVideoGravityResizeAspect];
}

- (AVPlayer *)player
{
    return [(AVPlayerLayer*)[self layer] player];
}

@end
