//
//  LFActionSheet.h
//  LFActionSheetDemo
//
//  Created by LamTsanFeng on 2017/4/27.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^LFActionSheetBlock)(NSInteger buttonIndex);

@interface LFActionSheet : UIView

/** 初始化 */
- (instancetype)initWithTitle:(NSString *)title cancelButtonTitle:(NSString *)cancelButtonTitle destructiveButtonTitle:(NSString *)destructiveButtonTitle otherButtonTitles:(NSArray <NSString *>*)otherButtonTitles didSelectBlock:(LFActionSheetBlock)didSelectBlock;

/** 显示在最顶层 */
- (void)show;
/** 显示某个view上（待续） */
//- (void)showInView:(UIView *)view;

@end
