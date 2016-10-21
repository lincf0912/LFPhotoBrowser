//
//  MJPhotoProgressView.m
//
//  Created by mj on 13-3-4.
//  Copyright (c) 2013年 itcast. All rights reserved.
//

#import "MLPhotoProgressView.h"

#define kDegreeToRadian(x) (M_PI/180.0 * (x))

@implementation MLPhotoProgressView

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

//- (void)drawRect:(CGRect)rect
//{    
//    CGPoint centerPoint = CGPointMake(rect.size.height / 2, rect.size.width / 2);
//    CGFloat radius = MIN(rect.size.height, rect.size.width) / 2;
//    
//    CGFloat pathWidth = radius * 0.3f;
//    
//    CGFloat radians = kDegreeToRadian((_progress*359.9)-90);
//    CGFloat xOffset = radius*(1 + 0.85*cosf(radians));
//    CGFloat yOffset = radius*(1 + 0.85*sinf(radians));
//    CGPoint endPoint = CGPointMake(xOffset, yOffset);
//    
//    CGContextRef context = UIGraphicsGetCurrentContext();
//    
//    [self.trackTintColor setFill];
//    CGMutablePathRef trackPath = CGPathCreateMutable();
//    CGPathMoveToPoint(trackPath, NULL, centerPoint.x, centerPoint.y);
//    CGPathAddArc(trackPath, NULL, centerPoint.x, centerPoint.y, radius, kDegreeToRadian(270), kDegreeToRadian(-90), NO);
//    CGPathCloseSubpath(trackPath);
//    CGContextAddPath(context, trackPath);
//    CGContextFillPath(context);
//    CGPathRelease(trackPath);
//    
//    [self.progressTintColor setFill];
//    CGMutablePathRef progressPath = CGPathCreateMutable();
//    CGPathMoveToPoint(progressPath, NULL, centerPoint.x, centerPoint.y);
//    CGPathAddArc(progressPath, NULL, centerPoint.x, centerPoint.y, radius, kDegreeToRadian(270), radians, NO);
//    CGPathCloseSubpath(progressPath);
//    CGContextAddPath(context, progressPath);
//    CGContextFillPath(context);
//    CGPathRelease(progressPath);
//    
//    
//    CGContextAddEllipseInRect(context, CGRectMake(centerPoint.x - pathWidth/2, 0, pathWidth, pathWidth));
//    CGContextFillPath(context);
//    
//    CGContextAddEllipseInRect(context, CGRectMake(endPoint.x - pathWidth/2, endPoint.y - pathWidth/2, pathWidth, pathWidth));
//    CGContextFillPath(context);
//    
//    CGContextSetBlendMode(context, kCGBlendModeClear);;
//    CGFloat innerRadius = radius * 0.9;
//	CGPoint newCenterPoint = CGPointMake(centerPoint.x - innerRadius, centerPoint.y - innerRadius);    
//	CGContextAddEllipseInRect(context, CGRectMake(newCenterPoint.x, newCenterPoint.y, innerRadius*2, innerRadius*2));
//	CGContextFillPath(context);
//}

- (void)drawRect:(CGRect)rect
{
    CGRect allRect = self.bounds;
    CGContextRef context = UIGraphicsGetCurrentContext();
    

    CGRect circleRect = CGRectInset(allRect, 2.0f, 2.0f);
    
    CGColorRef colorBackAlpha = CGColorCreateCopyWithAlpha([UIColor colorWithCGColor:CGColorCreateCopyWithAlpha(_progressTintColor.CGColor, 0.1)]. CGColor, 0.1f);
    
    [_progressTintColor setStroke];
    CGContextSetFillColorWithColor(context, colorBackAlpha);
    
    CGContextSetLineWidth(context, 2.0f);
    CGContextFillEllipseInRect(context, circleRect);
    CGContextStrokeEllipseInRect(context, circleRect);
    
    CGPoint center = CGPointMake(allRect.size.width / 2, allRect.size.height / 2);
    CGFloat radius = (allRect.size.width - 4) / 2 - 3;
    CGFloat startAngle = - ((float)M_PI / 2);
    CGFloat endAngle = (self.progress * 2 * (float)M_PI) + startAngle;
    [_progressTintColor setFill];
    CGContextMoveToPoint(context, center.x, center.y);
    CGContextAddArc(context, center.x, center.y, radius, startAngle, endAngle, 0);
    CGContextClosePath(context);
    CGContextFillPath(context);

}

#pragma mark - 绘制Text进度Label


#pragma mark - Property Methods

- (UIColor *)trackTintColor
{
    if (!_trackTintColor)
    {
        _trackTintColor = [UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.7f];
    }
    return _trackTintColor;
}

- (UIColor *)progressTintColor
{
    if (!_progressTintColor)
    {
        _progressTintColor = [UIColor whiteColor];
    }
    return _progressTintColor;
}

- (void)setProgress:(float)progress
{
    _progress = progress;
    [self setNeedsDisplay];
}

@end
