//
//  UIActionSheet+Block.h
//  MEMobile
//
//  Created by LamTsanFeng on 15/7/1.
//  Copyright (c) 2015年 GZMiracle. All rights reserved.
//

#import <UIKit/UIKit.h>

/** 分隔符 */
#define kSeparator @"｜"
/** 设置分隔符 kSeparatorWithStr(@"1,2,3") */
#define kSeparatorWithStr(str) [str stringByReplacingOccurrencesOfString:@"," withString:kSeparator]

typedef void (^UIActionSheetBlock)(NSInteger buttonIndex);

@interface UIActionSheet (LFPB_Block) <UIActionSheetDelegate>

- (id)initWithTitle:(NSString *)title cancelButtonTitle:(NSString *)cancelButtonTitle destructiveButtonTitle:(NSString *)destructiveButtonTitle otherButtonTitles:(NSString *)otherButtonTitles block:(UIActionSheetBlock)block;

@end
