//
//  UIView+LFFindTopView.m
//  LFActionSheetDemo
//
//  Created by LamTsanFeng on 2017/4/27.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import "UIView+LFFindTopView.h"

@implementation UIView (LFFindTopView)

#pragma mark - 查找键盘的父视图
+ (UIView *)lf_findKeyboardView
{
    UIView *keyboardView = nil;
    NSArray *windows = [[UIApplication sharedApplication] windows];
    for(UIWindow *window in [windows reverseObjectEnumerator]){
        keyboardView = [self findKeyboardInView:window];
        if(keyboardView)
        {
            return keyboardView;
        }
    }
    return nil;
}

+ (UIView *)findKeyboardInView:(UIView *)view
{
    for(UIView *subView in [view subviews]){
        if(strstr(object_getClassName(subView), "UIInputSetContainerView"))
        {
            for (UIView *possibleKeyboard in [subView subviews]) {
                if (strstr(object_getClassName(possibleKeyboard), "UIInputSetHostView"))
                {
                    /** possibleKeyboard的高度有可能为0，需要跳过 */
                    if (possibleKeyboard.frame.size.height > 0) {
                        /** 返回上级superView */
                        return subView;
                    }
                }
            }
        }else{
            UIView *tempView = [self findKeyboardInView:subView];
            if(tempView){
                return tempView;
            }
        }
    }
    return nil;
}

- (UIViewController*)viewController {
    for (UIView* next = [self superview]; next; next = next.superview) {
        UIResponder* nextResponder = [next nextResponder];
        if ([nextResponder isKindOfClass:[UIViewController class]]) {
            return (UIViewController*)nextResponder;
        }
    }
    return nil;
}

@end
