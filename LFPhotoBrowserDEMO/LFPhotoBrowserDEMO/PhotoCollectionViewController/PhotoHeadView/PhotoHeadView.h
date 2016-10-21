//
//  MyHeaderView.h
//  liaotiantupian
//
//  Created by Macx on 15/12/10.
//  Copyright (c) 2015年 Mr.D. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PhotoHeadView : UICollectionReusableView

@property (nonatomic,strong) UILabel *titleLab;


///标题表头
-(void)setTitleLabWithText:(NSString *)text;
@end
