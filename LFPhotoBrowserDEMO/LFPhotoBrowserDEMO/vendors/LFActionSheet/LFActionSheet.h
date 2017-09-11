//
//  LFActionSheet.h
//  LFActionSheetDemo
//
//  Created by LamTsanFeng on 2017/4/27.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@class LFActionSheet;

typedef void (^LFActionSheetBlock)(LFActionSheet *actionSheet, NSInteger buttonIndex);

@interface LFActionSheet : UIView

/** 初始化 */
- (instancetype)initWithTitle:(nullable NSString *)title cancelButtonTitle:(nullable NSString *)cancelButtonTitle destructiveButtonTitle:(nullable NSString *)destructiveButtonTitle otherButtonTitles:(nullable NSArray <NSString *>*)otherButtonTitles didSelectBlock:(LFActionSheetBlock)didSelectBlock;


- (NSInteger)indexButtonWithTitle:(nullable NSString *)title;    // returns index of button. 0 based.
- (nullable NSString *)buttonTitleAtIndex:(NSInteger)buttonIndex;
@property(nonatomic,readonly) NSInteger numberOfButtons;
@property(nonatomic,readonly) NSInteger cancelButtonIndex;      // if the delegate does not implement -actionSheetCancel:, we pretend this button was clicked on. default is -1
@property(nonatomic) NSInteger destructiveButtonIndex;        // sets destructive (red) button. -1 means none set. default is -1. ignored if only one button

@property(nonatomic,readonly) NSInteger firstOtherButtonIndex;	// -1 if no otherButtonTitles or initWithTitle:... not used

/** 显示在最顶层 */
- (void)show;
/** 显示某个view上 */
- (void)showInView:(UIView *)view;

#pragma mark - extend
@property(nonatomic, assign) NSInteger markButtonIndex; // The mark button will display tick off on the right， default -1 no mark


@end

NS_ASSUME_NONNULL_END
