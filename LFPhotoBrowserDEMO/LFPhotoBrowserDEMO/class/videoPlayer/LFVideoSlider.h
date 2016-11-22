//
//  LFVideoSlider.h
//  LFPhotoBrowserDEMO
//
//  Created by LamTsanFeng on 2016/11/21.
//  Copyright © 2016年 GZMiracle. All rights reserved.
//

#import <UIKit/UIKit.h>
@class LFVideoSlider;
@protocol LFVideoSliderDelegate <NSObject>

/** 是否播放 */
- (void)LFVideoSlider:(LFVideoSlider *)videoSlider isPlay:(BOOL)isPlay;
/** 开始滑动 */
- (void)LFVideoSliderBeginChange:(LFVideoSlider *)videoSlider;
/** 滑动中 */
- (void)LFVideoSliderChangedValue:(LFVideoSlider *)videoSlider;
/** 结束滑动 */
- (void)LFVideoSliderEndChange:(LFVideoSlider *)videoSlider;
@end

@interface LFVideoSlider : UIView

@property (nonatomic, readonly) UISlider *slider;

@property (nonatomic, weak) id<LFVideoSliderDelegate> delegate;

- (void)reset;
/** 设置显示时间 */
- (void)setTotalSecond:(double)second;

@end
