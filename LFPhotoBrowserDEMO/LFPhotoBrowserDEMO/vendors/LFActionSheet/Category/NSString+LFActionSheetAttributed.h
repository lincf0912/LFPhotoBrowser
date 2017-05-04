//
//  NSString+LFActionSheetAttributed.h
//  LFActionSheetDemo
//
//  Created by LamTsanFeng on 2017/4/27.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NSString (LFActionSheetAttributed)
/** 自定义文字 */
- (NSAttributedString *)lf_actionSheetAttributedStringWithFontSize:(CGFloat)fontSize
                                                             color:(UIColor *)color;

- (NSAttributedString *)lf_actionSheetAttributedStringWithFontSize:(CGFloat)fontSize
                                                             color:(UIColor *)color
                                                         alignment:(NSTextAlignment)alignment
                                                     lineBreakMode:(NSLineBreakMode)lineBreakMode;
@end
