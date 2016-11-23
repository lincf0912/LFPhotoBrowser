//
//  VideoProgressView.m
//  LFPhotoBrowserDEMO
//
//  Created by LamTsanFeng on 2016/11/21.
//  Copyright © 2016年 GZMiracle. All rights reserved.
//

#import "VideoProgressView.h"

@interface VideoProgressView ()

/** 大小 */
@property (nonatomic, assign) CGRect circlesSize;
/** 后圆环 */
@property (nonatomic, strong) CAShapeLayer *backCircle;
/** 前圆环 */
@property (nonatomic, strong) CAShapeLayer *foreCircle;

@property (nonatomic, strong) UIButton *playButton;
@property (nonatomic, strong) UILabel *tipsLabel;

@end

@implementation VideoProgressView

- (id)init
{
    return [self initWithFrame:CGRectMake(0.f, 0.f, 37.f, 37.f)];
}

-(id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if(self){
        self.backgroundColor = [UIColor clearColor];
        self.circlesSize = CGRectMake(20, 1, 18, 18);
        [self createView];
        [self resetProgressView];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    if (self.backCircle) {
        BOOL animated = [self.backCircle animationForKey:@"rotationAnimation"];
        [self.backCircle removeFromSuperlayer];
        [self addBackCircleWithSize:self.circlesSize.origin.x lineWidth:self.circlesSize.origin.y];
        if (animated) {
            [self startAnimation];
        }
    }
    if (self.foreCircle) {
        [self.foreCircle removeFromSuperlayer];
        [self addForeCircleWidthSize:self.circlesSize.size.width lineWidth:self.circlesSize.size.height];
        if (_progress > 0) {
            self.foreCircle.strokeEnd = _progress;
        }
    }
    
    self.tipsLabel.center = self.playButton.center = CGPointMake(self.center.x-self.frame.origin.x, self.center.y-self.frame.origin.y);
    CGRect lableFrame = self.tipsLabel.frame;
    lableFrame.origin.y += CGRectGetHeight(self.playButton.frame)/2 + CGRectGetHeight(lableFrame)/2 + 10.f;
    self.tipsLabel.frame = lableFrame;
}

-(void)createView
{
    if (self.playButton == nil) {
        self.playButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.playButton.frame = CGRectMake(0, 0, 45, 45);
        [self.playButton setImage:[UIImage imageNamed:@"LFPhotoSource.bundle/play"] forState:UIControlStateNormal];
        [self.playButton addTarget:self action:@selector(onClick:) forControlEvents:UIControlEventTouchUpInside];
        self.playButton.hidden = YES;
        [self addSubview:self.playButton];
    }
    if (self.tipsLabel == nil) {
        self.tipsLabel = [[UILabel alloc] init];
        self.tipsLabel.frame = CGRectMake(0, 0, 300, 20);
        self.tipsLabel.text = @"轻触载入";
        self.tipsLabel.textColor = [UIColor whiteColor];
        self.tipsLabel.textAlignment = NSTextAlignmentCenter;
        self.tipsLabel.hidden = YES;
        self.tipsLabel.font = [UIFont systemFontOfSize:14.f];
        [self addSubview:self.tipsLabel];
    }
}

#pragma mark - 后圆环
-(void)addBackCircleWithSize:(CGFloat)radius lineWidth:(CGFloat)lineWidth
{
    CGRect foreCircle_frame = CGRectMake(self.bounds.size.width/2-radius,
                                         self.bounds.size.height/2-radius,
                                         radius*2,
                                         radius*2);
    
    CAShapeLayer *layer = [CAShapeLayer layer];
    layer.frame = foreCircle_frame;
    UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:CGPointMake(radius, radius)
                                                        radius:radius-lineWidth/2
                                                    startAngle:0
                                                      endAngle:M_PI*2
                                                     clockwise:YES];
    layer.path = path.CGPath;
    layer.fillColor = [UIColor clearColor].CGColor;
    layer.backgroundColor = [UIColor clearColor].CGColor;
    layer.strokeColor = [UIColor whiteColor].CGColor;
    layer.lineWidth = lineWidth;
    layer.lineCap = @"round";
    layer.strokeStart = 0;
    layer.strokeEnd = 1;
    self.backCircle = layer;
    [self.layer addSublayer:self.backCircle];
    [self stopAnimation];
}

#pragma mark - 前圆环
-(void)addForeCircleWidthSize:(CGFloat)radius lineWidth:(CGFloat)lineWidth
{
    CGRect foreCircle_frame = CGRectMake(self.bounds.size.width/2-radius,
                                         self.bounds.size.height/2-radius,
                                         radius*2,
                                         radius*2);
    
    CAShapeLayer *layer = [CAShapeLayer layer];
    layer.frame = foreCircle_frame;
    UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:CGPointMake(radius, radius)
                                                        radius:radius-lineWidth/2
                                                    startAngle:-M_PI/2
                                                      endAngle:M_PI/180*270
                                                     clockwise:YES];
    layer.path = path.CGPath;
    layer.fillColor = [UIColor clearColor].CGColor;
    layer.backgroundColor = [UIColor clearColor].CGColor;
    layer.strokeColor = [UIColor whiteColor].CGColor;
    layer.lineWidth = lineWidth;
    layer.lineCap = @"buff";
    layer.strokeStart = 0;
    layer.strokeEnd = 0;
    self.foreCircle = layer;
    [self.layer addSublayer:self.foreCircle];
}

-(void)setProgress:(float)progress
{
    _progress = progress;
    
    self.playButton.hidden = self.tipsLabel.hidden = YES;
    
    if (self.backCircle == nil) {
        [self addBackCircleWithSize:self.circlesSize.origin.x lineWidth:self.circlesSize.origin.y];
    }
    if (self.foreCircle == nil) {
        [self addForeCircleWidthSize:self.circlesSize.size.width lineWidth:self.circlesSize.size.height];
    }
    
    if (progress >= 0) {
        self.foreCircle.strokeEnd = progress;
    }
    if (self.foreCircle.strokeEnd > 0.99)
    {
        [self startAnimation];
        [self.foreCircle removeFromSuperlayer];
        self.foreCircle = nil;
    } else if(self.foreCircle.strokeEnd > 0)
    {
        [self stopAnimation];
    } else {
        [self startAnimation];
    }
}
-(void)drawBackCircle:(BOOL)partial
{
    CGFloat startAngle = -((float)M_PI/2);
    CGFloat endAngle = (2 *(float)M_PI) + startAngle;
    CGFloat radius = self.circlesSize.origin.x;
    CGFloat lineWidth = self.circlesSize.origin.y;
    UIBezierPath *processBackgroundPath = [UIBezierPath bezierPath];
    processBackgroundPath.lineWidth = lineWidth;
    if(partial){
        endAngle = (1.8f * (float)M_PI) + startAngle;
    }
    [processBackgroundPath addArcWithCenter:CGPointMake(radius, radius) radius:radius-lineWidth/2 startAngle:startAngle endAngle:endAngle clockwise:YES];
    self.backCircle.path = processBackgroundPath.CGPath;
}

#pragma mark - 开启旋转
-(void)startAnimation
{
    if ([self.backCircle animationForKey:@"rotationAnimation"]) {
        return ;
    }
    self.playButton.hidden = self.tipsLabel.hidden = YES;
    [self drawBackCircle:YES];
    CABasicAnimation *rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotationAnimation.toValue = [NSNumber numberWithFloat:M_PI * 2.0];
    rotationAnimation.duration = 1;
    rotationAnimation.cumulative = YES;
    rotationAnimation.repeatCount = HUGE_VALF;
    [self.backCircle addAnimation:rotationAnimation forKey:@"rotationAnimation"];
}

#pragma mark - 停止旋转
-(void)stopAnimation
{
    [self drawBackCircle:NO];
    [self.backCircle removeAllAnimations];
}

#pragma mark - 重置progressView
-(void)resetProgressView
{
    [self.backCircle removeFromSuperlayer];
    [self.foreCircle removeFromSuperlayer];
    self.backCircle = nil;
    self.foreCircle = nil;
    _progress = 0;
    self.playButton.hidden = NO;
    self.tipsLabel.hidden = NO;
}

- (void)onClick:(id)sender
{
    self.progress = 0;
    if (self.clickBlock) {
        self.clickBlock();
    }
}

- (void)showLoading
{
    [self resetProgressView];
    
}
- (void)showFailure
{
    [self resetProgressView];
    [self.playButton setImage:[UIImage imageNamed:@"LFPhotoSource.bundle/not_play"] forState:UIControlStateNormal];
    self.tipsLabel.hidden = YES;
}
@end
