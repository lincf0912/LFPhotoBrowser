//
//  LFActionSheetCell.h
//  LFActionSheetDemo
//
//  Created by LamTsanFeng on 2017/4/27.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LFActionSheetCell : UITableViewCell

+(NSString *)identifier;
/** 文本 */
@property (nonatomic, copy) NSString *text;
/** 富文本 */
@property (nonatomic, copy) NSAttributedString *attributedText;


@end
