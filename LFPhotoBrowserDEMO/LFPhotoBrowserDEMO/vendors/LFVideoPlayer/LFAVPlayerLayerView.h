//
//  VideoView.h
//  VideoPlayDemo
//
//  Created by LamTsanFeng on 2016/11/17.
//  Copyright © 2016年 GZMiracle. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface LFAVPlayerLayerView : UIImageView

@property (nonatomic, readonly) AVPlayer *player;

- (void)setPlayer:(AVPlayer*)player;

@end
