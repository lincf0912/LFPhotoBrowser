//
//  LFScrollView.m
//  LFPhotoBrowserDEMO
//
//  Created by LamTsanFeng on 2016/11/22.
//  Copyright © 2016年 GZMiracle. All rights reserved.
//

#import "LFPhotoScrollView.h"

@interface LFPhotoScrollView ()

@end

@implementation LFPhotoScrollView

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.delaysContentTouches = NO;
        //        self.canCancelContentTouches = NO;
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.delaysContentTouches = NO;
    }
    return self;
}

- (BOOL)touchesShouldBegin:(NSSet *)touches withEvent:(UIEvent *)event inContentView:(UIView *)view {
    if ([view isKindOfClass:[UISlider class]]) {
        UITouch *touch = [[event allTouches] anyObject];
        CGPoint location = [touch locationInView:view];
        CGRect thumbRect;
        UISlider *mySlide = (UISlider*) view;
        CGRect trackRect = [mySlide trackRectForBounds:mySlide.bounds];
        thumbRect = [mySlide thumbRectForBounds:mySlide.bounds trackRect:trackRect value:mySlide.value];
        if (CGRectContainsPoint(thumbRect, location)) {
            return YES;
        } else {
            return NO;
        }
    }
    return YES;
}

@end
