//
//  UIActionSheet+Block.m
//  MEMobile
//
//  Created by LamTsanFeng on 15/7/1.
//  Copyright (c) 2015年 GZMiracle. All rights reserved.
//

#import "UIActionSheet+LFPB_Block.h"
#import <objc/runtime.h>

static char overActionSheetKey;

@implementation UIActionSheet (LFPB_Block)

- (id)initWithTitle:(NSString *)title cancelButtonTitle:(NSString *)cancelButtonTitle destructiveButtonTitle:(NSString *)destructiveButtonTitle otherButtonTitles:(NSString *)otherButtonTitles block:(UIActionSheetBlock)block
{
    objc_setAssociatedObject(self, &overActionSheetKey, block, OBJC_ASSOCIATION_COPY_NONATOMIC);
    NSArray *buttonTitles = [otherButtonTitles componentsSeparatedByString:kSeparator];
    NSInteger count = buttonTitles.count;
    if (count) {
        NSString *buttonTitle1 = buttonTitles[0]; count--;
        NSString *buttonTitle2 = count > 0 ? buttonTitles[1] : nil; count--;
        NSString *buttonTitle3 = count > 0 ? buttonTitles[2] : nil; count--;
        NSString *buttonTitle4 = count > 0 ? buttonTitles[3] : nil; count--;
        NSString *buttonTitle5 = count > 0 ? buttonTitles[4] : nil; count--;
        return [self initWithTitle:title delegate:self cancelButtonTitle:cancelButtonTitle destructiveButtonTitle:destructiveButtonTitle otherButtonTitles:buttonTitle1, buttonTitle2, buttonTitle3, buttonTitle4, buttonTitle5, nil];
    } else {
        return [self initWithTitle:title delegate:self cancelButtonTitle:cancelButtonTitle destructiveButtonTitle:destructiveButtonTitle otherButtonTitles:otherButtonTitles, nil];
    }
}

//#pragma mark - UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    //这里调用函数指针_block(要传进来的参数);
    UIActionSheetBlock block = (UIActionSheetBlock)objc_getAssociatedObject(self, &overActionSheetKey);
    if (block) {
        block(buttonIndex);
        objc_setAssociatedObject(self, &overActionSheetKey, nil, OBJC_ASSOCIATION_COPY_NONATOMIC);
    }
}

@end
