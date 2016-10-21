//
//  LLARingSpinnerView.m
//  LLARingSpinnerView
//
//  Created by Lukas Lipka on 05/04/14.
//  Copyright (c) 2014 Lukas Lipka. All rights reserved.
//

#import "LLARingSpinnerView.h"

static NSString *kLLARingSpinnerAnimationKey = @"llaringspinnerview.rotation";

@interface LLARingSpinnerView ()

@property (nonatomic, readonly) CAShapeLayer *progressLayer;
@property (nonatomic, readwrite) BOOL isAnimating;

@property (nonatomic, strong) CAShapeLayer *backgroudLayer;
@property (nonatomic, strong) UILabel *progressLabel; // 进度显示Label
@end

@implementation LLARingSpinnerView

@synthesize progressLayer = _progressLayer;
@synthesize isAnimating = _isAnimating;

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self initialize];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self initialize];
    }
    return self;
}

- (void)initialize {
    [self.layer addSublayer:self.backgroudLayer];
    [self.layer addSublayer:self.progressLayer];
    self.backgroundColor = [UIColor clearColor];
    
    self.progressLabel = [[UILabel alloc] initWithFrame:self.bounds];
    self.progressLabel.textColor = [UIColor whiteColor];
    self.progressLabel.backgroundColor = [UIColor clearColor];
    self.progressLabel.textAlignment = NSTextAlignmentCenter;
    self.progressLabel.font = [UIFont systemFontOfSize:10.0f];
    [self addSubview:_progressLabel];
}

- (void)layoutSubviews {
    [super layoutSubviews];

    self.progressLayer.frame = CGRectMake(0, 0, CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds));
    self.backgroudLayer.frame = CGRectMake(0, 0, CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds));

    [self updatePath];
}

- (void)tintColorDidChange {
    [super tintColorDidChange];

    self.progressLayer.strokeColor = self.tintColor.CGColor;
}

- (void)startAnimating {
    if (self.isAnimating)
        return;

    CABasicAnimation* rotationAnimation;
    rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotationAnimation.toValue = [NSNumber numberWithFloat: M_PI * 2.0 ];
    rotationAnimation.duration = 0.8f;
    rotationAnimation.cumulative = YES;
    rotationAnimation.repeatCount = INFINITY;
    
    [self.progressLayer addAnimation:rotationAnimation forKey:kLLARingSpinnerAnimationKey];
    self.isAnimating = true;
}

- (void)stopAnimating {
    if (!self.isAnimating)
        return;

    [self.progressLayer removeAnimationForKey:kLLARingSpinnerAnimationKey];
    self.isAnimating = false;
}

#pragma mark - Private

- (void)updatePath {
    CGPoint center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    CGFloat radius = MIN(CGRectGetWidth(self.bounds) / 2, CGRectGetHeight(self.bounds) / 2) - self.progressLayer.lineWidth / 2;
    CGFloat startAngle = (CGFloat)(-M_PI_4);
    CGFloat endAngle = (CGFloat)(M_PI_4);
    UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:center radius:radius startAngle:startAngle endAngle:endAngle clockwise:YES];
    self.progressLayer.path = path.CGPath;
    self.progressLayer.lineCap = kCALineCapRound; // 设置线条头圆角
    /** 设置背景*/
    CGFloat bg_startAngle = (CGFloat)(-M_PI);
    CGFloat bg_endAngle = (CGFloat)(M_PI);
    UIBezierPath *bg_path = [UIBezierPath bezierPathWithArcCenter:center radius:radius startAngle:bg_startAngle endAngle:bg_endAngle clockwise:YES];
    self.backgroudLayer.path = bg_path.CGPath;
}

- (void)drawRect:(CGRect)rect
{
    //CGContextRef context = UIGraphicsGetCurrentContext();
    //[self drawTextInContext:context];
    self.progressLabel.text = [NSString stringWithFormat:@"%i%%", (int)(_progress * 100.0f)];
    ;
}

- (void)drawTextInContext:(CGContextRef)context
{
    CGRect allRect = self.bounds;
    
    UIFont *font = [UIFont systemFontOfSize:10.0f];
    NSString *text = [NSString stringWithFormat:@"%i%%", (int)(_progress * 100.0f)];
    
    CGSize textSize = [text boundingRectWithSize:CGSizeMake(30000, 13) options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading|NSStringDrawingUsesDeviceMetrics|NSStringDrawingTruncatesLastVisibleLine attributes:@{NSFontAttributeName:font} context:nil].size;
    
    float x = floorf(allRect.size.width / 2) + 1 ;
    float y = floorf(allRect.size.height / 2) - 6 ;
 //!使用text drawAtPoint的SetFillColor会受backgroudLayer遮挡效果差不建议用
    CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
    [text drawAtPoint:CGPointMake(x - textSize.width / 2.0, y) withAttributes:@{NSFontAttributeName:font}];
}


#pragma mark - Properties
- (CAShapeLayer *)backgroudLayer
{
    if (!_backgroudLayer) {
        _backgroudLayer = [CAShapeLayer layer];
        _backgroudLayer.strokeColor = [[UIColor grayColor] colorWithAlphaComponent:.8f].CGColor;
        _backgroudLayer.fillColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:.3].CGColor;
        _backgroudLayer.lineWidth = 4.5f;
    }
    return _backgroudLayer;
}
- (CAShapeLayer *)progressLayer {
    if (!_progressLayer) {
        _progressLayer = [CAShapeLayer layer];
        _progressLayer.strokeColor = self.tintColor.CGColor;
        _progressLayer.fillColor = nil;
        _progressLayer.lineWidth = 3.5f;
    }
    return _progressLayer;
}

- (BOOL)isAnimating {
    return _isAnimating;
}

- (CGFloat)lineWidth {
    return self.progressLayer.lineWidth;
}

- (void)setLineWidth:(CGFloat)lineWidth {
    self.progressLayer.lineWidth = lineWidth;
    self.backgroudLayer.lineWidth = lineWidth;
    [self updatePath];
}

- (void)setProgress:(float)progress
{
    _progress = progress;
    /** 设置进度显示*/   
    [self setNeedsDisplay];
}
@end
