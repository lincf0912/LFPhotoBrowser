//
//  UIView+LFFindTopView.h
//  LFActionSheetDemo
//
//  Created by LamTsanFeng on 2017/4/27.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (LFFindTopView)

/** 查找键盘的父视图 */
+ (UIView *)lf_findKeyboardView;
@end
