//
//  MyHeaderView.m
//  liaotiantupian
//
//  Created by Macx on 15/12/10.
//  Copyright (c) 2015年 Mr.D. All rights reserved.
//

#import "PhotoHeadView.h"

#define TextColor [UIColor whiteColor]


@implementation PhotoHeadView

#pragma mark - init

-(instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        self.titleLab = [[UILabel alloc] init];
        self.titleLab.textColor = TextColor;
        self.titleLab.backgroundColor = [UIColor clearColor];
        self.titleLab.font = [UIFont fontWithName:@"Helvetica-Bold" size:17];
        [self addSubview:self.titleLab];
    }return self;
}


-(void)setTitleLabWithText:(NSString *)text{
    self.titleLab.text = text;
    ///返回现有的视图大小
    [self.titleLab setFrame:CGRectMake(10, 0, self.frame.size.width - 10, self.frame.size.height)];
}

@end
