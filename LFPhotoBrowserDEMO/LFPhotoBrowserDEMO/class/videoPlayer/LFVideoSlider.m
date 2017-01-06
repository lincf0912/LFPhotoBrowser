//
//  LFVideoSlider.m
//  LFPhotoBrowserDEMO
//
//  Created by LamTsanFeng on 2016/11/21.
//  Copyright © 2016年 GZMiracle. All rights reserved.
//

#import "LFVideoSlider.h"

#define kMargin 5.f
#define kPlayButtnWH 23.f

#define kSliderH 30.f

#define kTimeLabelFont [UIFont systemFontOfSize:13.f]

static void *LFVideoSliderValueObservationContext = &LFVideoSliderValueObservationContext;

@interface LFVideoSlider () <UIGestureRecognizerDelegate>
{
    BOOL isBeginChange;
    double duration;
    
    BOOL isOnClickPlay;
}

@property (nonatomic, strong) UIButton *play;

/** 总时间 */
@property (nonatomic, strong) UILabel *totalTimeLabel;
/** 播放时间 */
@property (nonatomic, strong) UILabel *playTimeLabel;

@end

@implementation LFVideoSlider

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _play = [UIButton buttonWithType:UIButtonTypeCustom];
        _play.frame = CGRectMake(2*kMargin, (frame.size.height-kPlayButtnWH)/2, kPlayButtnWH, kPlayButtnWH);
        [_play setImage:[UIImage imageNamed:@"LFPhotoSource.bundle/playback_play@2x"] forState:UIControlStateNormal];
        [_play setImage:[UIImage imageNamed:@"LFPhotoSource.bundle/playback_pause@2x"] forState:UIControlStateSelected];
        [_play addTarget:self action:@selector(playOnClick:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_play];
        
        _slider = [[UISlider alloc] initWithFrame:CGRectMake(CGRectGetMaxX(_play.frame)+kMargin, (frame.size.height-kSliderH)/2, CGRectGetWidth(frame) - CGRectGetMaxX(_play.frame) - 3*kMargin, kSliderH)];
        [_slider setThumbImage:[UIImage imageNamed:@"LFPhotoSource.bundle/slider_thumb@2x"] forState:UIControlStateNormal];
        
        [_slider setMinimumTrackTintColor:[UIColor whiteColor]];
        [_slider setMaximumTrackTintColor:[UIColor grayColor]];
        
        [_slider addTarget:self action:@selector(sliderBeginChangedValue:) forControlEvents:UIControlEventTouchDown];
        [_slider addTarget:self action:@selector(sliderChangedValue:) forControlEvents:UIControlEventValueChanged];
        [_slider addTarget:self action:@selector(sliderEndChangedValue:) forControlEvents:UIControlEventTouchUpInside];
        [_slider addTarget:self action:@selector(sliderEndChangedValue:) forControlEvents:UIControlEventTouchUpOutside];
        [self addSubview:_slider];
        
        /** kvo */
        [self.slider addObserver:self forKeyPath:@"value" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:LFVideoSliderValueObservationContext];
        
        
        self.backgroundColor = [UIColor colorWithWhite:0.33f alpha:0.5f];
        self.userInteractionEnabled = YES;
    }
    return self;
}

- (void)dealloc
{
    [self.slider removeObserver:self forKeyPath:@"value"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if (context == LFVideoSliderValueObservationContext)
    {
        [self setPlayLabelText];
    } else
    {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)reset
{
    self.play.selected = NO;
    self.slider.value = 0;
}

- (void)setTotalSecond:(double)second
{
    duration = second;
    
    NSString *text = [self convertTimeDesc:second];
    
    /** 时间 */
    if (_playTimeLabel == nil && _totalTimeLabel == nil) {
        _playTimeLabel = [self createTimeLabel:CGPointMake(CGRectGetMaxX(_play.frame)+kMargin, CGRectGetMinY(_play.frame))];
        [self addSubview:_playTimeLabel];
    
        _totalTimeLabel = [self createTimeLabel:CGPointMake(CGRectGetWidth(self.frame)-[self timeLabelSize:text].width-2*kMargin, CGRectGetMinY(_play.frame))];
        [self addSubview:_totalTimeLabel];
        
        [_slider setFrame:CGRectMake(CGRectGetMaxX(_playTimeLabel.frame)+kMargin, (self.frame.size.height-kSliderH)/2, CGRectGetMinX(_totalTimeLabel.frame) - CGRectGetMaxX(_playTimeLabel.frame) - 2*kMargin, kSliderH)];
    }
    
    self.totalTimeLabel.text = text;
}

- (void)playOnClick:(id)sender
{
    isOnClickPlay = !isOnClickPlay;
    self.play.selected = !self.play.selected;
    if ([self.delegate respondsToSelector:@selector(LFVideoSlider:isPlay:)]) {
        [self.delegate LFVideoSlider:self isPlay:[self.play isSelected]];
    }
}

- (void)sliderChangedValue:(UISlider *)sender
{
    if (isBeginChange) {
        //    NSLog(@"滑动....%f", sender.value);
        if ([self.delegate respondsToSelector:@selector(LFVideoSliderChangedValue:)]) {
            [self.delegate LFVideoSliderChangedValue:self];
        }
        [self setPlayLabelText];
    }
}

- (void)sliderBeginChangedValue:(id)sender
{
//    NSLog(@"开始滑动");
    if ([self.delegate respondsToSelector:@selector(LFVideoSliderBeginChange:)]) {
        [self.delegate LFVideoSliderBeginChange:self];
    }
    isBeginChange = YES;
}

- (void)sliderEndChangedValue:(id)sender
{
//    NSLog(@"结束滑动");
    if ([self.delegate respondsToSelector:@selector(LFVideoSliderEndChange:)]) {
        [self.delegate LFVideoSliderEndChange:self];
    }
    isBeginChange = NO;
}

#pragma mark - 创建时间标签
- (UILabel *)createTimeLabel:(CGPoint)origin
{
    UILabel *label = [[UILabel alloc] init];
    label.textAlignment = NSTextAlignmentCenter;
    NSString *text = @"00:00";
    CGSize labelSize = [self timeLabelSize:text];
    label.font = kTimeLabelFont;
    label.text = text;
    label.textColor = [UIColor colorWithWhite:1.f alpha:0.8];
    label.frame = (CGRect){origin, {labelSize.width, kPlayButtnWH}};
    
    return label;
}

- (CGSize)timeLabelSize:(NSString *)text
{
    UIFont *font = kTimeLabelFont;
    CGSize labelSize = [text sizeWithAttributes:@{NSFontAttributeName:font, NSForegroundColorAttributeName:[UIColor whiteColor]}];
    return CGSizeMake(labelSize.width+1.f, labelSize.height);
}

- (NSString *)convertTimeDesc:(double)second
{
    int min = (int)second / 60;
    int sec = (int)second % 60;
    NSString *text = [NSString stringWithFormat:@"%02d:%02d", min, sec];
    return text;
}

- (void)setPlayLabelText
{
    if (isBeginChange == NO && self.play.selected == NO) { /** 非手动滑动的情况，即开始播放 */
        /** 手动停止播放仍然会触发一会KVO */
        if (isOnClickPlay == NO) {
            self.play.selected = YES;
        }
    }
    if (duration > 0) {
        float minValue = self.slider.minimumValue;
        float maxValue = self.slider.maximumValue;
        float value = self.slider.value;
        
        double second = duration * (value - minValue) / (maxValue - minValue);
        
        NSString *text = [self convertTimeDesc:second];
        
        self.playTimeLabel.text = text;
    }
}
@end
