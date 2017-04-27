//
//  NSString+LFActionSheetAttributed.m
//  LFActionSheetDemo
//
//  Created by LamTsanFeng on 2017/4/27.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import "NSString+LFActionSheetAttributed.h"

@implementation NSString (LFActionSheetAttributed)

- (NSAttributedString *)lf_actionSheetAttributedStringWithFontSize:(CGFloat)fontSize
                                                             color:(UIColor *)color
{
    return [self lf_actionSheetAttributedStringWithFontSize:fontSize
                                                      color:color
                                                  alignment:NSTextAlignmentLeft
                                              lineBreakMode:NSLineBreakByWordWrapping];
}
- (NSAttributedString *)lf_actionSheetAttributedStringWithFontSize:(CGFloat)fontSize
                                                             color:(UIColor *)color
                                                         alignment:(NSTextAlignment)alignment
                                                     lineBreakMode:(NSLineBreakMode)lineBreakMode
{
    if (self.length == 0) return [[NSAttributedString alloc] initWithString:@""];
    //初始化文字
    NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] initWithString:self];
    //设置字体
    UIFont *baseFont = [UIFont systemFontOfSize:fontSize];
    [attrString addAttribute:NSFontAttributeName value:baseFont range:NSMakeRange(0, [self length])];//设置所有的字体
    //设置颜色
    [attrString addAttribute:NSForegroundColorAttributeName value:color range:NSMakeRange(0, [self length])];
    //设置行宽、间距等属性
    NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    style.alignment = alignment;//对齐方式
    style.lineBreakMode = lineBreakMode;//显示方式过长...
    style.firstLineHeadIndent = 5;//首行头缩进
    style.lineSpacing = 3.0f;//行距
    [attrString addAttribute:NSParagraphStyleAttributeName value:style range:NSMakeRange(0, [self length])];
    
    return attrString;
}

@end
