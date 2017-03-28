//
//  UIViewController+extend.m
//  MEMobile
//
//  Created by LamTsanFeng on 2016/10/20.
//  Copyright © 2016年 GZMiracle. All rights reserved.
//

#import "UIViewController+LFPB_Extension.h"

@implementation UIViewController (LFPB_Extension)

#pragma mark - 获取当前屏幕显示的ViewController
+ (UIViewController *)getCurrentVC
{
    UIViewController *result = nil;
    UIWindow * window = [[UIApplication sharedApplication] keyWindow];
    if (window.windowLevel != UIWindowLevelNormal)
    {
        NSArray *windows = [[UIApplication sharedApplication] windows];
        for(UIWindow * tempWindow in windows)
        {
            if (tempWindow.windowLevel == UIWindowLevelNormal)
            {
                window = tempWindow;
                break;
            }
        }
    }
    UIView *frontView = [[window subviews] objectAtIndex:0];
    id nextResponder = [frontView nextResponder];
    if ([nextResponder isKindOfClass:[UIViewController class]])
        result = nextResponder;
    else
        result = window.rootViewController;
    
    if ([result isKindOfClass:[UINavigationController class]]) {
        return [((UINavigationController *)result) visibleViewController];
    }
    return result;
}

@end
