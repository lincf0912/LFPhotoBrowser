//
//  LFPlayer.h
//  VideoPlayDemo
//
//  Created by LamTsanFeng on 2016/11/17.
//  Copyright © 2016年 GZMiracle. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@class LFPlayer;

@protocol LFPlayerDelegate <NSObject>

/** 画面回调 */
- (void)LFPlayerLayerDisplay:(LFPlayer *)player avplayer:(AVPlayer *)avplayer;
/** 可以播放 */
- (void)LFPlayerReadyToPlay:(LFPlayer *)player duration:(double)duration;
@optional
/** 播放结束 */
- (void)LFPlayerPlayDidReachEnd:(LFPlayer *)player;
/** 进度回调 */
- (UISlider *)LFPlayerSyncScrub:(LFPlayer *)player;
/** 错误回调 */
- (void)LFPlayerFailedToPrepare:(LFPlayer *)player error:(NSError *)error;

@end

@interface LFPlayer : NSObject
{
    NSURL* mURL;
    
    float mRestoreAfterScrubbingRate;
    BOOL seekToZeroBeforePlay;
    id mTimeObserver;
    BOOL isSeeking;
}
/** 视频URL */
@property (nonatomic, copy) NSURL* URL;
/** 代理 */
@property (nonatomic, weak) id<LFPlayerDelegate> delegate;
/** 视频大小 */
@property (nonatomic, readonly) CGSize size;

/** 视频控制 */
- (void)play;
- (void)pause;
- (BOOL)isPlaying;
/** 重置画面 */
- (void)resetDisplay;
/** 进度处理 */

/** 拖动开始调用 */
- (void)beginScrubbing;
/** 拖动进度改变入参 */
- (void)scrub:(UISlider *)slider;
/** 拖动结束调用 */
- (void)endScrubbing;
@end
